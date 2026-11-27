# Enlighten Them

A comedy puzzle game about paradigm shifts, made in Godot 4.1 for GitHub Game Off 2026 (theme: SHIFT).

A glowing light called the Light asks you to "enlighten" humanity one paradigm shift at a time. Every chapter zooms into the next one, and the fish you build in chapter 4, Carl, follows you for the rest of the game.

## Chapters

1. **Let There Be Light**: the Big Bang, then move the Sun to the middle and put the planets back on their rings.
2. **Pump It Round**: pump the flat Earth into a sphere without popping it.
3. **Break Up Pangaea**: drill along the fault lines with a wobbly drill.
4. **Make Carl**: build a fish. His look is saved and used in every later chapter.
5. **Road to the Library**: one button, five stages (walk, run, horse, car, plane).
6. **Sort the Library**: shelve books with liquid-sort rules.
7. **Be Kind, Rewind**: wire a VCR, fix the tracking, log into MixFlix, fight the buffering wheel.
8. **Dial It Up**: turn tiles to connect letters, telegraph and dial-up lines.
9. **Power Hungry**: coal, then a sun-and-wind grid, then a Dyson sphere.
10. **The Last Question**: catch the last light of dying stars. Then it all begins again.

## Controls

Mouse for everything. Space or Enter advances dialogue, and Space also works as the action button in Pump It Round, Road to the Library (where Up and W work too) and Power Hungry. Esc pauses. M mutes or unmutes all sound.

Options on the title screen: steady hands (no drill wobble), relaxed timers, mute, and volume for everything, music and sound effects.

## Project layout

- `scripts/core/game.gd`: global state (autoload `Game`): chapter order, Carl's saved appearance, settings, save file, zoom transitions.
- `scripts/core/dialog.gd`: dialogue box (autoload `Dialog`). Each speaker talks in their own synthesized bell dings while the text types out (`Sfx.VOICES`): high glassy bells for the Light, bouncy mid dings for Carl and a low desk-bell clunk for the librarian.
- `scripts/core/sfx.gd`: sound effects, dialogue voices and music (autoload `Sfx`). Every chapter plays one of CALL911imonfire's songs, stored as stems in `music/`. The title screen and the ending play stems of CALL911imonfire's song "The Lights" from `music/` (chords, bass, end, end echo), chapters 1 to 3 play its full arrangement (starting once the title loop finishes), and Make Carl and Road to the Library play his song "Carl" (120 BPM: chords, then bass, drums, extra and lane 7 joining one per loop, starting over after the full mix plays once, and all back in once Carl is done; harmony on the road, melody after its first phase, then 15 BPM faster each phase). Sort the Library and Be Kind, Rewind play his song "Library" (80 BPM), with its lane 5 joining for the buffering-wheel fight. Dial It Up and Power Hungry play his song "Glow", and The Last Question plays "Glow 2", switching over at the next bar of Glow, until the ending switches back to The Lights. Each song's stems loop in sync and fade in or out as the story moves on. The code can also generate a fallback track for a chapter without a song (chords, bass, arpeggio and soft drums, rendered on a worker thread), but every chapter has a song now, so those tracks are not heard in the game. Volume goes through `Music` and `SFX` audio buses.
- `scripts/core/art.gd`: code-drawn art shared by every scene, including the light and Carl. Small circles and ellipses come from one cached disc texture (`Art.dot`) because building a polygon for each one every frame made the browser build choppy.
- `scripts/core/stage.gd`: base class for chapters.
- `scripts/scenes/`: one script per chapter.
- `tools/`: developer checks (not used by the game).

## Developer tools

Check that every script parses:

```
godot --headless -s res://tools/check.gd
```

Play the whole game automatically (dialogue skips itself, each puzzle is solved by the test driver):

```
godot --headless --fixed-fps 60 -- --autotest --chapter=1
```

Start at any chapter with `-- --chapter=N`.

Render the generated fallback tracks to WAV files (to listen outside the game):

```
godot --headless -s res://tools/render_music.gd -- --out=C:/some/folder
```

Render each speaker's dialogue voice typing a sample line to WAV:

```
godot --headless -s res://tools/render_voices.gd -- --out=C:/some/folder
```

Time every chapter's frames (average, worst, and how long the chapter's own update and drawing take):

```
godot -- --bench
```

Take a screenshot of any chapter (also used to render the itch.io cover image with `--set="thumb=true" --crop=325,110,630,500 --zoom=1` on chapter 0):

```
godot -- --chapter=N --peek=out.png --wait=2 --nodialog
```

## Builds

`export_presets.cfg` has a Web preset (for itch.io, which needs its SharedArrayBuffer option turned on) and a Windows preset. With Godot 4.1.3's export templates installed:

```
godot --headless --export-release "Web" build/web/index.html
godot --headless --export-release "Windows" "build/windows/Enlighten Them.exe"
```

The browser build has no system fonts, so on-screen text sticks to plain letters and punctuation, and symbols are drawn as shapes.

## AI disclosure

- **By CALL911imonfire:** the game idea and design, story, puzzles and jokes, playtesting, and all of the music: "The Lights", "Carl", "Library", "Glow" and "Glow 2".
- **With Claude (Anthropic):** all of the code, some of the dialogue, brainstorming, and testing and debugging. The code includes the graphics and the sound effects:
  - Graphics: every shape is drawn by code while the game runs. There are no image files, and no image-generation AI was used.
  - Sound effects and dialogue voices: synthesized by code while the game runs. There are no audio samples, and no audio- or music-generation AI was used.

## Asset licenses

There are no third-party assets. Art and sound effects are generated by the game's own code, and all of the music is CALL911imonfire's own, all under this repository's license.
