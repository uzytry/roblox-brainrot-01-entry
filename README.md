# Brainrot Rush — Steal, Stack, Rebirth!

[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/uzytry/roblox-brainrot-01-entry/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/uzytry/roblox-brainrot-01-entry/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D Roblox brainrot game in the genre Steal a Brainrot began, built for the
[make.fun bounty "Make the best AI Roblox brainrot game"](https://make.fun/bounty/roblox-brainrot-01).
Buy absurd meme characters off the conveyor, stack them on your base, steal
from your rivals, outrun the tsunami wave, and rebirth for permanent income
multipliers.

## How to play

- **Buy** — Brainrots walk the conveyor belt in the middle of the map. Walk up
  and press **E** to buy one; it is placed on a free pedestal of your base and
  starts earning money every second.
- **Climb** — 14 characters over 7 rarities, from Noobini Pizzanini (Common,
  $1/s) to Dragon Cannelloni (Secret, $8,000/s). Golden, Diamond and Rainbow
  mutations multiply the rate x2, x3 and x5.
- **Steal** — Press **E** on a brainrot on someone else's base to carry it home
  over your head. You run slower while carrying. Press **F** near a carrier to
  slap the catch loose.
- **Lock** — Press **L** (or the LOCK BASE button) to lock your base for 30s so
  nobody can steal from it.
- **Survive** — Every 3 minutes a tsunami wave sweeps the map. Stand on your
  own base to stay safe; rare brainrots rain while it runs.
- **Rebirth** — Reach the cash and brainrot targets to rebirth: your cash and
  brainrots reset, but your income multiplies forever (x2, x3, ...).
- **Upgrades** — Press **U** for more pedestals (up to 12), +25% income per
  level and a longer base lock.

## What is in this repository

- `game.rbxl` — the place, built with Rojo 7.7.1 from `default.project.json`
- `src/` — every script of the place, as Luau files:
  - `src/shared/` — `BrainrotData` (the cast, rarities, mutations) and `Config`
    (every tuning number)
  - `src/server/` — `BrainrotServer` bootstrap, `PlayerData` (the single home
    of all player state), `BaseManager`, `BrainrotFactory` (builds each
    character as a 3D model of parts), `BrainrotSpawner` (the conveyor),
    `StealSystem`, `Economy` (income, buying, upgrades, rebirths, leaderboard)
    and `EventManager` (tsunami wave, Golden Hour)
  - `src/client/` — `Game` (HUD and keys) and `Effects` (particles, money
    ticks, camera kick)
- `screenshots/` — 4 screenshots; the first is the game's thumbnail
- `PLAY.json` — the link to the game's public place on Roblox
- `TOUR.json` — a tour of the screenshots for reviewers
- `main.ts` — the entry program: copies the game to `/output` and writes the
  dossier with `vendor/makefun-roblox.ts` (the kit's copy, unchanged)

## Build it yourself

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Open `game.rbxl` in Roblox Studio to play it. No uploaded assets are used:
every character is built from plain parts, so the game loads anywhere.
