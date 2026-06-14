#!/bin/bash
CONF="$HOME/.config/systemd/user/org.gnome.Shell@wayland.service.d/virtual-monitor.conf"

RES=$(zenity --list --title="Resolução do Monitor Virtual" \
  --column="Resolução" --column="Descrição" \
  --width=450 --height=320 \
  "2560x1600" "Nativa do tablet, texto pequeno" \
  "1920x1200" "Custo-benefício para Wi-Fi" \
  "1680x1050" "Intermediário" \
  "1440x900"  "Elementos maiores, leitura" \
  "1280x800"  "Elementos grandes")

[ -z "$RES" ] && exit 0

cat > "$CONF" << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/gnome-shell --virtual-monitor $RES
EOF

systemctl --user daemon-reload
zenity --info --title="Resolução alterada" \
  --text="Resolução definida para <b>$RES</b>.\n\nFaça <b>logout/login</b> para aplicar." \
  --width=300
