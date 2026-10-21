REVSCRIPTS="$ROOT/skills/revision-doc/scripts"
REV_PY="$(find_python)"

echo "revision-doc"
if [ -z "$REV_PY" ] || ! "$REV_PY" -c "import docx, PIL" >/dev/null 2>&1; then
    echo "python-docx or pillow not found, skipping revision-doc tests"
else
    REV="$WORK/revision"
    OUT=$(bash "$REVSCRIPTS/revision-doc.sh" init "$REV" --title "Revision 21" --lang en 2>&1); CODE=$?
    expect_exit "init exits 0" "$CODE" 0
    expect_contains "init creates the folder" "$OUT" "CREATED:"
    expect_contains "init uses the english labels" "$OUT" "LABELS: Asked, Changed, Checked"
    if [ -f "$REV/items.json" ] && [ -f "$REV/before/boxes.json" ] && [ -f "$REV/after/boxes.json" ]; then
        pass "init writes items.json and both boxes.json"
    else
        fail "init writes items.json and both boxes.json"
    fi
    OUT=$(bash "$REVSCRIPTS/revision-doc.sh" init "$REV" 2>&1); CODE=$?
    expect_exit "init refuses an existing report" "$CODE" 2
    expect_contains "init explains why it refused" "$OUT" "already exists"

    "$REV_PY" - "$REV" <<'PY'
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(sys.argv[1])
for side, color in (("before", (240, 200, 200)), ("after", (200, 230, 200))):
    folder = root / side / "hr"
    folder.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", (1440, 900), "white")
    ImageDraw.Draw(image).rectangle([100, 100, 700, 500], fill=color)
    image.save(folder / "01-screen.png")
(root / "before" / "boxes.json").write_text(json.dumps({"hr/01-screen.png": [{"x": 100, "y": 100, "w": 600, "h": 400}]}), encoding="utf-8")
(root / "items.json").write_text(json.dumps({
    "title": "Revision 21",
    "intro": "Before and after of each change.",
    "lang": "en",
    "output": "Revision 21.docx",
    "items": [
        {"title": "Sticky section list", "asked": ["Make it sticky"], "changed": ["It sticks"], "checked": ["Scrolled 700px"], "before": "hr/01-screen.png", "after": "hr/01-screen.png"},
        {"title": "Error in view", "asked": ["Error was hidden"], "changed": ["Scrolls to it"], "checked": ["Saved from the bottom"], "before_note": "The error was off screen.", "after": "hr/02-missing.png"},
    ],
}), encoding="utf-8")
PY

    mkdir -p "$WORK/revision-downloads"
    OUT=$(REVISION_DOC_AUTHOR="Test Author" bash "$REVSCRIPTS/revision-doc.sh" build "$REV" --copy-to "$WORK/revision-downloads" 2>&1); CODE=$?
    expect_exit "build exits 0" "$CODE" 0
    expect_contains "build uses the author override" "$OUT" "AUTHOR: Test Author"
    expect_contains "build counts the items" "$OUT" "ITEMS: 2"
    expect_contains "build counts the pictures it placed" "$OUT" "IMAGES: 2"
    expect_contains "build embeds a thumbnail" "$OUT" "THUMBNAIL: embedded"
    expect_contains "build reports a missing picture" "$OUT" "MISSING_IMAGE: after/hr/02-missing.png"
    expect_contains "build copies the report" "$OUT" "COPIED:"
    if [ -f "$WORK/revision-downloads/Revision 21.docx" ]; then
        pass "build copies the docx into the target folder"
    else
        fail "build copies the docx into the target folder"
    fi
    if [ -f "$REV/boxed/before/hr/01-screen.png" ]; then
        pass "build writes the boxed picture"
    else
        fail "build writes the boxed picture"
    fi

    OUT=$(bash "$REVSCRIPTS/revision-doc.sh" check "$REV/Revision 21.docx" 2>&1); CODE=$?
    expect_exit "check passes a built report" "$CODE" 0
    expect_contains "check reads the author" "$OUT" "AUTHOR: Test Author"
    expect_contains "check finds the thumbnail" "$OUT" "THUMBNAIL: embedded"

    OUT=$("$REV_PY" - "$REV/Revision 21.docx" "$REV/boxed/before/hr/01-screen.png" <<'PY'
import io
import sys
import zipfile
from PIL import Image

archive = zipfile.ZipFile(sys.argv[1])
names = archive.namelist()
thumbs = [name for name in names if name.startswith("docProps/thumbnail")]
print(f"THUMBS: {len(thumbs)}")
thumb = Image.open(io.BytesIO(archive.read(thumbs[0]))).convert("L")
dark = sum(thumb.histogram()[:200])
print(f"THUMB_BLANK: {'yes' if dark < 500 else 'no'}")
document = archive.read("word/document.xml").decode("utf-8")
print("LABELS_EN: " + ("yes" if "Before" in document and "Checked" in document else "no"))
print("NOTE: " + ("yes" if "The error was off screen." in document else "no"))
boxed = Image.open(sys.argv[2]).convert("RGB")
print(f"BOX_PIXEL: {boxed.getpixel((98, 300))}")
PY
)
    expect_contains "the docx holds one thumbnail, not the template's plus ours" "$OUT" "THUMBS: 1"
    expect_contains "the thumbnail is not a blank page" "$OUT" "THUMB_BLANK: no"
    expect_contains "the docx uses the english labels" "$OUT" "LABELS_EN: yes"
    expect_contains "the docx shows the note for a missing before shot" "$OUT" "NOTE: yes"
    expect_contains "the red box is drawn around the change" "$OUT" "BOX_PIXEL: (220, 38, 38)"

    OUT=$(bash "$REVSCRIPTS/revision-doc.sh" build "$REV" 2>&1); CODE=$?
    expect_exit "build without an override still exits 0" "$CODE" 0
    expect_matches "build without an override never writes python-docx as author" "$OUT" "AUTHOR: [^ ].*"
    if printf '%s\n' "$OUT" | grep -q "AUTHOR: python-docx"; then
        fail "the default author is not python-docx" "$OUT"
    else
        pass "the default author is not python-docx"
    fi

    "$REV_PY" -c "import docx, sys; docx.Document().save(sys.argv[1])" "$WORK/revision-plain.docx"
    OUT=$(bash "$REVSCRIPTS/revision-doc.sh" check "$WORK/revision-plain.docx" 2>&1); CODE=$?
    expect_exit "check fails a plain python-docx file" "$CODE" 1
    expect_contains "check flags the python-docx author" "$OUT" "PROBLEM: author is empty or python-docx"

    BAD="$WORK/revision-bad"
    mkdir -p "$BAD"
    printf '{"items": [{"before": "x.png"}]}' > "$BAD/items.json"
    OUT=$(bash "$REVSCRIPTS/revision-doc.sh" build "$BAD" 2>&1); CODE=$?
    expect_exit "build rejects a malformed items.json" "$CODE" 2
    expect_contains "build names the missing title" "$OUT" "INVALID: items.json needs 'title'"
    expect_contains "build names the missing after shot" "$OUT" "INVALID: item 1 needs 'after' or 'after_note'"

    bash "$REVSCRIPTS/revision-doc.sh" >/dev/null 2>&1; CODE=$?
    expect_exit "fails without a command" "$CODE" 1

    if [ -n "$POWERSHELL" ]; then
        echo "revision-doc.ps1"
        OUT=$(REVISION_DOC_AUTHOR="PS Author" run_ps "$REVSCRIPTS/revision-doc.ps1" build "$REV" -Out "$WORK/revision-ps.docx" 2>&1 | tr -d '\r'); CODE=$?
        expect_exit "ps1 build exits 0" "$CODE" 0
        expect_contains "ps1 build uses the author override" "$OUT" "AUTHOR: PS Author"
        expect_contains "ps1 build embeds a thumbnail" "$OUT" "THUMBNAIL: embedded"
        OUT=$(run_ps "$REVSCRIPTS/revision-doc.ps1" check "$WORK/revision-ps.docx" 2>&1 | tr -d '\r'); CODE=$?
        expect_exit "ps1 check passes a built report" "$CODE" 0
        OUT=$(run_ps "$REVSCRIPTS/revision-doc.ps1" check "$WORK/revision-plain.docx" 2>&1 | tr -d '\r'); CODE=$?
        expect_exit "ps1 check fails a plain python-docx file" "$CODE" 1
    fi
fi
