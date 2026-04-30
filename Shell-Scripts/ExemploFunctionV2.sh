
#########################################################################
# Exemplo de Função ler                                                 #
#																		#	
# Nome: ler.sh															#
#																		#
# Autor: Felipe Galeti Gôngora											#
# 																		#
#																		#				 					
#																		#
# Uso: ./ler.sh 											        	#
#																		#	
#########################################################################


#!/bin/bash

ler () {
	read -p "Informe o Nome: " NOME
	read -p "Informe o Sobrenome: " SOBRENOME
	return 10
}

ler
RETURN_CODE=$?
echo
echo $NOME $SOBRENOME
