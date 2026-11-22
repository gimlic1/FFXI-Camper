# FFXI Addon — Camper

> [!NOTE]
> **Quick Reference**
> - **Path:** `C:\Windower\addons\Camper\`
> - **Author / Version:** Ivaar / unversioned extension for `AuctionHelper`
> - **Commands:** `//camp ...` (via `unhandled command`)
> - **Load Status:** On-Demand (unloaded standalone; active copy is `require('camper')` inside `AuctionHelper`)
> - **Origin:** Third-Party (`https://gist.github.com/Ivaar/630ad6667dd80d3aedd3af3f2272ac76`)

Automated Auction House bid-camping module designed to run inside `AuctionHelper`, cycling through a `bidlist` of items, incrementing bids on failure (`0xC5`), and importing/exporting JSON profiles.

## What the Code Does
- Note: `Camper.lua` is not a standalone addon (it relies on globals `ah_proposal`, `zones`, `res_zones`, `res_items`, `default`, `settings`, `packets`, `get_item_res`, `format_price`, and `comma_value` defined in `AuctionHelper.lua`).
- `autoBid()` iterates `bidlist[actions.Ind]` starting from `minimum`, calling `ah_proposal('buy', ...)` and setting `bidding = true`.
- Listens to incoming `0x04C`:
  - `pType == 0x03`: stops cycling (`killCycle()`).
  - `pType == 0x0E`: on `byte(7) == 1` (bid won), decrements `quantity` (removing entry at `0` in standalone version, or advancing via `nextBid()` in `AuctionHelper\Camper.lua`) and schedules the next bid (`min_bid_delay`–`max_bid_delay`, `9–12s`); on `byte(7) == 0xC5` (bid failed), increments `currentbid` by `price_inc` up to `maximum`, then moves to `nextBid()` and waits `min_cycle_delay`–`max_cycle_delay` between full cycles.
- Recording mode (`//camp rec on`) inspects outgoing `0x04E` (`0x0E` bids) to build or update `bidlist` entries with observed `minimum`, `maximum`, and `price_inc`.
- Halts automatically on `/logout` (`outgoing text`), `zone change`, or `logout`.

## Commands & Usage
- `//camp on [<start_index>]` / `//camp off` — Starts or stops bid camping in AH zones.
- `//camp add <item> <single|0|stack|1> <price> [#qty]` — Adds/updates a `bidlist` item.
- `//camp clear` — Empties `bidlist`.
- `//camp qty <n>` / `//camp inc <n>` — Updates quantity or bid increment on the last `bidlist` entry.
- `//camp rec on|off` — Toggles recording manual/command bids into `bidlist`.
- `//camp import <name>` / `//camp export <name>` / `//camp exp <name>` — Loads or saves `data/<name>.json`.
- `//camp display [off]` — Shows/hides the click-drag `bidlist` text box.

## Events, Packets & Technical Hooks
- **Windower Events:** `incoming chunk`, `outgoing chunk`, `unhandled command`, `outgoing text`, `zone change`, `logout`
- **Packets:**
  - Incoming `0x04C`: reads `0x03` (menu abort) and `0x0E` (bid success `0x01` / fail `0xC5`).
  - Outgoing `0x04E`: monitored (`0x0E` bids) during `record` mode; injected via `AuctionHelper.ah_proposal()`.
- **Dependencies / Libraries:** `JSON.lua`, `files`, plus `AuctionHelper` globals (`packets`, `texts`, `resources`).

## Local Settings & Customizations
- Standalone `C:\Windower\addons\Camper\Camper.lua` is the unmodified upstream gist (`min_cycle_delay=60`, `max_cycle_delay=180`, sample `rhodium ore`/`ifritite`).
- Kevin's active modified copy lives at `C:\Windower\addons\AuctionHelper\Camper.lua` (`min_cycle_delay=180`, `max_cycle_delay=360`, hardcoded `Colibri Beak` and `Garglle. Shank`, and extra `display:show()` calls).

## Related Notes
- `FFXI Addon — AuctionHelper`
- `FFXI Windower Overview`
- `FFXI Windower Addons Catalog`
