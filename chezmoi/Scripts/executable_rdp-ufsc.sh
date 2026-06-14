#!/usr/bin/env bash
set -euo pipefail

LOGDIR="$HOME/.local/state/rdp-ufsc"
mkdir -p "$LOGDIR"

RDP_BIN="$(command -v xfreerdp3 || command -v xfreerdp)"
SENHA=$(zenity --password --title="UFSC REMOTO" --text="Senha:") || exit 1

# ---- Helpers ----
safe_name() {
  # Nome amigável pra unidade no remoto (Windows):
  # - troca espaços por _
  # - remove caracteres chatos
  local s="$1"
  s="${s// /_}"
  s="$(printf '%s' "$s" | tr -cd 'A-Za-z0-9._-')"
  # evita vazio
  [[ -n "$s" ]] || s="share"
  printf '%s' "$s"
}

add_drive() {
  local name="$1" path="$2"
  [[ -d "$path" ]] || return 0
  name="$(safe_name "$name")"
  DRIVES+=( "/drive:${name},${path}" )
}

# ---- Montagens ----
DRIVES=()

# 1) Cada pasta "visível" da HOME como unidade
# (evita pastas ocultas e pastas enormes/irrelevantes por padrão)
while IFS= read -r -d '' d; do
  base="$(basename "$d")"

  # pula hidden e algumas comuns que não valem (ajuste como quiser)
  case "$base" in
    .*|snap|.cache|.local|.config|.var) continue ;;
  esac

  add_drive "HOME_${base}" "$d"
done < <(find "$HOME" -mindepth 1 -maxdepth 1 -type d -print0)

# Sempre garante Documentos/Downloads se existirem (caso você tenha oculto/variação)
add_drive "HOME_Documentos" "$HOME/Documentos"
add_drive "HOME_Downloads"  "$HOME/Downloads"
add_drive "HOME_Imagens"    "$HOME/Imagens"
add_drive "HOME_Videos"     "$HOME/Videos"
add_drive "HOME_Musica"     "$HOME/Música"

# 2) Cada "disco" montado em / (menos o /) como unidade
# pega somente mountpoints diretos em /, ex: /mnt, /media, /data, /run/media/...
# se você usa /run/media/usuario/XXX, isso NÃO é direto em /; abaixo eu trato também.
while IFS= read -r mp; do
  [[ "$mp" == "/" ]] && continue
  # nome: MNT_<basename>
  add_drive "MNT_$(basename "$mp")" "$mp"
done < <(findmnt -rn -o TARGET | awk -F/ 'NF==2 {print "/"$2}' | sort -u)

# 2b) Também inclui montagens típicas do desktop (ex.: /media/$USER/..., /run/media/$USER/...)
for root in "/media/$USER" "/run/media/$USER"; do
  if [[ -d "$root" ]]; then
    while IFS= read -r -d '' mp; do
      add_drive "MNT_$(basename "$mp")" "$mp"
    done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -print0)
  fi
done

# ---- Exec FreeRDP ----
exec "$RDP_BIN" \
  /v:100.64.0.15:3389 \
  /u:marcosxavier \
  /p:"$SENHA" \
  /cert:ignore \
  /f \
  /multimon \
  "${DRIVES[@]}" \
  +clipboard \
  +auto-reconnect \
  /sound:sys:pulse \
  /microphone:sys:pulse \
  /log-level:WARN \
  2>>"$LOGDIR/rdp.log"
