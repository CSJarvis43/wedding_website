#!/usr/bin/env python3
"""Scan lines added on this branch (vs origin/main) for PII-shaped data.

Usage: pii-scan.py [base]   (default base: origin/main)

Flags real-looking emails, US phone numbers, and street addresses. Obvious
fakes are allowed: example.com/.org/.net, *.test, *.invalid, *.example,
GitHub/Anthropic noreply addresses, 555-01xx numbers, and addresses on an
"Example" street. A line containing `pii-ok` is skipped. Only add that marker
with the user's OK (e.g. the venue's public address on the info page).

It can't recognize names. Review fixtures and seed data for real-looking names yourself.

Exit 0 = clean, 1 = possible PII found (file:line printed), 2 = error.
"""

import re
import subprocess
import sys

EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@([A-Za-z0-9-]+\.)+[A-Za-z]{2,}")
FAKE_EMAIL = re.compile(
    r"@((.+\.)?example\.(com|org|net)|.+\.(test|invalid|example)|users\.noreply\.github\.com|anthropic\.com)$",
    re.I,
)
PHONE = re.compile(r"(?<!\d)(\+?1[-. ]?)?\(?(\d{3})\)?[-. ](\d{3})[-. ](\d{4})(?!\d)")
ADDRESS = re.compile(
    r"\b\d{1,5}\s+([A-Z][a-z]+\s+){1,3}(St|Street|Ave|Avenue|Rd|Road|Blvd|Boulevard|Ln|Lane|Dr|Drive|Ct|Court|Way|Pl|Place)\b"
)
SKIP_FILES = re.compile(r"(^|/)(pnpm-lock\.yaml|uv\.lock|package-lock\.json)$|\.(png|jpe?g|gif|webp|svg|ico|pdf)$")


def findings(line):
    for m in EMAIL.finditer(line):
        if not FAKE_EMAIL.search(m.group(0)):
            yield "email", m.group(0)
    for m in PHONE.finditer(line):
        if not (m.group(3) == "555" and m.group(4).startswith("01")):
            yield "phone", m.group(0)
    for m in ADDRESS.finditer(line):
        if "Example" not in m.group(0):
            yield "address", m.group(0)


def main():
    base = sys.argv[1] if len(sys.argv) > 1 else "origin/main"
    try:
        diff = subprocess.run(
            ["git", "diff", "--unified=0", "--no-color", f"{base}...HEAD"],
            check=True, capture_output=True, text=True,
        ).stdout
    except subprocess.CalledProcessError as e:
        print(f"error: git diff failed: {e.stderr.strip()}", file=sys.stderr)
        return 2

    hits, path, lineno = [], None, 0
    for raw in diff.splitlines():
        if raw.startswith("+++ "):
            path = raw[6:] if raw.startswith("+++ b/") else None
        elif raw.startswith("@@"):
            lineno = int(re.search(r"\+(\d+)", raw).group(1))
        elif raw.startswith("+") and path:
            text = raw[1:]
            if not SKIP_FILES.search(path) and "pii-ok" not in text:
                for kind, value in findings(text):
                    hits.append(f"{path}:{lineno}: {kind}: {value}")
            lineno += 1

    if hits:
        print("Possible PII in added lines:")
        print("\n".join(hits))
        return 1
    print("No PII-shaped data found in added lines (names still need a manual look).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
