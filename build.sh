#!/usr/bin/env bash
set -euo pipefail

# Genera el parser y sus tokens compartidos.
bison -d a_sintactico.y
# Genera el lexer a partir de las reglas emo.
flex a_lexico.l
# Compila lexer + parser en el binario sadScript.
cc lex.yy.c a_sintactico.tab.c -o sadScript -lfl -lm
# Deja el binario ejecutable para correr los scripts.
chmod +x sadScript
