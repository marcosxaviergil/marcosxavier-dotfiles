#!/bin/bash
# Pré-configura o servidor dos apps GUI (RocketChat e Bitwarden) numa instalação
# limpa, para que abram já apontando para os servidores certos.
# Idempotente: só escreve se a config de servidor ainda não existe — nunca
# sobrescreve sessão, login ou estado já configurado pelo uso normal.
set -e

# --- Bitwarden Desktop: servidor self-hosted da UFSC ---
BW_DATA="$HOME/.config/Bitwarden/data.json"
if command -v python3 >/dev/null; then
  mkdir -p "$(dirname "$BW_DATA")"
  python3 - << 'PYEOF'
import json, os
p = os.path.expanduser("~/.config/Bitwarden/data.json")
env = {"region": "Self-hosted",
       "urls": {"base": "https://vw.setic.ufsc.br", "api": None, "identity": None,
                "webVault": None, "icons": None, "notifications": None,
                "events": None, "keyConnector": None}}
try:
    d = json.load(open(p)) if os.path.exists(p) else {}
except Exception:
    d = {}
# Só define se ainda não houver servidor configurado
if not d.get("global_environment_environment", {}).get("urls", {}).get("base"):
    d["global_environment_environment"] = env
    json.dump(d, open(p, "w"))
    print("Bitwarden: servidor self-hosted da UFSC pré-configurado.")
else:
    print("Bitwarden: servidor já configurado, mantido.")
PYEOF
fi

# --- RocketChat Desktop: servidor chat.ufsc.br ---
RC_DATA="$HOME/.config/Rocket.Chat/config.json"
if command -v python3 >/dev/null; then
  mkdir -p "$(dirname "$RC_DATA")"
  python3 - << 'PYEOF'
import json, os
p = os.path.expanduser("~/.config/Rocket.Chat/config.json")
url = "https://chat.ufsc.br/"
try:
    d = json.load(open(p)) if os.path.exists(p) else {}
except Exception:
    d = {}
# Só define se ainda não houver nenhum servidor na lista
if not d.get("servers"):
    d["servers"] = [{"url": url, "title": "Chat@UFSC"}]
    d["lastSelectedServerUrl"] = url
    d["currentView"] = {"url": url}
    d["isAddNewServersEnabled"] = True
    json.dump(d, open(p, "w"))
    print("RocketChat: servidor chat.ufsc.br pré-configurado.")
else:
    print("RocketChat: servidor já configurado, mantido.")
PYEOF
fi
