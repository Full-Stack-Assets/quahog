# The Narrows — Visual Style Guide

The canonical look: **stylized-realistic, present-day (2026) South Coast Massachusetts**,
with photoreal elements folded into hero zones. Read should land between *modern
crime-drama dusk* and *a salt-stained postcard of the working waterfront*.

## Era & mood
- **Year:** 2026 (now). Contemporary cars, phones, and signage on the real OSM map.
- **Mood:** salt air, peeling paint, granite and brick, neon tavern signs at
  dusk, fog off Buzzards Bay. Hard-working, a little melancholy, proud.
- **Coastal Neon** is a *lighting palette* (wet asphalt, sodium lamps, pink/cyan
  accents) — not a period lock.

## Palette
| Role | Hex | Use |
|---|---|---|
| Brick red | `#8a5a48` `#6e4a3e` | triple-deckers, mill blocks |
| Granite grey | `#7c7e88` `#9aa0a6` | civic, banks, Fall River mills |
| Clapboard | `#b8b0a0` `#c2bcae` `#a8987e` | residential, Cape cottages |
| Hero gold | `#caa24a` | landmarks (Bethel, Whaling Museum) |
| Harbor water | `#16384a` | the Acushnet / harbor |
| Coastal neon | `#ff7ad9` `#ffcf4a` `#5ad0ff` | signage, UI accents |
| Night window | `#ffcf8a` | lit windows, lamp glow |

## Materials (PBR targets)
Asphalt (wet-shine in rain), granite setts/cobble, red brick (multiple bonds),
Fall River granite block, clapboard, wood shingle, painted brick, plate glass,
weathered steel. Everything carries **grime, salt-stain, peeling paint** — never
sterile showroom clean.

## Buildings
- **By use/height:** short (<14 m) → warm brick/clapboard; tall → granite/concrete
  greys; named → hero gold.
- **Façade:** window grid by floor (~3.2 m), storefronts at street level, cornices.
- **Roofs:** flat+parapet downtown, gable/mansard residential, sawtooth mills;
  chimneys, vents, water tanks, AC units.

## Lighting
- Warm key sun, cool sky fill; **golden-hour** and **coastal-neon dusk** are the
  signature times. Sun + shadows follow the player. Lit windows + sodium/LED street
  lamps at night; lighthouse beam; emergency lights flashing.

## Post
ACES tone-map · bloom (neon/headlights/sun glints) · soft vignette · light
chromatic aberration + film grain · SMAA. Add SSAO + wet-road reflections (P2).

## Signage & type
Green MUTCD street blades, route shields, hand-painted and LED tavern/shop signs.
UI font: Courier mono, neon-on-dark. Title: **THE NARROWS** / *South Coast · Now*.

## Don'ts
No flat untextured massing, no daylight that looks like flat noon all the time,
no sterile mall-clean streets. If it doesn't feel like the South Coast in the
fog at dusk, it's wrong.
