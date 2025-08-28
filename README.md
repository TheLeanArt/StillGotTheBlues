# Still Got the Blues

Super Game Boy / Noise channel mixer

## Controls ##

* A activates SGB sound A/B
  * A while holding START clears SGB sound
  * A while holding SELECT+START resets SGB sound
* B activates CH4 noise
  * B while holding START clears CH4 noise
  * B while holding SELECT+START resets CH4 noise
* START triggers all three in unison
* D-pad adjusts/moves between params
  * Adjust while holding A/B/START provides constant feedback
* SELECT moves between param groups
  * A while holding toggles SGB sound A/B
  * Up/Down while holding moves to respective param group
* A+B displays the parameter string

## Parameter String Mapping

  | Register | Alt  | Bits  | Digit  | Bits  |
  |----------|------|-------|--------|-------|
  | SOUND01  |      | 4 - 5 | 0      | 0 - 1 |
  | SOUND01  |      | 0 - 3 | 1      |       |
  | SOUND02  |      |     4 | 0      | 2     |
  | SOUND02  |      | 0 - 3 | 2      |       |
  | SOUND03  |      | 0 - 3 | 3      |       |
  | SOUND03  |      | 4 - 7 | 4      |       |
  | AUD4LEN  | NR41 |     4 | 0      | 3     |
  | AUD4LEN  | NR41 | 0 - 3 | 5      |       |
  | AUD4ENV  | NR42 | 4 - 7 | 6      |       |
  | AUD4ENV  | NR42 | 0 - 3 | 7      |       |
  | AUD4POLY | NR43 | 4 - 7 | 8      |       |
  | AUD4POLY | NR43 | 0 - 3 | 9      |       |
  | AUD4GO   | NR44 |     6 | Border |       |

## Building from Source

```
make
```

Known to work with RGBDS 0.9.2 on MSYS64.

## Limitations

Due to the tight schedule of GB Compo 2025, the following features have been left for a future release:

* Top part enable/disable animations
* Top part digit animations
* Bugfixes

## Accessibility

The tool has been designed with accessibility in mind. High-contrast assets are utilised for the benefit of the visually-impaired user.

## Thanks

* Nikku4211 for inspiring the creation of this tool and for initial testing
* m2m for testing on actual SGB and SGB2 hardware
* Rangi42 for patiently answering every dumb question
* Marc Robledo for creating some great GB development tools
* The entire GBdev community for their awesomeness
* avivace and bbbbbr for organising GB Compo 2025
* itch.io for hosting the event
* the judges for their hard work
