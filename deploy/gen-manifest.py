#!/usr/bin/env python3
"""
Regenerate deploy/manifest.json — the index that drives the main menu (index.html)
and the two note viewers (WorkflowHelper.html / BoxHelper.html).

Run it any time you add, rename, or reorder notes:

    python3 deploy/gen-manifest.py

Each topic below points at a folder of markdown notes and declares which viewer
opens it:  "workflow" -> WorkflowHelper.html (AD kill-chain),
           "box"      -> BoxHelper.html      (single standalone box).

Within a folder, README.md is pulled out as the topic's reference doc, images and
non-markdown files are ignored, numbered notes (01-..., 1-...) sort by their number,
and anything listed in `extra` is appended in that order.
"""
import json
import os
import re

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# id, dir, helper, title, blurb, extra (non-numbered notes to append, in order)
TOPICS = [
    ("active", "active", "workflow", "AD Playbook",
     "Consolidated foothold -> harvest -> enumerate -> escalate AD attack playbook.", []),
    ("htbad", "htbad", "workflow", "HTB Academy · Active Directory",
     "Full HTB Academy 'AD Enumeration & Attacks' module, start to finish.",
     ["oscp-practice-checklist.md"]),
    ("offad", "offad", "workflow", "OffSec PEN-200 · Active Directory",
     "PEN-200 AD modules 22-24: enumeration, auth attacks, lateral movement.",
     ["ad-practice-plan.md"]),
    ("scanning", "scanning", "box", "Scanning & Enumeration",
     "Host discovery, port scanning, and service enumeration.", []),
    ("web", "web", "box", "Web Attacks",
     "Web enumeration, content discovery, and common web exploitation.",
     ["enumeration.md", "directories_files.md", "attacks.md"]),
    ("exploits", "exploits", "box", "Exploitation",
     "Finding and running public exploits; MSSQL notes.", []),
    ("privilege", "privilege", "box", "Privilege Escalation",
     "Local privilege escalation on Linux and Windows.", []),
    ("tunnelling", "tunnelling", "box", "Tunnelling & Port Forwarding",
     "Pivoting, port forwarding, and tunnelling through a foothold.", []),
]

# Words that should render with fixed capitalisation.
ACRONYMS = {
    "ad": "AD", "acl": "ACL", "acls": "ACLs", "dcsync": "DCSync",
    "llmnr": "LLMNR", "nbtns": "NBT-NS", "ntlm": "NTLM", "spn": "SPN", "spns": "SPNs",
    "wmi": "WMI", "winrm": "WinRM", "dcom": "DCOM", "psexec": "PsExec",
    "os": "OS", "oscp": "OSCP", "smb": "SMB", "mssql": "MSSQL", "ldap": "LDAP",
    "dns": "DNS", "net": ".NET", "powershell": "PowerShell", "powerview": "PowerView",
    "sharphound": "SharpHound", "bloodhound": "BloodHound", "tgt": "TGT",
    "as": "AS", "rep": "REP", "pth": "PtH", "i": "I", "ii": "II", "iii": "III",
}
# Connector words to keep lowercase when not the first word.
SMALL = {"to", "and", "from", "of", "the", "a", "an", "with", "for", "our", "off", "in", "on"}

# Full-title overrides for the few names auto-casing can't get right.
TITLE_OVERRIDES = {
    "19-as-rep-roasting.md": "19 · AS-REP Roasting",
    "directories_files.md": "Directories & Files",
}


def title_words(words):
    out = []
    for i, w in enumerate(words):
        lw = w.lower()
        if lw in ACRONYMS:
            out.append(ACRONYMS[lw])
        elif i > 0 and lw in SMALL:
            out.append(lw)
        else:
            out.append(w[:1].upper() + w[1:])
    return " ".join(out)


def file_title(fn):
    if fn in TITLE_OVERRIDES:
        return TITLE_OVERRIDES[fn]
    base = fn[:-3] if fn.lower().endswith(".md") else fn
    num = None
    m = re.match(r"^(\d+)[-_](.*)$", base)
    if m:
        num, base = m.group(1), m.group(2)
    words = [w for w in re.split(r"[-_ ]+", base) if w]
    t = title_words(words)
    return f"{num} · {t}" if num else t


def num_prefix(fn):
    m = re.match(r"^(\d+)", fn)
    return int(m.group(1)) if m else 10 ** 9


def build():
    topics = []
    for tid, d, helper, title, blurb, extra in TOPICS:
        dirp = os.path.join(REPO, d)
        if not os.path.isdir(dirp):
            print(f"  ! skipping '{d}': directory not found")
            continue
        md = [f for f in os.listdir(dirp) if f.lower().endswith(".md")]
        readme = next((f for f in md if f.lower() == "readme.md"), None)
        rest = [f for f in md if f != readme]
        numbered = sorted([f for f in rest if re.match(r"^\d+[-_]", f)], key=num_prefix)
        others = [f for f in rest if not re.match(r"^\d+[-_]", f)]

        ordered = list(numbered)
        for e in extra:            # explicit extras first, in declared order
            if e in others:
                ordered.append(e)
        for o in sorted(others):   # then anything left over, alphabetically
            if o not in ordered:
                ordered.append(o)

        topics.append({
            "id": tid,
            "title": title,
            "helper": helper,
            "dir": d,
            "readme": readme,
            "blurb": blurb,
            "files": [{"file": f, "title": file_title(f)} for f in ordered],
        })
        print(f"  {tid:11s} {helper:8s} {len(ordered):2d} notes"
              + ("" if readme else "  (no README)"))
    return {"topics": topics}


def main():
    data = build()
    out = os.path.join(REPO, "deploy", "manifest.json")
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    print(f"wrote {os.path.relpath(out, REPO)}")


if __name__ == "__main__":
    main()
