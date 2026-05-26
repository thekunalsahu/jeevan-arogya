import json
import os
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler
from urllib.error import HTTPError
from urllib.request import Request, urlopen


GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
DEFAULT_MODEL = "meta-llama/llama-4-scout-17b-16e-instruct"


def cors_headers():
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
        "Content-Type": "application/json",
    }


def write_json(handler, status, payload):
    body = json.dumps(payload).encode("utf-8")
    handler.send_response(status)
    for key, value in cors_headers().items():
        handler.send_header(key, value)
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def read_json(handler):
    length = int(handler.headers.get("content-length", "0") or "0")
    if length <= 0:
        return {}
    return json.loads(handler.rfile.read(length).decode("utf-8"))


def clean_env(name):
    value = os.environ.get(name, "").strip()
    if (value.startswith("'") and value.endswith("'")) or (
        value.startswith('"') and value.endswith('"')
    ):
        value = value[1:-1].strip()
    return value


def summarize_list(title, rows, fields):
    if not rows:
        return f"{title}: none available from GPS yet."
    lines = [f"{title}:"]
    for row in rows[:8]:
        parts = [str(row.get(field, "")).strip() for field in fields]
        parts = [part for part in parts if part]
        lines.append(f"- {' | '.join(parts)}")
    return "\n".join(lines)


def build_prompt(data):
    location = data.get("location") or {}
    upload = data.get("upload") or {}
    language = data.get("language") or "english"
    prompt = [
        f"Preferred language: {language}.",
        f"User location: {location.get('label', 'not available')} "
        f"({location.get('lat', '')}, {location.get('lng', '')}).",
        f"User question: {data.get('message', '').strip()}",
        summarize_list(
            "Nearby hospitals",
            data.get("nearbyHospitals") or [],
            ["name", "distance", "status", "phone"],
        ),
        summarize_list(
            "Nearby doctors",
            data.get("nearbyDoctors") or [],
            ["name", "specialty", "distance", "phone", "address"],
        ),
        summarize_list(
            "Nearby medical stores",
            data.get("medicalStores") or [],
            ["name", "distance", "area", "phone"],
        ),
        summarize_list(
            "Saved health records",
            data.get("healthRecords") or [],
            ["title", "notes", "attachment", "mime"],
        ),
    ]
    if upload.get("name"):
        prompt.append(
            "Uploaded file: "
            f"{upload.get('name')} | {upload.get('mime')} | {upload.get('size')} bytes"
        )
    if upload.get("text"):
        prompt.append(f"Uploaded report text:\n{upload.get('text')}")
    return "\n\n".join(prompt)


def build_messages(data):
    system = (
        "You are ArogyaX, a careful health assistant inside Jeevan Arogya. "
        "You can explain medical reports, suggest what specialist to consult, "
        "and use the provided nearby doctors, hospitals, and medical stores. "
        "Do not claim a diagnosis. For emergency symptoms like chest pain, "
        "breathing difficulty, stroke signs, severe bleeding, poisoning, or "
        "loss of consciousness, tell the user to call local emergency services "
        "or visit the nearest emergency hospital immediately. Keep answers "
        "practical, location-aware, and easy to understand."
    )
    text = build_prompt(data)
    upload = data.get("upload") or {}
    image = upload.get("imageBase64") or ""
    mime = upload.get("mime") or "image/jpeg"
    if image and mime.startswith("image/"):
        content = [
            {"type": "text", "text": text},
            {
                "type": "image_url",
                "image_url": {"url": f"data:{mime};base64,{image}"},
            },
        ]
    else:
        content = text
    return [
        {"role": "system", "content": system},
        {"role": "user", "content": content},
    ]


def ask_groq(data):
    api_key = clean_env("GROQ_API_KEY")
    if not api_key:
        raise RuntimeError("GROQ_API_KEY env var is missing in Vercel.")
    model = clean_env("GROQ_MODEL") or DEFAULT_MODEL
    body = json.dumps(
        {
            "model": model,
            "messages": build_messages(data),
            "temperature": 0.35,
            "max_completion_tokens": 900,
        }
    ).encode("utf-8")
    request = Request(
        GROQ_URL,
        data=body,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urlopen(request, timeout=45) as response:
            raw = response.read().decode("utf-8")
            payload = json.loads(raw)
            return payload["choices"][0]["message"]["content"]
    except HTTPError as error:
        raw = error.read().decode("utf-8", errors="replace")
        try:
            payload = json.loads(raw)
            message = payload.get("error", {}).get("message") or raw
        except json.JSONDecodeError:
            message = raw or error.reason
        raise RuntimeError(str(message)) from error


class handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(HTTPStatus.NO_CONTENT)
        for key, value in cors_headers().items():
            self.send_header(key, value)
        self.end_headers()

    def do_POST(self):
        try:
            data = read_json(self)
            answer = ask_groq(data)
            write_json(self, HTTPStatus.OK, {"ok": True, "answer": answer})
        except Exception as error:
            write_json(
                self,
                HTTPStatus.BAD_REQUEST,
                {"ok": False, "stage": "arogyax", "error": str(error)},
            )
