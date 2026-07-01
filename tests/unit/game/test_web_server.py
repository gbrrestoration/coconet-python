from __future__ import annotations

import json
import threading
from http.client import HTTPConnection
from http.server import ThreadingHTTPServer
from pathlib import Path

from coconet.game.leaderboard import LeaderboardStore
from coconet.game.session import SessionStore
from coconet.game.web_server import make_handler


def test_web_server_creates_session_and_serves_static(tmp_path: Path) -> None:
    store = SessionStore()
    leaderboard = LeaderboardStore(tmp_path / "leaderboard.json")
    handler = make_handler(store, leaderboard)
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    host, port = server.server_address
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        conn = HTTPConnection(host, port, timeout=5)
        conn.request("POST", "/api/sessions")
        create_resp = conn.getresponse()
        assert create_resp.status == 201
        payload = json.loads(create_resp.read().decode("utf-8"))
        session_id = payload["session_id"]

        conn.request("GET", f"/api/sessions/{session_id}")
        state_resp = conn.getresponse()
        assert state_resp.status == 200
        state = json.loads(state_resp.read().decode("utf-8"))
        assert state["reef"]["coral_cover"] == 62.0

        conn.request("GET", "/api/help")
        help_resp = conn.getresponse()
        assert help_resp.status == 200
        help_payload = json.loads(help_resp.read().decode("utf-8"))
        assert "steps" in help_payload

        conn.request("GET", "/api/leaderboard")
        board_resp = conn.getresponse()
        assert board_resp.status == 200
        board_payload = json.loads(board_resp.read().decode("utf-8"))
        assert board_payload["entries"] == []

        conn.request("GET", "/leaderboard.html")
        board_page_resp = conn.getresponse()
        assert board_page_resp.status == 200

        conn.request("GET", "/")
        index_resp = conn.getresponse()
        assert index_resp.status == 200
        body = index_resp.read().decode("utf-8")
        assert "Reef Rescuer" in body
    finally:
        server.shutdown()
        thread.join(timeout=2)
