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

### 2. Donation total & goal — `donations.json`

```json
{
  "goal": 30,
  "raised": 3,
  "currency": "GBP",
  "closeWhenGoalReached": true,
  "surplusPolicy": "Any excess rolls into next year's hosting renewal."
}
```

- `goal` / `raised` drive the progress bar shown under "Where your money goes".
- `raised` starts each year at `3` (not `0`) to account for the owner's own automatic £3/yr contribution to the server. When you reset the total at the start of a new donation window, reset it to `3`, not `0`.
- `closeWhenGoalReached` (`true`/`false`): when `true` and `raised >= goal`, the page treats donations as closed even if the yearly window is still open — the Revolut/PayPal buttons are hidden and the banner shows "🎉 Goal reached, thank you!" with the final total instead. Set to `false` if you'd rather keep accepting donations past the goal.
- `surplusPolicy` is a short free-text note shown under the progress bar (e.g. what happens to money raised beyond the goal).
- Easiest way to update `raised`: run `./update-donations.sh <amount>` (see below) rather than hand-editing the JSON, though editing it directly works too.

### 3. Server name and donor list — in the HTML body of `index.html`

- Server name/subtitle: in the `<header class="hero">` section.
- Donor thank-you list: edit the `<ul class="donors" id="donorList">` items by hand — add or remove `<li>` entries, each optionally with a `<span class="amt">` for the amount.
- TeamSpeak address (`ts.arazez.com`) appears in a few places — the "Join the server" button href (`ts3server://ts.arazez.com`), the header, and the footer.

### Updating the raised total: `update-donations.sh`

```bash
./update-donations.sh 17.50
```

Rewrites the `raised` field in `donations.json` (requires Node, which is already on your machine if you've used npm/Cloudflare/GitHub tooling). Leaves `goal`, `currency`, `closeWhenGoalReached` and `surplusPolicy` untouched.

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
