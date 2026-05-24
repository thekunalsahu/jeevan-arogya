import base64
import json
import os
import re
from http import HTTPStatus
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


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


class TwilioApiError(Exception):
    pass


def clean_env(name):
    value = os.environ.get(name, "").strip()
    if (value.startswith("'") and value.endswith("'")) or (
        value.startswith('"') and value.endswith('"')
    ):
        value = value[1:-1].strip()
    return value


def twilio_config():
    account_sid = clean_env("TWILIO_ACCOUNT_SID")
    auth_token = clean_env("TWILIO_AUTH_TOKEN")
    service_sid = clean_env("TWILIO_VERIFY_SERVICE_SID")
    if not account_sid or not auth_token or not service_sid:
        raise RuntimeError(
            "Twilio env missing. Set TWILIO_ACCOUNT_SID, "
            "TWILIO_AUTH_TOKEN, and TWILIO_VERIFY_SERVICE_SID in Vercel."
        )
    if not account_sid.startswith("AC"):
        raise RuntimeError("TWILIO_ACCOUNT_SID must start with AC.")
    if not service_sid.startswith("VA"):
        raise RuntimeError("TWILIO_VERIFY_SERVICE_SID must start with VA.")
    if len(auth_token) < 20:
        raise RuntimeError("TWILIO_AUTH_TOKEN looks too short.")
    return account_sid, auth_token, service_sid


def twilio_env_status():
    account_sid = clean_env("TWILIO_ACCOUNT_SID")
    auth_token = clean_env("TWILIO_AUTH_TOKEN")
    service_sid = clean_env("TWILIO_VERIFY_SERVICE_SID")
    return {
        "ok": bool(account_sid and auth_token and service_sid),
        "twilio_account_sid": bool(account_sid),
        "twilio_auth_token": bool(auth_token),
        "twilio_verify_service_sid": bool(service_sid),
        "account_sid_prefix": account_sid[:2] if account_sid else "",
        "service_sid_prefix": service_sid[:2] if service_sid else "",
        "account_sid_valid": account_sid.startswith("AC") if account_sid else False,
        "service_sid_valid": service_sid.startswith("VA") if service_sid else False,
        "auth_token_length_ok": len(auth_token) >= 20 if auth_token else False,
    }


def twilio_error(error):
    return str(error)


def format_twilio_error(data, fallback):
    message = data.get("message") or data.get("error") or fallback
    code = data.get("code")
    more_info = data.get("more_info")
    details = []
    if code:
        details.append(f"code {code}")
    if more_info:
        details.append(str(more_info))
    if details:
        return f"{message} ({'; '.join(details)})"
    return str(message)


def twilio_post(path, payload):
    account_sid, auth_token, service_sid = twilio_config()
    url = f"https://verify.twilio.com/v2/Services/{service_sid}/{path}"
    body = urlencode(payload).encode("utf-8")
    auth = base64.b64encode(f"{account_sid}:{auth_token}".encode("utf-8"))
    request = Request(
        url,
        data=body,
        headers={
            "Authorization": f"Basic {auth.decode('ascii')}",
            "Content-Type": "application/x-www-form-urlencoded",
        },
        method="POST",
    )
    try:
        with urlopen(request, timeout=12) as response:
            return json.loads(response.read().decode("utf-8"))
    except HTTPError as error:
        raw = error.read().decode("utf-8")
        try:
            data = json.loads(raw)
            message = format_twilio_error(data, raw)
        except json.JSONDecodeError:
            message = raw or error.reason
        raise TwilioApiError(message) from error


def send_verification(phone):
    return twilio_post("Verifications", {"To": phone, "Channel": "sms"})


def check_verification(phone, code):
    return twilio_post("VerificationCheck", {"To": phone, "Code": code})


def handle_options(handler):
    handler.send_response(HTTPStatus.NO_CONTENT)
    for key, value in cors_headers().items():
        handler.send_header(key, value)
    handler.end_headers()
