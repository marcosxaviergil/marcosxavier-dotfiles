#!/usr/bin/env bash
set -e

CONN="UFSC"
ADDR="vpn.ufsc.br"
IDUFSC="marcos.xavier@ufsc.br"

[[ $EUID -ne 0 ]] && exec sudo bash "$0" "$@"

echo "Instalando pacotes..."
apt-get update -qq
apt-get install -y network-manager-strongswan strongswan-nm libcharon-extra-plugins libcharon-extauth-plugins >/dev/null 2>&1

echo "Matando processos órfãos..."
pkill -9 charon-nm 2>/dev/null || true

echo "Removendo conexão antiga..."
nmcli con delete "$CONN" 2>/dev/null || true

# Pede a senha ANTES
echo ""
echo "Digite sua senha do idUFSC:"
read -s SENHA
echo ""

if [[ -z "$SENHA" ]]; then
    echo "Senha vazia. Saindo."
    exit 1
fi

echo "Criando conexão com senha salva..."
nmcli con add type vpn ifname -- \
  vpn-type strongswan \
  connection.id "$CONN" \
  vpn.data "address=$ADDR,encap=no,ipcomp=no,method=eap,user=$IDUFSC,virtual=yes,proposal=no,esp=aes128gcm16" \
  vpn.secrets "password=$SENHA" \
  >/dev/null

systemctl restart NetworkManager
sleep 3

echo "Conectando..."
nmcli con up "$CONN"

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✓ Conectado!"
else
    echo ""
    echo "✗ Falhou. Verifique usuário/senha."
fi
