#!/bin/bash
#########################################################################
# Exercício - Instalação do Zabbix Agent 2 no Debian 11                 #
#                                                                       #
# Nome: InstalaZabbixAgent2_Debian.sh                                   #
#                                                                       #
# Autor: Felipe Galeti Gôngora                                          #
# Data: 13/03/2026                                                      #
#                                                                       #
# Descrição: Este script realiza a instalação do Zabbix Agent 2 versão  #
# 7.0 LTS no Debian 11. Ele instala o repositório oficial, o pacote     #
# via APT, edita parâmetros básicos de configuração (Server,             #
# ServerActive), comenta o Hostname (para pegar o nome nativo),         #
# ajusta o Timeout, permite Remote Commands (AllowKey), habilita e      #
# inicia o serviço, e libera a porta 10050 no firewall UFW.             #
#                                                                       #
# Uso: ./InstalaZabbixAgent2_Debian.sh                                  #
#                                                                       #
#########################################################################

echo "Instalando Zabbix Agent 2 versão 7.0 LTS no Debian..."

# Atualiza a lista de pacotes e instala dependências iniciais
apt update && apt install -y wget gnupg2

# Baixa e instala o repositório oficial do Zabbix 7.0 LTS para Debian 11
wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian11_all.deb
dpkg -i zabbix-release_latest+debian11_all.deb
apt update

# Instala o Zabbix Agent 2 e plugins adicionais
apt install -y zabbix-agent2 zabbix-agent2-plugin-*

# Edita as configurações de comunicação com o Server (IP conforme seu script do Rocky)
sed -i 's/^Server=.*/Server=IP_DO_SERVER/' /etc/zabbix/zabbix_agent2.conf
sed -i 's/^ServerActive=.*/ServerActive=IP_DO_SERVER/' /etc/zabbix/zabbix_agent2.conf

# Comenta o Hostname padrão para forçar o agente a usar o hostname do Sistema Operacional
sed -i 's/^Hostname=.*/# Hostname=/' /etc/zabbix/zabbix_agent2.conf

# Altera o Timeout padrão para o máximo (30 segundos)
sed -i 's/^# Timeout=.*/Timeout=30/' /etc/zabbix/zabbix_agent2.conf

# Adiciona a permissão para execução de comandos remotos (system.run) no final do arquivo
echo "" >> /etc/zabbix/zabbix_agent2.conf
echo "### Parametros Customizados ###" >> /etc/zabbix/zabbix_agent2.conf
echo "AllowKey=system.run[*]" >> /etc/zabbix/zabbix_agent2.conf

# Habilita e inicia o serviço do Agent 2
systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

# Libera a porta 10050 no firewall (se o UFW estiver instalado e ativo)
if command -v ufw >/dev/null 2>&1; then
    ufw allow 10050/tcp
    echo "Porta 10050 liberada no UFW."
fi

echo "Zabbix Agent 2 versão 7.0 LTS instalado e configurado com sucesso!"
echo "   -> Timeout configurado para 30s."
echo "   -> Execução de comandos remotos permitida via AllowKey."