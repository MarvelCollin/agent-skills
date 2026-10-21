#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: revision-doc.sh init <folder> [--title <title>] [--lang id|en]" >&2
    echo "       revision-doc.sh build <folder> [--out <file.docx>] [--copy-to <folder>]" >&2
    echo "       revision-doc.sh check <file.docx>" >&2
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON=""
for candidate in python3 python py; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c "import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)" >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo "ERROR: Python 3.8 or newer is needed. Install it, then run: pip install python-docx pillow" >&2
    exit 3
fi

exec "$PYTHON" "$DIR/revision_doc.py" "$@"
