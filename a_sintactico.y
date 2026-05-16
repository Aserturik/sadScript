%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

/* Variables externas del analizador léxico */
extern char* yytext;
extern int numeroLinea;
extern int numeroColumna;
extern bool tieneErrores;
extern int yylex(void);
extern FILE *yyin;

/* Variables globales para control semántico */
bool hayErroresSintacticos = false;
bool estaEnExcepcion = false;
bool tieneCasoDefecto = false;
int nivelAlcance = 0;
int tipoFuncionActual = -1;
bool tieneRetorno = false;

/* Función para reportar errores sintácticos */
void yyerror(const char* mensaje);

/* Estructura para tabla de símbolos */
typedef struct {
    char *nombre;
    bool esFuncion;
    int tipo;
    int nivelAlcance;
    int numeroParametros;
} Simbolo;

/* Tabla de símbolos global */
Simbolo tablaSimbolos[1000];
int contadorSimbolos = 0;

/* Funciones para manejo de tabla de símbolos */
void agregarSimbolo(char* nombre, int tipo, bool esFuncion, int numParams);
int buscarSimbolo(char* nombre, bool esFuncion);
int buscarSimboloGlobal(char* nombre);
bool existeSimbolo(char* nombre, bool esFuncion);
void eliminarSimbolosDelAlcance();
void iniciarBloque();
void terminarBloque();

/* Funciones para verificación de tipos */
int verificarOperacionNumerica(int tipo1, int tipo2);
int verificarComparacion(int tipo1, int tipo2);
int verificarComparacionValores(int tipo1, int tipo2);
int verificarAsignacion(int tipo1, int tipo2);
int verificarAsignacionSimple(int tipo1, int tipo2);
int verificarAsignacionSuma(int tipo1, int tipo2);
int verificarOperacionLogica(int tipo1, int tipo2);
int verificarIncrementoDecremento(int tipo);

/* Implementación de funciones de tabla de símbolos */
void agregarSimbolo(char* nombre, int tipo, bool esFuncion, int numParams) {
    if (!existeSimbolo(nombre, esFuncion)) {
        if (contadorSimbolos < 1000) {  // Verificar límite
            tablaSimbolos[contadorSimbolos] = (Simbolo) {
                strdup(nombre), esFuncion, tipo, nivelAlcance, numParams
            };
            contadorSimbolos++;
        } else {
            printf("Error: Tabla de símbolos llena\n");
            hayErroresSintacticos = true;
        }
        return;
    }
    printf("Error de definición en línea %d: %s '%s' ya está definido\n", 
           numeroLinea, esFuncion ? "función" : "variable", nombre);
    hayErroresSintacticos = true;
}

int buscarSimbolo(char* nombre, bool esFuncion) {
    int tipoEncontrado = 0;
    int nivelMasAlto = -1;
    
    // Buscar en el alcance actual primero, luego en alcances superiores
    for (int i = 0; i < contadorSimbolos; i++) {
        if (strcmp(nombre, tablaSimbolos[i].nombre) == 0 && 
            tablaSimbolos[i].esFuncion == esFuncion) {
            
            // Si es función, retornar inmediatamente (funciones son globales)
            if (esFuncion) {
                return tablaSimbolos[i].tipo;
            }
            
            // Para variables, buscar la del alcance más alto (más específico)
            if (tablaSimbolos[i].nivelAlcance >= nivelMasAlto) {
                nivelMasAlto = tablaSimbolos[i].nivelAlcance;
                tipoEncontrado = tablaSimbolos[i].tipo;
            }
        }
    }
    
    if (tipoEncontrado != 0) {
        return tipoEncontrado;
    }
    
    printf("Error de acceso en línea %d: %s '%s' no está definido\n", 
           numeroLinea, esFuncion ? "función" : "variable", nombre);
    hayErroresSintacticos = true;
    return 0;
}

int buscarSimboloGlobal(char* nombre) {
    for (int i = 0; i < contadorSimbolos; i++) {
        if (strcmp(nombre, tablaSimbolos[i].nombre) == 0 && 
            tablaSimbolos[i].nivelAlcance == 0 && !tablaSimbolos[i].esFuncion) {
            return tablaSimbolos[i].tipo;
        }
    }
    printf("Error de acceso en línea %d: variable global '%s' no está definida\n", 
           numeroLinea, nombre);
    hayErroresSintacticos = true;
    return 0;
}

bool existeSimbolo(char* nombre, bool esFuncion) {
    for (int i = 0; i < contadorSimbolos; i++) {
        if (strcmp(nombre, tablaSimbolos[i].nombre) == 0 && 
            tablaSimbolos[i].esFuncion == esFuncion) {
            
            // Para funciones, siempre retornar true si existe
            if (esFuncion) {
                return true;
            }
            
            // Para variables, verificar si está en el alcance actual
            if (tablaSimbolos[i].nivelAlcance == nivelAlcance) {
                return true;
            }
        }
    }
    return false;
}

void eliminarSimbolosDelAlcance() {
    int i = 0;
    while (i < contadorSimbolos) {
        if (tablaSimbolos[i].nivelAlcance == nivelAlcance && !tablaSimbolos[i].esFuncion) {
            // Liberar memoria del nombre
            free(tablaSimbolos[i].nombre);
            // Mover todos los elementos siguientes una posición hacia atrás
            for (int j = i; j < contadorSimbolos - 1; j++) {
                tablaSimbolos[j] = tablaSimbolos[j + 1];
            }
            contadorSimbolos--;
            // No incrementar i porque el siguiente elemento se movió a la posición actual
        } else {
            i++;
        }
    }
}

void iniciarBloque() {
    nivelAlcance++;
}

void terminarBloque() {
    eliminarSimbolosDelAlcance();
    nivelAlcance--;
}

/* Implementación de funciones de verificación de tipos */
int verificarOperacionNumerica(int tipo1, int tipo2) {
    if (tipo1 == 0 || tipo2 == 0) return 0;
    if (tipo1 <= 1 || tipo1 >= 4 || tipo2 <= 1 || tipo2 >= 4) {
        printf("Error de tipo incompatible en línea %d: operación inválida, los valores deben ser entero o decimal\n", 
               numeroLinea);
        hayErroresSintacticos = true;
        return 0;
    }
    return tipo1 == 3 || tipo2 == 3 ? 3 : 2; // decimal si alguno es decimal, sino entero
}

int verificarComparacion(int tipo1, int tipo2) {
    if (tipo1 == 0 || tipo2 == 0) return 0;
    if (tipo1 <= 1 || tipo1 >= 4 || tipo2 <= 1 || tipo2 >= 4) {
        printf("Error de tipo incompatible en línea %d: comparación inválida, los valores deben ser entero o decimal\n", 
               numeroLinea);
        hayErroresSintacticos = true;
    }
    return 4; // booleano
}

int verificarComparacionValores(int tipo1, int tipo2) {
    if (tipo1 == 0 || tipo2 == 0) return 0;
    if (tipo1 == tipo2) return 4;
    if (tipo1 == 5 || tipo2 == 5) return 4; // cadena
    if ((tipo1 == 2 && tipo2 == 3) || (tipo1 == 3 && tipo2 == 2)) return 4;
    printf("Error de tipo incompatible en línea %d: comparación inválida, tipos incompatibles\n", 
           numeroLinea);
    hayErroresSintacticos = true;
    return 4;
}

int verificarAsignacion(int tipo1, int tipo2) {
    if (tipo1 == 0 || tipo2 == 0) return 0;
    if (tipo1 != tipo2 && (tipo1 != 3 || tipo2 != 2)) {
        printf("Error de tipo incompatible en línea %d: asignación no soportada, ambos valores deben ser del mismo tipo\n",
               numeroLinea);
        hayErroresSintacticos = true;
        return 0;
    }
    return tipo1;
}

int verificarAsignacionSimple(int tipo1, int tipo2) {
    if (tipo1 == 0 || tipo2 == 0) return 0;
    if (tipo1 == 5 && tipo2 != 5 && tipo2 != 1) {
        printf("Error de tipo incompatible en línea %d: asignación de tipo no soportada\n",
               numeroLinea);
        hayErroresSintacticos = true;
    } else if (tipo1 != tipo2) {
        printf("Error de tipo incompatible en línea %d: asignación de tipo no soportada\n",
               numeroLinea);
        hayErroresSintacticos = true;
        return 0;
    }
    return tipo2;
}

int verificarAsignacionSuma(int tipo1, int tipo2) {
    if (tipo1 == 0 || tipo2 == 0) return 0;
    
    // Permitir suma para cadenas (concatenación)
    if (tipo1 == 5 || tipo2 == 5) {
        if ((tipo1 == 1 || tipo1 == 4 || tipo1 == 5) && 
            (tipo2 == 1 || tipo2 == 4 || tipo2 == 5)) {
            return tipo1;
        }
    }
    
    // Para tipos numéricos
    if ((tipo1 == 2 || tipo1 == 3) && (tipo2 == 2 || tipo2 == 3)) {
        return tipo1;
    }
    
    printf("Error de tipo incompatible en línea %d: asignación con suma no soportada para estos tipos\n",
           numeroLinea);
    hayErroresSintacticos = true;
    return 0;
}

int verificarOperacionLogica(int tipo1, int tipo2) {
    if (tipo1 == 0 || tipo2 == 0) return 0;
    if (tipo1 != 4 || tipo2 != 4) {
        printf("Error de tipo incompatible en línea %d: operación lógica inválida, los valores deben ser booleano\n", 
               numeroLinea);
        hayErroresSintacticos = true;
    }
    return 4;
}

int verificarIncrementoDecremento(int tipo) {
    if (tipo == 0) return 0;
    if (tipo != 2 && tipo != 3) {
        printf("Error de tipo incompatible en línea %d: operación no soportada, el tipo debe ser entero o decimal\n", 
               numeroLinea);
        hayErroresSintacticos = true;
    }
    return tipo;
}

%}

/* Definición de la unión para valores semánticos */
%union {
    int numero_entero;
    double numero_decimal;
    char caracter;
    char *cadena;
    struct {
        int tipo;
        int tieneValor;
        double valor;
    } datos_expresion;
}

/* Definición de precedencia y asociatividad */
%right OP_ASIGNACION OP_SUMA_ASIG OP_RESTA_ASIG OP_MULT_ASIG OP_DIV_ASIG OP_MOD_ASIG
%left OP_Y_LOGICO OP_O_LOGICO OP_Y_PALABRA OP_O_PALABRA
%left OP_IGUAL OP_DIFERENTE OP_DIFERENTE_ALT
%left OP_MAYOR OP_MENOR OP_MAYOR_IGUAL OP_MENOR_IGUAL
%left OP_SUMA OP_RESTA
%left OP_MULT OP_DIV OP_MOD
%right OP_NO_LOGICO OP_NO_PALABRA MENOS_UNARIO
%left OP_POTENCIA
%left OP_INCREMENTO OP_DECREMENTO

/* Tokens básicos */
%token PAREN_IZQ PAREN_DER LLAVE_IZQ LLAVE_DER CORCHETE_IZQ CORCHETE_DER
%token COMA PUNTO_COMA DOS_PUNTOS PUNTO FLECHA FLECHA_DOBLE NUMERAL ARROBA
%token NUEVA_LINEA

/* Palabras reservadas - Tipos */
%token TIPO_ENTERO TIPO_DECIMAL TIPO_BOOLEANO TIPO_CADENA TIPO_CARACTER
%token TIPO_VECTOR TIPO_MATRIZ TIPO_VACIO

/* Palabras reservadas - Control de flujo */
%token SI SINO MIENTRAS PARA HACER REPETIR HASTA SEGUN CASO DEFECTO
%token ROMPER CONTINUAR SALIR

/* Palabras reservadas - Funciones */
%token FUNCION PROCEDIMIENTO RETORNAR DEVOLVER

/* Palabras reservadas - Excepciones */
%token INTENTAR CAPTURAR FINALMENTE LANZAR AFIRMAR

/* Palabras reservadas - Valores */
%token VERDADERO FALSO NULO

/* Operadores */
%token OP_SUMA OP_RESTA OP_MULT OP_DIV OP_MOD OP_POTENCIA
%token OP_INCREMENTO OP_DECREMENTO
%token OP_SUMA_ASIG OP_RESTA_ASIG OP_MULT_ASIG OP_DIV_ASIG OP_MOD_ASIG
%token OP_Y_LOGICO OP_O_LOGICO OP_NO_LOGICO OP_Y_PALABRA OP_O_PALABRA OP_NO_PALABRA
%token OP_IGUAL OP_DIFERENTE OP_DIFERENTE_ALT OP_MENOR OP_MENOR_IGUAL OP_MAYOR OP_MAYOR_IGUAL
%token OP_ASIGNACION

/* Operadores de reducción */
%token OP_SUMA_REDUCCION OP_PROD_REDUCCION OP_MAX_REDUCCION OP_MIN_REDUCCION OP_PROM_REDUCCION

/* Literales y identificadores */
%token <numero_entero> LITERAL_ENTERO
%token <numero_decimal> LITERAL_DECIMAL
%token <caracter> LITERAL_CARACTER
%token <cadena> LITERAL_CADENA IDENTIFICADOR

/* Tipos no terminales */
%type <numero_entero> tipo tipo_funcion llamada_funcion incremento_decremento valor_variable declaracion_instancia
%type <datos_expresion> datos_valor expresion_operacion
%type <numero_entero> retorno bloque_switch linea_switch expresion_bloque
%type <numero_entero> declaracion asignacion bucle condicional excepcion 
%type <numero_entero> declaracion_lanzar declaracion_afirmar
%type <numero_entero> try_catch

%%

/* Regla inicial */
programa:
    /* vacio */ 
    | programa linea
    ;

linea:
    nueva_linea
    | expresion nueva_linea
    | expresion_con_bloque
    | error nueva_linea { 
        printf("Error sintáctico recuperado en línea %d\n", numeroLinea); 
        hayErroresSintacticos = true; 
        yyerrok; 
    }
    ;

nueva_linea:
    NUEVA_LINEA
    ;

expresion:
    declaracion
    | incremento_decremento
    | llamada_funcion
    | asignacion
    ;

expresion_con_bloque:
    bucle
    | condicional
    | excepcion
    | funcion
    ;

/* DECLARACIONES */
declaracion:
    declaracion_instancia { $$ = 0; }
    | declaracion_instancia OP_ASIGNACION expresion_operacion {
        if ($1 == 5 && $3.tipo != 5 && $3.tipo != 1 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: valor de inicialización no compatible con el tipo de dato\n", numeroLinea);
            hayErroresSintacticos = true;
        } else if ($1 != $3.tipo && $1 != 5 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: valor de inicialización no compatible con el tipo de dato\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$ = 0;
    }
    ;

declaracion_instancia:
    tipo IDENTIFICADOR {
        agregarSimbolo($2, $1, false, 0);
        $$ = $1;
    }
    ;

tipo:
    TIPO_CARACTER    { $$ = 1; }
    | TIPO_ENTERO    { $$ = 2; }
    | TIPO_DECIMAL   { $$ = 3; }
    | TIPO_BOOLEANO  { $$ = 4; }
    | TIPO_CADENA    { $$ = 5; }
    | TIPO_VECTOR    { $$ = 6; }
    | TIPO_MATRIZ    { $$ = 7; }
    ;

/* FUNCIONES */
funcion:
    declaracion_funcion bloque_estandar_delimitado {
        if (tipoFuncionActual != -1 && !tieneRetorno) {
            printf("Error de retorno faltante en línea %d: la función no tiene valor de retorno\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        tipoFuncionActual = -1;
        tieneRetorno = false;
    }
    ;

bloque_estandar_delimitado:
    LLAVE_IZQ { iniciarBloque(); } bloque LLAVE_DER { terminarBloque(); }
    ;

declaracion_funcion:
    FUNCION IDENTIFICADOR parametros_funcion tipo_funcion {
        agregarSimbolo($2, $4, true, 0);
    }
    | PROCEDIMIENTO IDENTIFICADOR parametros_funcion {
        agregarSimbolo($2, -1, true, 0);
        tipoFuncionActual = -1;
    }
    ;

bloque:
    /* vacio */
    | bloque linea_bloque
    ;

linea_bloque:
    nueva_linea
    | expresion_bloque nueva_linea
    ;

expresion_bloque:
    declaracion { $$ = 0; }
    | ROMPER { $$ = 0; }
    | CONTINUAR { $$ = 0; }
    | SALIR { $$ = 0; }
    | incremento_decremento { $$ = $1; }
    | llamada_funcion { $$ = $1; }
    | asignacion { $$ = 0; }
    | bucle { $$ = 0; }
    | condicional { $$ = 0; }
    | excepcion { $$ = 0; }
    | retorno {
        if (nivelAlcance == 1) {
            tieneRetorno = true;
        }
        if (tipoFuncionActual != -1 && $1 == -1 && $1 != 0) {
            printf("Error de tipo incompatible en línea %d: la función no tiene valor de retorno\n", numeroLinea);
            hayErroresSintacticos = true;
        } else if (tipoFuncionActual == -1 && $1 != -1) {
            printf("Error de tipo incompatible en línea %d: la función es void y tiene valor de retorno\n", numeroLinea);
            hayErroresSintacticos = true;
        } else if (tipoFuncionActual != -1 && tipoFuncionActual != $1 && $1 != 0) {
            printf("Error de tipo incompatible en línea %d: valor de retorno no compatible con el tipo de retorno de la función\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$ = $1;
    }
    | declaracion_lanzar { $$ = 0; }
    | declaracion_afirmar { $$ = 0; }
    ;

retorno:
    RETORNAR expresion_operacion { $$ = $2.tipo; }
    | RETORNAR { $$ = -1; }
    | DEVOLVER expresion_operacion { $$ = $2.tipo; }
    | DEVOLVER { $$ = -1; }
    ;

declaracion_lanzar:
    LANZAR IDENTIFICADOR PAREN_IZQ LITERAL_CADENA PAREN_DER { $$ = 0; }
    | LANZAR IDENTIFICADOR PAREN_IZQ PAREN_DER { $$ = 0; }
    ;

declaracion_afirmar:
    AFIRMAR PAREN_IZQ expresion_operacion PAREN_DER {
        if ($3.tipo != 4 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: la expresión de afirmación debe ser booleana\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$ = 0;
    }
    ;

tipo_funcion:
    DOS_PUNTOS tipo { 
        tipoFuncionActual = $2; 
        tieneRetorno = false; 
        $$ = $2; 
    }
    | DOS_PUNTOS TIPO_VACIO { 
        tipoFuncionActual = -1; 
        $$ = -1; 
    }
    ;

parametros_funcion:
    PAREN_IZQ seccion_parametros PAREN_DER
    | PAREN_IZQ PAREN_DER
    ;

seccion_parametros:
    parametro
    | parametro COMA seccion_parametros
    | parametro COMA nueva_linea seccion_parametros
    ;

parametro:
    IDENTIFICADOR DOS_PUNTOS tipo {
        // Agregar parámetro al alcance de función
        tablaSimbolos[contadorSimbolos] = (Simbolo) {
            strdup($1), false, $3, nivelAlcance + 1, 0
        };
        contadorSimbolos++;
    }
    | IDENTIFICADOR DOS_PUNTOS tipo OP_ASIGNACION expresion_operacion {
        // Agregar parámetro con valor por defecto
        tablaSimbolos[contadorSimbolos] = (Simbolo) {
            strdup($1), false, $3, nivelAlcance + 1, 0
        };
        contadorSimbolos++;
        if ($5.tipo != $3 && $5.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: valor de parámetro '%s' no compatible con el tipo de dato\n", numeroLinea, $1);
            hayErroresSintacticos = true;
        }
    }
    ;

/* BUCLES */
bucle:
    PARA PAREN_IZQ declaracion_for PAREN_DER bloque_estandar_delimitado { $$ = 0; }
    | expresion_while bloque_estandar_delimitado { $$ = 0; }
    | HACER bloque_estandar_delimitado expresion_while PUNTO_COMA { $$ = 0; }
    | REPETIR bloque_estandar_delimitado HASTA PAREN_IZQ expresion_operacion PAREN_DER PUNTO_COMA {
        if ($5.tipo != 4 && $5.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: la condición debe ser booleana\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$ = 0;
    }
    ;

declaracion_for:
    declaracion_variables_for DOS_PUNTOS condicion_for DOS_PUNTOS seccion_for
    ;

declaracion_variables_for:
    variable_for
    | variable_for COMA declaracion_variables_for
    ;

variable_for:
    IDENTIFICADOR OP_ASIGNACION expresion_operacion {
        if ($3.tipo != 2 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: la variable usada en la iteración for no es un valor entero\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        // Agregar variable de iteración
        tablaSimbolos[contadorSimbolos] = (Simbolo) {
            strdup($1), false, 2, nivelAlcance + 1, 0
        };
        contadorSimbolos++;
    }
    ;

condicion_for:
    expresion_operacion {
        if ($1.tipo != 4 && $1.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: la condición usada en la iteración for no es un valor booleano\n", numeroLinea);
            hayErroresSintacticos = true;
        }
    }
    ;

seccion_for:
    iteracion_for
    | iteracion_for COMA seccion_for
    ;

iteracion_for:
    incremento_decremento
    | asignacion
    ;

expresion_while:
    MIENTRAS PAREN_IZQ expresion_operacion PAREN_DER {
        if ($3.tipo != 4 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: la condición no es un valor booleano\n", numeroLinea);
            hayErroresSintacticos = true;
        }
    }
    ;

/* CONDICIONALES */
condicional:
    declaracion_if_else { $$ = 0; }
    | declaracion_switch { $$ = 0; }
    ;

declaracion_if_else:
    declaracion_if
    | declaracion_if declaracion_else
    | declaracion_if declaracion_else_if
    ;

declaracion_if:
    SI PAREN_IZQ expresion_operacion {
        if ($3.tipo != 4 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: la condición no es un valor booleano\n", numeroLinea);
            hayErroresSintacticos = true;
        }
    } PAREN_DER bloque_estandar_delimitado
    ;

declaracion_else:
    SINO bloque_estandar_delimitado
    ;

declaracion_else_if:
    SINO declaracion_if
    | declaracion_else_if SINO declaracion_if
    | declaracion_else_if declaracion_else
    ;

declaracion_switch:
    SEGUN PAREN_IZQ expresion_operacion PAREN_DER LLAVE_IZQ nueva_linea bloque_switch {
        if ($3.tipo != $7 && $7 != 0 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: los tipos de los casos no son compatibles con el tipo del valor del switch\n", numeroLinea);
            hayErroresSintacticos = true;
        }
    } LLAVE_DER { 
        tieneCasoDefecto = false; 
    }
    | SEGUN PAREN_IZQ expresion_operacion PAREN_DER LLAVE_IZQ nueva_linea LLAVE_DER
    ;

bloque_switch:
    linea_switch { 
        $$ = ($1 == -1) ? 0 : $1; 
    }
    | bloque_switch linea_switch {
        int temp1 = ($1 == -1) ? $2 : $1;
        int temp2 = ($2 == -1) ? $1 : $2;
        if (temp1 != temp2 && temp1 != 0 && temp2 != 0) {
            printf("Error de tipo incompatible en línea %d: los tipos de datos de los casos del switch no son compatibles\n", numeroLinea);
            hayErroresSintacticos = true;
            $$ = 0;
        } else {
            $$ = (temp2 != 0) ? temp2 : temp1;
        }
    }
    ;

linea_switch:
    CASO expresion_operacion DOS_PUNTOS { iniciarBloque(); } bloque { terminarBloque(); $$ = $2.tipo; }
    | DEFECTO DOS_PUNTOS { iniciarBloque(); } bloque {
        terminarBloque();
        if (tieneCasoDefecto) {
            printf("Error de definición en línea %d: el switch tiene más de un caso por defecto\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        tieneCasoDefecto = true;
        $$ = -1;
    }
    ;

/* EXCEPCIONES */
excepcion:
    try_catch { $$ = $1; }
    | try_catch FINALMENTE bloque_estandar_delimitado { $$ = $1; }
    ;

try_catch:
    INTENTAR LLAVE_IZQ { 
        estaEnExcepcion = true; 
        iniciarBloque(); 
    } bloque LLAVE_DER { 
        estaEnExcepcion = false; 
        terminarBloque(); 
    } CAPTURAR PAREN_IZQ IDENTIFICADOR PAREN_DER bloque_estandar_delimitado { $$ = 0; }
    ;

/* EXPRESIONES Y OPERACIONES */
datos_valor:
    LITERAL_CARACTER { 
        $$.tipo = 1; 
        $$.tieneValor = 0; 
    }
    | LITERAL_ENTERO { 
        $$.tipo = 2; 
        $$.tieneValor = 1; 
        $$.valor = $1; 
    }
    | LITERAL_DECIMAL { 
        $$.tipo = 3; 
        $$.tieneValor = 1; 
        $$.valor = $1; 
    }
    | VERDADERO { 
        $$.tipo = 4; 
        $$.tieneValor = 0; 
    }
    | FALSO { 
        $$.tipo = 4; 
        $$.tieneValor = 0; 
    }
    | LITERAL_CADENA { 
        $$.tipo = 5; 
        $$.tieneValor = 0; 
    }
    | NULO {
        $$.tipo = 0;
        $$.tieneValor = 0;
    }
    | valor_variable { 
        $$.tipo = $1; 
        $$.tieneValor = 0; 
    }
    ;

valor_variable:
    IDENTIFICADOR { 
        $$ = buscarSimbolo($1, false); 
    }
    | DOS_PUNTOS DOS_PUNTOS IDENTIFICADOR { 
        $$ = buscarSimboloGlobal($3); 
    }
    ;

expresion_operacion:
    /* Operaciones aritméticas */
    expresion_operacion OP_SUMA expresion_operacion {
        if ($1.tipo == 4 && $3.tipo == 4) {
            printf("Error de tipo incompatible en línea %d: no se pueden sumar valores booleanos\n", numeroLinea);
            hayErroresSintacticos = true;
            $$.tipo = 0;
        } else {
            if ($1.tipo != 0 && $3.tipo != 0) {
                $1.tipo = $1.tipo == 1 || $1.tipo == 4 ? 5 : $1.tipo;
                $3.tipo = $3.tipo == 1 || $3.tipo == 4 ? 5 : $3.tipo;
                $$.tipo = $1.tipo == 5 || $3.tipo == 5 ? 5 : $1.tipo == 3 || $3.tipo == 3 ? 3 : 2;
            } else {
                $$.tipo = 0;
            }
        }
        if ($1.tieneValor && $3.tieneValor) {
            $$.tieneValor = 1;
            $$.valor = $1.valor + $3.valor;
        } else {
            $$.tieneValor = 0;
        }
    }
   | expresion_operacion OP_RESTA expresion_operacion {
        $$.tipo = verificarOperacionNumerica($1.tipo, $3.tipo);
        if ($1.tieneValor && $3.tieneValor) {
            $$.tieneValor = 1;
            $$.valor = $1.valor - $3.valor;
        } else {
            $$.tieneValor = 0;
        }
    }
    | expresion_operacion OP_MULT expresion_operacion {
        $$.tipo = verificarOperacionNumerica($1.tipo, $3.tipo);
        if ($1.tieneValor && $3.tieneValor) {
            $$.tieneValor = 1;
            $$.valor = $1.valor * $3.valor;
        } else {
            $$.tieneValor = 0;
        }
    }
    | expresion_operacion OP_DIV expresion_operacion {
        $$.tipo = verificarOperacionNumerica($1.tipo, $3.tipo);
        if ($1.tieneValor && $3.tieneValor && $3.valor != 0) {
            $$.tieneValor = 1;
            $$.valor = $1.valor / $3.valor;
        } else {
            $$.tieneValor = 0;
        }
    }
    | expresion_operacion OP_MOD expresion_operacion {
        $$.tipo = verificarOperacionNumerica($1.tipo, $3.tipo);
        if ($1.tieneValor && $3.tieneValor && $3.valor != 0) {
            $$.tieneValor = 1;
            $$.valor = fmod($1.valor, $3.valor);
        } else {
            $$.tieneValor = 0;
        }
    }
    | expresion_operacion OP_POTENCIA expresion_operacion {
        $$.tipo = verificarOperacionNumerica($1.tipo, $3.tipo);
        if ($1.tieneValor && $3.tieneValor) {
            $$.tieneValor = 1;
            $$.valor = pow($1.valor, $3.valor);
        } else {
            $$.tieneValor = 0;
        }
    }
    
    /* Operaciones lógicas */
    | expresion_operacion OP_Y_LOGICO expresion_operacion {
        $$.tipo = verificarOperacionLogica($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    | expresion_operacion OP_O_LOGICO expresion_operacion {
        $$.tipo = verificarOperacionLogica($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    | expresion_operacion OP_Y_PALABRA expresion_operacion {
        $$.tipo = verificarOperacionLogica($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    | expresion_operacion OP_O_PALABRA expresion_operacion {
        $$.tipo = verificarOperacionLogica($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    
    /* Operaciones de comparación */
    | expresion_operacion OP_MAYOR expresion_operacion {
        $$.tipo = verificarComparacion($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    | expresion_operacion OP_MENOR expresion_operacion {
        $$.tipo = verificarComparacion($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    | expresion_operacion OP_MAYOR_IGUAL expresion_operacion {
        $$.tipo = verificarComparacion($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    | expresion_operacion OP_MENOR_IGUAL expresion_operacion {
        $$.tipo = verificarComparacion($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    | expresion_operacion OP_IGUAL expresion_operacion {
        $$.tipo = verificarComparacionValores($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    | expresion_operacion OP_DIFERENTE expresion_operacion {
        $$.tipo = verificarComparacionValores($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    | expresion_operacion OP_DIFERENTE_ALT expresion_operacion {
        $$.tipo = verificarComparacionValores($1.tipo, $3.tipo);
        $$.tieneValor = 0;
    }
    
    /* Operadores unarios */
    | OP_RESTA expresion_operacion %prec MENOS_UNARIO {
        if ($2.tipo != 2 && $2.tipo != 3 && $2.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: operador negativo solo aplicable a números\n", numeroLinea);
            hayErroresSintacticos = true;
            $$.tipo = 0;
        } else {
            $$.tipo = $2.tipo;
        }
        if ($2.tieneValor) {
            $$.tieneValor = 1;
            $$.valor = -$2.valor;
        } else {
            $$.tieneValor = 0;
        }
    }
    | OP_NO_LOGICO expresion_operacion {
        if ($2.tipo != 4 && $2.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: operador NOT solo aplicable a valores booleanos\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$.tipo = 4;
        $$.tieneValor = 0;
    }
    | OP_NO_PALABRA expresion_operacion {
        if ($2.tipo != 4 && $2.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: operador NO solo aplicable a valores booleanos\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$.tipo = 4;
        $$.tieneValor = 0;
    }
    
    /* Operadores de reducción */
    | OP_SUMA_REDUCCION PAREN_IZQ expresion_operacion PAREN_DER {
        if ($3.tipo != 6 && $3.tipo != 7 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: operador suma de reducción solo aplicable a vectores/matrices\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$.tipo = 2; // Resultado es entero
        $$.tieneValor = 0;
    }
    | OP_PROD_REDUCCION PAREN_IZQ expresion_operacion PAREN_DER {
        if ($3.tipo != 6 && $3.tipo != 7 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: operador producto de reducción solo aplicable a vectores/matrices\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$.tipo = 2;
        $$.tieneValor = 0;
    }
    | OP_MAX_REDUCCION PAREN_IZQ expresion_operacion PAREN_DER {
        if ($3.tipo != 6 && $3.tipo != 7 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: operador máximo de reducción solo aplicable a vectores/matrices\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$.tipo = 2;
        $$.tieneValor = 0;
    }
    | OP_MIN_REDUCCION PAREN_IZQ expresion_operacion PAREN_DER {
        if ($3.tipo != 6 && $3.tipo != 7 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: operador mínimo de reducción solo aplicable a vectores/matrices\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$.tipo = 2;
        $$.tieneValor = 0;
    }
    | OP_PROM_REDUCCION PAREN_IZQ expresion_operacion PAREN_DER {
        if ($3.tipo != 6 && $3.tipo != 7 && $3.tipo != 0) {
            printf("Error de tipo incompatible en línea %d: operador promedio de reducción solo aplicable a vectores/matrices\n", numeroLinea);
            hayErroresSintacticos = true;
        }
        $$.tipo = 3; // Resultado es decimal
        $$.tieneValor = 0;
    }
    
    /* Llamadas a función y expresiones con paréntesis */
    | llamada_funcion {
        $$.tipo = $1;
        $$.tieneValor = 0;
    }
    | PAREN_IZQ expresion_operacion PAREN_DER {
        $$ = $2;
    }
    | datos_valor {
        $$ = $1;
    }
    ;

/* ASIGNACIONES */
asignacion:
    valor_variable OP_ASIGNACION expresion_operacion {
        verificarAsignacionSimple($1, $3.tipo);
        $$ = 0;
    }
    | valor_variable OP_SUMA_ASIG expresion_operacion {
        verificarAsignacionSuma($1, $3.tipo);
        $$ = 0;
    }
    | valor_variable OP_RESTA_ASIG expresion_operacion {
        verificarAsignacion($1, $3.tipo);
        $$ = 0;
    }
    | valor_variable OP_MULT_ASIG expresion_operacion {
        verificarAsignacion($1, $3.tipo);
        $$ = 0;
    }
    | valor_variable OP_DIV_ASIG expresion_operacion {
        verificarAsignacion($1, $3.tipo);
        $$ = 0;
    }
    | valor_variable OP_MOD_ASIG expresion_operacion {
        verificarAsignacion($1, $3.tipo);
        $$ = 0;
    }
    ;

/* INCREMENTO Y DECREMENTO */
incremento_decremento:
    OP_INCREMENTO valor_variable {
        $$ = verificarIncrementoDecremento($2);
    }
    | valor_variable OP_INCREMENTO {
        $$ = verificarIncrementoDecremento($1);
    }
    | OP_DECREMENTO valor_variable {
        $$ = verificarIncrementoDecremento($2);
    }
    | valor_variable OP_DECREMENTO {
        $$ = verificarIncrementoDecremento($1);
    }
    ;

/* LLAMADAS A FUNCIÓN */
llamada_funcion:
    IDENTIFICADOR PAREN_IZQ PAREN_DER {
        $$ = buscarSimbolo($1, true);
    }
    | IDENTIFICADOR PAREN_IZQ argumentos_funcion PAREN_DER {
        $$ = buscarSimbolo($1, true);
    }
    ;

argumentos_funcion:
    argumento
    | argumento COMA argumentos_funcion
    ;

argumento:
    expresion_operacion
    | IDENTIFICADOR DOS_PUNTOS expresion_operacion  /* Argumento nombrado */
    ;

%%

/* Función de manejo de errores sintácticos */
void yyerror(const char* mensaje) {
    printf("Error sintáctico en línea %d: %s cerca de '%s'\n", 
           numeroLinea, mensaje, yytext);
    hayErroresSintacticos = true;
}

/* Función principal para probar el analizador */
int main(int argc, char* argv[]) {
    FILE* archivo = NULL;
    
    printf("=== Analizador Léxico y Sintáctico ===\n");
    
    if (argc > 1) {
        archivo = fopen(argv[1], "r");
        if (!archivo) {
            printf("Error: No se puede abrir el archivo '%s'\n", argv[1]);
            return 1;
        }
        yyin = archivo;
        printf("Analizando archivo: %s\n", argv[1]);
    } else {
        printf("Leyendo desde entrada estándar...\n");
        yyin = stdin;
    }
    
    printf("Iniciando análisis...\n\n");
    
    // Ejecutar el analizador sintáctico
    int resultado = yyparse();
    
    // Mostrar resultados
    printf("\n=== Resultados del Análisis ===\n");
    
    if (tieneErrores) {
        printf("❌ Se encontraron errores léxicos\n");
    } else {
        printf("✅ Análisis léxico completado sin errores\n");
    }
    
    if (hayErroresSintacticos || resultado != 0) {
        printf("❌ Se encontraron errores sintácticos\n");
    } else {
        printf("✅ Análisis sintáctico completado sin errores\n");
    }
    
    printf("Total de símbolos en tabla: %d\n", contadorSimbolos);
    
    // Limpiar memoria antes de salir
    limpiarTablaSimbolos();
    
    // Cerrar archivo si fue abierto
    if (archivo) {
        fclose(archivo);
    }
    
    return (tieneErrores || hayErroresSintacticos) ? 1 : 0;
}

void limpiarTablaSimbolos() {
    for (int i = 0; i < contadorSimbolos; i++) {
        if (tablaSimbolos[i].nombre) {
            free(tablaSimbolos[i].nombre);
            tablaSimbolos[i].nombre = NULL;
        }
    }
    contadorSimbolos = 0;
}

