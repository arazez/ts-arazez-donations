#!/usr/bin/env bash
# Update donations.json: either set the raised total directly, or add a
# named donor to the "Thank you" list. These are independent — adding a
# donor does not touch the raised total, since no amount is stored or
# shown per donor.
#
# Usage:
#   ./update-donations.sh <raised-amount>
#     Set the raised total directly. Donor list untouched.
#
#   ./update-donations.sh add "<Name>" ["<Level>"]
#     Add a named donor: appends { name, level } to the donors list
#     shown in "Thank you". The optional 2nd arg is a hand-written
#     admin level (e.g. "Full Admin", "Trial Admin") shown as a badge
#     next to their name; omit it for a donor who wasn't given admin.
#
# Examples:
#   ./update-donations.sh 17.50
#   ./update-donations.sh add "Jamie" "Full Admin"
#   ./update-donations.sh add "Anonymous"
#
# Either mode also bumps "lastUpdated" to today's date automatically,
# which the page shows as "Totals last updated ...".
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
  if [ $# -lt 2 ]; then
    echo "Usage: $0 add \"<Name>\" [\"<Level>\"]" >&2
    exit 1
  fi
  NAME="$2"
  LEVEL="${3:-}"

  node -e "
const fs = require('fs');
const path = process.argv[1];
const name = process.argv[2];
const level = process.argv[3];
const data = JSON.parse(fs.readFileSync(path, 'utf8'));
data.donors = data.donors || [];
const donor = { name };
if (level) donor.level = level;
data.donors.push(donor);
data.lastUpdated = new Date().toISOString().slice(0, 10);
fs.writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
console.log('Added donor ' + name + (level ? ' (' + level + ')' : '') + ' in ' + path);
" "$FILE" "$NAME" "$LEVEL"
  exit 0
fi

# Plain mode: set the raised total directly.
if [ $# -ne 1 ]; then
  echo "Usage: $0 <raised-amount>" >&2
  echo "   or: $0 add \"<Name>\" [\"<Level>\"]" >&2
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
data.lastUpdated = new Date().toISOString().slice(0, 10);
fs.writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
console.log('Updated raised to', amount, 'in', path);
" "$FILE" "$AMOUNT"
