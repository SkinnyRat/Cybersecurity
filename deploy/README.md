# deploy/

Everything needed to run **WorkflowHelper.html** offline and serve it on Kali at boot.

```
deploy/
├── vendor/            # the 4 CDN assets, downloaded locally (no internet needed)
│   ├── github-markdown-dark.css
│   ├── highlight-github-dark.min.css
│   ├── marked.min.js
│   └── highlight.min.js
├── serve.sh           # git pull + two http.server instances (notes + toolbox)
├── install.sh         # installs & enables the systemd service
└── README.md
```

The service runs **two** servers:

| What | URL | Serves | Reachable from |
|------|-----|--------|----------------|
| Notes | `http://127.0.0.1:18888/WorkflowHelper.html` | the repo | localhost only |
| Toolbox | `http://0.0.0.0:80/` | `/home/user/Documents` | anyone on the network (for pushing tools to targets) |

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

1. `git pull --ff-only` refreshes the notes (best-effort — a failed/offline pull won't stop the servers)
2. the **notes** server starts on `http://127.0.0.1:18888/WorkflowHelper.html` (localhost only)
3. the **toolbox** server starts on `http://0.0.0.0:80/` serving `/home/user/Documents`

The unit is granted `CAP_NET_BIND_SERVICE` so your normal user can bind port 80 without
running as root.

> ⚠️ **The toolbox server on `0.0.0.0:80` is reachable by every host on the network,
> including the machines you're attacking.** That's the point — targets pull tools from it.
> But it means anything under `/home/user/Documents` is readable by that network. Fine for
> HTB/lab VLANs; on a real engagement point it at a dedicated scratch dir (see `TOOLBOX_DIR`
> below), not your whole Documents folder.

If the toolbox dir doesn't exist, or port 80 is taken, that server is skipped/errors and the
notes server still runs.

## Handy commands

```bash
systemctl status workflowhelper      # is it running?
journalctl -u workflowhelper -f      # live logs (pull output, requests)
sudo systemctl restart workflowhelper
sudo systemctl disable --now workflowhelper   # stop + don't start at boot
```

## Tweaks

All configurable via env vars (set them in the unit's `[Service]` as `Environment=` or on a
standalone run):

| Var | Default | Meaning |
|-----|---------|---------|
| `PORT` / `BIND` | `18888` / `127.0.0.1` | notes server |
| `TOOLBOX_DIR` | `/home/user/Documents` | what the transfer server serves |
| `TOOLBOX_PORT` / `TOOLBOX_BIND` | `80` / `0.0.0.0` | transfer server; set `TOOLBOX_BIND` to a `tun0` IP to limit exposure to the VPN |

- **Serve a different transfer dir on the VPN only** — e.g. standalone:
  ```bash
  TOOLBOX_DIR=/home/user/transfer TOOLBOX_BIND=10.10.14.5 ./deploy/serve.sh
  ```
- **Disable the toolbox server** — point it at a non-existent dir: `TOOLBOX_DIR=/nonexistent`.
- **Run manually without the service** — `./deploy/serve.sh`
- **Uninstall** —
  ```bash
  sudo systemctl disable --now workflowhelper
  sudo rm /etc/systemd/system/workflowhelper.service
  sudo systemctl daemon-reload
  ```
