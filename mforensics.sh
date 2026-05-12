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
echo "  ║   Intelligence. Documentation. Truth.   ║"
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

# date and time clearly readable in filenames — no colons, uses h/m format
START_TIME=$(date +%H%Mh%Mm)

LOG_BASE="${TID}-${PROJECT}-LOG${LOG_NUM}-${TODAY}_${START_TIME}"

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
echo "  ║  mflog         → view current log       ║"
echo "  ║  Ctrl+C        → cancel current cmd     ║"
echo "  ║  Ctrl+D or exit → end session           ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

# ── Export variables for mfscreenshot / mfnote ────────────────
export MF_PROJECT="$PROJECT"
export MF_TID="$TID"
export MF_DAY_DIR="$DAY_DIR"
export MF_LOG_FILE="$LOG_FILE"
export MF_MD_FILE="$MD_FILE"

# ── Helper: strip ANSI/color/escape codes ─────────────────────
# Handles CSI sequences, OSC sequences (title, bell), true color,
# and carriage returns — keeps log files completely clean
_mf_strip() {
    sed 's/\x1b\[[0-9;]*[a-zA-Z]//g;
         s/\x1b\][0-9;]*[^\a]*\a//g;
         s/\x1b[^[]*//g;
         s/\r//g'
}

# ── Helper: rotate log ────────────────────────────────────────
_mf_rotate() {
    LOG_NUM=$((LOG_NUM + 1))
    LOG_LINES=0

    # consistent readable filename format on rotation too
    START_TIME=$(date +%H%Mh%Mm)
    LOG_BASE="${TID}-${PROJECT}-LOG${LOG_NUM}-${TODAY}_${START_TIME}"
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
# strips color codes before writing so logs are always clean
_mf_log() {
    local TEXT
    TEXT=$(printf '%s\n' "$1" | _mf_strip)
    echo "$TEXT" >> "$LOG_FILE"
    echo "$TEXT" >> "$MD_FILE"
    LOG_LINES=$((LOG_LINES + 1))
}

# ── Helper: mfscreenshot ──────────────────────────────────────
_mf_screenshot() {

    # readable timestamp in screenshot filename — date + time clearly shown
    local TS_LABEL
    TS_LABEL=$(date +%Y-%m-%d_%H%Mh%Mm%Ss)
    local LOG_TS
    LOG_TS=$(date "+%Y-%m-%d | %H:%M:%S")
    local SAFE_TID
    SAFE_TID=$(printf '%s' "$TID" | tr -cd '[:alnum:]_-')
    local FILE="$DAY_DIR/screenshots/${SAFE_TID}-${TS_LABEL}.png"

    # if no display available, save a system snapshot instead of failing silently
    if [ -z "$DISPLAY" ]; then
        echo ""
        echo "  [!]  No display available — saving system snapshot instead."
        local SNAP_FILE="$DAY_DIR/screenshots/${SAFE_TID}-${TS_LABEL}-snapshot.txt"
        {
            echo "===== SYSTEM SNAPSHOT ====="
            echo "Time    : $(date)"
            echo "User    : $(whoami)"
            echo "Host    : $(hostname)"
            echo ""
            echo "--- Network Interfaces ---"
            ip a 2>/dev/null || ifconfig 2>/dev/null
            echo ""
            echo "--- Active Connections ---"
            ss -tunaph 2>/dev/null || netstat -tunaph 2>/dev/null
            echo ""
            echo "--- Running Processes ---"
            ps aux 2>/dev/null
        } > "$SNAP_FILE"
        echo "  [✓]  Snapshot saved: $(basename "$SNAP_FILE")"
        _mf_log "[$LOG_TS] 📋 No display — system snapshot saved: $(basename "$SNAP_FILE")"
        echo ""
        return
    fi

    if [ "$SCROT_OK" -eq 0 ]; then
        echo ""
        echo "  [!]  scrot not installed. Screenshots disabled."
        echo "       Install: sudo apt install scrot"
        echo ""
        return
    fi

    echo ""
    echo "  📸  Select area for screenshot (3 seconds to switch window)..."

    # 3 second delay so you can switch windows before selecting area
    # Falls back to full-screen capture if area selection fails (some WMs)
    if scrot -s -d 3 "$FILE" 2>/dev/null; then
        # verify file actually exists and has content before confirming
        if [ -s "$FILE" ]; then
            echo "  [✓]  Screenshot saved: $(basename "$FILE")"
            _mf_log "[$LOG_TS] 📸 Screenshot saved: $(basename "$FILE")"
        else
            echo "  [!]  Screenshot file empty or missing — trying full screen..."
            local FULL_FILE="$DAY_DIR/screenshots/${SAFE_TID}-${TS_LABEL}-full.png"
            if scrot -d 2 "$FULL_FILE" 2>/dev/null && [ -s "$FULL_FILE" ]; then
                echo "  [✓]  Full screenshot saved: $(basename "$FULL_FILE")"
                _mf_log "[$LOG_TS] 📸 Full screenshot saved: $(basename "$FULL_FILE")"
            else
                echo "  [!]  Screenshot failed — try again."
                _mf_log "[$LOG_TS] [!] Screenshot failed — empty file"
            fi
        fi
    else
        echo "  [!]  Area selection failed — trying full screen..."
        local FULL_FILE="$DAY_DIR/screenshots/${SAFE_TID}-${TS_LABEL}-full.png"
        if scrot -d 2 "$FULL_FILE" 2>/dev/null && [ -s "$FULL_FILE" ]; then
            echo "  [✓]  Full screenshot saved: $(basename "$FULL_FILE")"
            _mf_log "[$LOG_TS] 📸 Full screenshot saved: $(basename "$FULL_FILE")"
        else
            echo "  [!]  Screenshot cancelled or failed."
            _mf_log "[$LOG_TS] [!] Screenshot cancelled or failed."
        fi
    fi
    echo ""
}

# ── Helper: mflog ─────────────────────────────────────────────
_mf_viewlog() {
    if [ -f "$LOG_FILE" ]; then
        # +G jumps to end of file — most recent commands first
        less +G "$LOG_FILE"
    else
        echo "  [!]  No log file found."
    fi
}

# ── Helper: mfnote ────────────────────────────────────────────
_mf_note() {
    local NOTE_TEXT="$1"
    local TS
    TS=$(date "+%Y-%m-%d | %H:%M:%S")
    local NOTES_FILE="$DAY_DIR/notes/notes.md"

    if [ ! -f "$NOTES_FILE" ]; then
        echo "# Notes — $PROJECT — $TODAY" > "$NOTES_FILE"
        echo "" >> "$NOTES_FILE"
    fi

    if [ -n "$NOTE_TEXT" ]; then
        printf '[%s] [%s] %s\n\n' "$TS" "$TID" "$NOTE_TEXT" >> "$NOTES_FILE"
        echo "  [✓]  Note saved."
        _mf_log "[$TS] 📝 Note: $NOTE_TEXT"
    else
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

    trap 'echo ""; continue' INT

    # FIX: Ctrl+D now exits cleanly instead of looping forever
    if ! read -r CMD; then
        echo ""
        break
    fi

    trap '' INT

    [ -z "$CMD" ] && continue

    # full date + time in every log timestamp — easy to notice at a glance
    TS=$(date "+%Y-%m-%d | %H:%M:%S")

    # ── Built-in: mflog ────────────────────────────────────────
    if [ "$CMD" = "mflog" ]; then
        _mf_viewlog
        continue
    fi

    # ── Built-in: mfscreenshot ─────────────────────────────────
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

    # ── Detect scrot launched externally — alias to mfscreenshot ──
    if echo "$CMD" | grep -qi '^scrot'; then
        _mf_log "[$TS] CMD: $CMD  (→ mfscreenshot)"
        _mf_screenshot
        continue
    fi

    # ── Regular command — execute and capture ──────────────────
    # clear divider before each command so log is easy to read back
    _mf_log "--------------------------------------------"
    _mf_log "[$TS] CMD: $CMD"
    _mf_log "--------------------------------------------"

    TMPOUT=$(mktemp /tmp/.mf_out_XXXXXX)

    # NOTE: eval is used intentionally here to support pipes, redirects,
    # and multi-command strings. This tool is designed for single-user
    # forensic workstations where the operator controls all input.
    (
        trap - INT
        eval "$CMD"
    ) 2>&1 | tee "$TMPOUT"
    CMD_EXIT=${PIPESTATUS[0]}

    OUTPUT=$(cat "$TMPOUT")
    rm -f "$TMPOUT"

    # strip color codes from output before writing to log
    OUT_LINES=$(printf '%s\n' "$OUTPUT" | wc -l)
    _mf_log "[OUTPUT]"
    while IFS= read -r line; do
        _mf_log "$line"
    done <<< "$OUTPUT"

    # closing divider after output so each command block is clearly boxed
    _mf_log "--------------------------------------------"
    _mf_log ""

    # FIX: variable name case matches exactly (OUT_LINES, not Out_LINES)
    LOG_LINES=$((LOG_LINES + OUT_LINES))

    # ── Rotation check: 300 lines or 2MB ───────────────────────
    LOG_SIZE=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)

    if [ "$LOG_LINES" -ge 300 ] || [ "$LOG_SIZE" -ge 2097152 ]; then
        # FIX: store count before reset so rotation message is accurate
        OLD_LINES=$LOG_LINES
        _mf_log "[$TS] --- Log rotated after $OLD_LINES lines ---"
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
