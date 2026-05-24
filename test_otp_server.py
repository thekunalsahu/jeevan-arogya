import base64
import json
import os
import unittest
from unittest.mock import patch

from server import twilio_verify


class TwilioVerifyTests(unittest.TestCase):
    def test_normalize_phone_indian_number(self):
        self.assertEqual(twilio_verify.normalize_phone("9301739370"), "+919301739370")
        self.assertEqual(twilio_verify.normalize_phone("+91 93017 39370"), "+919301739370")

    def test_env_validation(self):
        with patch.dict(
            os.environ,
            {
                "TWILIO_ACCOUNT_SID": "bad",
                "TWILIO_AUTH_TOKEN": "x" * 32,
                "TWILIO_VERIFY_SERVICE_SID": "VA" + "1" * 32,
            },
            clear=True,
        ):
            with self.assertRaisesRegex(RuntimeError, "must start with AC"):
                twilio_verify.twilio_config()

    def test_send_verification_request_shape(self):
        captured = {}

        class FakeResponse:
            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc, tb):
                return False

            def read(self):
                return json.dumps({"status": "pending"}).encode("utf-8")

        def fake_urlopen(request, timeout):
            captured["url"] = request.full_url
            captured["body"] = request.data.decode("utf-8")
            captured["auth"] = request.headers["Authorization"]
            return FakeResponse()

        with patch.dict(
            os.environ,
            {
                "TWILIO_ACCOUNT_SID": "AC" + "1" * 32,
                "TWILIO_AUTH_TOKEN": "a" * 32,
                "TWILIO_VERIFY_SERVICE_SID": "VA" + "2" * 32,
            },
            clear=True,
        ), patch("server.twilio_verify.urlopen", fake_urlopen):
            response = twilio_verify.send_verification("+919301739370")

        expected_auth = base64.b64encode(
            f"{'AC' + '1' * 32}:{'a' * 32}".encode("utf-8")
        ).decode("ascii")
        self.assertEqual(response["status"], "pending")
        self.assertIn("/Verifications", captured["url"])
        self.assertIn("To=%2B919301739370", captured["body"])
        self.assertIn("Channel=sms", captured["body"])
        self.assertEqual(captured["auth"], f"Basic {expected_auth}")


if __name__ == "__main__":
    unittest.main()
