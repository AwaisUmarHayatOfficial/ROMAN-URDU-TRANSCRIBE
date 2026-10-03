#!/usr/bin/env bash
# =============================================================================
#  YouTube -> Roman Urdu Notes  |  One-click launcher
# =============================================================================
#  What this script does:
#    1. Goes to the project folder and activates the virtual environment
#    2. Guides you to get a Google Gemini API key (if you don't have one)
#    3. Asks for your API key (input is hidden)
#    4. Asks for the YouTube video URL
#    5. Runs yt_to_roman_urdu.py and shows live logs (also saved to ./logs)
#
#  Usage:
#    bash ~/ROMAN-URDU/run_roman_urdu.sh
# =============================================================================

# ----------------------------- Configuration ---------------------------------
PROJECT_DIR="$HOME/ROMAN-URDU"
VENV_DIR="$PROJECT_DIR/venv"
PY_SCRIPT="$PROJECT_DIR/yt_to_roman_urdu.py"
LOG_DIR="$PROJECT_DIR/logs"
SAVED_KEY_FILE="$PROJECT_DIR/Gemini_Keys"   # saved key (auto-deleted after KEY_TTL_HOURS)
KEY_TTL_HOURS=24          # how long a saved key stays valid
API_KEY_URL="https://aistudio.google.com/apikey"

# ------------------------------- Colors --------------------------------------
if [ -t 1 ]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi

info()  { echo "${BLUE}[INFO]${RESET}  $*"; }
ok()    { echo "${GREEN}[ OK ]${RESET}  $*"; }
warn()  { echo "${YELLOW}[WARN]${RESET}  $*"; }
error() { echo "${RED}[FAIL]${RESET}  $*" >&2; }

banner() {
  echo
  echo "${BOLD}=============================================${RESET}"
  echo "${BOLD}   YouTube -> Roman Urdu Notes Generator${RESET}"
  echo "${BOLD}=============================================${RESET}"
  echo
}

# ------------------------- Step 1: Environment -------------------------------
setup_environment() {
  info "Step 1/4: Preparing environment..."

  if [ ! -d "$PROJECT_DIR" ]; then
    error "Project folder not found: $PROJECT_DIR"
    exit 1
  fi
  cd "$PROJECT_DIR" || exit 1
  ok "Project folder: $PROJECT_DIR"

  if [ ! -f "$PY_SCRIPT" ]; then
    error "Python script not found: $PY_SCRIPT"
    exit 1
  fi

  if [ ! -f "$VENV_DIR/bin/activate" ]; then
    error "Virtual environment not found at: $VENV_DIR"
    echo "  Create it with:"
    echo "    cd $PROJECT_DIR && python3 -m venv venv"
    echo "    source venv/bin/activate && pip install <your-required-libraries>"
    exit 1
  fi

  # shellcheck disable=SC1091
  source "$VENV_DIR/bin/activate"
  ok "Virtual environment activated."
  mkdir -p "$LOG_DIR"
}

# ----------------------- Step 2: API key guide -------------------------------
show_api_key_guide() {
  echo
  echo "${BOLD}How to get a free Google Gemini API key${RESET}"
  echo "---------------------------------------"
  echo "  1. Open this page in your browser:"
  echo "       ${BLUE}${API_KEY_URL}${RESET}"
  echo "  2. Sign in with your Google account."
  echo "  3. Click the ${BOLD}\"Create API key\"${RESET} button."
  echo "  4. Choose an existing Google Cloud project, or let it create a new one."
  echo "  5. Copy the key that is shown (usually starts with ${BOLD}AIza...${RESET} or ${BOLD}AQ.${RESET})."
  echo "  6. Come back to this terminal and paste it below."
  echo
  echo "  ${YELLOW}Keep your key private. Never share it or post it in chats.${RESET}"
  echo

  # Try to open the browser automatically (silently ignore if not possible)
  if command -v xdg-open >/dev/null 2>&1; then
    read -r -p "Open the API key page in your browser now? [Y/n]: " open_ans
    open_ans="${open_ans:-Y}"
    if [[ "$open_ans" =~ ^[Yy]$ ]]; then
      xdg-open "$API_KEY_URL" >/dev/null 2>&1 &
      ok "Browser opened. Create your key, then return here."
    fi
  fi
  echo
}

# ---------------------------- Step 3: Get key --------------------------------
key_age_seconds() {
  local saved
  saved="$(stat -c %Y "$SAVED_KEY_FILE" 2>/dev/null || echo 0)"
  echo $(( $(date +%s) - saved ))
}

# Background timer: deletes the key file exactly when it turns KEY_TTL_HOURS old.
# (It re-checks the file's age first, so a newer key is never deleted early.)
schedule_key_expiry() {
  local ttl=$(( KEY_TTL_HOURS * 3600 ))
  nohup setsid bash -c '
    f="$1"; ttl="$2"
    while [ -f "$f" ]; do
      age=$(( $(date +%s) - $(stat -c %Y "$f" 2>/dev/null || echo 0) ))
      [ "$age" -ge "$ttl" ] && { rm -f "$f"; exit 0; }
      sleep $(( ttl - age + 1 ))
    done
  ' _ "$SAVED_KEY_FILE" "$ttl" >/dev/null 2>&1 &
  disown 2>/dev/null || true
}

get_api_key() {
  info "Step 2/4: Gemini API key"

  # --- IF a saved key file exists -> check it; ELSE ask the user ---------------
  if [ -f "$SAVED_KEY_FILE" ]; then
    local age content left_min
    age="$(key_age_seconds)"
    content="$(tr -d '[:space:]' < "$SAVED_KEY_FILE")"

    if [ "$age" -ge $(( KEY_TTL_HOURS * 3600 )) ]; then
      rm -f "$SAVED_KEY_FILE"
      warn "Saved key in Gemini_Keys expired (older than ${KEY_TTL_HOURS} hours) and was deleted."
    elif [ "${#content}" -lt 20 ]; then
      rm -f "$SAVED_KEY_FILE"
      warn "Gemini_Keys did not contain a valid key and was deleted."
    else
      API_KEY="$content"
      left_min=$(( (KEY_TTL_HOURS * 3600 - age) / 60 ))
      ok "Using the saved key from Gemini_Keys (valid for another $((left_min / 60))h $((left_min % 60))m)."
      echo "  To enter a different key, run:  bash $0 --reset-key"
      return
    fi
  else
    info "No saved key found (Gemini_Keys is missing). A new key is needed."
  fi

  read -r -p "Do you already have a Gemini API key? [y/N]: " have_key
  if [[ ! "$have_key" =~ ^[Yy]$ ]]; then
    show_api_key_guide
  fi

  while true; do
    read -r -s -p "Paste your Gemini API key (input is hidden): " API_KEY
    echo
    API_KEY="$(echo "$API_KEY" | tr -d '[:space:]')"

    if [ -z "$API_KEY" ]; then
      warn "The key cannot be empty. Please try again."
    elif [ "${#API_KEY}" -lt 20 ]; then
      warn "That key looks too short (${#API_KEY} characters). Please paste the FULL key."
    else
      break
    fi
  done

  ( umask 077; printf '%s' "$API_KEY" > "$SAVED_KEY_FILE" )
  schedule_key_expiry
  ok "Key saved in Gemini_Keys for ${KEY_TTL_HOURS} hours, then it is deleted automatically. You will only be asked for the video URL next time."
}

# ---------------------------- Step 4: Get URL --------------------------------
get_youtube_url() {
  info "Step 3/4: YouTube video URL"
  while true; do
    read -r -p "Paste the YouTube video URL: " VIDEO_URL
    VIDEO_URL="$(echo "$VIDEO_URL" | tr -d '[:space:]')"

    if [[ "$VIDEO_URL" =~ ^https?://(www\.|m\.)?(youtube\.com|youtu\.be)/ ]]; then
      ok "URL accepted."
      break
    else
      warn "That doesn't look like a YouTube link. Example:"
      echo "     https://www.youtube.com/watch?v=XXXXXXXXXXX"
    fi
  done
}

# ---------------------------- Step 5: Run ------------------------------------
run_job() {
  info "Step 4/4: Running the converter..."

  local ts logfile status
  ts="$(date +%Y%m%d_%H%M%S)"
  logfile="$LOG_DIR/run_${ts}.log"

  echo "  Video : $VIDEO_URL"
  echo "  Log   : $logfile"
  echo "  Started at: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "---------------------------------------------"

  # Expose the key to the script via environment variables AND via stdin
  # (the Python script asks for the key with input(), so we feed it in).
  export GEMINI_API_KEY="$API_KEY"
  export GOOGLE_API_KEY="$API_KEY"

  printf '%s\n' "$API_KEY" | python -u "$PY_SCRIPT" "$VIDEO_URL" 2>&1 | tee -a "$logfile"
  status=${PIPESTATUS[1]}

  echo "---------------------------------------------"
  echo "  Finished at: $(date '+%Y-%m-%d %H:%M:%S')"

  if [ "$status" -eq 0 ] && grep -q '^\[X\]' "$logfile"; then
    status=1
  fi

  if [ "$status" -eq 0 ]; then
    ok "Done! Your notes (.txt and .docx) are in: $PROJECT_DIR"
  else
    error "The script exited with an error (code $status)."
    echo "  Check the log for details: $logfile"
    echo "  Common fixes:"
    echo "    - Invalid/expired API key -> create a new one at $API_KEY_URL"
    if grep -qiE "API_KEY_INVALID|API key not valid|PERMISSION_DENIED|UNAUTHENTICATED" "$logfile"; then
      rm -f "$SAVED_KEY_FILE"
      warn "The API key was rejected, so the saved key was deleted. Run the script again."
    fi
    echo "    - Missing library         -> pip install <library-name> (venv is active)"
    echo "    - No subtitles found      -> the video may be a LIVE stream, or has captions"
    echo "                                 disabled. Wait until a live stream ends (captions"
    echo "                                 can take hours) or try a normal video."
  fi
  return "$status"
}

# ------------------------------- Main ----------------------------------------
if [ "${1:-}" = "--reset-key" ]; then
  rm -f "$SAVED_KEY_FILE"
  echo "Saved API key removed."
fi

rm -f "$HOME/.roman_urdu_gemini_key" 2>/dev/null   # old location, no longer used
banner
setup_environment
get_api_key

while true; do
  get_youtube_url
  run_job
  echo
  read -r -p "Convert another video? [y/N]: " again
  [[ "$again" =~ ^[Yy]$ ]] || break
  echo
done

echo
ok "Goodbye!"
