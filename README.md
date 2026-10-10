# Roman Urdu Transcribe

Convert any YouTube video into professionally formatted **Roman Urdu study notes** (Word `.docx` and plain `.txt`) using the YouTube transcript and Google Gemini.

The tool fetches the video's subtitles, converts them word-by-word into Roman Urdu, and organizes the result into a clean, book-style document with headings, bullet points, tables, callout boxes, and clickable timestamps.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation (Ubuntu / Linux)](#installation-ubuntu--linux)
- [Installation (Windows)](#installation-windows)
- [Installation (macOS)](#installation-macos)
- [Getting a Gemini API Key](#getting-a-gemini-api-key)
- [Usage](#usage)
- [Output](#output)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)

---

## Features

- **One-command launcher** – `Run.sh` handles the virtual environment, API key, URL input, and logging.
- **Automatic transcript retrieval** – uses `youtube-transcript-api` with a `yt-dlp` fallback; tries Urdu, Hindi, and English subtitles.
- **Faithful conversion** – converts every sentence into Roman Urdu without summarizing or skipping content.
- **Coverage verification** – compares input and output word counts; chunks that fall below the threshold are automatically retried or split into smaller parts.
- **Structured notes** – headings, bullet and numbered lists, tables, and highlighted callout boxes for questions, definitions, and notes.
- **Clickable timestamps** – every timestamp in the Word document links back to the exact moment in the video.
- **Auto-detected branding** – header and tagline are generated from the channel name and video subject.
- **Model fallback** – automatically selects and falls back across available Gemini models if one is rate-limited.
- **Run logs** – every execution is saved to the `logs/` folder.

---

## Requirements

| Requirement | Details |
| --- | --- |
| Operating system | Ubuntu 22.04 or later (recommended), Windows 10/11 (via WSL2 or native), or macOS 12 or later |
| Python | 3.9 or later |
| System packages | `python3`, `python3-venv`, `python3-pip`, `ffmpeg` |
| Python packages | `python-docx`, `google-genai`, `requests`, `youtube-transcript-api`, `yt-dlp` |
| API access | A free [Google Gemini API key](https://aistudio.google.com/apikey) |
| Internet | Required for YouTube and the Gemini API |

---

## Installation (Ubuntu / Linux)

### 1. Install system dependencies

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip ffmpeg git
```

### 2. Clone the repository

```bash
git clone https://github.com/AwaisUmarHayatOfficial/ROMAN-URDU-TRANSCRIBE.git
cd ROMAN-URDU-TRANSCRIBE
```

### 3. Create and activate a virtual environment

```bash
python3 -m venv venv
source venv/bin/activate
```

### 4. Install Python dependencies

```bash
pip install --upgrade pip
pip install python-docx google-genai requests youtube-transcript-api yt-dlp
```

### 5. Make the launcher executable (optional)

```bash
chmod +x Run.sh
```

> **Note:** Run these commands as a normal user. Only the `apt` commands need `sudo`. Avoid switching to a root shell (`sudo su`) so that generated files and the virtual environment stay owned by your own account.

---

## Installation (Windows)

There are two ways to run the project on Windows 10/11. **Option A (WSL2) is recommended**, because `Run.sh` is a Bash script and works exactly as it does on Ubuntu.

### Option A: WSL2 with Ubuntu (recommended)

1. Open **PowerShell as Administrator** and install WSL with Ubuntu:

   ```powershell
   wsl --install -d Ubuntu
   ```

2. Restart the computer when prompted, then open **Ubuntu** from the Start menu and create your Linux username and password.
3. Inside the Ubuntu terminal, follow every step in [Installation (Ubuntu / Linux)](#installation-ubuntu--linux) and then [Usage](#usage).

> **Tip:** Generated `.docx` and `.txt` files are stored inside the WSL project folder. To open that folder in Windows File Explorer, run `explorer.exe .` from inside the project directory.

### Option B: Native Windows (PowerShell)

`Run.sh` cannot run in PowerShell, so on native Windows you run the Python script directly.

1. **Install Python 3.9+, FFmpeg and Git** (open PowerShell):

   ```powershell
   winget install -e --id Python.Python.3.12
   winget install -e --id Gyan.FFmpeg
   winget install -e --id Git.Git
   ```

   Close and reopen PowerShell afterwards so the new commands are available.

2. **Clone the repository:**

   ```powershell
   git clone https://github.com/AwaisUmarHayatOfficial/ROMAN-URDU-TRANSCRIBE.git
   cd ROMAN-URDU-TRANSCRIBE
   ```

3. **Remove the bundled Linux `venv` folder and create a fresh one.** The `venv` in the repository was created on Linux and does not work on Windows:

   ```powershell
   Remove-Item -Recurse -Force venv
   python -m venv venv
   ```

4. **Activate the virtual environment:**

   ```powershell
   .\venv\Scripts\Activate.ps1
   ```

   If PowerShell blocks the script, run this once and try again:

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

5. **Install the Python dependencies:**

   ```powershell
   python -m pip install --upgrade pip
   pip install python-docx google-genai requests youtube-transcript-api yt-dlp
   ```

6. **Run the converter** (see [Getting a Gemini API Key](#getting-a-gemini-api-key)):

   ```powershell
   $env:GEMINI_API_KEY = "your_api_key_here"
   python yt_to_roman_urdu.py "https://www.youtube.com/watch?v=XXXXXXXXXXX"
   ```

   If the script asks for the key, paste it when prompted. The key is only set for the current PowerShell window.

---

## Installation (macOS)

These steps work on both Apple Silicon (M1/M2/M3 and later) and Intel Macs. Use the **Terminal** app.

1. **Install Homebrew** (skip if already installed):

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install Python, FFmpeg and Git:**

   ```bash
   brew install python ffmpeg git
   ```

3. **Clone the repository:**

   ```bash
   git clone https://github.com/AwaisUmarHayatOfficial/ROMAN-URDU-TRANSCRIBE.git
   cd ROMAN-URDU-TRANSCRIBE
   ```

4. **Remove the bundled Linux `venv` folder and create a fresh one.** The `venv` in the repository was created on Linux and does not work on macOS:

   ```bash
   rm -rf venv
   python3 -m venv venv
   source venv/bin/activate
   ```

5. **Install the Python dependencies:**

   ```bash
   pip install --upgrade pip
   pip install python-docx google-genai requests youtube-transcript-api yt-dlp
   ```

6. **Run the converter** (see [Getting a Gemini API Key](#getting-a-gemini-api-key)):

   ```bash
   export GEMINI_API_KEY="your_api_key_here"
   python yt_to_roman_urdu.py "https://www.youtube.com/watch?v=XXXXXXXXXXX"
   ```

   If the script asks for the key, paste it when prompted.

> **Note on `Run.sh` on macOS:** The launcher was written for GNU/Linux tools (`stat -c`, `setsid`, `xdg-open`). It can start on macOS, but the 24-hour saved-key feature and automatic browser opening will not work correctly, so you may be asked for your API key on every run. Running the Python script directly, as shown above, is the most reliable method.

---

## Getting a Gemini API Key

1. Open <https://aistudio.google.com/apikey>.
2. Sign in with your Google account.
3. Click **Create API key** and choose (or create) a Google Cloud project.
4. Copy the key (it usually starts with `AIza...`).

`Run.sh` will guide you through this on first launch and can open the page in your browser automatically.

---

## Usage

**Ubuntu / Linux and Windows (WSL2):** from the project folder, run:

```bash
bash Run.sh
```

**Native Windows and macOS:** run `python yt_to_roman_urdu.py "<video_url>"` as described in the installation sections above.

The launcher will:

1. Activate the virtual environment.
2. Ask for your Gemini API key (input is hidden). The key is stored in the `Gemini_Keys` file and **deleted automatically after 24 hours**.
3. Ask for the YouTube video URL.
4. Convert the transcript and show live progress.
5. Offer to convert another video when finished.

To remove the saved key and enter a different one:

```bash
bash Run.sh --reset-key
```

You can also run the Python script directly with your key set in the environment:

```bash
source venv/bin/activate
export GEMINI_API_KEY="your_api_key_here"
python yt_to_roman_urdu.py "https://www.youtube.com/watch?v=XXXXXXXXXXX"
```

---

## Output

For each video, the following files are created in the project folder:

| File | Description |
| --- | --- |
| `<video_title>.docx` | Formatted Word document with Roman Urdu notes |
| `<video_title>.txt` | Plain-text version of the notes |
| `logs/run_<timestamp>.log` | Full log of the run |

---

## Configuration

Design and behavior settings are located at the top of `yt_to_roman_urdu.py`:

| Setting | Default | Description |
| --- | --- | --- |
| `BRAND_OVERRIDE` | `""` | Force a specific brand name in the header |
| `SUBJECT_OVERRIDE` | `""` | Force a specific subject in the tagline |
| `FOOTER_LABEL` | `"Roman Urdu"` | Text shown in the page footer |
| `FONT_NAME` | `"Roboto Serif"` | Document font (see note below) |
| `SHOW_TIMESTAMPS` | `True` | Show or hide `[MM:SS]` markers |
| `CHUNK_MINUTES` | `5` | Transcript chunk size sent to Gemini |
| `MIN_COVERAGE` | `0.88` | Minimum word coverage before a chunk is retried |
| `AUTO_BOLD` | `True` | Automatically bold numbers, amounts, percentages, and uppercase terms |
| `ADD_CHUNK_HEADINGS` | `False` | Add a heading for every chunk |

**Font note:** *Roboto Serif* must be installed on the machine that opens the `.docx`. Install it from [Google Fonts](https://fonts.google.com/specimen/Roboto+Serif), or set `FONT_NAME` to a font you already have (for example `"Georgia"` or `"Cambria"`).

---

## Project Structure

```
ROMAN-URDU-TRANSCRIBE/
├── Run.sh                 # One-click launcher
├── yt_to_roman_urdu.py    # Main conversion script
├── Gemini_Keys            # Temporary saved API key (auto-deleted after 24 hours)
├── logs/                  # Run logs
├── venv/                  # Python virtual environment (created during setup)
└── README.md
```

---

## Troubleshooting

| Problem | Solution |
| --- | --- |
| `Virtual environment not found` | Complete [Installation](#installation-ubuntu--linux) step 3 inside the project folder. |
| `ModuleNotFoundError` | Activate the environment with `source venv/bin/activate` and re-run the `pip install` command. |
| API key invalid or expired | Run `bash Run.sh --reset-key` and enter a new key. |
| No subtitles found | The video may be a live stream or have captions disabled. Wait for live streams to finish (captions can take hours) or try another video. |
| Rate-limit or quota errors | Wait a few minutes and retry. The tool already retries and falls back across Gemini models. |
| `python3 -m venv` fails | Install the venv package: `sudo apt install python3-venv`. |
| Windows: `python` is not recognized | Reopen PowerShell after installing Python, or reinstall and tick **Add Python to PATH**. |
| Windows: `running scripts is disabled` | Run `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`. |
| Windows / macOS: venv activation fails | Delete the bundled Linux `venv` folder and create a new one (see the Windows or macOS installation steps). |
| `ffmpeg` or `yt-dlp` not found | Make sure FFmpeg is installed and available in your `PATH`, and that the virtual environment is active. |
| Permission denied on `Run.sh` | Run `chmod +x Run.sh`, or start it with `bash Run.sh`. |

---

## Security Notes

- **Never commit your API key.** Add the following to a `.gitignore` file so that keys, environments, logs, and generated notes are not pushed to GitHub:

  ```gitignore
  venv/
  logs/
  Gemini_Keys
  *.docx
  *.txt
  ```

- If a key was ever committed or shared, revoke it at <https://aistudio.google.com/apikey> and create a new one.

---

## Disclaimer

This tool depends on the availability of YouTube captions and the Google Gemini API. Output quality depends on the accuracy of the source subtitles. Please respect YouTube's Terms of Service and the rights of content creators when using generated notes.
