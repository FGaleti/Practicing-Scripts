#!/bin/bash

# Interrompe o script imediatamente se qualquer comando falhar
set -e

echo "🔧 Instalando repositório e Zabbix Agent (Versão 6.0 LTS) no Ubuntu 22.04..."

# 1. Baixa e instala o repositório oficial do Zabbix para Ubuntu 22.04 (Jammy)
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu22.04_all.deb
dpkg -i zabbix-release_6.0-4+ubuntu22.04_all.deb

# 2. Atualiza os pacotes e instala o agente
apt update
apt install -y zabbix-agent

# 3. Edita a configuração do agente
echo "⚙️ Configurando o agente..."
sed -i 's/^Server=.*/Server=IP/' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^ServerActive=.*/ServerActive=IP/' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^Hostname=.*/Hostname=#HostName/' /etc/zabbix/zabbix_agentd.conf

# 4. Habilita e inicia o serviço
echo "🚀 Iniciando o serviço..."
systemctl enable zabbix-agent
systemctl restart zabbix-agent

# 5. Libera a porta 10050 no firewall (se UFW estiver ativo)
if command -v ufw >/dev/null 2>&1; then
    echo "🛡️ Configurando o UFW..."
    ufw allow 10050/tcp
fi

echo "✅ Zabbix Agent instalado e configurado com sucesso!"