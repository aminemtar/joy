# JOY sound effects

These 15 short arcade cues are synthesized specifically for JOY by `tool/build_sound_effects.py`. There are no downloaded recordings, external audio services, or third-party sound-pack attributions. Rebuild with `python tool/build_sound_effects.py` (Python standard library only).

WAV format: 22,050 Hz, mono, signed 16-bit PCM. Sounds use bounded levels, soft attack/release envelopes and silent tails. The complete pack is bundled for offline playback.

- tap / flip: menu actions, board moves, letter entry and card reveals
- correct / wrong: goals, matches, answers, solved clues and missed attempts
- hit / jump / shoot: paddle contacts, collisions, tower placement and action controls
- tick / start: countdown and game start
- win / draw: match results and tournament results
- note_blue / note_coral / note_gold / note_purple: Simon Echo playback and pad input

The audio service mixes short effects with other apps, uses the media/game audio channel, throttles rapid repeated effects, and stops playback when muted, backgrounded or leaving a match. Sound effects and volume preferences are saved locally.

Use **Settings → Test sound** to check playback. This shows plugin or asset errors instead of silently hiding them. If enabling sound after setting volume to zero, JOY restores a 60% app volume. Device media volume and connected audio outputs still apply.

## Background music

`background.wav` is JOY’s original 20-second, 96 BPM arcade-lounge loop (Cmaj7 / Am7 / Fmaj7 / G6, synthesized keys, bass, pad and percussion). Generate it with `python tool/build_background_music.py`. It is independently controlled from sound effects, loops through the splash/lobby/game screens, pauses in the background and resumes on return. Native startup requests playback automatically; browsers can require user interaction. The loop is mono 22,050 Hz PCM with bounded peaks and silent boundary samples.
