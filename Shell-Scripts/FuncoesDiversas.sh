#!/bin/bash

#########################################################################
# Exercício 1 - Funções 												#
#																		#	
# Nome: FuncoesDiversas.sh												#	
#																		#
# Autor: Felipe Galeti Gôngora											#
# 																		#
#																		#	
# Descrição: Script com diversas funções que fazem						#
# tratamentos com datas						 							#	
#																		#
# Uso: ./FuncoesDiversas.sh --help										#
#      ./FuncoesDiversas.sh OPÇÃO DATA									#
#																		#
# Opções:																#
# -f = Retorna 0 para BR, 1 para US, 2 quando impossível determinar		#
#      e 3 para formato de data inválido								#
# -i = Inverte formato BR para US e US para BR. Inclui as Barras		#
# -b = Inclui Barras de Data. Exemplo: de 13081981 para 13/08/1981		#
# -e = Exibe a data em formato extenso. Exemplo de 13081981 			#
#      para 13 de Agosto de 1981 										#
#																		#	
#########################################################################


# --- Utilitários ---

limpa_data() {
  # Remove barras e espaços
  echo "$1" | tr -d "/[:space:]"
}

so_digitos_8() {
  # Retorna 0 se tem exatamente 8 dígitos; caso contrário, 1
  local d="$1"
  [[ "$d" =~ ^[0-9]{8}$ ]] && return 0 || return 1
}

parse_ddmmyyyy() {
  # Extrai dia, mês, ano de uma string DDMMYYYY (sem barras), em variáveis globais DIA MES ANO
  local d="$1"
  DIA="${d:0:2}"
  MES="${d:2:2}"
  ANO="${d:4:4}"
}

valida_data_real() {
  # Valida se DIA/MES/ANO formam uma data real (considera bissexto)
  local dd="$((10#$DIA))"
  local mm="$((10#$MES))"
  local yyyy="$((10#$ANO))"

  # Mês entre 1 e 12
  if (( mm < 1 || mm > 12 )); then return 1; fi
  # Dia mínimo 1
  if (( dd < 1 )); then return 1; fi

  # Dias por mês
  local maxdia=31
  case "$mm" in
    4|6|9|11) maxdia=30 ;;
    2)
      # Bissexto: ano % 400 == 0 ou (ano % 4 == 0 e ano % 100 != 0)
      if (( (yyyy % 400 == 0) || (yyyy % 4 == 0 && yyyy % 100 != 0) )); then
        maxdia=29
      else
        maxdia=28
      fi
      ;;
  esac

  (( dd <= maxdia )) && return 0 || return 1
}

mes_extenso_pt() {
  case "$MES" in
    01) echo "Janeiro" ;;
    02) echo "Fevereiro" ;;
    03) echo "Março" ;;
    04) echo "Abril" ;;
    05) echo "Maio" ;;
    06) echo "Junho" ;;
    07) echo "Julho" ;;
    08) echo "Agosto" ;;
    09) echo "Setembro" ;;
    10) echo "Outubro" ;;
    11) echo "Novembro" ;;
    12) echo "Dezembro" ;;
    *)  echo "" ;;
  esac
}

# --- Funções principais ---

RetornaFormato() {
  # Determina se a string está em BR (DDMMYYYY) ou US (MMDDYYYY)
  # Retorna:
  # 0 -> BR
  # 1 -> US
  # 2 -> Indefinido (mas potencialmente válido)
  # 3 -> Inválido
  local in="$1"
  local data="$(limpa_data "$in")"

  # Validação inicial
  so_digitos_8 "$data" || return 3

  local VAL1="${data:0:2}"
  local VAL2="${data:2:2}"
  local ANO="${data:4:4}"

  # Convertendo para base 10 para evitar octal
  local v1="$((10#$VAL1))"
  local v2="$((10#$VAL2))"

  # Heurística original do script
  if (( v1 <= 12 && v1 == v2 )); then
    # Dia = Mês => considerar BR
    parse_ddmmyyyy "$data"
    valida_data_real && return 0 || return 3
  elif (( v1 > 12 && v2 <= 12 )); then
    # BR
    parse_ddmmyyyy "$data"
    valida_data_real && return 0 || return 3
  elif (( v1 <= 12 && v2 > 12 )); then
    # US
    # Interpretar como MMDDYYYY para validar corretamente
    local DIA="$VAL2"; local MES="$VAL1"; local ANO="$ANO"
    # Ajusta variáveis globais para validar:
    DIA="$VAL2"; MES="$VAL1"; ANO="$ANO"
    valida_data_real && return 1 || return 3
  elif (( v1 <= 12 && v2 <= 12 )); then
    # Indefinido, mas válido (pode ser BR ou US). Vamos aceitar como 2
    # Ainda assim, validar ambas interpretações:
    # BR:
    parse_ddmmyyyy "$data"
    if ! valida_data_real; then
      # US:
      DIA="${data:2:2}"; MES="${data:0:2}"; ANO="${data:4:4}"
      if ! valida_data_real; then
        return 3
      fi
    fi
    return 2
  else
    return 3
  fi
}

InverteDiaMes() {
  local in="$1"
  local data="$(limpa_data "$in")"
  so_digitos_8 "$data" || { echo "Formato de Data Invalido"; return 3; }

  # Tentar determinar formato
  RetornaFormato "$data"
  local FORMATO=$?

  if [ "$FORMATO" -eq 3 ]; then
    echo "Formato de Data Invalido"; return 3
  fi

  # Quando BR (0): DD/MM/YYYY -> vira MM/DD/YYYY
  # Quando US (1): MM/DD/YYYY -> vira DD/MM/YYYY
  # Quando 2: por padrão vamos inverter assumindo BR->US (ou seja, trocar VAL1 e VAL2)
  local VAL1="${data:0:2}"
  local VAL2="${data:2:2}"
  local ANO="${data:4:4}"

  echo "${VAL2}/${VAL1}/${ANO}"
}

IncluiBarra() {
  local in="$1"
  local data="$(limpa_data "$in")"
  so_digitos_8 "$data" || { echo "Formato de Data Invalido"; return 3; }

  local VAL1="${data:0:2}"
  local VAL2="${data:2:2}"
  local ANO="${data:4:4}"
  echo "${VAL1}/${VAL2}/${ANO}"
}

DataExtenso() {
  local in="$1"
  local data="$(limpa_data "$in")"
  so_digitos_8 "$data" || { echo "Formato de Data Invalido"; return 3; }

  RetornaFormato "$data"
  local RETURN_FORM=$?

  local DIA MES ANO
  case "$RETURN_FORM" in
    0) # BR
      DIA="${data:0:2}"; MES="${data:2:2}"; ANO="${data:4:4}"
      ;;
    1) # US
      DIA="${data:2:2}"; MES="${data:0:2}"; ANO="${data:4:4}"
      ;;
    2) # Indefinido: perguntar
      local FORMATO=0
      until [ "$FORMATO" = 1 -o "$FORMATO" = 2 ]; do
        echo
        echo "Impossível determinar o padrão de data."
        echo "1 - BR (DD/MM/YYYY)"
        echo "2 - US (MM/DD/YYYY)"
        read -p "Informe o formato (1 ou 2): " FORMATO
        case "$FORMATO" in
          1) DIA="${data:0:2}"; MES="${data:2:2}"; ANO="${data:4:4}" ;;
          2) DIA="${data:2:2}"; MES="${data:0:2}"; ANO="${data:4:4}" ;;
          *) echo "Opção Inválida" ;;
        esac
      done
      ;;
    3)
      echo "Formato de Data Invalido"
      return 3
      ;;
  esac

  # Validar data real antes de imprimir
  valida_data_real || { echo "Formato de Data Invalido"; return 3; }

  local MESEXT
  MES="$MES" # garantir variável pronta
  MESEXT="$(mes_extenso_pt)"
  if [ -z "$MESEXT" ]; then
    echo "Formato de Data Invalido"; return 3
  fi

  echo "$DIA de $MESEXT de $ANO"
  return 0
}

############################
# Inicio do Fluxo do Script
############################

case "$1" in
  "-f")
    RetornaFormato "$2"
    echo "$?"
    ;;
  "-i")
    InverteDiaMes "$2"
    ;;
  "-b")
    IncluiBarra "$2"
    ;;
  "-e")
    DataExtenso "$2"
    ;;
  "--help")
    echo "Uso $0 OPÇÃO DATA"
    echo
    echo "DATA nos formatos DDMMYYYY ou MMDDYYYY, com ou sem /"
    echo
    echo "Opções:"
    echo "-f = Retorna 0 para BR, 1 para US e 2 quando impossível determinar, 3 Inválido"
    echo "-i = Inverte formato BR para US e US para BR. Inclui as Barras"
    echo "-b = Inclui Barras de Data. Exemplo: de 13081981 para 13/08/1981"
    echo "-e = Exibe a data em formato extenso. Exemplo: de 13081981 para 13 de Agosto de 1981 "
    ;;
  *)
    echo "Uso indevido. Utilize $0 --help"
    ;;
esac

