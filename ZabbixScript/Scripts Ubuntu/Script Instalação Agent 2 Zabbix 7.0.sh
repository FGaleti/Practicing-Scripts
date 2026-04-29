#!/bin/bash
#########################################################################
# Exercício - Instalação do Zabbix Agent 2 no Ubuntu 24.10              #
#                                                                       #
# Nome: InstalaZabbixAgent2_Ubuntu.sh                                   #
#                                                                       #
# Autor: Felipe Galeti Gôngora                                          #
#                                                                       #
# Descrição: Este script realiza a instalação do Zabbix Agent 2 versão  #
# 7.0 LTS no Ubuntu 24.10 (usando a base do 24.04). Ele baixa o         #
# repositório oficial, instala o pacote via APT, edita os parâmetros    #
# (Server, ServerActive), comenta o Hostname (para usar o nome nativo), #
# ajusta o Timeout, permite Remote Commands (AllowKey), habilita e      #
# inicia o serviço, e libera a porta 10050 no UFW (firewall).           #
#                                                                       #
# Uso: sudo ./InstalaZabbixAgent2_Ubuntu.sh                             #
#                                                                       #
#########################################################################

# Interrompe o script imediatamente se qualquer comando falhar (Boa prática)

echo " Preparando a instalação do Zabbix Agent 2 (7.0 LTS)..."

# Baixa e instala o repositório oficial do Zabbix 7.0 LTS (Usando a base do Ubuntu 24.04 Noble)
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu24.04_all.deb -O zabbix-release_latest.deb
dpkg -i zabbix-release_latest.deb

# Atualiza a lista de pacotes e instala o Zabbix Agent 2 com seus plugins
apt update
apt install -y zabbix-agent2 zabbix-agent2-plugin-*

echo " Configurando o agente..."

# Edita as configurações de comunicação com o Server
sed -i 's/^Server=.*/Server=IP_DO_SERVER/' /etc/zabbix/zabbix_agent2.conf
sed -i 's/^ServerActive=.*/ServerActive=IP_DO_SERVER/' /etc/zabbix/zabbix_agent2.conf

# Comenta o Hostname padrão para forçar o agente a usar o hostname do Sistema Operacional
sed -i 's/^Hostname=.*/# Hostname=/' /etc/zabbix/zabbix_agent2.conf

# Altera o Timeout padrão (normalmente de 3) para o máximo (30 segundos)
sed -i 's/^# Timeout=.*/Timeout=30/' /etc/zabbix/zabbix_agent2.conf

# Adiciona a permissão para execução de comandos remotos (system.run) no final do arquivo
echo "" >> /etc/zabbix/zabbix_agent2.conf
echo "### Parametros Customizados ###" >> /etc/zabbix/zabbix_agent2.conf
echo "AllowKey=system.run[*]" >> /etc/zabbix/zabbix_agent2.conf

echo " Habilitando e iniciando o serviço..."
# Habilita e inicia o serviço do Agent 2
systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

# Libera a porta 10050 no firewall (se UFW estiver ativo)
if command -v ufw >/dev/null 2>&1; then
    echo "🛡️ Configurando o firewall UFW..."
    ufw allow 10050/tcp
    ufw reload
fi

# Limpa o pacote .deb baixado para não deixar sujeira no servidor
rm -f zabbix-release_latest.deb

echo "✅ Zabbix Agent 2 versão 7.0 LTS instalado e configurado com sucesso!"
echo "   -> Timeout configurado para 30s."
echo "   -> Execução de comandos remotos permitida."