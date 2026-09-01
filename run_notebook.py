"""Executa um notebook .ipynb com progresso por célula de código."""

from __future__ import annotations

import asyncio
import sys
import warnings
from pathlib import Path

import nbformat
from nbclient import NotebookClient

# No Windows (< 3.14), o ProactorEventLoop do asyncio não cobre bem o zmq do kernel.
if sys.platform.startswith("win") and sys.version_info < (3, 14):
    try:
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    except AttributeError:
        pass

warnings.filterwarnings(
    "ignore",
    message=".*Proactor event loop does not implement add_reader.*",
)


def _preview(source: str, max_len: int = 64) -> str:
    line = (source or "").strip().splitlines()
    text = line[0] if line else "(vazia)"
    text = " ".join(text.split())
    if len(text) > max_len:
        return text[: max_len - 3] + "..."
    return text


def main() -> int:
    if len(sys.argv) != 2:
        print("Uso: python run_notebook.py <caminho.ipynb>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1]).resolve()
    if not path.is_file():
        print(f"Notebook não encontrado: {path}", file=sys.stderr)
        return 1

    nb = nbformat.read(path, as_version=4)
    code_total = sum(1 for cell in nb.cells if cell.cell_type == "code")
    print(f"Notebook: {path.name} ({code_total} células de código)")
    print("")

    notebook_dir = path.parent
    print(f"Diretório: {notebook_dir}")
    print("")

    client = NotebookClient(
        nb,
        timeout=None,
        kernel_name="python3",
        resources={"metadata": {"path": str(notebook_dir)}},
    )
    done = 0

    with client.setup_kernel():
        for index, cell in enumerate(nb.cells):
            if cell.cell_type != "code":
                continue
            done += 1
            print(f"[{done}/{code_total}] {_preview(cell.source)}", flush=True)
            client.execute_cell(cell, index)

    nbformat.write(nb, path)
    print("")
    print(f"Salvo: {path.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
