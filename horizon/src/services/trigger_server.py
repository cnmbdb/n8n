"""Small HTTP trigger service for running Horizon from n8n."""

from __future__ import annotations

import json
import os
import subprocess
import threading
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


HOST = os.getenv("HORIZON_TRIGGER_HOST", "0.0.0.0")
PORT = int(os.getenv("HORIZON_TRIGGER_PORT", "8765"))
LOG_DIR = Path(os.getenv("HORIZON_TRIGGER_LOG_DIR", "data/logs"))

_run_lock = threading.Lock()
_active_process: subprocess.Popen[str] | None = None


def _json_response(handler: BaseHTTPRequestHandler, status: int, payload: dict[str, Any]) -> None:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


def _read_json(handler: BaseHTTPRequestHandler) -> dict[str, Any]:
    length = int(handler.headers.get("Content-Length", "0") or "0")
    if length <= 0:
        return {}
    raw = handler.rfile.read(length).decode("utf-8")
    return json.loads(raw) if raw.strip() else {}


def _start_horizon(hours: int) -> tuple[str, subprocess.Popen[str], Path]:
    global _active_process

    run_id = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:8]
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_path = LOG_DIR / f"horizon-{run_id}.log"
    log_file = log_path.open("w", encoding="utf-8")
    command = ["uv", "run", "horizon", "--hours", str(hours)]

    process = subprocess.Popen(
        command,
        cwd="/app",
        stdout=log_file,
        stderr=subprocess.STDOUT,
        text=True,
    )
    _active_process = process
    return run_id, process, log_path


def _clear_active_when_done(process: subprocess.Popen[str]) -> None:
    global _active_process
    process.wait()
    with _run_lock:
        if _active_process is process:
            _active_process = None


class TriggerHandler(BaseHTTPRequestHandler):
    server_version = "HorizonTrigger/1.0"

    def do_GET(self) -> None:
        if self.path == "/health":
            _json_response(self, 200, {"ok": True, "service": "horizon-trigger"})
            return
        _json_response(self, 404, {"ok": False, "error": "not_found"})

    def do_POST(self) -> None:
        global _active_process

        if self.path != "/run-horizon":
            _json_response(self, 404, {"ok": False, "error": "not_found"})
            return

        try:
            payload = _read_json(self)
            hours = int(payload.get("hours", 24))
            wait = bool(payload.get("wait", False))
        except Exception as exc:
            _json_response(self, 400, {"ok": False, "error": f"invalid_request: {exc}"})
            return

        with _run_lock:
            if _active_process and _active_process.poll() is None:
                _json_response(self, 409, {"ok": False, "error": "horizon_already_running"})
                return
            run_id, process, log_path = _start_horizon(hours)

        if wait:
            return_code = process.wait()
            with _run_lock:
                if _active_process is process:
                    _active_process = None
            _json_response(
                self,
                200 if return_code == 0 else 500,
                {
                    "ok": return_code == 0,
                    "run_id": run_id,
                    "return_code": return_code,
                    "log_path": str(log_path),
                },
            )
            return

        threading.Thread(target=_clear_active_when_done, args=(process,), daemon=True).start()
        _json_response(
            self,
            202,
            {
                "ok": True,
                "run_id": run_id,
                "pid": process.pid,
                "log_path": str(log_path),
            },
        )

    def log_message(self, fmt: str, *args: Any) -> None:
        print(f"{self.address_string()} - {fmt % args}", flush=True)


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), TriggerHandler)
    print(f"Horizon trigger server listening on {HOST}:{PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
