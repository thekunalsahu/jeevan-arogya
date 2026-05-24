import json
import os
import re
from http import HTTPStatus

from twilio.base.exceptions import TwilioRestException
from twilio.rest import Client


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
    raw = handler.rfile.read(length)
    return json.loads(raw.decode("utf-8"))


def normalize_phone(phone):
    trimmed = str(phone or "").strip()
    digits = re.sub(r"\D", "", trimmed)
    if len(digits) < 10:
        raise ValueError("Valid mobile number required.")
    if trimmed.startswith("+"):
        return f"+{digits}"
    if digits.startswith("91") and len(digits) == 12:
        return f"+{digits}"
    return f"+91{digits[-10:]}"


def twilio_client():
    account_sid = os.environ.get("TWILIO_ACCOUNT_SID", "").strip()
    auth_token = os.environ.get("TWILIO_AUTH_TOKEN", "").strip()
    service_sid = os.environ.get("TWILIO_VERIFY_SERVICE_SID", "").strip()
    if not account_sid or not auth_token or not service_sid:
        raise RuntimeError(
            "Twilio env missing. Set TWILIO_ACCOUNT_SID, "
            "TWILIO_AUTH_TOKEN, and TWILIO_VERIFY_SERVICE_SID in Vercel."
        )
    return Client(account_sid, auth_token), service_sid


def twilio_error(error):
    if isinstance(error, TwilioRestException):
        return error.msg or str(error)
    return str(error)


def handle_options(handler):
    handler.send_response(HTTPStatus.NO_CONTENT)
    for key, value in cors_headers().items():
        handler.send_header(key, value)
    handler.end_headers()
