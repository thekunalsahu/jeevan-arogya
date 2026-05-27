import json
import math
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlencode, urlparse
from urllib.request import Request, urlopen


OVERPASS_ENDPOINTS = (
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.openstreetmap.ru/api/interpreter",
)
NOMINATIM_ENDPOINT = "https://nominatim.openstreetmap.org/search"
DEFAULT_RADIUS_METERS = 25000


def cors_headers():
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
        "Content-Type": "application/json",
        "Cache-Control": "s-maxage=300, stale-while-revalidate=600",
    }


def write_json(handler, status, payload):
    body = json.dumps(payload).encode("utf-8")
    handler.send_response(status)
    for key, value in cors_headers().items():
        handler.send_header(key, value)
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def parse_float(params, name):
    raw = (params.get(name) or [""])[0]
    try:
        value = float(raw)
    except ValueError as error:
        raise ValueError(f"Valid {name} is required.") from error
    return value


def validate_coordinates(lat, lng):
    if lat < -90 or lat > 90:
        raise ValueError("Latitude is out of range.")
    if lng < -180 or lng > 180:
        raise ValueError("Longitude is out of range.")


def parse_radius(params):
    raw = (params.get("radius") or [""])[0]
    if not raw:
        return DEFAULT_RADIUS_METERS
    try:
        value = int(float(raw))
    except ValueError as error:
        raise ValueError("Valid radius is required.") from error
    return max(2000, min(value, 30000))


def overpass_query(lat, lng, radius):
    return f"""
[out:json][timeout:18];
(
  nwr["amenity"="hospital"]["name"](around:{radius},{lat:.6f},{lng:.6f});
  nwr["healthcare"="hospital"]["name"](around:{radius},{lat:.6f},{lng:.6f});
  nwr["amenity"="doctors"]["name"](around:{radius},{lat:.6f},{lng:.6f});
  nwr["healthcare"="doctor"]["name"](around:{radius},{lat:.6f},{lng:.6f});
  nwr["amenity"="pharmacy"]["name"](around:{radius},{lat:.6f},{lng:.6f});
  nwr["healthcare"="pharmacy"]["name"](around:{radius},{lat:.6f},{lng:.6f});
  nwr["shop"~"chemist|pharmacy"]["name"](around:{radius},{lat:.6f},{lng:.6f});
);
out center 1200;
"""


def fetch_from_overpass(query):
    errors = []
    body = query.encode("utf-8")
    for endpoint in OVERPASS_ENDPOINTS:
        request = Request(
            endpoint,
            data=body,
            headers={
                "Accept": "application/json",
                "Content-Type": "text/plain; charset=utf-8",
                "User-Agent": "JeevanArogya/1.0 health-places-proxy",
            },
            method="POST",
        )
        try:
            with urlopen(request, timeout=9) as response:
                raw = response.read().decode("utf-8")
                data = json.loads(raw)
                if not isinstance(data.get("elements"), list):
                    raise ValueError("OpenStreetMap response missing elements.")
                data["proxy_source"] = endpoint
                return data
        except HTTPError as error:
            details = error.read().decode("utf-8", errors="replace")[:240]
            errors.append(f"{endpoint}: HTTP {error.code} {details}")
        except (URLError, TimeoutError, ValueError, json.JSONDecodeError) as error:
            errors.append(f"{endpoint}: {error}")
    raise RuntimeError(" | ".join(errors) or "OpenStreetMap request failed.")


def bbox_for(lat, lng, radius):
    lat_delta = radius / 111_320
    lng_scale = max(0.2, abs(math.cos(math.radians(lat))))
    lng_delta = radius / (111_320 * lng_scale)
    return (
        max(-180, lng - lng_delta),
        min(90, lat + lat_delta),
        min(180, lng + lng_delta),
        max(-90, lat - lat_delta),
    )


def fetch_nominatim_search(query, category, lat, lng, radius, limit=20):
    west, north, east, south = bbox_for(lat, lng, radius)
    params = {
        "q": query,
        "format": "jsonv2",
        "addressdetails": "1",
        "bounded": "1",
        "limit": str(limit),
        "viewbox": f"{west:.6f},{north:.6f},{east:.6f},{south:.6f}",
    }
    request = Request(
        f"{NOMINATIM_ENDPOINT}?{urlencode(params)}",
        headers={
            "Accept": "application/json",
            "User-Agent": "JeevanArogya/1.0 health-places-proxy",
        },
        method="GET",
    )
    with urlopen(request, timeout=10) as response:
        rows = json.loads(response.read().decode("utf-8"))
    if not isinstance(rows, list):
        raise ValueError("Nominatim response was not a list.")
    return [nominatim_row_to_element(row, category) for row in rows]


def nominatim_row_to_element(row, category):
    name = (
        row.get("name")
        or row.get("display_name", "").split(",")[0].strip()
        or row.get("type")
        or category
    )
    tags = {
        "name": name,
        "display_name": row.get("display_name", ""),
        "source": "Nominatim",
    }
    address = row.get("address") if isinstance(row.get("address"), dict) else {}
    for source_key, target_key in (
        ("road", "addr:street"),
        ("suburb", "addr:suburb"),
        ("neighbourhood", "addr:neighbourhood"),
        ("city", "addr:city"),
        ("town", "addr:city"),
        ("state", "addr:state"),
    ):
        if address.get(source_key):
            tags[target_key] = address[source_key]
    if category == "hospital":
        tags["amenity"] = "hospital"
        tags["healthcare"] = "hospital"
    elif category == "doctor":
        tags["amenity"] = "doctors"
        tags["healthcare"] = "doctor"
        if row.get("type") and row.get("type") != "doctors":
            tags["healthcare:speciality"] = row.get("type")
    elif category == "pharmacy":
        tags["amenity"] = "pharmacy"
        tags["healthcare"] = "pharmacy"
    elif category == "jan_aushadhi":
        tags["amenity"] = "pharmacy"
        tags["healthcare"] = "pharmacy"
        tags["brand"] = "Jan Aushadhi"
    return {
        "type": "node",
        "id": row.get("place_id"),
        "lat": float(row["lat"]),
        "lon": float(row["lon"]),
        "tags": tags,
    }


def fetch_from_nominatim(lat, lng, radius):
    elements = []
    errors = []
    searches = (
        ("hospital", "hospital", 30),
        ("doctor", "doctor", 25),
        ("pharmacy", "pharmacy", 30),
        ("Jan Aushadhi", "jan_aushadhi", 15),
    )
    for index, (query, category, limit) in enumerate(searches):
        if index:
            time.sleep(1.05)
        try:
            elements.extend(fetch_nominatim_search(query, category, lat, lng, radius, limit))
        except (HTTPError, URLError, TimeoutError, ValueError, json.JSONDecodeError, KeyError) as error:
            errors.append(f"{category}: {error}")
    if not elements:
        raise RuntimeError("Nominatim fallback failed: " + " | ".join(errors))
    return {
        "elements": elements,
        "proxy_source": "nominatim.openstreetmap.org",
        "fallback": True,
        "fallback_errors": errors,
    }


def fetch_health_places(lat, lng, radius):
    try:
        return fetch_from_nominatim(lat, lng, radius)
    except Exception as nominatim_error:
        data = fetch_from_overpass(overpass_query(lat, lng, radius))
        data["nominatim_error"] = str(nominatim_error)
        return data


class handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(HTTPStatus.NO_CONTENT)
        for key, value in cors_headers().items():
            self.send_header(key, value)
        self.end_headers()

    def do_GET(self):
        try:
            params = parse_qs(urlparse(self.path).query)
            lat = parse_float(params, "lat")
            lng = parse_float(params, "lng")
            radius = parse_radius(params)
            validate_coordinates(lat, lng)
            data = fetch_health_places(lat, lng, radius)
            write_json(self, HTTPStatus.OK, data)
        except ValueError as error:
            write_json(
                self,
                HTTPStatus.BAD_REQUEST,
                {"ok": False, "stage": "health_places", "error": str(error)},
            )
        except Exception as error:
            write_json(
                self,
                HTTPStatus.BAD_GATEWAY,
                {"ok": False, "stage": "health_places", "error": str(error)},
            )


if __name__ == "__main__":
    from http.server import HTTPServer

    server = HTTPServer(("127.0.0.1", 8787), handler)
    print("Jeevan Arogya health proxy running at http://127.0.0.1:8787")
    server.serve_forever()
