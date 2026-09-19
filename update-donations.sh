#!/usr/bin/env bash
# Update donations.json: either set the raised total directly, or add a
# named donor (which also bumps the raised total by their amount).
#
# Usage:
#   ./update-donations.sh <raised-amount>
#     Set the raised total directly. Donor list untouched.
#
#   ./update-donations.sh add "<Name>" <amount> [admin]
#     Add a named donor: increments raised by <amount>, appends
#     { name, admin } to the donors list shown in "Thank you". Pass the
#     literal word "admin" as a 4th arg to flag them as an admin donor
#     (e.g. because their amount met donations.json's "adminMinimum").
#
# Examples:
#   ./update-donations.sh 17.50
#   ./update-donations.sh add "Jamie" 5 admin
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
    echo "Usage: $0 add \"<Name>\" <amount> [admin]" >&2
    exit 1
  fi
  NAME="$2"
  AMOUNT="$3"
  ADMIN_FLAG="${4:-}"

  if ! [[ "$AMOUNT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: amount must be a positive number, got '$AMOUNT'" >&2
    exit 1
  fi

  ADMIN_BOOL="false"
  if [ "$ADMIN_FLAG" = "admin" ]; then
    ADMIN_BOOL="true"
  fi

  node -e "
const fs = require('fs');
const path = process.argv[1];
const name = process.argv[2];
const amount = Number(process.argv[3]);
const admin = process.argv[4] === 'true';
const data = JSON.parse(fs.readFileSync(path, 'utf8'));
data.raised = Math.round(((data.raised || 0) + amount) * 100) / 100;
data.donors = data.donors || [];
data.donors.push({ name, admin });
fs.writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
console.log('Added donor ' + name + ' (amount ' + amount + ', admin ' + admin + ') - raised is now ' + data.raised + ' in ' + path);
" "$FILE" "$NAME" "$AMOUNT" "$ADMIN_BOOL"
  exit 0
fi

# Plain mode: set the raised total directly.
if [ $# -ne 1 ]; then
  echo "Usage: $0 <raised-amount>" >&2
  echo "   or: $0 add \"<Name>\" <amount> [admin]" >&2
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
