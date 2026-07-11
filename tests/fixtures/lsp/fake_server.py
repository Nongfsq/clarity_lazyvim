from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any


def read_message() -> dict[str, Any] | None:
    headers: dict[str, str] = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            return None
        if line in {b"\n", b"\r\n"}:
            break
        name, value = line.decode("ascii").split(":", 1)
        headers[name.lower()] = value.strip()

    length = int(headers.get("content-length", "0"))
    if length <= 0:
        return None
    return json.loads(sys.stdin.buffer.read(length))


def send(message: dict[str, Any]) -> None:
    payload = json.dumps(message, separators=(",", ":")).encode("utf-8")
    sys.stdout.buffer.write(f"Content-Length: {len(payload)}\r\n\r\n".encode("ascii"))
    sys.stdout.buffer.write(payload)
    sys.stdout.buffer.flush()


def record(message: dict[str, Any]) -> None:
    target = os.environ.get("CLARITY_FAKE_LSP_LOG")
    if not target:
        return
    event = dict(message)
    event["_server_pid"] = os.getpid()
    with Path(target).open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, separators=(",", ":")) + "\n")


def locations(message: dict[str, Any]) -> list[dict[str, Any]]:
    uri = message.get("params", {}).get("textDocument", {}).get("uri", "")
    return [
        {
            "uri": uri,
            "range": {
                "start": {"line": line, "character": 0},
                "end": {"line": line, "character": 5},
            },
        }
        for line in (0, 2, 4)
    ]


def workspace_edit(message: dict[str, Any], new_text: str, current_uri: str = "") -> dict[str, Any]:
    uri = message.get("params", {}).get("textDocument", {}).get("uri") or current_uri
    return {
        "changes": {
            uri: [
                {
                    "range": {
                        "start": {"line": 0, "character": 6},
                        "end": {"line": 0, "character": 13},
                    },
                    "newText": new_text,
                }
            ]
        }
    }


def result_for(method: str, message: dict[str, Any], current_uri: str = "") -> Any:
    if method == "initialize":
        return {
            "capabilities": {
                "codeActionProvider": True,
                "definitionProvider": True,
                "documentSymbolProvider": True,
                "hoverProvider": True,
                "inlayHintProvider": True,
                "referencesProvider": True,
                "renameProvider": True,
                "textDocumentSync": 1,
                "workspaceSymbolProvider": True,
            },
            "serverInfo": {"name": "clarity-contract-lsp", "version": "1"},
        }
    if method in {"textDocument/definition", "textDocument/references"}:
        return locations(message)
    if method == "textDocument/hover":
        return {"contents": {"kind": "markdown", "value": "Clarity fixture hover"}}
    if method == "textDocument/codeAction":
        return [
            {
                "title": "Clarity fixture code action",
                "kind": "quickfix",
                "isPreferred": True,
                "edit": workspace_edit(message, "clarity_action_applied", current_uri),
            }
        ]
    if method == "textDocument/inlayHint":
        return []
    if method == "textDocument/documentSymbol":
        return [
            {
                "name": "clarity_fixture",
                "kind": 12,
                "range": {
                    "start": {"line": 0, "character": 0},
                    "end": {"line": 0, "character": 8},
                },
                "selectionRange": {
                    "start": {"line": 0, "character": 0},
                    "end": {"line": 0, "character": 8},
                },
            }
        ]
    if method == "workspace/symbol":
        return [
            {
                "name": "clarity_fixture",
                "kind": 12,
                "location": {
                    "uri": current_uri,
                    "range": {
                        "start": {"line": 0, "character": 0},
                        "end": {"line": 0, "character": 8},
                    },
                },
            }
        ]
    if method == "textDocument/rename":
        new_name = str(message.get("params", {}).get("newName", ""))
        return workspace_edit(message, new_name, current_uri)
    if method == "shutdown":
        return None
    return None


def main() -> int:
    current_uri = ""
    while True:
        message = read_message()
        if message is None:
            return 0
        record(message)
        method = message.get("method")
        if method == "textDocument/didOpen":
            current_uri = message.get("params", {}).get("textDocument", {}).get("uri", current_uri)
        if method == "exit":
            return 0
        if "id" in message:
            send(
                {
                    "jsonrpc": "2.0",
                    "id": message["id"],
                    "result": result_for(str(method), message, current_uri),
                }
            )


if __name__ == "__main__":
    raise SystemExit(main())
