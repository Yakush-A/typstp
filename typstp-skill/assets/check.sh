#!/usr/bin/env bash
# Обёртка над check.py. Использование:
#   ./check.sh --type diploma|course|lab|other [--strict] main.typ [package-path]
# Все параметры и проверки: python3 check.py --help (или шапка check.py).
exec python3 "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check.py" "$@"
