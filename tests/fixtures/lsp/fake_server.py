from __future__ import annotations

import json
import sys
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


def result_for(method: str) -> Any:
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
    if method in {
        "textDocument/codeAction",
        "textDocument/definition",
        "textDocument/documentSymbol",
        "textDocument/inlayHint",
        "textDocument/references",
        "workspace/symbol",
    }:
        return []
    if method == "textDocument/hover":
        return None
    if method == "textDocument/rename":
        return {"changes": {}}
    if method == "shutdown":
        return None
    return None


def main() -> int:
    while True:
        message = read_message()
        if message is None:
            return 0
        method = message.get("method")
        if method == "exit":
            return 0
        if "id" in message:
            send({"jsonrpc": "2.0", "id": message["id"], "result": result_for(str(method))})


if __name__ == "__main__":
    raise SystemExit(main())
