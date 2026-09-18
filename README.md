# Mandem Server — Donation Page

A single static `index.html` (HTML + CSS + vanilla JS, no build step, no frameworks) for collecting donations toward the yearly TeamSpeak hosting cost.

## Editing

Everything you'd want to change lives in two places inside `index.html`:

### 1. Donation window & links — top of the `<script>` block

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

### 2. Server name, goal, and donor list — in the HTML body

- Server name/subtitle: in the `<header class="hero">` section.
- Yearly goal (`£30`): in the "Where your money goes" section (`.goal-line`).
- Donor thank-you list: edit the `<ul class="donors" id="donorList">` items by hand — add or remove `<li>` entries, each optionally with a `<span class="amt">` for the amount.
- TeamSpeak address (`ts.arazez.com`) appears in a few places — the "Join the server" button href (`ts3server://ts.arazez.com`), the header, and the footer.

### Testing the donation window locally

Open the page with a query string override so you don't have to wait for the real date:

- `index.html?preview=open` — forces the OPEN state (buttons + "closes in" countdown)
- `index.html?preview=closed` — forces the CLOSED state (no buttons, "opens in" countdown)

No override = real date/time logic based on `TIMEZONE`.

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
