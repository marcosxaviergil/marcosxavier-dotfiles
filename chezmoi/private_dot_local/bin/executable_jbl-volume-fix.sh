#!/usr/bin/env bash
set -u

echo "===== Detectando card JBL ====="
CARD="$(awk '
  /JBL Quantum 950 Wireless/ {
    for (i=1; i<=NF; i++) {
      if ($i ~ /^\[/) {
        gsub(/\[/, "", $i)
        print $i
        exit
      }
    }
  }
' /proc/asound/cards)"

if [ -z "${CARD:-}" ]; then
  echo "JBL Quantum 950 Wireless não encontrado em /proc/asound/cards"
  exit 0
fi

echo "JBL encontrado no card ALSA: $CARD"

echo "===== Driver usado pelo JBL ====="
readlink -f "/sys/class/sound/card${CARD}/device/driver" 2>/dev/null || true
cat "/proc/asound/card${CARD}/usbid" 2>/dev/null || true

echo "===== Ajustando controles ALSA Playback para 100% ====="
amixer -c "$CARD" scontrols | sed -n "s/^Simple mixer control '\([^']*\)'.*/\1/p" | while read -r CONTROL; do
  if amixer -c "$CARD" sget "$CONTROL" | grep -q "Playback"; then
    echo "Ajustando: $CONTROL"
    amixer -c "$CARD" sset "$CONTROL" 100% unmute || true
  fi
done

echo "===== Detectando sink JBL no PipeWire ====="
SINK="$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -i 'JBL Quantum 950 Wireless' | head -n1 | awk '{
  for (i=1; i<=NF; i++) {
    if ($i ~ /^[0-9]+\.$/) {
      gsub(/\./, "", $i)
      print $i
      exit
    }
  }
}')"

if [ -n "${SINK:-}" ]; then
  echo "JBL encontrado no PipeWire sink: $SINK"
  wpctl set-default "$SINK" || true
  wpctl set-mute "$SINK" 0 || true
  wpctl set-volume "$SINK" 1.00 || true
else
  echo "Sink JBL não encontrado no PipeWire"
fi

echo "===== Estado final ALSA ====="
amixer -c "$CARD" scontents

echo "===== Estado final PipeWire ====="
wpctl status | sed -n '/Sinks:/,/Sources:/p'
[ -n "${SINK:-}" ] && wpctl get-volume "$SINK" || true
