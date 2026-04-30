
#########################################################################
# Exemplo de Função                                                     #
#																		#	
# Nome: maiuscula.sh													#
#																		#
# Autor: Felipe Galeti Gôngora											#
# 																		#
#																		#				 					
#																		#
# Uso: ./maiuscula.sh 											     	#
#																		#	
#########################################################################


#!/bin/bash

maiuscula () {
local VAR1=$(echo $1 | tr a-z A-Z)
}

maiuscula script
echo $VAR1
