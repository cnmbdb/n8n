#!/usr/bin/env python3
"""Bind the Horizon trigger server lifecycle to the Horizon Docker container."""

from __future__ import annotations

import os
import signal
import subprocess
import time
from datetime import datetime
from pathlib import Path


ROOT_DIR = Path(os.environ.get("N8N_PROJECT_DIR", "/Users/a2333/IDE/n8n"))
LOG_DIR = Path(os.environ.get("HORIZON_TRIGGER_LOG_DIR", ROOT_DIR / "logs"))
CONTAINER = os.environ.get("HORIZON_CONTAINER_NAME", "horizon")
PYTHON = os.environ.get("HORIZON_TRIGGER_PYTHON", "/opt/homebrew/opt/python@3.11/libexec/bin/python3")
DOCKER = os.environ.get("HORIZON_TRIGGER_DOCKER", "/usr/local/bin/docker")
SERVER_SCRIPT = ROOT_DIR / "scripts" / "horizon_trigger_server.py"

server_proc: subprocess.Popen | None = None


def now() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def log(message: str) -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with (LOG_DIR / "horizon-trigger-watcher.log").open("a", encoding="utf-8") as fh:
        fh.write(f"[{now()}] {message}\n")


def horizon_running() -> bool:
    result = subprocess.run(
        [DOCKER, "inspect", "-f", "{{.State.Running}}", CONTAINER],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=False,
    )
    return result.returncode == 0 and result.stdout.strip() == "true"


def start_server() -> None:
    global server_proc
    if server_proc and server_proc.poll() is None:
        return

    env = os.environ.copy()
    env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    stdout = (LOG_DIR / "horizon-trigger-server.log").open("a", encoding="utf-8")
    server_proc = subprocess.Popen(
        [PYTHON, str(SERVER_SCRIPT)],
        cwd=str(ROOT_DIR),
        env=env,
        stdout=stdout,
        stderr=subprocess.STDOUT,
        text=True,
    )
    log(f"started trigger server pid={server_proc.pid}")


def stop_server() -> None:
    global server_proc
    if not server_proc or server_proc.poll() is not None:
        server_proc = None
        return

    pid = server_proc.pid
    server_proc.terminate()
    try:
        server_proc.wait(timeout=8)
    except subprocess.TimeoutExpired:
        server_proc.kill()
        server_proc.wait(timeout=3)
    log(f"stopped trigger server pid={pid}")
    server_proc = None


def sync_once() -> None:
    if horizon_running():
        start_server()
    else:
        stop_server()


def follow_docker_events() -> None:
    cmd = [
        DOCKER,
        "events",
        "--filter",
        f"container={CONTAINER}",
        "--filter",
        "type=container",
        "--format",
        "{{.Action}}",
    ]
    log(f"watching Docker events for container={CONTAINER}")
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    assert proc.stdout is not None
    for line in proc.stdout:
        action = line.strip()
        if not action:
            continue
        log(f"docker event: {action}")
        if action in {"start", "restart"}:
            start_server()
        elif action in {"die", "stop", "kill", "destroy"}:
            stop_server()

    rc = proc.wait()
    log(f"docker events exited rc={rc}; reconnecting")


def handle_shutdown(signum: int, _frame: object) -> None:
    log(f"watcher received signal {signum}")
    stop_server()
    raise SystemExit(0)


def main() -> None:
    signal.signal(signal.SIGTERM, handle_shutdown)
    signal.signal(signal.SIGINT, handle_shutdown)
    log("watcher started")

    while True:
        sync_once()
        try:
            follow_docker_events()
        except Exception as exc:
            log(f"watcher error: {exc}")
            time.sleep(3)


if __name__ == "__main__":
    main()
