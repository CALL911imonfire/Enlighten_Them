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

Mouse for everything. Space or Enter advances dialogue, and Space also works as the action button in Pump It Round, Road to the Library and Power Hungry. Esc pauses.

Options on the title screen: steady hands (no drill wobble), relaxed timers, music on or off.

## Project layout

- `scripts/core/game.gd`: global state (autoload `Game`): chapter order, Carl's saved appearance, settings, save file, zoom transitions.
- `scripts/core/dialog.gd`: dialogue box (autoload `Dialog`).
- `scripts/core/sfx.gd`: synthesized sound effects and music (autoload `Sfx`).
- `scripts/core/art.gd`: code-drawn art shared by every scene, including the light and Carl.
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

## AI disclosure

Story, puzzles and jokes by CALL911imonfire. Code (including the code-drawn graphics and synthesized audio) and some dialogue written with Claude. No image-generation AI was used: every shape is drawn by code.
