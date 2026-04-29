#!/bin/bash
#########################################################################
# Exercício - Instalação do Zabbix Agent 2 no Rocky Linux/RHEL 9        #
#                                                                       #
# Nome: InstalaZabbixAgent2_Rocky.sh                                    #
#                                                                       #
# Autor: Felipe Galeti Gôngora                                          #
# Data: 09/12/2025                                                      #
#                                                                       #
# Descrição: Este script realiza a instalação do Zabbix Agent 2 versão  #
# 7.0 LTS no Rocky Linux/RHEL 9. Ele instala o repositório oficial, o   #
# pacote via DNF, edita parâmetros básicos de configuração (Server,     #
# ServerActive), comenta o Hostname (para pegar o nome nativo),         #
# ajusta o Timeout, permite Remote Commands (AllowKey), habilita e      #
# inicia o serviço, e libera a porta 10050 no firewall.                 #
#                                                                       #
# Uso: ./InstalaZabbixAgent2_Rocky.sh                                   #
#                                                                       #
#########################################################################

# Instala o repositório oficial do Zabbix 7.0 LTS apontando para a latest do Rocky 9
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm

# Instala o Zabbix Agent 2 (e os plugins adicionais do Agent 2)
dnf install -y zabbix-agent2 zabbix-agent2-plugin-*

# Edita as configurações de comunicação com o Server
sed -i 's/^Server=.*/Server=IP_DO_SERVER/' /etc/zabbix/zabbix_agent2.conf
sed -i 's/^ServerActive=.*/ServerActive=IP_DO_SERVER_ACTIVE/' /etc/zabbix/zabbix_agent2.conf

# Comenta o Hostname padrão para forçar o agente a usar o hostname do Sistema Operacional
sed -i 's/^Hostname=.*/# Hostname=/' /etc/zabbix/zabbix_agent2.conf

# Altera o Timeout padrão (normalmente de 3) para o máximo (30 segundos)
sed -i 's/^# Timeout=.*/Timeout=30/' /etc/zabbix/zabbix_agent2.conf

# Adiciona a permissão para execução de comandos remotos (system.run) no final do arquivo
echo "" >> /etc/zabbix/zabbix_agent2.conf
echo "### Parametros Customizados ###" >> /etc/zabbix/zabbix_agent2.conf
echo "AllowKey=system.run[*]" >> /etc/zabbix/zabbix_agent2.conf

# Habilita e inicia o serviço do Agent 2
systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

# Libera a porta 10050 no firewall
firewall-cmd --add-port=10050/tcp --permanent
firewall-cmd --reload

echo "✅ Zabbix Agent 2 versão 7.0 LTS instalado e configurado com sucesso!"
echo "   -> Timeout configurado para 30s."
echo "   -> Execução de comandos remotos permitida."