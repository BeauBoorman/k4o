#!/usr/bin/env bash
# knap-textile verification script.
#
# Not CI: run it yourself. It resolves the repo root from its own location.
# Checks:
#   1. zig build                                          (clean build)
#   2. zig build test                                     (expects success)
#   3. zig build test -Dengine-mode=passthrough           (expects failure: goldbrick engine)
#   4. zig build test -Dengine-mode=markdown              (expects failure: Markdown emission)
#   5. zig build test -Doptimize=ReleaseSafe              (expects success)
#   6. CLI smoke: the three examples byte-compare, plus error paths
#      (non-zero exit with empty stdout), --help and --version
#   7. static cross-build for x86_64-linux-musl (file(1): "statically linked")
#
# Logs are written under $KT_VERIFY_DIR (default: a unique directory in
# TMPDIR) and are kept for inspection.

set -u
cd "$(dirname "$0")/.." || exit 2
REPO="$PWD"
ZIG="${ZIG:-zig}"
VERIFY_DIR="${KT_VERIFY_DIR:-${TMPDIR:-/tmp}/knap-textile-verify-$$}"
mkdir -p "$VERIFY_DIR"

pass_count=0
fail_count=0

note() { printf '%s\n' "$*"; }

check_zero() { # desc, log, cmd...
  local desc="$1" log="$2"
  shift 2
  if "$@" >"$log" 2>&1; then
    note "PASS  $desc"
    pass_count=$((pass_count + 1))
  else
    note "FAIL  $desc (expected exit 0)"
    tail -n 15 "$log" | sed 's/^/      | /'
    fail_count=$((fail_count + 1))
  fi
}

check_nonzero_tests() { # desc, log, cmd... (expects non-zero AND test failures)
  local desc="$1" log="$2"
  shift 2
  local rc=0
  "$@" >"$log" 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    note "FAIL  $desc (expected non-zero exit, got 0)"
    fail_count=$((fail_count + 1))
    return
  fi
  local summary
  summary=$(grep -Eo "[0-9]+ pass, [0-9]+ fail \([0-9]+ total\)" "$log" | tail -1)
  if [ -n "$summary" ]; then
    note "PASS  $desc (exit=$rc; $summary)"
    pass_count=$((pass_count + 1))
  else
    note "FAIL  $desc (non-zero exit but no test summary — build error?)"
    tail -n 15 "$log" | sed 's/^/      | /'
    fail_count=$((fail_count + 1))
  fi
}

check_cli_error() { # desc, logbase, cmd... (expects non-zero exit AND empty stdout)
  local desc="$1" logbase="$2"
  shift 2
  local out rc=0
  out=$("$@" 2>"$logbase.err") || rc=$?
  printf '%s' "$out" >"$logbase.out"
  if [ "$rc" -ne 0 ] && [ -z "$out" ]; then
    note "PASS  $desc (exit=$rc, stdout empty)"
    pass_count=$((pass_count + 1))
  else
    note "FAIL  $desc (exit=$rc, stdout bytes=$(wc -c <"$logbase.out"))"
    tail -n 5 "$logbase.err" | sed 's/^/      | /'
    fail_count=$((fail_count + 1))
  fi
}

BIN="$REPO/zig-out/bin/knap-textile"

check_zero "zig build" "$VERIFY_DIR/01-build.log" "$ZIG" build
check_zero "zig build test (normal: all pass)" "$VERIFY_DIR/02-test.log" "$ZIG" build test
check_nonzero_tests "passthrough mutant fails the suite" "$VERIFY_DIR/03-passthrough.log" \
  "$ZIG" build test -Dengine-mode=passthrough
check_nonzero_tests "markdown mutant fails the suite" "$VERIFY_DIR/04-markdown.log" \
  "$ZIG" build test -Dengine-mode=markdown
check_zero "zig build test -Doptimize=ReleaseSafe (all pass)" "$VERIFY_DIR/05-release-safe.log" \
  "$ZIG" build test -Doptimize=ReleaseSafe

for e in heading list table; do
  check_zero "example '$e' renders byte-exact" "$VERIFY_DIR/06-example-$e.log" \
    bash -c "cd '$REPO' && '$BIN' render 'examples/$e.knap' --data 'examples/$e.json' | cmp -s - 'examples/$e.textile'"
done

check_cli_error "error path: unknown filter (exit 1, empty stdout)" "$VERIFY_DIR/07-unknown-filter" \
  "$BIN" render "$REPO/fixtures/errors/err-unknown-filter.knap"
check_cli_error "error path: unclosed if block" "$VERIFY_DIR/08-unclosed-if" \
  "$BIN" render "$REPO/fixtures/errors/err-unclosed-if.knap"
check_cli_error "error path: missing data file" "$VERIFY_DIR/09-missing-data" \
  "$BIN" render "$REPO/examples/heading.knap" --data "$REPO/does-not-exist.json"
check_cli_error "error path: malformed JSON data" "$VERIFY_DIR/10-bad-data" \
  "$BIN" render "$REPO/examples/heading.knap" --data "$REPO/fixtures/errors/bad-data.json"
check_cli_error "error path: no arguments" "$VERIFY_DIR/11-no-args" "$BIN"

check_zero "--help exits 0" "$VERIFY_DIR/12-help.log" "$BIN" --help
check_zero "--version exits 0" "$VERIFY_DIR/13-version.log" "$BIN" --version

check_zero "static x86_64-linux-musl build is statically linked" "$VERIFY_DIR/14-static.log" \
  bash -c "'$ZIG' build -Doptimize=ReleaseSafe -Dtarget=x86_64-linux-musl --prefix '$VERIFY_DIR/static' && file '$VERIFY_DIR/static/bin/knap-textile' | grep -q 'statically linked'"

note "-------------------------------------------"
note "knap-textile verify: $pass_count passed, $fail_count failed"
note "logs kept under: $VERIFY_DIR"
if [ "$fail_count" -ne 0 ]; then
  exit 1
fi
exit 0
