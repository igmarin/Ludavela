# Install runbook

**Testers (family, seniors) install through TestFlight**: no cable, builds last 90 days, no re-sign.
The owner-side steps and the beta review text are in [testflight-beta.md](testflight-beta.md).
**Everything below is the free-Apple-ID path for dev devices only**: a signed build from this Mac that
expires 7 days later. Don't use it for testers.

Team: Ismael Marin Cabrera (Personal Team), `VB42T7NYX2` — already pre-filled by
the generator, so Xcode never asks.

## Install (or re-install) on a device

```sh
cd <path-to-your-Ludavela-checkout>
swift tools/generate_project.swift               # local-only is the default
open Ludavela.xcodeproj
```

In Xcode:

1. Connect the device, unlock it, tap **Trust This Computer**.
2. Select the device as the run destination.
3. **⌘R**.

On the device, first install only:

4. **Settings → General → VPN & Device Management → Developer App → Trust**.

Command-line alternative (device already trusted and connected):

```sh
DEV=$(xcrun devicectl list devices | awk '/available/ {print $NF; exit}')
xcrun devicectl device install app --device "$DEV" \
  ~/Library/Developer/Xcode/DerivedData/Ludavela-*/Build/Products/Debug-iphoneos/Ludavela.app
```

## The 7-day expiry (dev devices only)

A free-account build **stops launching when its provisioning profile expires**,
7 days after the *profile* was created, not after the build was signed. Xcode
reuses a cached profile until it expires, so a fresh build can have only a day
or two left (2026-10-13: signed that day, profile from Oct 8, expiring Oct 15).
Re-sign the day before any playtest, then check the date:

```sh
APP=$(ls -dt ~/Library/Developer/Xcode/DerivedData/Ludavela-*/Build/Products/Debug-iphoneos/Ludavela.app | head -1)
security cms -D -i "$APP/embedded.mobileprovision" | plutil -extract ExpirationDate raw -
```

The date is in UTC. Fewer than 6 days left? Move the cached profile out of
`~/Library/Developer/Xcode/UserData/Provisioning Profiles/` and build again;
Xcode makes a new 7-day one. The file to move is `<UUID>.mobileprovision`, where
`<UUID>` is the same command with `UUID` in place of `ExpirationDate`.

- Renewal = repeat the install steps with the device connected. Two minutes.
- The app's data (sessions, settings) survives renewal. **Deleting the app does
  not:** it erases My Week and all progress (#106). Never delete to "fix" an
  expired install — renew it.
- Renewal stops the running app. Since #106 every finished game is saved the
  moment it ends, so a renewal right after a game loses nothing.
- The app icon stays on the home screen but taps do nothing until renewed; the
  iOS error is "Unable to Verify App".

## When signing refuses

| Symptom | Fix |
|---|---|
| "Maximum number of apps for free development profiles has been reached" | Delete *other* unused apps installed from Xcode on that device (each device allows 3 at a time) — not Ludavela, which would erase its history |
| "The device is not registered" / provisioning fails | Xcode → Settings → Accounts → select the team → **Manage Certificates / Download Manual Profiles**; then ⌘R again |
| Bundle ID taken by another team | Change `PRODUCT_BUNDLE_IDENTIFIER` in `tools/generate_project.swift` to something unique |
| Build installs but immediately closes | Check `~/Library/Logs/DiagnosticReports/` for the crash log, or Xcode → Window → Devices → View Device Logs |

## What cannot work in this mode (don't fight it)

- **TestFlight** — uses the paid team (#224), not the Personal Team; see [testflight-beta.md](testflight-beta.md).
- **CloudKit / family sharing / push** — need the iCloud entitlement; the app
  falls back to an on-device store (see `LudavelaApp.swift`, `LOCAL_ONLY`).
- **Installs lasting longer than a week, and remote testers** — use TestFlight for both.

## Privacy and support pages (Cloudflare Pages, #34)

The app and store draft still use the configured host `menteviva-e4s.pages.dev`.
Keep those URLs until a Ludavela host is deployed and checked from a public
browser; a repository rename does not rename the Cloudflare Pages site.
The pages are in `site/`. If the host is moved, update
`Ludavela/Localizable.xcstrings`, `docs/store-listing.md`, and App Store Connect
together, then verify the English and Spanish privacy and support pages.

If Cloudflare needs the repository selected again, choose `igmarin/Ludavela`.
Pushes to `main` redeploy; PR branches get preview URLs.

## CloudKit later

```sh
swift tools/generate_project.swift --cloudkit   # only with the paid account + container
```
