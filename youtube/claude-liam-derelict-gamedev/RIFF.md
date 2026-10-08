# RIFF — evidence-led commentary (inspected output only)

Things the captures, renders and logs actually showed, which the narration can riff on. Each one names the evidence.

1. **Mute is a fader, not a stop button.** RUN_C v1 muted SFX, the shot killed the zombie, and unmuting 1.0 s later produced a −5 dB burst: the 2.4 s collapse sound, still playing silently. (`audio_director.gd` 71 mutes the bus; nothing stops the players.) The film's route waits it out; a player pressing N mid-fight would hear a tail. *Used in B13/B14.*
2. **The zombie can't catch a walker.** RUN_B v1 walked straight east past it and was never grabbed: 140 px/s vs 55 px/s. The design note in `zombie.gd` 17 says that's intentional ("backing off while aiming works"). The capture had to walk *into* it. *Possible aside in B09.*
3. **The test's four broken guards fail four different ways.** SHOT 4 (held button refires), HURT 135 (every physics tick), DOWN 3, CLEAR 3. The spam scenario still passes with guards removed, because shot spacing alone caps it. The test isn't redundant, but one scenario is weaker than it looks. *B23.*
4. **Free rotation failed twice, not once.** Upside-down was the visible failure; the 7fc6a99 grid also shows the gun 90° off the shot in *both* the current and +180 formulas. A 180° offset could never have fixed it. *B15/B16.*
5. **Readability on the real floor.** In every full-room frame the olive scavenger is the hardest thing to find; the placeholder zombie is the easiest (B05 right). Real art made the game *less* readable than placeholders. *Verdict.*
6. **The HUD as evidence.** The debug readout (`State`, `SFX fired`) ticks exactly once per event in all three captures. On-screen corroboration of the test, in real play rather than a test harness. *B07/B11/B14/B21.*
