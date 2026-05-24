from http import HTTPStatus
from http.server import BaseHTTPRequestHandler

from server.twilio_verify import (
    handle_options,
    normalize_phone,
    read_json,
    send_verification,
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
            verification = send_verification(phone)
            write_json(
                self,
                HTTPStatus.OK,
                {
                    "ok": True,
                    "provider": "twilio_verify",
                    "phone": phone,
                    "status": verification.get("status", "pending"),
                },
            )
        except Exception as error:
            write_json(
                self,
                HTTPStatus.BAD_REQUEST,
                {
                    "ok": False,
                    "stage": "send_otp",
                    "error": twilio_error(error),
                },
            )
