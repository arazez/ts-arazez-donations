# Mandem Server — Donation Page

A single static `index.html` (HTML + CSS + vanilla JS, no build step, no frameworks) for collecting donations toward the yearly TeamSpeak hosting cost, plus `donations.json` for the live total.

## Editing

### 1. Donation window & links — top of the `<script>` block in `index.html`

```js
var DONATION_OPEN_MONTH = 10;      // October (1-12)
var DONATION_OPEN_DAY = 1;         // day of month the window opens
var DONATION_DURATION_DAYS = 31;   // window stays open this many days
var TIMEZONE = "Europe/London";

var REVOLUT_URL = "https://revolut.me/amjedlwa";
var PAYPAL_URL = "https://paypal.me/arazez";
```

- The window can cross a year boundary fine (e.g. opening 15 December for 31 days runs into mid-January) — the JS checks both the previous year's and current year's window.
- Change `REVOLUT_URL` / `PAYPAL_URL` if your payment links ever change.

### 2. Donation total, goal, rules, and donor list — `donations.json`

```json
{
  "goal": 30,
  "raised": 3,
  "currency": "GBP",
  "closeWhenGoalReached": true,
  "adminMinimum": 3,
  "maxPerPerson": 5,
  "donors": [
    { "name": "Amjed", "level": "Full Admin" },
    { "name": "Anonymous", "level": "Admin" }
  ]
}
```

This one file now drives the progress bar, the donation rules note, and the donor list in "Thank you" — the donor `<ul>` in `index.html` is empty and gets filled in by JS from `donors` on load.

- `goal` / `raised` drive the progress bar shown under "Where your money goes".
- `raised` starts each year at `3` (not `0`) to account for the owner's own automatic £3/yr contribution to the server. When you reset the total at the start of a new donation window, reset it to `3`, not `0`.
- `closeWhenGoalReached` (`true`/`false`): when `true` and `raised >= goal`, the page treats donations as closed even if the yearly window is still open — the Revolut/PayPal buttons are hidden and the banner shows "🎉 Goal reached, thank you!" with the final total instead. Set to `false` if you'd rather keep accepting donations past the goal.
- `adminMinimum`: the donation amount that qualifies someone for admin. Shown in the rules note under the donate buttons and in the "Thank you" intro text (both auto-formatted with `currency`).
- `maxPerPerson`: the donation cap per person, shown as "Max £X per person so everyone gets a fair shot." in that same rules note.
- `donors`: array of `{ "name": "...", "level": "..." }`. `level` is optional, hand-written free text (e.g. `"Full Admin"`, `"Admin"`, `"Trial Admin"`) shown as a badge next to their name in "Thank you" — you decide it per donor, it isn't auto-computed from `adminMinimum`. Leave it out entirely for a donor who wasn't given admin. No donation amounts are stored or shown per donor, only whether they donated and what level (if any) they were given.
- Easiest way to update `raised` and `donors`: run `./update-donations.sh` (see below) rather than hand-editing the JSON, though editing it directly works too.

### 3. Server name and contact links — in the HTML body of `index.html`

- Server name/subtitle: in the `<header class="hero">` section.
- TeamSpeak address (`ts.arazez.com`) appears in a few places — the "Join the server" button href (`ts3server://ts.arazez.com`), the header, and the footer.
- Contact section (bottom of the page, `.contact-links`): three small chips — Discord handle (plain text), Twitter link, Steam profile link. Edit the handle text or the `href`s directly in that block.

### Section visibility by state

- **Open**: banner, buttons, admin/max-donation rules note, "Where your money goes" (with progress bar), "Thank you" (donor list, 🛡️ level badge on donors who have one).
- **Goal reached**: same as open minus the buttons/rules note; "Where your money goes" still shows to display the final total.
- **Closed**: banner only (no buttons, no rules note) — "Where your money goes" is hidden entirely (no stale progress bar), leaving just "Thank you".

### Updating totals and donors: `update-donations.sh`

```bash
# Set the raised total directly (donor list untouched)
./update-donations.sh 17.50

# Add a named donor: bumps raised by their amount (not stored per donor),
# adds them to the "Thank you" list. Pass a hand-written level as the
# 4th arg to give them a badge; omit it if they weren't given admin.
./update-donations.sh add "Jamie" 5 "Full Admin"
./update-donations.sh add "Anonymous" 2
```

Rewrites `donations.json` in place (requires Node, which is already on your machine if you've used npm/Cloudflare/GitHub tooling). The plain `<amount>` form only touches `raised`; the `add` form also appends to `donors`. Either way, the amount only ever affects the running total — it's never written into a donor's own entry.

### Testing locally

`index.html` loads `donations.json` via `fetch()`, which browsers block on a plain `file://` URL. Serve the folder over local HTTP first, e.g.:

```bash
npx serve .
# or
python3 -m http.server 8000
```

Then open the page with a query string override so you don't have to wait for the real date or edit `donations.json`:

- `?preview=open` — forces the OPEN state (buttons + "closes in" countdown), using the real `donations.json` totals for the progress bar
- `?preview=closed` — forces the CLOSED state (no buttons, "opens in" countdown)
- `?preview=goal` — forces the GOAL REACHED state (no buttons, "🎉 Goal reached" banner, progress bar shown full)

No override = real date/time logic based on `TIMEZONE`, combined with the real `donations.json` totals.

**Temporary review toggle:** the page currently also has a small floating "Open / Closed / Goal / Real" button group (bottom-right) that does the same thing as `?preview=` but instantly, client-side, no URL editing. Every block is commented `TEMP REVIEW TOGGLE — remove before deploying` in `index.html` (CSS, HTML, and JS) — search for that and delete all three before shipping to production.

## Deploying

This is a static site — any static host works. No build step, no dependencies to install.

### Cloudflare Pages

1. Push this repo to GitHub (or connect a local folder via Wrangler).
2. In the Cloudflare dashboard: **Workers & Pages → Create → Pages → Connect to Git**, pick this repo.
3. Build settings: **no build command**, output directory `/` (root).
4. Deploy.
5. Custom domain: **Pages project → Custom domains → Add** → `donate.arazez.com`. Cloudflare will prompt you to add a CNAME (or it's automatic if `arazez.com`'s DNS is already on Cloudflare).

### GitHub Pages

1. Push this repo to GitHub.
2. **Settings → Pages → Source**: deploy from the `main` branch, root folder.
3. **Settings → Pages → Custom domain**: enter `donate.arazez.com`, save (this creates a `CNAME` file in the repo automatically — commit it if GitHub doesn't do so for you).
4. At your DNS provider, add a `CNAME` record: `donate` → `<your-username>.github.io`.
5. Wait for DNS to propagate, then enable **Enforce HTTPS** in the Pages settings once the certificate is issued.

## Notes

- No tracking scripts, no external dependencies besides an optional Google Fonts stylesheet (`Rubik`).
- No bank details are shown anywhere — only Revolut/PayPal links, and only while the donation window is open.
