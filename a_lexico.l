%{
#include "a_sintactico.tab.h"
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>

/* Variables globales para control de errores y estado */
bool tieneErrores = false;
bool estaEnComentario = false;
int numeroLinea = 1;
int numeroColumna = 1;

/* Función para actualizar posición en el código fuente */
void actualizarPosicion() {
    int i;
    for (i = 0; yytext[i] != '\0'; i++) {
        if (yytext[i] == '\n') {
            numeroLinea++;
            numeroColumna = 1;
        } else {
            numeroColumna++;
        }
    }
}

/* Función para reportar errores léxicos */
void reportarErrorLexico(const char* token) {
    printf("Error léxico en línea %d, columna %d: token no reconocido '%s'\n", 
           numeroLinea, numeroColumna, token);
    tieneErrores = true;
}
%}

/* Definiciones de expresiones regulares básicas */
letra               [a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]
digito              [0-9]
alfanumerico        {letra}|{digito}|\_
caracter_texto      [ -~áéíóúüñÁÉÍÓÚÜÑ¿¡]
espacio_blanco      [ \t\r\f]

/* Patrones para identificadores y literales */
IDENTIFICADOR       {letra}+{alfanumerico}*
CARACTER_LITERAL    \'{caracter_texto}\'
CADENA_LITERAL      \"{caracter_texto}*\"
NUMERO_ENTERO       {digito}+
NUMERO_DECIMAL      {digito}+\.{digito}+
NUMERO_CIENTIFICO   ({digito}+\.{digito}+|{digito}+)[eE][+-]?{digito}+

/* Patrones para comentarios */
COMENTARIO_LINEA    \/\/.*
COMENTARIO_INICIO   \/\*
COMENTARIO_FIN      \*\/

/* Estados para manejo de comentarios multilínea */
%x COMENTARIO_MULTI

%%

{COMENTARIO_LINEA}                      { /* Ignorar comentarios de línea */ }
{COMENTARIO_INICIO}                     { BEGIN(COMENTARIO_MULTI); }
<COMENTARIO_MULTI>{COMENTARIO_FIN}      { BEGIN(INITIAL); }
<COMENTARIO_MULTI>\n                    { numeroLinea++; numeroColumna = 1; }
<COMENTARIO_MULTI>.                     { /* Ignorar contenido del comentario */ }

                        /* PALABRAS RESERVADAS - TIPOS DE DATOS */
 confesar                               { return PRINT; }
 dolor                                   { return ENTERO; }
 vacio                                  { return FLOTANTE; }
 esperanza                              { return BOOLEANO; }
 recuerdo                               { return CADENA; }
 cicatriz                               { return VECTOR; }
 trauma                                 { return MATRIZ; }

                        /* PALABRAS RESERVADAS - CONTROL DE FLUJO */
 si_duele                                { return IF; }
 si_no_duele                             { return ELSE; }
 si_no_duele_pero                        { return ELSEIF; }
 segun_mi_animo                          { return SWITCH; }
 caso                                    { return CASE; }
 por_defecto_mio                         { return DEFAULT; }
 mientras_duela                          { return WHILE; }
 para_que_duela                           { return FOR; }
 aunque_no_quiera                        { return DO; }
 cortarme                                { return BREAK; }
 seguir_fingiendo                        { return CONTINUE; }

                        /* PALABRAS RESERVADAS - FUNCIONES Y MODULARIDAD */
 ritual                                  { return FUNCTION; }
 regresar_a_llorar                       { return RETURN; }

                        /* PALABRAS RESERVADAS - MANEJO DE EXCEPCIONES */
 intentar_sentir                         { return TRY; }
 romperse                                { return CATCH; }
 colapsar                                { return THROW; }
 afirmar                                 { return ASSERT; }

                        /* PALABRAS RESERVADAS - VALORES LÓGICOS */
 vivo                                   { return TRUE; }
 muerto                                 { return FALSE; }
 nulo                                   { return NULO; }

                        /* OPERADORES DE REDUCCIÓN */
 sum                                    { return OP_SUMA_REDUCCION; }
 prod                                   { return OP_PROD_REDUCCION; }
 max                                    { return OP_MAX_REDUCCION; }
 min                                    { return OP_MIN_REDUCCION; }
 prom                                   { return OP_PROM_REDUCCION; }

                        /* OPERADORES ARITMÉTICOS */
\+\+                                   { return OP_INCREMENTO; }
\+\=                                   { return OP_SUMA_ASIG; }
\+                                     { return OP_SUMA; }
\-\-                                   { return OP_DECREMENTO; }
\-\=                                   { return OP_RESTA_ASIG; }
\-                                     { return OP_RESTA; }
\*\=                                   { return OP_MULT_ASIG; }
\*                                     { return OP_MULT; }
\/\=                                   { return OP_DIV_ASIG; }
\/                                     { return OP_DIV; }
\%\=                                   { return OP_MOD_ASIG; }
\%                                     { return OP_MOD; }
\*\*                                   { return OP_POTENCIA; }

                        /* OPERADORES LÓGICOS */
\&\&                                   { return OP_Y_LOGICO; }
\|\|                                   { return OP_O_LOGICO; }
\!                                     { return OP_NO_LOGICO; }
y                                      { return OP_Y_PALABRA; }
o                                      { return OP_O_PALABRA; }
no                                     { return OP_NO_PALABRA; }

                        /* OPERADORES RELACIONALES */
\=\=                                   { return OP_IGUAL; }
\!\=                                   { return OP_DIFERENTE; }
\<\>                                   { return OP_DIFERENTE_ALT; }
\<                                     { return OP_MENOR; }
\<\=                                   { return OP_MENOR_IGUAL; }
\>                                     { return OP_MAYOR; }
\>\=                                   { return OP_MAYOR_IGUAL; }

                        /* OPERADOR DE ASIGNACIÓN */
\=                                     { return OP_ASIGNACION; }

                        /* DELIMITADORES */
\(                                     { return PAREN_IZQ; }
\)                                     { return PAREN_DER; }
\{                                     { return LLAVE_IZQ; }
\}                                     { return LLAVE_DER; }
\[                                     { return CORCHETE_IZQ; }
\]                                     { return CORCHETE_DER; }

                        /* SEPARADORES */
\,                                     { return COMA; }
\;                                     { return PUNTO_COMA; }
\:                                     { return DOS_PUNTOS; }
\.                                     { return PUNTO; }

                        /* OPERADORES ESPECIALES */
\-\>                                   { return FLECHA; }
\=\>                                   { return FLECHA_DOBLE; }
\#                                     { return NUMERAL; }
\@                                     { return ARROBA; }

                        /* IDENTIFICADORES Y LITERALES */
{IDENTIFICADOR}                        { 
                                         yylval.cadena = strdup(yytext); 
                                         return IDENTIFICADOR; 
                                       }

{NUMERO_CIENTIFICO}                    { 
                                         yylval.numero_decimal = atof(yytext); 
                                         return LITERAL_DECIMAL; 
                                       }

{NUMERO_DECIMAL}                       { 
                                         yylval.numero_decimal = atof(yytext); 
                                         return LITERAL_DECIMAL; 
                                       }

{NUMERO_ENTERO}                        { 
                                         yylval.numero_entero = atoi(yytext); 
                                         return LITERAL_ENTERO; 
                                       }

{CADENA_LITERAL}                       { 
                                         /* Remover comillas y guardar contenido */
                                         yylval.cadena = strndup(yytext + 1, strlen(yytext) - 2); 
                                         return LITERAL_CADENA; 
                                       }

{CARACTER_LITERAL}                     { 
                                         /* Guardar el carácter sin comillas */
                                         yylval.caracter = yytext[1]; 
                                         return LITERAL_CARACTER; 
                                       }

                        /* MANEJO DE SALTOS DE LÍNEA Y ESPACIOS */
 \n                                     { 
                                          numeroLinea++; 
                                          numeroColumna = 1; 
                                        }

{espacio_blanco}+                      { 
                                         /* Actualizar columna y ignorar espacios */ 
                                         numeroColumna += yyleng;
                                       }

                        /* MANEJO DE ERRORES LÉXICOS */
.                                      { 
                                         reportarErrorLexico(yytext);
                                         numeroColumna++;
                                       }

%%

/* Función requerida por Flex para indicar fin de archivo */
int yywrap() { 
    return 1; 
}

/* Función para obtener el número de línea actual */
int obtenerNumeroLinea() {
    return numeroLinea;
}

/* Función para obtener el número de columna actual */
int obtenerNumeroColumna() {
    return numeroColumna;
}

/* Función para verificar si hay errores léxicos */
bool hayErroresLexicos() {
    return tieneErrores;
}

/* Función para reiniciar el analizador léxico */
void reiniciarAnalizadorLexico() {
    tieneErrores = false;
    estaEnComentario = false;
    numeroLinea = 1;
    numeroColumna = 1;
}
