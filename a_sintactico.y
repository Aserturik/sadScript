%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

extern int yylex(void);
extern FILE *yyin;
extern char *yytext;
extern int numeroLinea;
extern int numeroColumna;
extern bool tieneErrores;

void yyerror(const char* mensaje);
%}

%define parse.error verbose

%union {
    int numero_entero;
    double numero_decimal;
    char caracter;
    char* cadena;
}

/* Delimitadores y separadores */
%token PAREN_IZQ PAREN_DER LLAVE_IZQ LLAVE_DER CORCHETE_IZQ CORCHETE_DER
%token COMA PUNTO_COMA DOS_PUNTOS PUNTO FLECHA FLECHA_DOBLE NUMERAL ARROBA

/* Tipos */
%token ENTERO FLOTANTE BOOLEANO CADENA VECTOR MATRIZ

/* Control de flujo */
%token IF ELSE ELSEIF SWITCH CASE DEFAULT WHILE FOR DO BREAK CONTINUE

/* Funciones y modularidad */
%token FUNCTION RETURN PRINT

/* Excepciones y validación */
%token TRY CATCH THROW ASSERT

/* Literales lógicos */
%token TRUE FALSE NULO

/* Operadores */
%token OP_SUMA OP_RESTA OP_MULT OP_DIV OP_MOD OP_POTENCIA
%token OP_INCREMENTO OP_DECREMENTO
%token OP_SUMA_ASIG OP_RESTA_ASIG OP_MULT_ASIG OP_DIV_ASIG OP_MOD_ASIG
%token OP_Y_LOGICO OP_O_LOGICO OP_NO_LOGICO OP_Y_PALABRA OP_O_PALABRA OP_NO_PALABRA
%token OP_IGUAL OP_DIFERENTE OP_DIFERENTE_ALT OP_MENOR OP_MENOR_IGUAL OP_MAYOR OP_MAYOR_IGUAL
%token OP_ASIGNACION

/* Reducción */
%token OP_SUMA_REDUCCION OP_PROD_REDUCCION OP_MAX_REDUCCION OP_MIN_REDUCCION OP_PROM_REDUCCION

/* Tokens con valor */
%token <numero_entero> LITERAL_ENTERO
%token <numero_decimal> LITERAL_DECIMAL
%token <caracter> LITERAL_CARACTER
%token <cadena> LITERAL_CADENA IDENTIFICADOR

%right OP_ASIGNACION OP_SUMA_ASIG OP_RESTA_ASIG OP_MULT_ASIG OP_DIV_ASIG OP_MOD_ASIG
%left OP_O_LOGICO OP_O_PALABRA
%left OP_Y_LOGICO OP_Y_PALABRA
%left OP_IGUAL OP_DIFERENTE OP_DIFERENTE_ALT
%left OP_MAYOR OP_MENOR OP_MAYOR_IGUAL OP_MENOR_IGUAL
%left OP_SUMA OP_RESTA
%left OP_MULT OP_DIV OP_MOD
%right OP_POTENCIA
%right OP_NO_LOGICO OP_NO_PALABRA
%right MENOS_UNARIO
%nonassoc ELSE

%%

programa
    : lista_sentencias
    ;

lista_sentencias
    : /* vacío */
    | lista_sentencias sentencia
    ;

sentencia
    : declaracion PUNTO_COMA
    | asignacion PUNTO_COMA
    | llamada_o_print PUNTO_COMA
    | RETURN expresion_opt PUNTO_COMA
    | THROW PAREN_IZQ expresion PAREN_DER PUNTO_COMA
    | ASSERT PAREN_IZQ expresion PAREN_DER PUNTO_COMA
    | BREAK PUNTO_COMA
    | CONTINUE PUNTO_COMA
    | bloque
    | condicional
    | bucle
    | sentencia_switch
    | funcion
    | try_catch
    | PUNTO_COMA
    ;

declaracion
    : tipo IDENTIFICADOR inicializacion_opt
    ;

tipo
    : ENTERO
    | FLOTANTE
    | BOOLEANO
    | CADENA
    | VECTOR
    | MATRIZ
    ;

inicializacion_opt
    : /* vacío */
    | OP_ASIGNACION expresion
    ;

asignacion
    : lvalue operador_asignacion expresion
    ;

operador_asignacion
    : OP_ASIGNACION
    | OP_SUMA_ASIG
    | OP_RESTA_ASIG
    | OP_MULT_ASIG
    | OP_DIV_ASIG
    | OP_MOD_ASIG
    ;

lvalue
    : IDENTIFICADOR
    | lvalue CORCHETE_IZQ expresion CORCHETE_DER
    ;

llamada_o_print
    : llamada_funcion
    | PRINT PAREN_IZQ expresion PAREN_DER
    ;

bloque
    : LLAVE_IZQ lista_sentencias LLAVE_DER
    ;

condicional
    : IF PAREN_IZQ expresion PAREN_DER bloque lista_elseif else_opt
    ;

lista_elseif
    : /* vacío */
    | lista_elseif ELSEIF PAREN_IZQ expresion PAREN_DER bloque
    ;

else_opt
    : /* vacío */
    | ELSE bloque
    ;

bucle
    : WHILE PAREN_IZQ expresion PAREN_DER bloque
    | FOR PAREN_IZQ for_init_opt PUNTO_COMA expresion_opt PUNTO_COMA for_update_opt PAREN_DER bloque
    | DO bloque WHILE PAREN_IZQ expresion PAREN_DER PUNTO_COMA
    ;

for_init_opt
    : /* vacío */
    | declaracion
    | asignacion
    | expresion
    ;

for_update_opt
    : /* vacío */
    | asignacion
    | expresion
    ;

sentencia_switch
    : SWITCH PAREN_IZQ expresion PAREN_DER LLAVE_IZQ lista_case default_opt LLAVE_DER
    ;

lista_case
    : /* vacío */
    | lista_case bloque_case
    ;

bloque_case
    : CASE expresion DOS_PUNTOS lista_sentencias_case
    ;

lista_sentencias_case
    : /* vacío */
    | lista_sentencias_case sentencia_case
    ;

sentencia_case
    : declaracion PUNTO_COMA
    | asignacion PUNTO_COMA
    | llamada_o_print PUNTO_COMA
    | RETURN expresion_opt PUNTO_COMA
    | THROW PAREN_IZQ expresion PAREN_DER PUNTO_COMA
    | ASSERT PAREN_IZQ expresion PAREN_DER PUNTO_COMA
    | BREAK PUNTO_COMA
    | CONTINUE PUNTO_COMA
    | bloque
    | condicional
    | bucle
    | try_catch
    | PUNTO_COMA
    ;

default_opt
    : /* vacío */
    | DEFAULT DOS_PUNTOS lista_sentencias_case
    ;

funcion
    : FUNCTION IDENTIFICADOR PAREN_IZQ parametros_opt PAREN_DER DOS_PUNTOS tipo bloque
    | FUNCTION IDENTIFICADOR PAREN_IZQ parametros_opt PAREN_DER bloque
    ;

parametros_opt
    : /* vacío */
    | lista_parametros
    ;

lista_parametros
    : parametro
    | lista_parametros COMA parametro
    ;

parametro
    : tipo IDENTIFICADOR
    | IDENTIFICADOR DOS_PUNTOS tipo
    ;

try_catch
    : TRY bloque CATCH PAREN_IZQ IDENTIFICADOR PAREN_DER bloque
    ;

expresion_opt
    : /* vacío */
    | expresion
    ;

expresion
    : literal
    | lvalue
    | llamada_funcion
    | vector_literal
    | PAREN_IZQ expresion PAREN_DER
    | OP_RESTA expresion %prec MENOS_UNARIO
    | OP_NO_LOGICO expresion
    | OP_NO_PALABRA expresion
    | expresion OP_SUMA expresion
    | expresion OP_RESTA expresion
    | expresion OP_MULT expresion
    | expresion OP_DIV expresion
    | expresion OP_MOD expresion
    | expresion OP_POTENCIA expresion
    | expresion OP_Y_LOGICO expresion
    | expresion OP_O_LOGICO expresion
    | expresion OP_Y_PALABRA expresion
    | expresion OP_O_PALABRA expresion
    | expresion OP_MAYOR expresion
    | expresion OP_MENOR expresion
    | expresion OP_MAYOR_IGUAL expresion
    | expresion OP_MENOR_IGUAL expresion
    | expresion OP_IGUAL expresion
    | expresion OP_DIFERENTE expresion
    | expresion OP_DIFERENTE_ALT expresion
    | OP_SUMA_REDUCCION PAREN_IZQ expresion PAREN_DER
    | OP_PROD_REDUCCION PAREN_IZQ expresion PAREN_DER
    | OP_MAX_REDUCCION PAREN_IZQ expresion PAREN_DER
    | OP_MIN_REDUCCION PAREN_IZQ expresion PAREN_DER
    | OP_PROM_REDUCCION PAREN_IZQ expresion PAREN_DER
    ;

llamada_funcion
    : IDENTIFICADOR PAREN_IZQ argumentos_opt PAREN_DER
    ;

argumentos_opt
    : /* vacío */
    | lista_argumentos
    ;

lista_argumentos
    : argumento
    | lista_argumentos COMA argumento
    ;

argumento
    : expresion
    | IDENTIFICADOR DOS_PUNTOS expresion
    ;

literal
    : LITERAL_ENTERO
    | LITERAL_DECIMAL
    | LITERAL_CARACTER
    | LITERAL_CADENA
    | TRUE
    | FALSE
    | NULO
    ;

vector_literal
    : CORCHETE_IZQ elementos_vector_opt CORCHETE_DER
    ;

elementos_vector_opt
    : /* vacío */
    | lista_expresiones
    ;

lista_expresiones
    : expresion
    | lista_expresiones COMA expresion
    ;

%%

void yyerror(const char* mensaje) {
    fprintf(stderr,
            "Error sintáctico en línea %d, columna %d: %s cerca de '%s'\n",
            numeroLinea,
            numeroColumna,
            mensaje,
            yytext ? yytext : "EOF");
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <archivo.sad>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("No se pudo abrir el archivo");
        return 1;
    }

    int resultado = yyparse();
    fclose(yyin);

    if (tieneErrores || resultado != 0) {
        return 1;
    }

    printf("Análisis léxico y sintáctico completado sin errores.\n");
    return 0;
}
