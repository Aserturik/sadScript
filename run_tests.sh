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
	["tests/02_lexer_error.sad"]=0
	["tests/03_syntax_error.sad"]=0
	["tests/04_default_switch.sad"]=0
	["tests/05_lexer_fail.sad"]=1
	["tests/06_parser_fail.sad"]=1
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

	if [[ "$actual" -eq "$expected" ]]; then
		echo "[PASS] $(basename "$test_file") (exit=$actual)"
		passed=$((passed + 1))
	else
		echo "[FAIL] $(basename "$test_file") (esperado=$expected, real=$actual)"
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
