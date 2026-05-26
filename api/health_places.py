import json
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlparse
from urllib.request import Request, urlopen


OVERPASS_ENDPOINTS = (
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass.openstreetmap.ru/api/interpreter",
)


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


def overpass_query(lat, lng):
    return f"""
[out:json][timeout:30];
(
  node["amenity"~"hospital|doctors|pharmacy"](around:25000,{lat:.6f},{lng:.6f});
  way["amenity"~"hospital|doctors|pharmacy"](around:25000,{lat:.6f},{lng:.6f});
  relation["amenity"~"hospital|doctors|pharmacy"](around:25000,{lat:.6f},{lng:.6f});
  node["healthcare"~"hospital|doctor|pharmacy"](around:25000,{lat:.6f},{lng:.6f});
  way["healthcare"~"hospital|doctor|pharmacy"](around:25000,{lat:.6f},{lng:.6f});
  relation["healthcare"~"hospital|doctor|pharmacy"](around:25000,{lat:.6f},{lng:.6f});
);
out center 1500;
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
            with urlopen(request, timeout=35) as response:
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
            validate_coordinates(lat, lng)
            data = fetch_from_overpass(overpass_query(lat, lng))
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
