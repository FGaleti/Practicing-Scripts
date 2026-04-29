#!/bin/bash
#########################################################################
# Exercício - Instalação do Zabbix Agent no Debian                      #
#                                                                       #
# Nome: InstalaZabbixAgent.sh                                           #
#                                                                       #
# Autor:Felipe Galeti Gôngora                                           #
# Data: 09/12/2025                                                      #
#                                                                       #
# Descrição: Este script realiza a instalação do Zabbix Agent versão    #
# 6.2.9 no Debian 11. Ele atualiza pacotes, instala dependências,       #
# baixa o pacote do agente, configura parâmetros básicos (Server,       #
# ServerActive, Hostname), habilita e inicia o serviço, e libera a      #
# porta 10050 no firewall caso o UFW esteja ativo.                      #
#                                                                       #
# Uso: ./InstalaZabbixAgent.sh                                          #
#                                                                       #
#########################################################################

echo "🔧 Instalando Zabbix Agent 1 versão 6.2.9 no Debian..."

# Atualiza pacotes e instala dependências
apt update
apt install -y wget gnupg2

# Baixa e instala o pacote do agente (para Debian 11)
wget https://repo.zabbix.com/zabbix/6.2/debian/pool/main/z/zabbix-agent/zabbix-agent_6.2.9-1+debian11_amd64.deb
dpkg -i zabbix-agent_6.2.9-1+debian11_amd64.deb

# Edita a configuração do agente
sed -i 's/^Server=.*/Server=127.0.0.1/' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^ServerActive=.*/ServerActive=127.0.0.1/' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^Hostname=.*/Hostname=debian-agent/' /etc/zabbix/zabbix_agentd.conf

# Habilita e inicia o serviço
systemctl enable zabbix-agent
systemctl restart zabbix-agent

# Libera a porta 10050 no firewall (se UFW estiver ativo)
if command -v ufw >/dev/null 2>&1; then
    ufw allow 10050/tcp
fi

echo "✅ Zabbix Agent instalado e configurado com sucesso no Debian."