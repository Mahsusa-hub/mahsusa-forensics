#!/bin/bash
# ============================================================
#  Mahsusa Forensics — mforensics.sh
#  Usage:  ~/mforensics.sh <project-name>
#  Example: ~/mforensics.sh Trilocor.local
# ============================================================

set -o pipefail

# ── Argument check ────────────────────────────────────────────
if [ -z "$1" ]; then
    echo ""
    echo "  Usage: ~/mforensics.sh <project-name>"
    echo ""
    echo "  Example:"
    echo "    ~/mforensics.sh Trilocor.local"
    echo ""
    exit 1
fi

PROJECT="$1"
BASE="$HOME/$PROJECT"
TODAY=$(date +%Y-%m-%d)
DAY_DIR="$BASE/$TODAY"

# ── Folder structure ──────────────────────────────────────────
mkdir -p "$DAY_DIR/logs"
mkdir -p "$DAY_DIR/markdown"
mkdir -p "$DAY_DIR/notes"
mkdir -p "$DAY_DIR/screenshots"

# ── Dependency check (once per terminal) ──────────────────────
echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   Mahsusa Forensics — Session Start     ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""
echo "  Checking dependencies..."

MISSING=0
SCROT_OK=1
ZENITY_OK=1

for TOOL in bash tee date mkdir; do
    if ! command -v "$TOOL" >/dev/null 2>&1; then
        echo "    $TOOL  ✗  MISSING (critical)"
        MISSING=1
    fi
done

if command -v scrot >/dev/null 2>&1; then
    echo "    scrot    ✓  screenshots ready"
else
    echo "    scrot    ✗  not found — screenshots disabled"
    SCROT_OK=0
fi

if command -v zenity >/dev/null 2>&1; then
    echo "    zenity   ✓  notes editor ready"
else
    echo "    zenity   –  not found — using nano for notes"
    ZENITY_OK=0
fi

if [ "$MISSING" -eq 1 ]; then
    echo ""
    echo "  Critical tools missing. Install and retry."
    exit 1
fi

# ── TID assignment (per day) ──────────────────────────────────
TID_FILE="$DAY_DIR/.tid_counter"

if [ -f "$TID_FILE" ]; then
    TID_NUM=$(cat "$TID_FILE")
    TID_NUM=$((TID_NUM + 1))
else
    TID_NUM=1
fi
echo "$TID_NUM" > "$TID_FILE"

TID=$(printf "TID%03d" "$TID_NUM")

# ── Log file setup ────────────────────────────────────────────
LOG_NUM=1
LOG_LINES=0
START_TIME=$(date +%H.%M)

LOG_BASE="${TID}-${PROJECT}${LOG_NUM}-${TODAY}:${START_TIME}"

LOG_FILE="$DAY_DIR/logs/${LOG_BASE}.log"
MD_FILE="$DAY_DIR/markdown/${LOG_BASE}.md"

# ── Write headers ─────────────────────────────────────────────
{
    echo "# ${PROJECT} — Session Log"
    echo ""
    echo "| Field | Value |"
    echo "|-------|-------|"
    echo "| Project  | $PROJECT |"
    echo "| TID      | $TID |"
    echo "| Date     | $TODAY |"
    echo "| Started  | $(date '+%H:%M:%S') |"
    echo ""
    echo "---"
    echo ""
} > "$MD_FILE"

# Identical header in .log
{
    echo "============================================"
    echo " Project : $PROJECT"
    echo " TID     : $TID"
    echo " Date    : $TODAY"
    echo " Started : $(date '+%H:%M:%S')"
    echo "============================================"
    echo ""
} > "$LOG_FILE"

# ── Banner ────────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════════╗"
printf "  ║  Project : %-30s║\n" "$PROJECT"
printf "  ║  TID     : %-30s║\n" "$TID"
printf "  ║  Date    : %-30s║\n" "$TODAY"
printf "  ║  Log     : %-30s║\n" "${LOG_BASE}.log"
echo "  ║                                          ║"
echo "  ║  mfscreenshot  → take screenshot        ║"
echo "  ║  mfnote        → write note (zenity)    ║"
echo "  ║  mfnote \"txt\"  → quick inline note     ║"
echo "  ║  Ctrl+C        → cancel current cmd     ║"
echo "  ║  Close terminal → end session           ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

# ── Export variables for mfscreenshot / mfnote ────────────────
export MF_PROJECT="$PROJECT"
export MF_TID="$TID"
export MF_DAY_DIR="$DAY_DIR"
export MF_LOG_FILE="$LOG_FILE"
export MF_MD_FILE="$MD_FILE"

# ── Helper: rotate log ────────────────────────────────────────
_mf_rotate() {
    LOG_NUM=$((LOG_NUM + 1))
    LOG_LINES=0
    START_TIME=$(date +%H.%M)
    LOG_BASE="${TID}-${PROJECT}${LOG_NUM}-${TODAY}:${START_TIME}"
    LOG_FILE="$DAY_DIR/logs/${LOG_BASE}.log"
    MD_FILE="$DAY_DIR/markdown/${LOG_BASE}.md"

    {
        echo "# ${PROJECT} — Session Log (cont.)"
        echo ""
        echo "| Field | Value |"
        echo "|-------|-------|"
        echo "| Project  | $PROJECT |"
        echo "| TID      | $TID |"
        echo "| Date     | $TODAY |"
        echo "| Started  | $(date '+%H:%M:%S') |"
        echo "| Rotation | $LOG_NUM |"
        echo ""
        echo "---"
        echo ""
    } > "$MD_FILE"

    {
        echo "============================================"
        echo " Project  : $PROJECT"
        echo " TID      : $TID"
        echo " Date     : $TODAY"
        echo " Started  : $(date '+%H:%M:%S')"
        echo " Rotation : $LOG_NUM"
        echo "============================================"
        echo ""
    } > "$LOG_FILE"

    export MF_LOG_FILE="$LOG_FILE"
    export MF_MD_FILE="$MD_FILE"

    echo ""
    echo "  [↻]  Rotated to log #${LOG_NUM}"
    echo ""
}

# ── Helper: write to both log files ───────────────────────────
_mf_log() {
    local TEXT="$1"
    echo "$TEXT" >> "$LOG_FILE"
    echo "$TEXT" >> "$MD_FILE"
    LOG_LINES=$((LOG_LINES + 1))
}

# ── Helper: mfscreenshot ──────────────────────────────────────
_mf_screenshot() {
    if [ "$SCROT_OK" -eq 0 ]; then
        echo ""
        echo "  [!]  scrot not installed. Screenshots disabled."
        echo "       Install: sudo apt install scrot"
        echo ""
        return
    fi

    if [ -z "$DISPLAY" ]; then
        echo ""
        echo "  [!]  No display available. Screenshots require GUI."
        echo ""
        return
    fi

    local TS=$(date +%H-%M-%S)
    local SAFE_TID=$(printf '%s' "$TID" | tr -cd '[:alnum:]_-')
    local FILE="$DAY_DIR/screenshots/${SAFE_TID}-${TS}.png"

    echo ""
    echo "  📸  Select area for screenshot..."

    if scrot -s "$FILE" 2>/dev/null; then
        echo "  [✓]  Screenshot saved: $(basename "$FILE")"
        _mf_log "[$(date +%H:%M:%S)] 📸 Screenshot taken: $(basename "$FILE")"
    else
        echo "  [!]  Screenshot cancelled."
    fi
    echo ""
}

# ── Helper: mflog ─────────────────────────────────────────────
_mf_viewlog() {
    if [ -f "$LOG_FILE" ]; then
        cat "$LOG_FILE" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | less
    else
        echo "  [!]  No log file found."
    fi
}

# ── Helper: mfnote ────────────────────────────────────────────
_mf_note() {
    local NOTE_TEXT="$1"
    local TS=$(date +%H:%M:%S)
    local NOTES_FILE="$DAY_DIR/notes/notes.md"

    if [ ! -f "$NOTES_FILE" ]; then
        echo "# Notes — $PROJECT — $TODAY" > "$NOTES_FILE"
        echo "" >> "$NOTES_FILE"
    fi

    if [ -n "$NOTE_TEXT" ]; then
        # Inline note
        printf '[%s] [%s] %s\n\n' "$TS" "$TID" "$NOTE_TEXT" >> "$NOTES_FILE"
        echo "  [✓]  Note saved."
        _mf_log "[$TS] 📝 Note: $NOTE_TEXT"
    else
        # Open editor
        if [ "$ZENITY_OK" -eq 1 ] && [ -n "$DISPLAY" ]; then
            local RESULT
            RESULT=$(zenity --text-info --editable \
                --title="Note — $PROJECT — $TID" \
                --filename="$NOTES_FILE" \
                --width=600 --height=400 \
                --font="Monospace 11" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$RESULT" ]; then
                printf '%s\n' "$RESULT" > "$NOTES_FILE"
                echo "  [✓]  Note saved."
                _mf_log "[$TS] 📝 Note edited (zenity)"
            else
                echo "  [!]  Note cancelled."
            fi
        else
            nano "$NOTES_FILE"
            echo "  [✓]  Note saved."
            _mf_log "[$TS] 📝 Note edited (nano)"
        fi
    fi
}

# ── Trap Ctrl+C — cancel command only, not session ────────────
trap '' INT

# ═══════════════════════════════════════════════════════════════
#  MAIN SESSION LOOP
# ═══════════════════════════════════════════════════════════════
while true; do

    # ── Prompt ─────────────────────────────────────────────────
    printf "\n┌──(Mahsusa㉿kali|MForensics)-[%s]\n└─\$ " "$(pwd | sed "s|$HOME|~|")"

    # Restore INT during read so user can Ctrl+C the read itself
    trap 'echo ""; continue' INT
    read -r CMD
    trap '' INT

    # ── Terminal closed? ───────────────────────────────────────
    if [ -z "$CMD" ] && [ $? -ne 0 ]; then
        break
    fi

    # ── Skip empty lines ───────────────────────────────────────
    [ -z "$CMD" ] && continue

    # ── Timestamp ──────────────────────────────────────────────
    TS=$(date +%H:%M:%S)

    # ── Built-in: mfscreenshot ─────────────────────────────────
    if [ "$CMD" = "mflog" ]; then
        _mf_viewlog
        continue
    fi

    if [ "$CMD" = "mfscreenshot" ]; then
        _mf_log "[$TS] CMD: mfscreenshot"
        _mf_screenshot
        continue
    fi

    # ── Built-in: mfnote ───────────────────────────────────────
    if echo "$CMD" | grep -q '^mfnote'; then
        NOTE_ARG=$(echo "$CMD" | sed 's/^mfnote *//')
        _mf_log "[$TS] CMD: mfnote $NOTE_ARG"
        _mf_note "$NOTE_ARG"
        continue
    fi

    # ── Detect scrot launched externally ───────────────────────
    if echo "$CMD" | grep -qi '^scrot'; then
        _mf_log "[$TS] CMD: $CMD"
        _mf_screenshot
        continue
    fi

    # ── Regular command — execute and capture ──────────────────
    _mf_log "[$TS] CMD: $CMD"

    TMPOUT=$(mktemp /tmp/.mf_out_XXXXXX)

    # Run command, capture output, show to user
    (
        trap - INT
        eval "$CMD"
    ) 2>&1 | tee "$TMPOUT"
    CMD_EXIT=${PIPESTATUS[0]}

    OUTPUT=$(cat "$TMPOUT")
    rm -f "$TMPOUT"

    # ── Log output ─────────────────────────────────────────────
    OUT_LINES=$(printf '%s\n' "$OUTPUT" | wc -l)
    _mf_log "[OUT]"
    while IFS= read -r line; do
        _mf_log "$line"
    done <<< "$OUTPUT"
    _mf_log ""

    LOG_LINES=$((LOG_LINES + OUT_LINES))

    # ── Rotation check: 300 lines or 2MB ───────────────────────
    LOG_SIZE=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)

    if [ "$LOG_LINES" -ge 300 ] || [ "$LOG_SIZE" -ge 2097152 ]; then
        _mf_log "[$(date +%H:%M:%S)] --- Log rotated after $LOG_LINES lines ---"
        _mf_rotate
    fi

done

# ═══════════════════════════════════════════════════════════════
#  SESSION END
# ═══════════════════════════════════════════════════════════════
echo ""
echo "  ─────────────────────────────────────────────"
echo "  Session ended."
echo "  TID     : $TID"
echo "  Project : $PROJECT"
echo "  Date    : $TODAY"
echo "  Logs    : $DAY_DIR/logs/"
echo "  ─────────────────────────────────────────────"
echo ""
