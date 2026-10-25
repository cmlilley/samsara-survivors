# Samsara Survivors

A PICO-8 Vampire Survivors style roguelite about reincarnation. Every life is five minutes. How you live it decides what you come back as.

## The wheel

Karma runs from -100 to +100 and sets your next form:

- **+60 or more:** Deva
- **+20 to +59:** Virtuous Human
- **-19 to +19:** Animal
- **-59 to -20:** Hungry Ghost
- **-60 or less:** Hellborn

Every first life is a **Soul Mote** (a cockroach). Usurping a god earns a one-life **Asura**.

Normal kills give no karma. Karma comes from events: the roadside shrine (pray or smash it), ambient innocents crossing the map (protect them or don't), the Rival Soul at four minutes (mercy or execute), and the boss itself.

## Godhood

At 7:30 the boss locks to one of six gods, and its form reads your karma: **Trial** form at +30 or more (win for a Sun Mark), **War** form at -30 or less (win for a Blood Mark), or the easier **Feral** form in between (no mark). All six Sun Marks earn the Crown of Heaven; all six Blood Marks earn the Crown of Hell.

Hold both crowns and an Ascension Life unlocks: all six gods back to back, then the Judge of Karma, who fights with a copy of your strongest build. Beat him and choose: sit on the throne (free play) or step off the wheel (the true ending).

## Builds

Eleven upgrades: Melee, Bolt, Spread, Damage, Speed, Max HP, Armor, Regen, Crit, Cooldown, Magnet. Most are pure numbers; there is no trait system. Instead, your three most-stacked upgrades carry into your next life at one stack each. Bosses keep their signature systems: Vora's vacuum gulp, Aurel's shield and turret shrines, Kharun's orbiting swords.

## Controls

- Arrow keys: move (attacks are automatic)
- Z: confirm, pick upgrades, channel the shrine
- X (on the rebirth screen): start the Ascension Life, once unlocked
- Down (on the rebirth screen): toggle **god mode** for testing (invulnerable, 15x damage, 3x magnet, 1.5x speed, on a separate scratch save)

## Building

`src/main.lua` is the source of truth. `tools/build_cart.py` assembles `samsara.p8` from it plus `assets/sprite-sheet.png`:

```
python3 tools/build_cart.py
```

The cart sits at 7,789 of PICO-8's 8,192 tokens.

## Music

Original soundtrack composed for PICO-8's built-in tracker, all in one key (D minor pentatonic/dorian): a slow title theme for the rebirth screen, a driving loop for a life, and a faster, tenser loop for boss fights and the Ascension Life, plus sound effects for level-ups, pickups, hits, the shrine, and boss deaths. `tools/gen_audio.py` composes the tracker data from note tables into `assets/audio_sections.txt`, and `tools/build_cart.py` splices it into the cart on every build.
