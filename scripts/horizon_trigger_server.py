#!/usr/bin/env python3
"""Small host-side HTTP trigger for running Horizon from n8n.

n8n runs inside Docker, so its Execute Command node cannot directly run the
host's uv/Horizon environment. This listener stays on the Mac host and exposes
a tiny HTTP API that n8n can call via http://host.docker.internal:<port>.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import threading
import uuid
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


ROOT_DIR = Path(os.environ.get("N8N_PROJECT_DIR", "/Users/a2333/IDE/n8n"))
HORIZON_DIR = Path(os.environ.get("HORIZON_DIR", ROOT_DIR / "horizon"))
LOG_DIR = Path(os.environ.get("HORIZON_TRIGGER_LOG_DIR", ROOT_DIR / "logs"))
HOST = os.environ.get("HORIZON_TRIGGER_HOST", "0.0.0.0")
PORT = int(os.environ.get("HORIZON_TRIGGER_PORT", "8765"))
TOKEN = os.environ.get("HORIZON_TRIGGER_TOKEN", "")
UV_BIN = os.environ.get("HORIZON_UV_BIN") or shutil.which("uv") or "/opt/homebrew/bin/uv"

RUNS: dict[str, dict[str, Any]] = {}
RUN_LOCK = threading.Lock()


def now_iso() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def archive_summaries(log_file: Path) -> None:
    summaries = HORIZON_DIR / "data" / "summaries"
    archive = summaries / "archive"
    archive.mkdir(parents=True, exist_ok=True)

    with log_file.open("a", encoding="utf-8") as log:
        log.write(f"\n[{now_iso()}] Organizing Horizon summaries...\n")

        for pattern in ("horizon-*-en.md", "horizon-*-zh.md"):
            for src in summaries.glob(pattern):
                dst = archive / src.name
                if src.resolve() == dst.resolve():
                    continue
                if dst.exists():
                    dst.unlink()
                shutil.move(str(src), str(dst))
                log.write(f"[{now_iso()}] archived {src} -> {dst}\n")

        for alias in (
            summaries / "latest-en.md",
            summaries / "horizon-summary-en.md",
            summaries / "horizon-summary-zh.md",
            archive / "horizon-summary-en.md",
            archive / "horizon-summary-zh.md",
        ):
            if alias.exists():
                alias.unlink()
                log.write(f"[{now_iso()}] removed {alias}\n")


def run_horizon(run_id: str, hours: int) -> None:
    started = now_iso()
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    log_file = LOG_DIR / f"horizon-manual-{datetime.now():%Y%m%d-%H%M%S}-{run_id}.log"

    RUNS[run_id].update(
        {
            "status": "running",
            "started_at": started,
            "log_file": str(log_file),
        }
    )

    try:
        with RUN_LOCK:
            cmd = [UV_BIN, "run", "horizon", "--hours", str(hours)]
            env = os.environ.copy()
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

            with log_file.open("w", encoding="utf-8") as log:
                log.write(f"[{started}] Running: {' '.join(cmd)}\n")
                log.write(f"[{started}] cwd: {HORIZON_DIR}\n\n")
                log.flush()

                proc = subprocess.Popen(
                    cmd,
                    cwd=str(HORIZON_DIR),
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                )
                assert proc.stdout is not None
                for line in proc.stdout:
                    log.write(line)
                    log.flush()

                rc = proc.wait()

            if rc == 0:
                archive_summaries(log_file)

            latest_zh = latest_archive_file("zh")
            latest_en = latest_archive_file("en")
            generated_summary = bool(latest_zh or latest_en)
            status = "success" if rc == 0 and generated_summary else "failed"
            error = None
            if rc == 0 and not generated_summary:
                error = "Horizon exited successfully but no summary markdown files were generated."
            elif rc != 0:
                error = f"Horizon exited with code {rc}."

            RUNS[run_id].update(
                {
                    "status": status,
                    "finished_at": now_iso(),
                    "return_code": rc,
                    "latest_zh": str(latest_zh) if latest_zh else None,
                    "latest_en": str(latest_en) if latest_en else None,
                    "error": error,
                }
            )
    except Exception as exc:
        with log_file.open("a", encoding="utf-8") as log:
            log.write(f"\n[{now_iso()}] ERROR: {exc}\n")
        RUNS[run_id].update(
            {
                "status": "failed",
                "finished_at": now_iso(),
                "return_code": None,
                "error": str(exc),
            }
        )


def latest_archive_file(language: str) -> Path | None:
    archive = HORIZON_DIR / "data" / "summaries" / "archive"
    files = sorted(
        archive.glob(f"horizon-*-{language}.md"),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    return files[0] if files else None


class Handler(BaseHTTPRequestHandler):
    server_version = "HorizonTrigger/1.0"

    def do_GET(self) -> None:
        if not self.authorized():
            return

        if self.path == "/health":
            self.send_json({"ok": True, "service": "horizon-trigger", "time": now_iso()})
            return

        if self.path == "/runs":
            self.send_json({"runs": list(RUNS.values())})
            return

        if self.path.startswith("/runs/"):
            run_id = self.path.rsplit("/", 1)[-1]
            run = RUNS.get(run_id)
            if not run:
                self.send_json({"error": "run not found", "run_id": run_id}, status=404)
                return
            self.send_json(run)
            return

        self.send_json({"error": "not found"}, status=404)

    def do_POST(self) -> None:
        if not self.authorized():
            return

        if self.path != "/run-horizon":
            self.send_json({"error": "not found"}, status=404)
            return

        payload = self.read_json()
        hours = int(payload.get("hours", 24))
        wait = bool(payload.get("wait", False))
        run_id = uuid.uuid4().hex[:12]
        RUNS[run_id] = {
            "run_id": run_id,
            "status": "queued",
            "hours": hours,
            "created_at": now_iso(),
        }

        thread = threading.Thread(target=run_horizon, args=(run_id, hours), daemon=True)
        thread.start()

        if wait:
            thread.join()

        body = {
            **RUNS[run_id],
            "status_url": f"/runs/{run_id}",
        }
        if wait and body.get("status") == "failed":
            self.send_json(body, status=500)
        else:
            self.send_json(body)

    def read_json(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0") or "0")
        if length <= 0:
            return {}
        raw = self.rfile.read(length).decode("utf-8")
        return json.loads(raw or "{}")

    def authorized(self) -> bool:
        if not TOKEN:
            return True
        got = self.headers.get("X-Horizon-Token", "")
        if got == TOKEN:
            return True
        self.send_json({"error": "unauthorized"}, status=401)
        return False

    def send_json(self, data: dict[str, Any], status: int = 200) -> None:
        body = json.dumps(data, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args: Any) -> None:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        with (LOG_DIR / "horizon-trigger-access.log").open("a", encoding="utf-8") as log:
            log.write(f"[{now_iso()}] {self.address_string()} {fmt % args}\n")


def main() -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Horizon trigger listening on http://{HOST}:{PORT}")
    print(f"Horizon dir: {HORIZON_DIR}")
    server.serve_forever()


if __name__ == "__main__":
    main()
