import json
import os
from urllib.error import HTTPError
from urllib.parse import urljoin
from urllib.request import Request, urlopen


class EmailOtpServiceError(Exception):
    pass


def email_otp_base_url():
    value = os.environ.get("EMAIL_OTP_SERVICE_URL", "").strip().rstrip("/")
    if not value:
        raise RuntimeError(
            "EMAIL_OTP_SERVICE_URL is missing. Add your deployed github otp-service URL."
        )
    if not value.startswith("http"):
        raise RuntimeError("EMAIL_OTP_SERVICE_URL must start with http or https.")
    return value


def _request_json(path, payload):
    base_url = email_otp_base_url()
    url = urljoin(f"{base_url}/", path.lstrip("/"))
    request = Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=12) as response:
            body = response.read().decode("utf-8")
            if not body:
                return {}
            return json.loads(body)
    except HTTPError as error:
        raw = error.read().decode("utf-8")
        try:
            data = json.loads(raw)
            message = data.get("message") or data.get("error") or raw
        except json.JSONDecodeError:
            message = raw or str(error.reason)
        raise EmailOtpServiceError(str(message)) from error


def send_email_otp(email):
    return _request_json(
        "/api/otp/generate",
        {
            "email": email,
            "type": "numeric",
            "organization": "Jeevan Arogya",
            "subject": "Your Jeevan Arogya OTP",
        },
    )


def verify_email_otp(email, code):
    return _request_json("/api/otp/verify", {"email": email, "otp": code})
