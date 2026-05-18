# sadScript — Requisitos Léxicos, Sintácticos y Plan de Pruebas

## 1. Objetivo

sadScript debe sentirse triste, cansado y existencial por fuera, pero seguir siendo formalmente compilable por dentro. El lenguaje se diseña para que la capa léxica y sintáctica usen vocabulario emo en primera persona, sin perder expresividad, precedencia ni estructura apta para Flex/Bison.

## 2. Principios de diseño

- Toda palabra reservada debe tener una carga temática clara.
- Los tipos deben ser explícitos, no inferidos.
- Las colecciones deben existir de verdad: vectores y matrices con literal, acceso e inicialización.
- El parser debe aceptar anidación robusta y reportar errores precisos.
- La compatibilidad con un núcleo básico es válida, pero el vocabulario emo manda.

## 3. Capa léxica

### 3.1 Tokens reservados

- `confesar` → salida por consola.
- `vivo` → booleano verdadero.
- `muerto` → booleano falso.
- `si_duele` → if.
- `si_no_duele` → else.
- `si_no_duele_pero` → elseif.
- `segun_mi_animo` → switch.
- `caso` → case.
- `por_defecto_mio` → default.
- `mientras_duela` → while.
- `para_que_duela` → for.
- `aunque_no_quiera` → do.
- `cortarme` → break.
- `seguir_fingiendo` → continue.
- `ritual` → function.
- `regresar_a_llorar` → return.
- `intentar_sentir` → try.
- `romperse` → catch.
- `colapsar` → throw.
- `dolor` → entero.
- `vacio` → flotante.
- `esperanza` → booleano como tipo explícito.
- `recuerdo` → cadena.
- `cicatriz` → vector.
- `trauma` → matriz.

### 3.2 Identificadores y literales

- `IDENT`: `[a-zA-Z_][a-zA-Z0-9_]*`
- `ENTERO`: `[0-9]+`
- `FLOTANTE`: `[0-9]+\.[0-9]+`
- `CADENA`: `"([^"\\]|\\.)*"`
- `BOOLEANO`: `vivo | muerto`
- Comentarios: `//` línea y `/* bloque */`
- Espacios en blanco: ignorados por el lexer.

### 3.3 Mapeo interno

- La capa visible usa palabras emo, pero el parser recibe tokens estándar.
- `confesar` -> `PRINT`
- `dolor` -> `ENTERO`
- `vacio` -> `FLOTANTE`
- `esperanza` -> `BOOLEANO`
- `recuerdo` -> `CADENA`
- `cicatriz` -> `VECTOR`
- `trauma` -> `MATRIZ`
- `si_duele` -> `IF`
- `si_no_duele` -> `ELSE`
- `si_no_duele_pero` -> `ELSEIF`
- `segun_mi_animo` -> `SWITCH`
- `caso` -> `CASE`
- `por_defecto_mio` -> `DEFAULT`
- `mientras_duela` -> `WHILE`
- `para_que_duela` -> `FOR`
- `aunque_no_quiera` -> `DO`
- `cortarme` -> `BREAK`
- `seguir_fingiendo` -> `CONTINUE`
- `ritual` -> `FUNCTION`
- `regresar_a_llorar` -> `RETURN`
- `intentar_sentir` -> `TRY`
- `romperse` -> `CATCH`
- `colapsar` -> `THROW`
- `vivo` -> `TRUE`
- `muerto` -> `FALSE`

### 3.4 Regla de prioridad léxica

- Primero se reconocen palabras reservadas.
- Luego identificadores normales.
- Luego literales y operadores.
- Si una palabra coincide con una reservada, no puede usarse como `IDENT`.

## 4. Capa sintáctica

### 4.1 Declaraciones

- Forma base: `tipo identificador = expresion;`
- Ejemplos canónicos:
  - `dolor edad = 20;`
  - `vacio promedio = 3.14;`
- `esperanza seguir_vivo = muerto;`
  - `recuerdo mensaje = "nadie me entiende";`

### 4.2 Vectores

- Declaración: `cicatriz dolor notas = [1, 2, 3, 4];`
- Acceso: `notas[0]`
- El parser debe validar que el literal de colección sea homogéneo.

### 4.3 Matrices

- Declaración: `trauma vacio depresion = [[1.2, 3.4], [5.6, 7.8]];`
- Acceso: `depresion[0][1]`
- Cada fila debe tener la misma cantidad de columnas.

### 4.4 Expresiones

- Soportar `+`, `-`, `*`, `/`, `%`, paréntesis y precedencia clásica.
- Soportar comparaciones y lógicas: `==`, `!=`, `<`, `<=`, `>`, `>=`, `&&`, `||`, `!`.
- Soportar literales de colección dentro de expresiones.

### 4.5 Control de flujo

- `si_duele (expresion) { ... } si_no_duele { ... }`
- `mientras_duela (expresion) { ... }`
- `para_que_duela (...) { ... }`
- `aunque_no_quiera { ... } mientras_duela (expresion);`
- Bloques obligatorios con `{}`.
- Se permite shadowing dentro de bloques anidados.
- No hay clases.

### 4.6 Funciones

- `ritual nombre(parametros) { ... regresar_a_llorar expresion; }`
- Se aceptan parámetros posicionales y nombrados.
- La firma debe incluir tipo de retorno y tipos de parámetros para soportar sobrecarga.
- La recursividad debe ser válida.

### 4.7 Manejo de errores

- `intentar_sentir { ... } romperse(error) { ... }`
- `colapsar(expresion);`
- `afirmar(expresion);`
- El parser debe diferenciar error sintáctico, error léxico y constructo inválido.

## 5. Gramática mínima esperada

- `programa ::= { declaracion | sentencia }`
- `declaracion ::= tipo IDENT '=' expresion ';'`
- `tipo ::= dolor | vacio | esperanza | recuerdo | cicatriz | trauma`
- `sentencia ::= bloque | if | while | funcion | retorno | llamada | trycatch | assert`
- `bloque ::= '{' { sentencia | declaracion } '}'`
- `if ::= si_duele '(' expresion ')' bloque [ 'si_no_duele' bloque ]`
- `while ::= mientras_duela '(' expresion ')' bloque`
- `funcion ::= ritual IDENT '(' parametros ')' bloque`
- `retorno ::= regresar_a_llorar expresion ';'`

## 6. Resolución de ambigüedad

- Precedencia de operadores para evitar conflictos infijos.
- Factor común en reglas de llamada, indexación y agrupación.
- Separación clara entre declaración y expresión para reducir `shift/reduce`.

## 7. Plan de pruebas

### 7.1 Casos felices

- `T01_declaraciones_basicas`: `int/float/bool/string` con inicialización explícita.
- `T02_vectores`: literal, acceso e inferencia de homogeneidad.
- `T03_matrices`: literal, acceso bidimensional y verificación de filas.
- `T04_control_flujo`: if anidado, while y bloques con shadowing.
- `T05_funciones`: parámetros, retorno, recursión y sobrecarga por firma.
- `T06_excepciones`: try/catch/throw y assert.
- `T07_switch_default`: `segun_mi_animo` con `caso` y `por_defecto_mio`.

### 7.2 Scripts de prueba

- `tests/01_happy.sad`: programa válido con declaraciones, colecciones, `if`, `while` y función.
- `tests/02_lexer_ok.sad`: programa válido de cobertura léxica.
- `tests/03_syntax_ok.sad`: programa válido de cobertura sintáctica.
- `tests/04_default_switch.sad`: `switch` con `caso` y `por_defecto_mio`.
- `tests/05_lexer_fail.sad`: error léxico intencional con carácter inválido.
- `tests/06_parser_fail.sad`: error sintáctico intencional por bloque sin cierre.
- `build.sh`: compila lexer y parser en `sadScript` y deja el binario ejecutable.

### 7.3 Casos negativos

- `T07_lexico_invalido`: caracteres fuera de alfabeto o strings mal cerradas.
- `T08_sintaxis_incompleta`: llaves, paréntesis o punto y coma faltantes.
- `T09_tipo_incompatible`: vector mezclado o matriz jagged.
- `T10_llamada_ambigua`: sobrecarga sin firma resoluble.
- `T11_retorno_invalido`: retorno fuera de función.
- `T12_error_asertivo`: afirmación falsa con línea reportada.

### 7.4 Criterios de aceptación

- El lexer produce tokens reservados correctos y distingue identificadores.
- El parser acepta programas válidos completos sin conflictos abiertos.
- Cada caso negativo debe fallar con mensaje y línea útiles.
- Las estructuras de colección deben ser reales, no meros identificadores decorativos.
- Todo el lenguaje debe expresarse en primera persona y usar `;` como fin de sentencia.

## 8. Resultado esperado

sadScript queda definido como un lenguaje temáticamente triste, pero técnicamente serio: léxico claro, sintaxis formal, colecciones reales, control de flujo estable y una suite de pruebas que cubre tanto el dolor funcional como el dolor de los errores.
