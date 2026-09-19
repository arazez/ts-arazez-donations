#!/usr/bin/env bash
# Update the "raised" total in donations.json.
#
# Usage:
#   ./update-donations.sh <raised-amount>
#
# Example:
#   ./update-donations.sh 17.50
#
# Uses Node (already required if you're deploying via Cloudflare Pages /
# GitHub Pages tooling) to rewrite donations.json in place, keeping the
# other fields (goal, currency, closeWhenGoalReached, surplusPolicy) as-is.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="$SCRIPT_DIR/donations.json"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <raised-amount>" >&2
  exit 1
fi

AMOUNT="$1"

if ! [[ "$AMOUNT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Error: amount must be a positive number, got '$AMOUNT'" >&2
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "Error: $FILE not found" >&2
  exit 1
fi

node -e "
const fs = require('fs');
const path = process.argv[1];
const amount = Number(process.argv[2]);
const data = JSON.parse(fs.readFileSync(path, 'utf8'));
data.raised = amount;
fs.writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
console.log('Updated raised to', amount, 'in', path);
" "$FILE" "$AMOUNT"
