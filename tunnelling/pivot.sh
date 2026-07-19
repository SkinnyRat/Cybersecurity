#!/usr/bin/env bash
#
# pivot.sh - HTB/OSCP pivot quick-start + preflight
#
# Collapses the ssh -D / proxychains / verify dance into one command, with the
# gotchas from tunnelling.md SS G baked in: LOCAL socks address (not the pivot),
# socks5, host-key auto-accept, key perms, and listener + path verification.
#
#   why:  tunnelling.md  SS B.2 (-D SOCKS)  .  SS B.1 (-L forward)  .  SS G (triage)
#
# Modes:
#   ./pivot.sh socks -j <PIVOT_IP> -i <KEY> [-u root] [-p 9999] [-t 172.16.8.3:445]
#       Start a dynamic SOCKS tunnel, point proxychains at 127.0.0.1:<port>, verify.
#       -t <host:port> = a known internal service to prove the path (optional but do it).
#
#   ./pivot.sh fwd   -j <PIVOT_IP> -i <KEY> [-u root] -L <LPORT:TARGET_IP:RPORT>
#       Single-service forward, e.g. RDP:  -L 13389:172.16.8.20:3389
#       then:  xfreerdp /v:127.0.0.1:13389 /u:USER /p:PASS /cert:ignore
#
#   ./pivot.sh check [-p 9999] [-t 172.16.8.3:445]
#       Re-run the preflight (listener + path) without starting anything.
#
#   ./pivot.sh down  [-p 9999]
#       Tear down the SOCKS tunnel on <port>.
#
set -euo pipefail

PORT=9999
SSH_USER=root
KEY=""
PIVOT=""
TEST=""
LSPEC=""

die(){  echo "[!] $*" >&2; exit 1; }
info(){ echo "[*] $*"; }
ok(){   echo "[+] $*"; }

usage(){ sed -n '3,33p' "$0" | sed 's/^#\s\?//'; exit "${1:-1}"; }

SSH_OPTS=(-o StrictHostKeyChecking=accept-new
          -o ServerAliveInterval=60 -o ServerAliveCountMax=3
          -o ExitOnForwardFailure=yes)

find_pc_conf(){
  # proxychains-ng precedence: /etc/proxychains.conf WINS over /etc/proxychains4.conf
  for f in /etc/proxychains.conf /etc/proxychains4.conf; do
    [ -f "$f" ] && { echo "$f"; return; }
  done
  die "no proxychains conf found (/etc/proxychains.conf or /etc/proxychains4.conf)"
}

set_proxychains(){
  local conf bak; conf="$(find_pc_conf)"; bak="${conf}.bak.$(date +%s)"
  info "proxychains conf in use: $conf  (backup: $bak)"
  sudo cp "$conf" "$bak"
  # keep everything up to & including [ProxyList], then exactly ONE local socks5 line
  awk -v port="$PORT" '
    {print}
    /^\[ProxyList\]/ {print "socks5 127.0.0.1 " port; exit}
  ' "$bak" | sudo tee "$conf" >/dev/null
  ok "proxy set -> socks5 127.0.0.1 $PORT   (LOCAL port, not the pivot IP - SS G)"
}

verify(){
  info "checking SOCKS listener on :$PORT ..."
  if ss -ltnp 2>/dev/null | grep -q ":$PORT "; then
    ok "listener up on :$PORT"
  else
    die "no listener on :$PORT - ssh -D never connected (key perms? host-key prompt? routing?)"
  fi
  [ -n "$TEST" ] || { info "no -t target given, skipping path test"; return; }
  local host="${TEST%%:*}" tport="${TEST##*:}"
  info "testing path to $host:$tport through the proxy ..."
  if proxychains -q nc -zv -w5 "$host" "$tport" 2>&1 | grep -qi succeeded; then
    ok "path OK - proxychains reaches $host:$tport"
  else
    die "path FAILED to $host:$tport - proxy up but target/route unreachable (see SS G)"
  fi
}

need_ssh(){
  [ -n "$PIVOT" ] && [ -n "$KEY" ] || die "need -j <PIVOT_IP> and -i <KEY>"
  [ -f "$KEY" ] || die "key not found: $KEY"
  chmod 600 "$KEY" 2>/dev/null || true
}

cmd_socks(){
  need_ssh
  info "starting SOCKS: ssh -D 0.0.0.0:$PORT via $SSH_USER@$PIVOT"
  ssh -f -N -D "0.0.0.0:$PORT" -i "$KEY" "${SSH_OPTS[@]}" "$SSH_USER@$PIVOT" \
    || die "ssh -D failed (bad key / host down / auth)"
  sleep 1
  set_proxychains
  verify
  echo
  ok "ready - prefix tools with:  proxychains -q <tool>   (ONE target at a time over a pivot)"
}

cmd_fwd(){
  need_ssh
  [ -n "$LSPEC" ] || die "fwd needs -L <LPORT:TARGET_IP:RPORT>  (e.g. 13389:172.16.8.20:3389)"
  local lport="${LSPEC%%:*}"
  info "forwarding 127.0.0.1:$lport -> $LSPEC via $SSH_USER@$PIVOT"
  ssh -f -N -L "$LSPEC" -i "$KEY" "${SSH_OPTS[@]}" "$SSH_USER@$PIVOT" || die "ssh -L failed"
  ok "up - connect to 127.0.0.1:$lport   (e.g. xfreerdp /v:127.0.0.1:$lport /cert:ignore ...)"
}

cmd_down(){
  if pkill -f "ssh -f -N -D 0.0.0.0:$PORT"; then ok "SOCKS tunnel on :$PORT down"
  else die "no SOCKS tunnel found on :$PORT"; fi
}

[ $# -ge 1 ] || usage
MODE="$1"; shift || true
while getopts "j:i:u:p:t:L:h" o; do
  case "$o" in
    j) PIVOT="$OPTARG";; i) KEY="$OPTARG";; u) SSH_USER="$OPTARG";;
    p) PORT="$OPTARG";;  t) TEST="$OPTARG";; L) LSPEC="$OPTARG";;
    h) usage 0;;         *) usage;;
  esac
done

case "$MODE" in
  socks) cmd_socks;;
  fwd)   cmd_fwd;;
  check) verify;;
  down)  cmd_down;;
  -h|--help|help) usage 0;;
  *) die "unknown mode '$MODE' (socks|fwd|check|down)";;
esac
