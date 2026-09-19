#!/usr/bin/env bash
# Update donations.json: either set the raised total directly, or add a
# named donor (which also bumps the raised total by their amount).
#
# Usage:
#   ./update-donations.sh <raised-amount>
#     Set the raised total directly. Donor list untouched.
#
#   ./update-donations.sh add "<Name>" <amount> ["<Level>"]
#     Add a named donor: increments raised by <amount>, appends
#     { name, level } to the donors list shown in "Thank you". <amount>
#     only affects the running total — it is never stored or shown per
#     donor. The optional 4th arg is a hand-written admin level (e.g.
#     "Full Admin", "Trial Admin") shown as a badge next to their name;
#     omit it for a donor who wasn't given admin.
#
# Examples:
#   ./update-donations.sh 17.50
#   ./update-donations.sh add "Jamie" 5 "Full Admin"
#   ./update-donations.sh add "Anonymous" 2
#
# Uses Node (already required if you're deploying via Cloudflare Pages /
# GitHub Pages tooling) to rewrite donations.json in place.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="$SCRIPT_DIR/donations.json"

if [ ! -f "$FILE" ]; then
  echo "Error: $FILE not found" >&2
  exit 1
fi

if [ "${1:-}" = "add" ]; then
  if [ $# -lt 3 ]; then
    echo "Usage: $0 add \"<Name>\" <amount> [\"<Level>\"]" >&2
    exit 1
  fi
  NAME="$2"
  AMOUNT="$3"
  LEVEL="${4:-}"

  if ! [[ "$AMOUNT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: amount must be a positive number, got '$AMOUNT'" >&2
    exit 1
  fi

  node -e "
const fs = require('fs');
const path = process.argv[1];
const name = process.argv[2];
const amount = Number(process.argv[3]);
const level = process.argv[4];
const data = JSON.parse(fs.readFileSync(path, 'utf8'));
data.raised = Math.round(((data.raised || 0) + amount) * 100) / 100;
data.donors = data.donors || [];
const donor = { name };
if (level) donor.level = level;
data.donors.push(donor);
fs.writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
console.log('Added donor ' + name + (level ? ' (' + level + ')' : '') + ' - raised is now ' + data.raised + ' in ' + path);
" "$FILE" "$NAME" "$AMOUNT" "$LEVEL"
  exit 0
fi

# Plain mode: set the raised total directly.
if [ $# -ne 1 ]; then
  echo "Usage: $0 <raised-amount>" >&2
  echo "   or: $0 add \"<Name>\" <amount> [\"<Level>\"]" >&2
  exit 1
fi

AMOUNT="$1"

if ! [[ "$AMOUNT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Error: amount must be a positive number, got '$AMOUNT'" >&2
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
