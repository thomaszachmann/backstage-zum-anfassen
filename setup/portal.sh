#!/usr/bin/env bash
# portal.sh start|stop|restart|status|logs – Backstage (yarn start) im Hintergrund.
# Log: $LAB/portal.log. Startet erst, wenn Frontend und Backend antworten.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"
PIDFILE="$LAB/portal.pid"; LOG="$LAB/portal.log"
killtree() { local c; for c in $(pgrep -P "$1" || true); do killtree "$c"; done
  kill "$1" 2>/dev/null || true; }
ready() { curl -sf -m 3 "$BACKSTAGE/.backstage/health/v1/readiness" >/dev/null &&
  curl -sf -m 3 "$APP" >/dev/null; }
case "${1:-status}" in
  start)
    if ready; then echo "✔ läuft bereits: $APP"; exit 0; fi
    cd "$PORTAL"
    nohup yarn start >"$LOG" 2>&1 </dev/null &
    echo $! >"$PIDFILE"
    for _ in $(seq 1 120); do
      if ready; then echo "✔ Backstage läuft: $APP (Backend $BACKSTAGE)"; exit 0; fi
      kill -0 "$(cat "$PIDFILE")" 2>/dev/null || break   # yarn start abgestürzt
      sleep 3
    done
    echo "✘ Start fehlgeschlagen – siehe: tail -50 $LOG" >&2; exit 1 ;;
  stop)
    [ -s "$PIDFILE" ] && killtree "$(cat "$PIDFILE")"; rm -f "$PIDFILE"
    for _ in $(seq 1 20); do ready || { echo "✔ gestoppt"; exit 0; }; sleep 1; done
    echo "✘ läuft noch – Prozesse: lsof -i :$APP_PORT -i :$BACKSTAGE_PORT" >&2; exit 1 ;;
  restart) "$0" stop; "$0" start ;;
  status) if ready; then echo "✔ läuft: $APP"; else echo "✘ läuft nicht"; exit 1; fi ;;
  logs) tail -n "${2:-40}" "$LOG" ;;
  *) echo "Aufruf: portal.sh start|stop|restart|status|logs [n]" >&2; exit 2 ;;
esac
