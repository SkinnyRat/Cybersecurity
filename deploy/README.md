# deploy/

Everything needed to run **WorkflowHelper.html** offline and serve it on Kali at boot.

```
deploy/
├── vendor/            # the 4 CDN assets, downloaded locally (no internet needed)
│   ├── github-markdown-dark.css
│   ├── highlight-github-dark.min.css
│   ├── marked.min.js
│   └── highlight.min.js
├── serve.sh           # git pull + `python3 -m http.server` on 127.0.0.1:18888
├── install.sh         # installs & enables the systemd service
└── README.md
```

`WorkflowHelper.html` (repo root) now references `deploy/vendor/*` instead of the CDNs,
so it works fully offline — you can also just double-click it into Firefox.

## Install the boot service (Kali)

Clone the repo somewhere on Kali, then:

```bash
cd Cybersecurity
sudo ./deploy/install.sh
```

This auto-detects the repo path and your username, writes
`/etc/systemd/system/workflowhelper.service`, and enables it. From now on, every boot:

1. `git pull --ff-only` refreshes the notes (best-effort — a failed/offline pull won't stop the server)
2. a static HTTP server starts on **http://127.0.0.1:18888/WorkflowHelper.html**

The server is bound to `127.0.0.1` (localhost only). The whole repo is served, so the
`htbad/*.md` notes are reachable too — but the Import button reads from disk directly, so
that's just a bonus.

## Handy commands

```bash
systemctl status workflowhelper      # is it running?
journalctl -u workflowhelper -f      # live logs (pull output, requests)
sudo systemctl restart workflowhelper
sudo systemctl disable --now workflowhelper   # stop + don't start at boot
```

## Tweaks

- **Different port / expose on LAN** — edit the service or run standalone:
  ```bash
  PORT=9000 BIND=0.0.0.0 ./deploy/serve.sh
  ```
  Binding to `0.0.0.0` exposes it to the whole network — avoid that on hostile/engagement networks.
- **Run manually without the service** — `./deploy/serve.sh`
- **Uninstall** —
  ```bash
  sudo systemctl disable --now workflowhelper
  sudo rm /etc/systemd/system/workflowhelper.service
  sudo systemctl daemon-reload
  ```
