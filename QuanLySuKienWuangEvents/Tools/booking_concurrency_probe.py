"""HTTP concurrency probe for WuangEvents ticket inventory.

The target event and ticket type must already exist and be on sale. Each worker
uses a separate seeded buyer account, prepares a checkout draft, then all
workers submit the final free-ticket confirmation at the same time.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import http.cookiejar
import json
import re
import statistics
import threading
import time
import urllib.parse
import urllib.request


TOKEN_PATTERN = re.compile(
    r'name="__RequestVerificationToken"[^>]*value="([^"]+)"|'
    r'value="([^"]+)"[^>]*name="__RequestVerificationToken"',
    re.IGNORECASE,
)


class WebSession:
    def __init__(self, base_url: str) -> None:
        self.base_url = base_url.rstrip("/")
        cookie_jar = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(cookie_jar)
        )

    def request(self, path: str, data: dict[str, str] | None = None):
        body = None if data is None else urllib.parse.urlencode(data).encode()
        request = urllib.request.Request(self.base_url + path, data=body)
        with self.opener.open(request, timeout=45) as response:
            return response.geturl(), response.status, response.read().decode(
                "utf-8", errors="replace"
            )


def anti_forgery_token(html: str) -> str:
    match = TOKEN_PATTERN.search(html)
    if not match:
        raise RuntimeError("Không tìm thấy anti-forgery token trong HTML.")
    return match.group(1) or match.group(2)


def prepare_worker(
    base_url: str,
    email: str,
    password: str,
    event_id: str,
    ticket_type_id: int,
) -> tuple[WebSession, str, str]:
    session = WebSession(base_url)
    session.request(
        "/Account/DangNhap",
        {"email": email, "matKhau": password, "returnUrl": "/"},
    )
    _, _, detail_html = session.request(f"/Home/ChiTiet?id={event_id}")
    form_token = anti_forgery_token(detail_html)
    final_url, _, checkout_html = session.request(
        "/Booking/DatVe",
        {
            "__RequestVerificationToken": form_token,
            "suKienId": event_id,
            f"veChon[{ticket_type_id}]": "1",
        },
    )
    query = urllib.parse.parse_qs(urllib.parse.urlsplit(final_url).query)
    checkout_token = query.get("token", [""])[0]
    if not checkout_token:
        raise RuntimeError(f"Không tạo được bản nháp thanh toán; URL cuối: {final_url}")
    return session, checkout_token, anti_forgery_token(checkout_html)


def submit_worker(
    prepared: tuple[WebSession, str, str], start: threading.Event
) -> dict[str, object]:
    session, checkout_token, form_token = prepared
    start.wait()
    began = time.perf_counter()
    try:
        final_url, status, html = session.request(
            "/Booking/XacNhanThanhToan",
            {
                "__RequestVerificationToken": form_token,
                "token": checkout_token,
                "phuongThuc": "vnpay",
            },
        )
        latency_ms = round((time.perf_counter() - began) * 1000, 1)
        success = "/Booking/ThanhCong" in final_url
        sold_out = "hết" in html.lower() or "không thể bắt đầu" in html.lower()
        return {
            "success": success,
            "sold_out": sold_out,
            "status": status,
            "latency_ms": latency_ms,
            "final_url": final_url,
        }
    except Exception as exc:  # noqa: BLE001 - report every probe failure
        return {
            "success": False,
            "sold_out": False,
            "status": 0,
            "latency_ms": round((time.perf_counter() - began) * 1000, 1),
            "error": str(exc),
        }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default="http://127.0.0.1:5080")
    parser.add_argument("--event-id", required=True)
    parser.add_argument("--ticket-type-id", required=True, type=int)
    parser.add_argument("--users", default=20, type=int)
    parser.add_argument("--password", default="123456")
    args = parser.parse_args()

    prepared: list[tuple[WebSession, str, str]] = []
    for index in range(1, args.users + 1):
        email = f"buyer{index}@wuangevents.com"
        prepared.append(
            prepare_worker(
                args.base_url,
                email,
                args.password,
                args.event_id,
                args.ticket_type_id,
            )
        )

    start = threading.Event()
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.users) as pool:
        futures = [pool.submit(submit_worker, item, start) for item in prepared]
        started_at = time.perf_counter()
        start.set()
        results = [future.result() for future in futures]
        wall_ms = round((time.perf_counter() - started_at) * 1000, 1)

    latencies = [float(item["latency_ms"]) for item in results]
    summary = {
        "attempts": len(results),
        "successes": sum(bool(item["success"]) for item in results),
        "rejected_or_failed": sum(not bool(item["success"]) for item in results),
        "wall_ms": wall_ms,
        "latency_ms_min": min(latencies),
        "latency_ms_median": round(statistics.median(latencies), 1),
        "latency_ms_max": max(latencies),
        "results": results,
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
