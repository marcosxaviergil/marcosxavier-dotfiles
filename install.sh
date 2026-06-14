#!/bin/bash
# GitHub:  bash <(curl -fsSL https://raw.githubusercontent.com/marcosxaviergil/marcosxavier-dotfiles/master/install.sh)
# Forgejo: bash <(curl -fsSL https://forgejo.consciencia.dev.br/marcosxavier/marcosxavier-dotfiles/raw/branch/master/install.sh)
set -e

echo "=== 0. Pré-requisitos mínimos ==="
sudo apt update && sudo apt install -y git ansible npm
if ! command -v chezmoi &>/dev/null; then
  sudo sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
fi

echo "=== 1. Clonar ou atualizar dotfiles ==="
if [ ! -d ~/dotfiles ]; then
  git clone https://github.com/marcosxaviergil/marcosxavier-dotfiles.git ~/dotfiles
else
  git -C ~/dotfiles fetch origin
  git -C ~/dotfiles reset --hard origin/master
fi

# Re-executar o install.sh atualizado se este script foi atualizado pelo reset
SCRIPT_ATUAL="$HOME/dotfiles/install.sh"
if ! cmp -s "$0" "$SCRIPT_ATUAL" 2>/dev/null; then
  echo "=== install.sh atualizado, re-executando versão nova ==="
  exec bash "$SCRIPT_ATUAL"
fi

echo "=== 2. Ansible ==="
cd ~/dotfiles/ansible && ansible-playbook playbook.yml -K

echo "=== 3. Chezmoi ==="
echo "   ⚠️  Certifique-se de que o Bitwarden está logado e desbloqueado antes de aplicar os dotfiles."
echo "   Se necessário, execute: bw login --apikey && export BW_SESSION=$(bw unlock --raw)"
chezmoi init --source ~/dotfiles
chezmoi apply --source ~/dotfiles
# Para aplicar templates que dependem do Bitwarden (remmina, obs, spotify, tailscale):
#   bw config server https://vw.setic.ufsc.br
#   bw login --apikey                      # pede client_id e client_secret (Settings > Security > Keys)
#   export BW_SESSION=$(bw unlock --raw)   # pede a senha mestra
#   bw sync                                # obrigatorio: sem isso o vault fica vazio (erro InvalidMac)
#   chezmoi apply --source ~/dotfiles