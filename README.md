# UnBalatro

**Unbalanced Balatro**: 15 custom Jokers and 10 custom Decks for the [Balatro3DS](https://github.com/idkhan/Balatro3DS) fan port.

Some of them are fair. Some are not. That's the point.

## Install

1. Download `UnBalatro_2.0.0.zip` from the [latest release](../../releases/latest).
2. Unzip it and copy the **`UnBalatro`** folder to your 3DS SD card at:
   `/3ds/save/Balatro3DS/sdmc/mods/`
3. Launch Balatro3DS. Open **Options > Mods** and check that UnBalatro is listed.

If something doesn't load, look at `mods/mods_log.txt` on the SD card.

> **Saved runs are tied to the mod version.** If you update UnBalatro in the middle of a run, that run may not load.

## Jokers

| Joker | Rarity | Cost | Effect |
|---|---|---|---|
| Aces Up | Common | $4 | Earn $3 at end of round for each Ace in your full deck |
| Triggered Joker | Rare | $7 | Retrigger all played and held cards 2X |
| Wizard Joker | Common | $5 | Gains +25 Chips for every Tarot card used this run |
| Bizarro Joker | Common | $7 | Create 1 random Uncommon Negative Joker when a Blind is selected |
| Perkeo Jr. | Uncommon | $7 | When a Blind is selected, create a Negative copy of the last Tarot or Planet card used |
| Infinity Joker | Uncommon | $6 | Create The Soul after defeating a Boss Blind (must have room) |
| Freedom Joker | Common | $4 | Gains +4 Mult for every played King, Queen, 6 and 9, and +20 Chips for every played 4 |
| Sisyphus | Common | $6 | Retrigger all other Jokers on the final hand of the round |
| Hyperspace | Uncommon | $6 | 1 in 3 chance to create Black Hole when a Blind is selected (must have room) |
| Mario | Rare | $10 | +3 Joker slots |
| Luigi | Rare | $10 | +4 Joker slots |
| Link | Common | $5 | X15 Mult. Gains X5 Mult when a Boss Blind is defeated |
| Samus Aran | Common | $5 | +99 Chips and X2 Mult |
| Kirby | Rare | $10 | Copies the ability of a random Joker each round |
| Donkey Kong | Legendary | $15 | Creates a Negative copy of the Joker to its left when a Boss Blind is defeated |

### Notes on how they work

- **Kirby** picks a new target each time a Blind is selected and copies it the way Blueprint does. Like Blueprint, he can only copy Jokers that are Blueprint-compatible.
- **Donkey Kong** does nothing if he is the leftmost Joker. The clone keeps the original's saved state (for example, Link's scaling) and is never Eternal.
- **Perkeo Jr.** works like The Fool: it does nothing until you have used a Tarot or Planet card.
- **Wizard Joker** counts every Tarot used this run, including ones used before you bought it.
- **Mario and Luigi** each take a slot themselves, so the net gain is +2 and +3.
- **Blueprint and Brainstorm** can copy exactly four UnBalatro Jokers: Wizard, Freedom, Samus Aran and Perkeo Jr. The rest are left out on purpose to avoid runaway scaling (a copied Link would be X15 on top of X15).

## Decks

| Deck | Effect |
|---|---|
| Conjurer | +2 hand size. Creates a random Spectral card each round (must have room) |
| Vagabond | Tarot cards and Arcana Packs are free. +2 consumable slots |
| Stacked | Chip value of all cards doubled. -1 hand |
| Adventurer | +1 hand, +1 discard. Start with Telescope, $20, +2 Joker slots |
| Faceoff | 26 face cards and 26 10s (no other ranks) |
| Patio | All Clubs and Diamonds, plus 26 Stone cards |
| Collector | Start with 26 random Foil cards |
| Hei | Start with 5 bags of Popcorn |
| Elevated | Deck has no cards below 5 (no 2s, 3s or 4s) |
| Jockler | +4 Joker slots and 10 random Holographic cards |

## Reporting bugs

Open an [issue](../../issues) and include what you were doing, which Jokers and Deck you had, and the contents of `mods/mods_log.txt` if the game printed an error.

## Credits and license

Made by **amateur-logic**. Built on [Balatro3DS](https://github.com/idkhan/Balatro3DS) by idkhan.

The mod's code is released under the MIT License (see `LICENSE`). The artwork depicts characters owned by their respective rights holders (Nintendo and others); it is fan art, not licensed by or affiliated with them, and the MIT license covers only the code and the original artwork. Balatro is made by LocalThunk and Playstack. This project is not affiliated with or endorsed by either.
