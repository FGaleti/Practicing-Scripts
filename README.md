
# Practicing-Scripts

### Automação, Monitoramento e Infraestrutura — Production-Ready

[![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?style=flat-square&logo=gnubash)](https://www.gnu.org/software/bash/)
[![Zabbix](https://img.shields.io/badge/Zabbix-6.2%20%7C%207.0-E82834?style=flat-square&logo=zabbix)](https://www.zabbix.com)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%2F24.04-E95420?style=flat-square&logo=ubuntu)](https://ubuntu.com)
[![Debian](https://img.shields.io/badge/Debian-11%2B-A81D33?style=flat-square&logo=debian)](https://www.debian.org)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

---

## Por que usar este repositório?

Este é um **conjunto pré-validado de scripts de produção** para:

- **Instalação automatizada do Zabbix** em múltiplas distribuições Linux
- **Monitoramento empresarial** de processos, filesystem, CPU, memória e rede
- **Gestão de infraestrutura** via script — reduzindo tempo de deployment
- **Padrões de qualidade** — todos os scripts possuem tratamento de erros, logging e validações

### Benefícios Imediatos

| Feature | Descrição |
|---------|-----------|
| **Deploy em minutos** | Instalação e configuração completa do Zabbix Agent/Proxy |
| **Multi-distribuição** | Debian, Ubuntu, Red Hat, CentOS, AlmaLinux |
| **Versões LTS** | Zabbix 6.2.9, 7.0 — compatibilidade garantida |
| **Idempotente** | Execute múltiplas vezes sem efeitos colaterais |
| **Bem documentado** | Comentários inline, flags claras, exemplos prontos |
| **Validações rigorosas** | Verificação de conectividade, permissões, dependências |

---

## Estrutura do Repositório

```
Practicing-Scripts/
├── Shell-Scripts/              # Utilitários e ferramentas de sistema
│   ├── CriaArquivo.sh          # Criador de arquivos com estrutura
│   ├── GerarBackupHome.sh      # Backup automatizado de home directory
│   ├── MonitoraProcesso.sh     # Monitoramento contínuo de processos
│   ├── MonitoraFS.sh           # Alertas de espaço em disco
│   ├── MonitoraSwap.sh         # Monitoramento de memória swap
│   ├── RelatorioMaquina.sh     # Relatório de hardware e sistema
│   └── RelatorioUsuario.sh     # Relatório de usuários e permissões
│
└── ZabbixScript/               # Automação de deployement Zabbix
    ├── Scripts Debian/         # Agent 6.2.9 e 7.0 para Debian 11
    ├── Scripts Red Hat/        # Agent 6.2.9 e 7.0 para RHEL/CentOS
    ├── Scripts Ubuntu/         # Agent 6.0, 7.0 para Ubuntu 22.04+
    │   └── Script Instalação de Proxy/    # Proxy SQLite3 7.0 (production-ready)
```

---

## Quick Start

### Instalação do Zabbix Agent 2 (Ubuntu 24.04)

```bash
# Clonar repositório
git clone https://github.com/seu-usuario/Practicing-Scripts.git
cd Practicing-Scripts/ZabbixScript/Scripts\ Ubuntu/

# Fazer script executável
chmod +x "Script Instalação Agent 2 Zabbix 7.0.sh"

# Executar (requer sudo)
sudo ./Script\ Instalação\ Agent\ 2\ Zabbix\ 7.0.sh
```

### Instalação do Zabbix Proxy 7.0 com SQLite3

```bash
cd "ZabbixScript/Scripts Ubuntu/Script Instalação de Proxy/"
chmod +x "Script-Instalação-Proxy7.0-SQLite.bash"

# Configure as variáveis de ambiente
export ZABBIX_SERVER_IP="192.168.1.100"
export PROXY_HOSTNAME="proxy-producao-01"

sudo ./Script-Instalação-Proxy7.0-SQLite.bash
```

---

## Funcionalidades Principais

### Shell-Scripts (Monitoramento e Gestão)

| Script | Objetivo | Quando Usar |
|--------|----------|------------|
| `MonitoraProcesso.sh` | Rastreia uso de CPU/memória de processos específicos | Alertas automáticos, dashboards |
| `MonitoraFS.sh` | Monitora crescimento anômalo de filesystem | Prevenção de out-of-disk |
| `RelatorioMaquina.sh` | Snapshot de hardware, SO, configurações | Auditorias, compliance |
| `GerarBackupHome.sh` | Backup incremental com retenção | Disaster recovery |

### Zabbix Scripts

#### Agent Installation (Debian, Red Hat, Ubuntu)

- Baixa versões oficiais do repositório Zabbix
- Configura Server, ServerActive, Hostname automaticamente
- Libera porta 10050 no firewall (UFW/firewalld)
- Habilita e valida o serviço

#### Proxy Installation (Ubuntu 24.04 + SQLite3)

- Deploy completo do Zabbix Proxy 7.0 LTS
- Banco de dados SQLite3 pré-inicializado
- Configuração de firewall, permissões e diretórios
- Systemd service units validadas
- Suporte a Agent2 local para monitoramento do próprio Proxy

---

## Pré-requisitos

### Mínimos

- **OS**: Linux (Debian 11+, Ubuntu 22.04+, RHEL 8+)
- **Bash**: 4.x ou superior
- **Acesso root**: via `sudo` ou conta root
- **Conectividade**: Acesso a `repo.zabbix.com` (para download de pacotes)

### Recomendados

- **VM ou Server dedicado**: Para testes use máquinas isoladas
- **Snapshot/Backup**: Faça snapshot antes de rodar scripts críticos
- **Logs**: Monitore `/var/log/` durante a execução

---

## Como Usar

### Execução Básica

```bash
# 1. Clonar
git clone https://github.com/seu-usuario/Practicing-Scripts.git

# 2. Navegar
cd Practicing-Scripts/Shell-Scripts/

# 3. Tornar executável
chmod +x MonitoraProcesso.sh

# 4. Executar
./MonitoraProcesso.sh [PROCESSO_NOME]
```

### Validação de Sintaxe (antes de rodar)

```bash
bash -n ./seu_script.sh    # Valida sem executar
```

### Execução em Modo Seco

```bash
./script.sh --dry-run      # Mostra o que será feito
```

### Coleta de Logs

```bash
bash -x ./script.sh 2>&1 | tee script_debug.log
```

---

## Boas Práticas de Segurança

| Prática | Ação |
|---------|------|
| **Teste isolado** | Execute em VM / container primeiro |
| **Backup prévio** | Faça snapshot ou copy de arquivos de config |
| **Validação de entrada** | Revise variáveis de ambiente antes de rodar |
| **Logs detalhados** | Capture stderr/stdout para auditoria |
| **Permissões mínimas** | Use `sudo` apenas quando necessário |
| **Idempotência** | Execute 2x para validar |

---

## Casos de Uso

### Caso 1: Deploy de Zabbix Agent em 50 servidores Ubuntu

```bash
# Executar em paralelo via Ansible/parallel
for server in servidor1 servidor2 ... servidor50; do
  ssh "$server" "sudo ./Script\ Instalação\ Agent\ 2\ Zabbix\ 7.0.sh"
done
```

### Caso 2: Monitoramento de aplicação crítica

```bash
# Usar MonitoraProcesso.sh em cron
*/5 * * * * /root/Practicing-Scripts/Shell-Scripts/MonitoraProcesso.sh nginx
```

### Caso 3: Auditoria periódica de máquinas

```bash
# Gerar relatório semanal
0 2 * * 0 /root/Practicing-Scripts/Shell-Scripts/RelatorioMaquina.sh > /var/reports/hw_$(date +%Y%m%d).txt
```

---

## Troubleshooting

### Erro: "Script permission denied"

```bash
chmod +x script.sh
```

### Erro: "Command not found: wget"

```bash
# Ubuntu/Debian
sudo apt-get install wget

# Red Hat
sudo yum install wget
```

### Zabbix Agent não conecta ao Server

```bash
# Validar arquivo de config
sudo cat /etc/zabbix/zabbix_agent2.conf | grep "^Server="

# Testar conexão
nc -zv ZABBIX_SERVER_IP 10051
```

---

## Contribuindo

1. **Fork** o repositório
2. **Crie branch** para sua feature (`git checkout -b feature/nova-automacao`)
3. **Teste extensivamente** em múltiplas distribuições
4. **Documente** flags, pré-requisitos e exemplos
5. **Envie PR** com descrição clara

Guidelines:
- Código limpo e comentado
- Use `shellcheck` para validar Bash
- Scripts idempotentes (seguro rodar múltiplas vezes)
- Tratamento de erro consistente

---

## Documentação Completa

Cada script possui **cabeçalho com instruções**:

```bash
head -20 seu_script.sh
# Mostra: autor, data, descrição, uso, pré-requisitos
```

---

## Licença

[MIT License](LICENSE) — Use livremente em projetos comerciais e educacionais.

---

## Suporte e Contato

- **Issues**: [Abra uma issue](../../issues) para bugs ou sugestões
---

## Status Atual

| Componente | Status | Versão |
|------------|--------|--------|
| Shell-Scripts | Estável | 2026 |
| Zabbix Agent (Debian) | Produção | 6.2.9 / 7.0 |
| Zabbix Agent (Ubuntu) | Produção | 6.0 / 7.0 LTS |
| Zabbix Proxy | Produção | 7.0 LTS + SQLite3 |

---

### Made with attention to detail

_Automação profissional que funciona. Pronta para produção._

