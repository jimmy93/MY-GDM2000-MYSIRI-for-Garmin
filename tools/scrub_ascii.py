#!/usr/bin/env python3
"""scrub_ascii.py - replace non-ASCII characters in all project text files
with ASCII equivalents (avoids encoding issues in PowerShell 5.1, monkeyc,
and XML parsers on Windows).

Dev-only helper. Idempotent.
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
EXTS = {".mc", ".xml", ".ps1", ".jungle", ".md", ".py", ".json", ".txt"}

# non-ASCII -> ASCII replacement map
MAP = {
    0x2014: "--",   # em dash
    0x2018: "'",    # left single quote
    0x2019: "'",    # right single quote
    0x201C: '"',    # left double quote
    0x201D: '"',    # right double quote
    0x00B0: "deg",  # degree sign
    0x00E9: "e",    # e acute
    0x00F1: "n",    # n tilde
    0x2192: "->",   # right arrow
    0x2264: "<=",   # less-than-or-equal
    0x2248: "~=",   # approximately
    0x00A0: " ",    # non-breaking space
}

def main():
    changed = 0
    for p in ROOT.rglob("*"):
        if not p.is_file() or p.suffix not in EXTS:
            continue
        data = p.read_bytes()
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            continue  # binary or already-ANSI; skip
        out = []
        for ch in text:
            cp = ord(ch)
            if cp < 128:
                out.append(ch)
            elif cp in MAP:
                out.append(MAP[cp])
            else:
                out.append("?")
        new_text = "".join(out)
        if new_text != text:
            p.write_bytes(new_text.encode("ascii"))
            changed += 1
            print("scrubbed %s" % p)
    print("Done. %d files updated." % changed)

if __name__ == "__main__":
    main()
