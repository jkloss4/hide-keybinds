# Hide Keybinds

A World of Warcraft addon that hides the keybind text on your action bars, with a key that shows it again while
you hold it down.

Retail (Interface 120100) and WoW: Forever (Interface 16001).

## Options

Options > AddOns > Hide Keybinds (or `/hidekeybinds`):

- **Hide Keybinds**: on or off for every bar at once (`/hidekeybinds on|off`).
- **Hide the Range Dot**: buttons without a keybind show a small dot that turns red when your target is out of
  range. It stays visible unless you turn this on.
- **Show Keybinds While Held**: click, then press a key (Shift, Ctrl and Alt combinations and extra mouse buttons
  work). Escape cancels, right-click clears it. It's the same binding as Options > Keybindings > AddOns > Hide
  Keybinds.
- **Action Bars**: choose the bars to hide keybinds on: Action Bars 1 to 8, the pet, stance and totem bars, the
  vehicle and possess bars and the extra action button (each client lists the bars it has).

Only the keybind text is made invisible, so it works in combat and Blizzard's buttons keep working as usual.

## Install

Download the zip from the latest release and extract it into `Interface\AddOns`, or from this repo:

    powershell -ExecutionPolicy Bypass -File scripts/install-local.ps1 -Client retail|forever

## Developing / releasing

- Test local changes: `.\scripts\install-local.ps1 -Client retail|forever` copies the addon folder into `AddOns`
  (retail by default), then `/reload`.
- After a WoW patch: bump `## Interface:` in `HideKeybinds/HideKeybinds.toc`.
- Release: `git tag v1.0.1 && git push --tags`. The [Release workflow](.github/workflows/release.yml) stamps the
  version into the TOC, builds the zip (with a `release.json` for the retail and Forever flavors) and publishes the
  GitHub release.

## License

MIT ([`LICENSE`](LICENSE), also included in the addon folder).
