# Mahsusa Forensics

**Terminal session logger for penetration testing and forensic investigations.**

One command. No install. Logs everything.

---

## Quick Start

```bash
~/mforensics.sh <project-name>


~/mforensics.sh Acme-Corp



Folder Structure
text
Acme-Corp/
├── 2026-05-08/
│   ├── logs/
│   │   └── TID001-Acme-Corp1-2026-05-08:09.00.log
│   ├── markdown/
│   │   └── TID001-Acme-Corp1-2026-05-08:09.00.md
│   ├── notes/
│   │   └── notes.md
│   └── screenshots/
│       └── TID001-09-15-22.png
├── 2026-05-09/
│   └── ...
Features
Feature	Description
Dual logging	Every command saved as .log and .md
Rotation	New log file every 5 MB
TID system	Each terminal gets a unique ID, resets daily
Screenshots	mfscreenshot captures via scrot -s, filed with TID + timestamp
Notes	mfnote opens zenity editor (falls back to nano)
Log viewer	mflog displays clean log with less
Safe interrupts	Ctrl+C cancels current command only — never kills the session
Brand prompt	┌──(Mahsusa㉿kali|MForensics)-[~] shows session is active
No install	Single bash script, runs anywhere
Commands Inside a Session
Command	Action
mfscreenshot	Interactive area screenshot (scrot -s)
mfnote "text"	Quick inline note
mfnote	Open note editor (zenity or nano)
mflog	View current log (press q to return)
Ctrl+C	Cancel current command
Close terminal	End session
Dependencies
Tool	Required	Purpose
bash	Yes	Core shell
tee	Yes	Output capture
scrot	Recommended	Screenshots
zenity	Recommended	GUI note editor
nano	Fallback	Terminal note editor
Install missing tools:

bash
sudo apt install scrot zenity
How TID Works
TID = Terminal ID, assigned per terminal session

Resets to TID001 each new day

Same terminal keeps the same TID through log rotations

Screenshots are stamped with their TID for traceability

Example Workflow
bash
$ ~/mforensics.sh Client-Audit

  ╔══════════════════════════════════════════╗
  ║   Mahsusa Forensics — Session Start     ║
  ╚══════════════════════════════════════════╝

  Checking dependencies...
    scrot    ✓  screenshots ready
    zenity   ✓  notes editor ready

  ╔══════════════════════════════════════════╗
  ║  Project : Client-Audit                 ║
  ║  TID     : TID001                       ║
  ║  Date    : 2026-05-08                   ║
  ╚══════════════════════════════════════════╝

┌──(Mahsusa㉿kali|MForensics)-[~]
└─$ nmap -sV 10.10.10.5
Starting Nmap...
[output captured]

┌──(Mahsusa㉿kali|MForensics)-[~]
└─$ mfscreenshot
📸  Select area for screenshot...
[✓]  Screenshot saved: TID001-09-15-22.png

┌──(Mahsusa㉿kali|MForensics)-[~]
└─$ mfnote "Found open SSH on port 22"
[✓]  Note saved.

┌──(Mahsusa㉿kali|MForensics)-[~]
└─$ mflog
...view log, press q to return...

┌──(Mahsusa㉿kali|MForensics)-[~]
└─$ [close terminal]
Session ended.
Why "Mahsusa"?
Mahsusa (محصوسة) — Arabic for "meticulously recorded" or "well-documented." Because that's exactly what this tool does.

License
MIT

Author
Mahsusa
