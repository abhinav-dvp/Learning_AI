#!/usr/bin/env bash
set -euo pipefail

# Run the app using the project's venv if present. Optionally auto-open the
# browser once the server is responsive. Configure via env vars:
#   PORT (default 12345), AUTO_OPEN_BROWSER (true/false)

VENV="./venv"
PORT=${PORT:-12345}
AUTO_OPEN_BROWSER=${AUTO_OPEN_BROWSER:-true}

_start_python() {
	local py="$1"
	echo "Starting server with: $py app.py"
	# Start server in background so we can open browser afterwards
	"$py" app.py &
	echo $!
}

if [ -d "$VENV" ]; then
	if [ -f "$VENV/bin/activate" ]; then
		# shellcheck disable=SC1091
		source "$VENV/bin/activate"
		PY_CMD="$VENV/bin/python"
	elif [ -x "$VENV/bin/python" ]; then
		PY_CMD="$VENV/bin/python"
	fi
fi

if [ -z "${PY_CMD:-}" ]; then
	echo "Virtual environment not found at ./venv or python not available there. Please run ./setup.sh or activate your environment manually."
	exit 1
fi

PID=$(_start_python "$PY_CMD")

# Wait for the server to become available
echo "Waiting for server to respond on http://127.0.0.1:$PORT/ ..."
TIMEOUT=30
COUNT=0
until [ $COUNT -ge $TIMEOUT ]
do
	HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/" || true)
	if [ "$HTTP_CODE" != "" ] && [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
		echo "Server is up (HTTP $HTTP_CODE)"
		break
	fi
	sleep 1
	COUNT=$((COUNT+1))
done

if [ "$AUTO_OPEN_BROWSER" = "true" ] || [ "$AUTO_OPEN_BROWSER" = "1" ]; then
	URL="http://localhost:$PORT"
	echo "Opening $URL in default browser..."
	if command -v open >/dev/null 2>&1; then
		open "$URL"
	elif command -v xdg-open >/dev/null 2>&1; then
		xdg-open "$URL"
	else
		echo "Could not find 'open' or 'xdg-open' to launch browser. Please open $URL manually."
	fi
fi

echo "Server PID: $PID"
# Wait for server process to finish so this script stays attached
wait $PID
