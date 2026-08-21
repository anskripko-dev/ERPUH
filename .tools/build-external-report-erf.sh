#!/usr/bin/env bash
# Сборка .erf из XML-выгрузки внешнего отчёта (без платформы 1С).
# Использует dmpas/v8unpack: https://github.com/dmpas/v8unpack
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="$REPO_ROOT/ExternalReports/нп_МестаИспользованияНоменклатурыИКонтрагентов"
OUTPUT_ERF="$REPORT_DIR/нп_МестаИспользованияНоменклатурыИКонтрагентов.erf"
V8UNPACK_DIR="${V8UNPACK_DIR:-/tmp/v8unpack-dmpas}"
V8UNPACK_BIN="$V8UNPACK_DIR/bin/Release/v8unpack"
STAGING_DIR="$(mktemp -d)"

cleanup() {
	rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

ensure_v8unpack() {
	if [[ -x "$V8UNPACK_BIN" ]]; then
		return
	fi

	echo "Сборка v8unpack в $V8UNPACK_DIR ..."
	if [[ ! -d "$V8UNPACK_DIR/.git" ]]; then
		git clone --depth 1 https://github.com/dmpas/v8unpack.git "$V8UNPACK_DIR"
	fi
	(
		cd "$V8UNPACK_DIR"
		make clean >/dev/null 2>&1 || true
		make
	)
}

build_erf() {
	cp "$REPORT_DIR/нп_МестаИспользованияНоменклатурыИКонтрагентов.xml" "$STAGING_DIR/"
	cp -r "$REPORT_DIR/нп_МестаИспользованияНоменклатурыИКонтрагентов" "$STAGING_DIR/"

	"$V8UNPACK_BIN" -BUILD "$STAGING_DIR" "$OUTPUT_ERF"
	echo "Готово: $OUTPUT_ERF ($(wc -c < "$OUTPUT_ERF") байт)"
}

ensure_v8unpack
build_erf
