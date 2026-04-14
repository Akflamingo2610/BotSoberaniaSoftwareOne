from __future__ import annotations

import json
import sys

from app.lambda_handler import handler


def main() -> int:
    event = {
        "version": "2.0",
        "routeKey": "GET /health",
        "rawPath": "/health",
        "rawQueryString": "",
        "headers": {"host": "localhost", "x-forwarded-proto": "https"},
        "requestContext": {
            "http": {
                "method": "GET",
                "path": "/health",
                "protocol": "HTTP/1.1",
                "sourceIp": "127.0.0.1",
                "userAgent": "lambda-smoke-test",
            },
            "requestId": "lambda-smoke-test",
            "routeKey": "GET /health",
            "stage": "$default",
            "time": "07/Apr/2026:18:10:00 +0000",
            "timeEpoch": 1775585400000,
        },
        "isBase64Encoded": False,
    }

    response = handler(event, {})
    status_code = int(response.get("statusCode", 0))
    body_raw = response.get("body", "{}")
    body = json.loads(body_raw) if isinstance(body_raw, str) else body_raw

    if status_code != 200:
        print(f"Lambda smoke test failed: status={status_code}, response={response}")
        return 1
    if not body.get("ok"):
        print(f"Lambda smoke test failed: invalid body={body}")
        return 1

    print("Lambda smoke test passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
