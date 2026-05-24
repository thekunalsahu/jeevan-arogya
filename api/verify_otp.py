from http import HTTPStatus
from http.server import BaseHTTPRequestHandler

from server.twilio_verify import (
    handle_options,
    normalize_phone,
    read_json,
    check_verification,
    twilio_error,
    write_json,
)


class handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        handle_options(self)

    def do_POST(self):
        try:
            data = read_json(self)
            phone = normalize_phone(data.get("phone"))
            code = str(data.get("code") or "").strip()
            if len(code) < 4:
                raise ValueError("Valid OTP code required.")

            check = check_verification(phone, code)
            status = check.get("status")
            approved = status == "approved"
            write_json(
                self,
                HTTPStatus.OK if approved else HTTPStatus.UNAUTHORIZED,
                {
                    "ok": approved,
                    "provider": "twilio_verify",
                    "phone": phone,
                    "status": status,
                    "error": None if approved else "Invalid or expired OTP.",
                },
            )
        except Exception as error:
            write_json(
                self,
                HTTPStatus.BAD_REQUEST,
                {"ok": False, "error": twilio_error(error)},
            )
