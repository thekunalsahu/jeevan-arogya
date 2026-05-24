from http import HTTPStatus
from http.server import BaseHTTPRequestHandler

from server.twilio_verify import handle_options, twilio_env_status, write_json


class handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        handle_options(self)

    def do_GET(self):
        write_json(self, HTTPStatus.OK, twilio_env_status())
