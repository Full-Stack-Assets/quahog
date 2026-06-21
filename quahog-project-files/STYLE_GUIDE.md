# Mount Hope — Visual Style Guide

The canonical look: **stylized-realistic, 1986 South Coast Massachusetts**, with
photoreal elements folded into hero zones. Read should land between *Vice City
dusk* and *a faded Kodachrome postcard of the working waterfront*.

## Era & mood
- **Year:** 1986. No modern cars, glass towers, LEDs, or cell phones.
- **Mood:** salt air, peeling paint, granite and brick, neon tavern signs at
  dusk, fog off Buzzards Bay. Hard-working, a little melancholy, proud.

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
clean.

## Buildings
- **By use/height:** short (<14 m) → warm brick/clapboard; tall → granite/concrete
  greys; named → hero gold.
- **Façade:** window grid by floor (~3.2 m), storefronts at street level, cornices.
- **Roofs:** flat+parapet downtown, gable/mansard residential, sawtooth mills;
  chimneys, vents, water tanks, AC units.

## Lighting
- Warm key sun, cool sky fill; **golden-hour** and **coastal-neon dusk** are the
  signature times. Sun + shadows follow the player. Lit windows + sodium street
  lamps at night; lighthouse beam; emergency lights flashing.

## Post
ACES tone-map · bloom (neon/headlights/sun glints) · soft vignette · light
chromatic aberration + film grain · SMAA. Add SSAO + wet-road reflections (P2).

## Signage & type
Green MUTCD street blades, route shields, hand-painted tavern/shop signs, the
Feast of the Blessed Sacrament banner. UI font: Courier mono, neon-on-dark.

## Don'ts
No modern brands, no clean/new surfaces, no flat untextured massing, no daylight
that looks like noon all the time. If it doesn't feel like 1986 New Bedford in the
fog, it's wrong.
