#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

cleanup() {
	for tmp in "${TMP_FILES[@]:-}"; do
		[[ -n "$tmp" && -e "$tmp" ]] && rm -f "$tmp"
	done
}
trap cleanup EXIT

if [[ ! -x ./build.sh ]]; then
	echo "[ERROR] No existe build.sh ejecutable en: $ROOT_DIR" >&2
	exit 1
fi

echo "==> Compilando con build.sh"
./build.sh

if [[ ! -x ./sadScript ]]; then
	echo "[ERROR] No se generó el binario ./sadScript" >&2
	exit 1
fi

declare -A expected_exit=(
	["tests/01_happy.sad"]=0
	["tests/02_typo_keyword_fail.sad"]=1
	["tests/03_missing_semicolon_fail.sad"]=1
	["tests/04_default_switch.sad"]=0
	["tests/05_lexer_fail.sad"]=1
	["tests/06_parser_fail.sad"]=1
)

declare -A expected_message=(
	["tests/01_happy.sad"]="Análisis léxico y sintáctico completado sin errores."
	["tests/02_typo_keyword_fail.sad"]="syntax error, unexpected LLAVE_IZQ, expecting PUNTO_COMA"
	["tests/03_missing_semicolon_fail.sad"]="syntax error, unexpected PRINT, expecting PUNTO_COMA"
	["tests/05_lexer_fail.sad"]="Error léxico en línea 4, columna 3: token no reconocido '~'"
	["tests/06_parser_fail.sad"]="syntax error, unexpected end of file"
)

declare -A expected_stream=(
	["tests/01_happy.sad"]="stdout"
	["tests/02_typo_keyword_fail.sad"]="stderr"
	["tests/03_missing_semicolon_fail.sad"]="stderr"
	["tests/05_lexer_fail.sad"]="stdout"
	["tests/06_parser_fail.sad"]="stderr"
)

shopt -s nullglob
TEST_FILES=(tests/*.sad)
shopt -u nullglob

if [[ "${#TEST_FILES[@]}" -eq 0 ]]; then
	echo "[ERROR] No se encontraron archivos tests/*.sad" >&2
	exit 1
fi

total=0
passed=0
failed=0
TMP_FILES=()

echo
echo "==> Ejecutando tests"
for test_file in "${TEST_FILES[@]}"; do
	total=$((total + 1))

	out_file="$(mktemp)"
	err_file="$(mktemp)"
	TMP_FILES+=("$out_file" "$err_file")

	set +e
	./sadScript "$test_file" >"$out_file" 2>"$err_file"
	actual=$?
	set -e

	if [[ -v expected_exit["$test_file"] ]]; then
		expected="${expected_exit[$test_file]}"
	else
		echo "[ERROR] Falta expectativa para $test_file en expected_exit" >&2
		failed=$((failed + 1))
		continue
	fi

	message_ok=true
	stream="${expected_stream[$test_file]:-stdout}"
	expected_text="${expected_message[$test_file]:-}"

	if [[ "$actual" -ne "$expected" ]]; then
		message_ok=false
		failure_reason="esperado=$expected, real=$actual"
	elif [[ -n "$expected_text" ]]; then
		if [[ "$stream" == "stdout" ]]; then
			if ! grep -Fq "$expected_text" "$out_file"; then
				message_ok=false
				failure_reason="stdout no contiene el mensaje esperado"
			fi
		else
			if ! grep -Fq "$expected_text" "$err_file"; then
				message_ok=false
				failure_reason="stderr no contiene el mensaje esperado"
			fi
		fi
	fi

	if [[ "$message_ok" == true ]]; then
		if [[ "$expected" -eq 0 ]] && [[ -s "$err_file" ]]; then
			message_ok=false
			failure_reason="se esperaba stderr vacío"
		fi
	fi

	if [[ "$message_ok" == true ]]; then
		echo "[PASS] $(basename "$test_file") (exit=$actual)"
		passed=$((passed + 1))
	else
		echo "[FAIL] $(basename "$test_file") ($failure_reason)"
		if [[ -s "$out_file" ]]; then
			sed 's/^/  stdout: /' "$out_file"
		fi
		if [[ -s "$err_file" ]]; then
			sed 's/^/  stderr: /' "$err_file"
		fi
		failed=$((failed + 1))
	fi

done

echo
echo "==> Resumen"
echo "Total:  $total"
echo "OK:     $passed"
echo "Fail:   $failed"

if [[ "$failed" -gt 0 ]]; then
	exit 1
fi
