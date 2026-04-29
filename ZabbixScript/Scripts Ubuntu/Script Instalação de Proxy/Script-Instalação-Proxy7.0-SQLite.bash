#!/usr/bin/env bash
# =============================================================================
# Zabbix Proxy 7.0 LTS - Instalação Automatizada
# OS      : Ubuntu 24.04 LTS (Noble Numbat)
# DB      : SQLite3
# Autor   : Felipe Galeti Gôngora
# =============================================================================
# USO:
#   chmod +x proxycria
#   sudo ./proxycria
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ---------------------------------------------------------------------------
# VARIÁVEIS DE CONFIGURAÇÃO — edite antes de executar
# ---------------------------------------------------------------------------
ZABBIX_SERVER_IP="192.168.1.1"       # IP ou FQDN do Zabbix Server
PROXY_HOSTNAME="zabbix-proxy-01"     # Hostname do proxy (deve coincidir com o cadastro no Server)
PROXY_MODE=0                          # 0 = active | 1 = passive
PROXY_PORT=10051                      # Porta padrão do proxy
SQLITE_DB_PATH="/var/lib/zabbix/zabbix_proxy.db"
LOG_FILE="/var/log/zabbix_proxy_install.log"
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# CORES / HELPERS
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()     { echo -e "$(date '+%Y-%m-%d %H:%M:%S') | $*" | tee -a "$LOG_FILE"; }
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; log "[INFO]  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; log "[OK]    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; log "[WARN]  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; log "[ERROR] $*"; exit 1; }

banner() {
  echo -e "${BOLD}${CYAN}"
  echo "============================================================"
  echo "  Zabbix Proxy 7.0 LTS — Instalação Automatizada"
  echo "  Ubuntu 24.04 (Noble) + SQLite3"
  echo "============================================================${RESET}"
  echo ""
}

# ---------------------------------------------------------------------------
# PRÉ-REQUISITOS
# ---------------------------------------------------------------------------
check_root() {
  [[ $EUID -eq 0 ]] || error "Execute este script como root: sudo $0"
}

check_os() {
  info "Verificando sistema operacional..."
  local os_id os_version
  os_id=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
  os_version=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
  [[ "$os_id" == "ubuntu" && "$os_version" == "24.04" ]] \
    || error "Sistema não suportado: $os_id $os_version. Requerido: Ubuntu 24.04."
  success "OS: Ubuntu $os_version (Noble)"
}

check_internet() {
  info "Verificando conectividade com a internet..."
  ping -c1 -W3 repo.zabbix.com &>/dev/null \
    || error "Sem acesso a repo.zabbix.com. Verifique a rede."
  success "Conectividade OK"
}

validate_config() {
  info "Validando variáveis de configuração..."
  [[ -n "$ZABBIX_SERVER_IP" ]]  || error "ZABBIX_SERVER_IP não definido."
  [[ -n "$PROXY_HOSTNAME" ]]    || error "PROXY_HOSTNAME não definido."
  [[ "$PROXY_MODE" =~ ^[01]$ ]] || error "PROXY_MODE deve ser 0 (active) ou 1 (passive)."
  success "Configurações validadas"
}

# ---------------------------------------------------------------------------
# INSTALAÇÃO
# ---------------------------------------------------------------------------
update_system() {
  info "Atualizando lista de pacotes..."
  apt-get update -qq
  apt-get upgrade -y -qq
  success "Sistema atualizado"
}

install_dependencies() {
  info "Instalando dependências essenciais..."
  apt-get install -y -qq \
    wget curl gnupg lsb-release ca-certificates \
    sqlite3 libsqlite3-dev \
    snmp snmpd snmp-mibs-downloader \
    fping nmap traceroute net-tools iputils-ping \
    unzip tar
  success "Dependências instaladas"
}

add_zabbix_repo() {
  info "Adicionando repositório oficial Zabbix 7.0..."
  local deb_pkg="zabbix-release_latest_7.0+ubuntu24.04_all.deb"
  local deb_url="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/${deb_pkg}"
  local tmp_deb="/tmp/${deb_pkg}"

  wget -q --show-progress -O "$tmp_deb" "$deb_url" \
    || error "Falha ao baixar o pacote do repositório Zabbix."

  # dpkg pode retornar exit 1 se já instalado com mesma versão; ignoramos e deixamos o apt corrigir
  dpkg -i "$tmp_deb" || true
  rm -f "$tmp_deb"

  apt-get update -qq
  success "Repositório Zabbix 7.0 adicionado"
}

install_zabbix_proxy() {
  info "Instalando Zabbix Proxy 7.0 com suporte a SQLite3..."

  # --reinstall garante que os arquivos de schema sejam extraídos mesmo em re-execução
  apt-get install -y --reinstall \
    zabbix-proxy-sqlite3 \
    zabbix-sql-scripts \
    zabbix-agent2

  # Confirma instalação
  dpkg -l zabbix-sql-scripts 2>/dev/null | grep -q "^ii" \
    || error "Pacote zabbix-sql-scripts não instalado corretamente."

  success "Zabbix Proxy 7.0 instalado"

  # Diagnóstico: loga todos os arquivos SQL disponíveis
  info "Arquivos SQL disponíveis no sistema:"
  find /usr/share /usr/lib -path "*zabbix*" -name "*.sql*" 2>/dev/null | tee -a "$LOG_FILE" || true
}

# ---------------------------------------------------------------------------
# BANCO DE DADOS SQLite3
# ---------------------------------------------------------------------------
setup_sqlite_db() {
  info "Configurando banco de dados SQLite3..."

  local db_dir
  db_dir=$(dirname "$SQLITE_DB_PATH")

  mkdir -p "$db_dir"
  chown -R zabbix:zabbix "$db_dir"
  chmod 750 "$db_dir"

  # --- Localiza o schema (paths conhecidos do Zabbix 7.x) ---
  local schema_file=""
  local candidates=(
    "/usr/share/zabbix-sql-scripts/sqlite3/proxy.sql.gz"
    "/usr/share/zabbix/sql-scripts/sqlite3/proxy.sql.gz"
    "/usr/share/doc/zabbix-sql-scripts/sqlite3/proxy.sql.gz"
    "/usr/share/zabbix-sql-scripts/sqlite3/proxy.sql"
    "/usr/share/zabbix/sql-scripts/sqlite3/proxy.sql"
  )

  for p in "${candidates[@]}"; do
    if [[ -f "$p" ]]; then
      schema_file="$p"
      info "Schema encontrado: $schema_file"
      break
    fi
  done

  # Fallback amplo
  if [[ -z "$schema_file" ]]; then
    info "Buscando schema via find..."
    schema_file=$(find /usr/share /usr/lib -name "proxy.sql*" 2>/dev/null | head -1 || true)
    [[ -n "$schema_file" ]] && info "Schema encontrado via find: $schema_file"
  fi

  if [[ -z "$schema_file" ]]; then
    warn "Schema não encontrado nos paths padrão. Listando conteúdo do pacote zabbix-sql-scripts:"
    dpkg -L zabbix-sql-scripts 2>/dev/null | tee -a "$LOG_FILE" || true
    error "Schema SQLite3 não encontrado. Consulte o log: $LOG_FILE"
  fi

  if [[ ! -f "$SQLITE_DB_PATH" ]]; then
    info "Inicializando schema do banco SQLite3..."
    if [[ "$schema_file" == *.gz ]]; then
      zcat "$schema_file" | sqlite3 "$SQLITE_DB_PATH" \
        || error "Falha ao inicializar o banco SQLite3 via zcat."
    else
      sqlite3 "$SQLITE_DB_PATH" < "$schema_file" \
        || error "Falha ao inicializar o banco SQLite3 via sqlite3."
    fi
    success "Schema SQLite3 criado"
  else
    warn "Banco SQLite3 já existe em $SQLITE_DB_PATH — pulando inicialização."
  fi

  chown zabbix:zabbix "$SQLITE_DB_PATH"
  chmod 640 "$SQLITE_DB_PATH"
  success "Banco SQLite3 configurado em: $SQLITE_DB_PATH"
}

# ---------------------------------------------------------------------------
# CONFIGURAÇÃO DO PROXY
# ---------------------------------------------------------------------------
configure_proxy() {
  info "Configurando zabbix_proxy.conf..."
  local conf_file="/etc/zabbix/zabbix_proxy.conf"
  local conf_backup="/etc/zabbix/zabbix_proxy.conf.bak.$(date +%Y%m%d%H%M%S)"

  [[ -f "$conf_file" ]] && cp "$conf_file" "$conf_backup" \
    && info "Backup criado: $conf_backup"

  cat > "$conf_file" <<EOF
# =============================================================================
# Zabbix Proxy 7.0 - Configuração
# Gerado automaticamente em: $(date)
# =============================================================================

# --- Identidade do Proxy ---
Hostname=${PROXY_HOSTNAME}
ProxyMode=${PROXY_MODE}

# --- Conexão com o Zabbix Server ---
Server=${ZABBIX_SERVER_IP}
ListenPort=${PROXY_PORT}

# --- Banco de Dados SQLite3 ---
DBName=${SQLITE_DB_PATH}

# --- Logs ---
LogFile=/var/log/zabbix/zabbix_proxy.log
LogFileSize=100
DebugLevel=3
PidFile=/run/zabbix/zabbix_proxy.pid

# --- Performance e Workers ---
StartPollers=5
StartPreprocessors=3
StartPollersUnreachable=1
StartHTTPPollers=1
StartDiscoverers=1
StartPingers=1
StartTrappers=5
StartDBSyncers=4
CacheSize=32M
HistoryCacheSize=16M
HistoryIndexCacheSize=4M
ProxyLocalBuffer=0
ProxyOfflineBuffer=1
AllowKey=system.run[*]

# --- Timeout e Rede ---
Timeout=4
UnreachablePeriod=45
UnavailableDelay=60
UnreachableDelay=15
ProxyConfigFrequency=10
DataSenderFrequency=1

# --- SNMP ---
SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
StartSNMPTrapper=0

# --- Diretórios externos ---
ExternalScripts=/usr/lib/zabbix/externalscripts
FpingLocation=/usr/bin/fping
Fping6Location=/usr/bin/fping6
TmpDir=/tmp/zabbix_proxy

# --- TLS (desabilitado por padrão — configure conforme necessário) ---
# TLSConnect=psk
# TLSAccept=psk
# TLSPSKIdentity=PSK 001
# TLSPSKFile=/etc/zabbix/zabbix_proxy.psk

EOF

  chmod 640 "$conf_file"
  chown root:zabbix "$conf_file"
  success "zabbix_proxy.conf configurado"
}

configure_agent2() {
  info "Configurando Zabbix Agent2 (monitoramento local do proxy)..."
  local agent_conf="/etc/zabbix/zabbix_agent2.conf"

  sed -i \
    -e "s|^Server=.*|Server=${ZABBIX_SERVER_IP}|" \
    -e "s|^ServerActive=.*|ServerActive=${ZABBIX_SERVER_IP}|" \
    -e "s|^Hostname=.*|Hostname=${PROXY_HOSTNAME}|" \
    "$agent_conf"

  success "Zabbix Agent2 configurado"
}

# ---------------------------------------------------------------------------
# DIRETÓRIOS E PERMISSÕES
# ---------------------------------------------------------------------------
setup_directories() {
  info "Criando diretórios necessários..."
  local dirs=(
    "/var/log/zabbix"
    "/run/zabbix"
    "/tmp/zabbix_proxy"
    "/usr/lib/zabbix/externalscripts"
    "/var/log/snmptrap"
  )

  for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
    chown zabbix:zabbix "$dir"
    chmod 755 "$dir"
    info "  Criado: $dir"
  done

  success "Diretórios configurados"
}

# ---------------------------------------------------------------------------
# FIREWALL
# ---------------------------------------------------------------------------
configure_firewall() {
  info "Configurando regras de firewall (UFW)..."

  if command -v ufw &>/dev/null; then
    ufw allow "${PROXY_PORT}/tcp" comment "Zabbix Proxy" &>/dev/null
    ufw allow 10050/tcp comment "Zabbix Agent2" &>/dev/null
    ufw reload &>/dev/null
    success "UFW configurado"
  else
    warn "UFW não encontrado. Configure o firewall manualmente."
    warn "  Portas necessárias: ${PROXY_PORT}/tcp (Proxy), 10050/tcp (Agent)"
  fi
}

# ---------------------------------------------------------------------------
# SERVIÇOS
# ---------------------------------------------------------------------------
enable_services() {
  info "Habilitando e iniciando serviços..."
  systemctl daemon-reload

  for svc in zabbix-proxy zabbix-agent2; do
    systemctl enable "$svc"
    systemctl restart "$svc"
    sleep 2

    if systemctl is-active --quiet "$svc"; then
      success "$svc: ATIVO"
    else
      error "$svc falhou ao iniciar. Verifique: journalctl -u $svc --no-pager"
    fi
  done
}

# ---------------------------------------------------------------------------
# VERIFICAÇÃO FINAL
# ---------------------------------------------------------------------------
verify_installation() {
  info "Executando verificação final..."
  echo ""
  echo -e "${BOLD}--- Status dos Serviços ---${RESET}"
  systemctl status zabbix-proxy  --no-pager -l | grep -E "(Active|Main PID|Tasks)" || true
  systemctl status zabbix-agent2 --no-pager -l | grep -E "(Active|Main PID|Tasks)" || true

  echo ""
  echo -e "${BOLD}--- Versão Instalada ---${RESET}"
  zabbix_proxy --version 2>&1 | head -1 || true

  echo ""
  echo -e "${BOLD}--- Banco de Dados ---${RESET}"
  [[ -f "$SQLITE_DB_PATH" ]] \
    && echo -e "${GREEN}SQLite3 OK:${RESET} $SQLITE_DB_PATH ($(du -sh "$SQLITE_DB_PATH" | cut -f1))" \
    || echo -e "${RED}Banco não encontrado!${RESET}"

  echo ""
  echo -e "${BOLD}--- Portas em Escuta ---${RESET}"
  ss -tlnp | grep -E "(:${PROXY_PORT}|:10050)" || warn "Nenhuma porta Zabbix detectada ainda."

  echo ""
  echo -e "${BOLD}--- Log do Proxy (últimas 10 linhas) ---${RESET}"
  sleep 2
  tail -n 10 /var/log/zabbix/zabbix_proxy.log 2>/dev/null || warn "Log ainda não disponível."
}

print_summary() {
  echo ""
  echo -e "${BOLD}${GREEN}"
  echo "============================================================"
  echo "  INSTALAÇÃO CONCLUÍDA COM SUCESSO"
  echo "============================================================${RESET}"
  echo ""
  echo -e "  ${BOLD}Proxy Hostname  :${RESET} ${PROXY_HOSTNAME}"
  echo -e "  ${BOLD}Modo            :${RESET} $([ "$PROXY_MODE" -eq 0 ] && echo 'Active' || echo 'Passive')"
  echo -e "  ${BOLD}Zabbix Server   :${RESET} ${ZABBIX_SERVER_IP}:${PROXY_PORT}"
  echo -e "  ${BOLD}Banco de Dados  :${RESET} SQLite3 → ${SQLITE_DB_PATH}"
  echo -e "  ${BOLD}Log do Proxy    :${RESET} /var/log/zabbix/zabbix_proxy.log"
  echo -e "  ${BOLD}Log Instalação  :${RESET} ${LOG_FILE}"
  echo ""
  echo -e "  ${YELLOW}PRÓXIMO PASSO:${RESET} Adicione o proxy no Zabbix Server em:"
  echo -e "  Administration → Proxies → Create Proxy"
  echo -e "  Hostname: ${BOLD}${PROXY_HOSTNAME}${RESET}"
  echo ""
  echo -e "  ${CYAN}Comandos úteis:${RESET}"
  echo -e "    systemctl status zabbix-proxy"
  echo -e "    systemctl restart zabbix-proxy"
  echo -e "    tail -f /var/log/zabbix/zabbix_proxy.log"
  echo ""
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
main() {
  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE"

  banner
  check_root
  check_os
  check_internet
  validate_config

  info "Iniciando instalação do Zabbix Proxy 7.0..."
  echo ""

  update_system
  install_dependencies
  add_zabbix_repo
  install_zabbix_proxy
  setup_directories
  setup_sqlite_db
  configure_proxy
  configure_agent2
  configure_firewall
  enable_services
  verify_installation
  print_summary
}

main "$@"