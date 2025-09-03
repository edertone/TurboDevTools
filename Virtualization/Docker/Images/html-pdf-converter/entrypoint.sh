#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Check for input and output arguments, quoting the variables correctly.
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $(basename "$0") <input.html> <output.pdf>"
  exit 1
fi

INPUT_HTML="$1"
OUTPUT_PDF="$2"

# Execute the conversion command with all necessary flags for a headless environment.
# (detect chrome or chromium)
CHROME_BIN=$(command -v google-chrome-stable || command -v chromium-browser)

$CHROME_BIN \
  --headless \
  --disable-gpu \
  --no-sandbox \
  --disable-dev-shm-usage \
  --print-to-pdf="$OUTPUT_PDF" \
  "$INPUT_HTML" 2>/dev/null

echo "Conversion of '$INPUT_HTML' to '$OUTPUT_PDF'... complete"