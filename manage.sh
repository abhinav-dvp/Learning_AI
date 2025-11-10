#!/usr/bin/env bash
set -euo pipefail

# Small helper to automate common tasks: setup, run, publish, test
# Usage: ./manage.sh setup|run|publish|test

CMD=${1:-}
if [ -z "$CMD" ]; then
  echo "Usage: $0 {setup|run|publish|test|help}"
  exit 1
fi

case "$CMD" in
  setup)
    echo "Running setup.sh to create venv and install dependencies..."
    chmod +x setup.sh
    ./setup.sh
    ;;

  run)
    echo "Starting the app (will prefer ./venv if present)..."
    chmod +x run.sh
    ./run.sh
    ;;

  publish)
    echo "Publishing to GitHub using publish_to_github.sh"
    chmod +x publish_to_github.sh
    ./publish_to_github.sh
    ;;

  test)
    echo "Running quick syntax check..."
    python3 -m py_compile app.py
    echo "OK: app.py compiles"
    ;;

  help)
    echo "Commands: setup, run, publish, test"
    ;;

  *)
    echo "Unknown command: $CMD"
    exit 2
    ;;
esac
