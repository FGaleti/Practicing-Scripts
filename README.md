
# Practicing-Scripts — Laboratório Pessoal de Scripts e Automação

Uma coleção organizada de scripts, utilitários e exemplos focados em automação, monitoramento e práticas de linha de comando. Este repositório é um histórico didático das abordagens, iterações e soluções construídas durante estudos e experimentos práticos.

Badges: Status: Learning | Shell: ✓ | Zabbix: ✓

---

## Índice

- [Visão Geral](#visão-geral)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Como Usar](#como-usar)
- [Boas Práticas ao Testar Scripts](#boas-práticas-ao-testar-scripts)
- [Contribuição](#contribuição)
- [Licença](#licença)
- [Contato](#contato)

---

## Visão Geral

Este repositório centraliza pequenos projetos e scripts voltados a:

- Automação de tarefas no shell (Bash)
- Scripts de instalação e configuração para Zabbix (diversas distribuições)
- Ferramentas de monitoramento e relatórios simples

O objetivo é ser didático e reutilizável: cada script costuma conter comentários explicativos e instruções mínimas de uso.

---

## Estrutura do Repositório

Organização atual (principais diretórios e finalidade):

- `Shell-Scripts/` — Coleção de utilitários e exercícios em Bash para tarefas como criação de arquivos, backups, monitoramento de processos e geração de relatórios.
	- Exemplos: `CriaArquivo.sh`, `GerarBackupHome.sh`, `MonitoraProcesso.sh`
- `ZabbixScript/` — Scripts relacionados à instalação e configuração do agente Zabbix em diferentes distribuições.
	- `Scripts Debian/` — Instaladores e helpers voltados para Debian/Ubuntu (ex.: instalações para Zabbix 6.2.9 e 7.0).
	- `Scripts Red Hat/` — Versões para RHEL/CentOS/AlmaLinux.
	- `Scripts Ubuntu/` — Scripts específicos e variações para Ubuntu.
	- `Script Instalação de Proxy/` — Automação para instalação de Proxy Zabbix (ex.: SQLite-based proxy).

Cada pasta contém scripts com nomes descritivos; abra o arquivo desejado para ver parâmetros e instruções específicas.

---

## Como Usar

Recomendações gerais para executar os scripts localmente:

1. Abra um terminal em uma máquina compatível (Linux / WSL).
2. Navegue até o diretório que contém o script.
3. Garanta permissões de execução e execute:

```bash
chmod +x ./nome_do_script.sh
sudo ./nome_do_script.sh
```

Observações por tipo de script:

- Scripts de instalação do Zabbix: execute como `root` ou via `sudo`. Verifique a compatibilidade da versão do agente com sua distribuição antes de rodar.
- Scripts de monitoramento: podem ser testados em modo `--dry-run` quando implementado; leia os comentários no topo do arquivo para flags disponíveis.

Pré-requisitos comuns:

- `bash` (>= 4.x recomendado)
- `curl` ou `wget` (para downloads automatizados)
- `sudo` (para operações que alteram o sistema)

---

## Boas Práticas ao Testar Scripts

- Leia os comentários no início do script — eles descrevem parâmetros e efeitos colaterais.
- Teste em um ambiente controlado (máquina virtual, container ou snapshot).
- Faça backup de arquivos de configuração antes de sobrescrevê-los.
- Utilize `set -euo pipefail` (quando aplicável) para detectar erros precocemente.

Exemplo rápido para teste seguro:

```bash
bash -n ./script.sh        # verifica sintaxe
./script.sh --help         # checar flags (se implementado)
./script.sh --dry-run      # execução sem efeitos (se implementado)
```

---

## Contribuição

Contribuições são bem-vindas — abra uma issue ou um pull request com:

- Descrição do objetivo da mudança
- Testes e passos para reproduzir
- Arquivos modificados e rationale

Guidelines rápidas:

- Prefira clareza e comentários didáticos.
- Scripts devem ser idempotentes quando possível.
- Documente flags e pré-requisitos no cabeçalho do arquivo.

---

## Licença

Este repositório é destinado a fins educacionais; utilize conforme necessidade. Se quiser aplicar uma licença permissiva, recomendo MIT.

---

## Contato

Se quiser discutir melhorias, correções ou usar algo como base para um projeto, entre em contato.

---

