from http import HTTPStatus
from http.server import BaseHTTPRequestHandler

from server.email_otp_service import verify_email_otp
from server.twilio_verify import handle_options, read_json, write_json


def normalize_email(value):
    email = str(value or "").strip().lower()
    if "@" not in email or "." not in email.split("@")[-1]:
        raise ValueError("Valid email is required.")
    return email


class handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        handle_options(self)

    def do_POST(self):
        try:
            data = read_json(self)
            email = normalize_email(data.get("email"))
            code = str(data.get("code") or "").strip()
            if len(code) < 4:
                raise ValueError("Valid OTP code is required.")
            verify_email_otp(email, code)
            write_json(
                self,
                HTTPStatus.OK,
                {
                    "ok": True,
                    "provider": "github_email_otp_service",
                    "email": email,
                },
            )
        except Exception as error:
            write_json(
                self,
                HTTPStatus.BAD_REQUEST,
                {
                    "ok": False,
                    "stage": "verify_email_otp",
                    "error": str(error),
                },
            )
