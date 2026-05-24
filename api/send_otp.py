from http import HTTPStatus
from http.server import BaseHTTPRequestHandler

from server.twilio_verify import (
    handle_options,
    normalize_phone,
    read_json,
    twilio_client,
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
            client, service_sid = twilio_client()
            verification = client.verify.v2.services(
                service_sid
            ).verifications.create(to=phone, channel="sms")
            write_json(
                self,
                HTTPStatus.OK,
                {
                    "ok": True,
                    "provider": "twilio_verify",
                    "phone": phone,
                    "status": verification.status,
                },
            )
        except Exception as error:
            write_json(
                self,
                HTTPStatus.BAD_REQUEST,
                {"ok": False, "error": twilio_error(error)},
            )
