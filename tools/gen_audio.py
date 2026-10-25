#!/usr/bin/env python3
"""Compose the Samsara Survivors soundtrack into assets/audio_sections.txt.

The soundtrack is authored here as readable note tables (step, note,
waveform, volume) and encoded into the standard .p8 text formats:

  __sfx__   line = 168 hex chars: 4 header bytes (mode, speed, loop
            start, loop end) + 32 notes of 5 hex chars each
            (pitch 2, waveform 1, volume 1, effect 1).
  __music__ line = flags byte, a space, then 4 channel bytes
            (sfx index, +0x40 mutes a channel). Flags: bit 0 = loop
            begin, bit 1 = loop end, bit 2 = stop. This matches the
            format PICO-8 itself writes (see any editor-saved cart).

One musical identity throughout: D minor pentatonic / D dorian,
meditative but driving, for a game about reincarnation and karma.

Layout:
  sfx 0..31   music components (one 32-note sequence per channel slot)
  sfx 32      all-silent sequence (sounds the muted title channel)
  sfx 40..44  one-shot effects: level-up, pickup, hurt, boss death,
              shrine chime

Run:  python3 tools/gen_audio.py     (deterministic, no randomness)
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio_sections.txt"

SEMI = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4,
        "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9,
        "A#": 10, "Bb": 10, "B": 11}

# Waveforms: 0 triangle, 1 tilted saw, 2 saw, 3 square, 4 pulse,
# 5 organ, 6 noise, 7 phaser.
TRI, TSAW, SAW, SQR, PLS, ORG, NOI = 0, 1, 2, 3, 4, 5, 6


def P(note):
    """'D3' / 'Eb2' / 'C#4' -> PICO-8 pitch (12*octave + semitone)."""
    if isinstance(note, int):
        return note
    if note[-2] in ("#", "b"):
        name, octv = note[:-1], int(note[-1])
    else:
        name, octv = note[:-1], int(note[-1])
    return 12 * octv + SEMI[name]


def seq(notes):
    """[(step, note, wave, vol), ...] -> {step: (pitch, wave, vol)}."""
    out = {}
    for step, note, wave, vol in notes:
        assert 0 <= step < 32, step
        out[step] = (P(note), wave, vol)
    return out


def eighth_line(pitches, wave, vol, offset=0):
    """Notes on every 2nd step (eighth notes), for basslines."""
    return [(offset + 2 * i, p, wave, vol) for i, p in enumerate(pitches)]


# ---------------------------------------------------------------- sfx
# index -> (speed, {step: (pitch, wave, vol)})
SFX = {}

# --- TITLE / REBIRTH THEME (music pattern 0, speed 24, slow) ----------
# sfx 0: bass, a low D drone figure on triangle, quiet.
SFX[0] = (24, seq([
    (0, "D2", TRI, 4), (8, "F2", TRI, 3),
    (16, "D2", TRI, 4), (24, "C3", TRI, 3),
]))
# sfx 1: lead, a simple descending D minor pentatonic phrase.
SFX[1] = (24, seq([
    (0, "A4", TRI, 4), (4, "F4", TRI, 4), (8, "D4", TRI, 4),
    (12, "C4", TRI, 3), (16, "D4", TRI, 4),
    (24, "A3", TRI, 3), (28, "D4", TRI, 4),
]))
# sfx 2: harmony, a sparse slow organ arp, quiet.
SFX[2] = (24, seq([
    (2, "D4", ORG, 2), (6, "F4", ORG, 2), (10, "A4", ORG, 2),
    (14, "F4", ORG, 2), (18, "D4", ORG, 2), (22, "C4", ORG, 2),
    (26, "A3", ORG, 2), (30, "F3", ORG, 2),
]))

# --- LIFE LOOP A (music pattern 1, speed 15) --------------------------
# sfx 4: driving eighth-note bass pulse on D.
SFX[4] = (15, seq(eighth_line(
    ["D2", "D2", "D2", "D2", "F2", "F2", "D2", "D2",
     "D2", "D2", "D2", "D2", "A2", "A2", "G2", "G2"], TSAW, 4)))
# sfx 5: pentatonic lead, first half.
SFX[5] = (15, seq([
    (0, "D4", PLS, 4), (4, "F4", PLS, 4), (8, "A4", PLS, 4),
    (12, "G4", PLS, 4), (16, "F4", PLS, 4), (20, "E4", PLS, 4),
    (24, "D4", PLS, 4), (28, "C4", PLS, 3), (30, "D4", PLS, 3),
]))
# sfx 6: quiet off-beat arp.
SFX[6] = (15, seq([
    (2, "D4", ORG, 2), (6, "F4", ORG, 2), (10, "A4", ORG, 2),
    (14, "F4", ORG, 2), (18, "D4", ORG, 2), (22, "F4", ORG, 2),
    (26, "A4", ORG, 2), (30, "F4", ORG, 2),
]))
# sfx 7: noise percussion, low thud on beats, hats on off-beats.
SFX[7] = (15, seq(
    [(s, 10, NOI, 3) for s in (0, 8, 16, 24)] +
    [(s, 50, NOI, 2) for s in (2, 6, 10, 14, 18, 22, 26, 30)]))

# --- LIFE LOOP B (music pattern 2, speed 15) --------------------------
# sfx 8: bass, second half (rises to C before falling back to D).
SFX[8] = (15, seq(eighth_line(
    ["D2", "D2", "D2", "D2", "F2", "F2", "G2", "G2",
     "D2", "D2", "D2", "D2", "C3", "C3", "A2", "A2"], TSAW, 4)))
# sfx 9: lead, second half, resolves back toward pattern A's D.
SFX[9] = (15, seq([
    (0, "A4", PLS, 4), (4, "C5", PLS, 4), (8, "A4", PLS, 4),
    (12, "G4", PLS, 4), (16, "F4", PLS, 4), (20, "A4", PLS, 4),
    (24, "G4", PLS, 4), (28, "F4", PLS, 3), (30, "E4", PLS, 3),
]))
# sfx 10: arp, second half.
SFX[10] = (15, seq([
    (2, "F4", ORG, 2), (6, "A4", ORG, 2), (10, "C5", ORG, 2),
    (14, "A4", ORG, 2), (18, "F4", ORG, 2), (22, "A4", ORG, 2),
    (26, "G4", ORG, 2), (30, "F4", ORG, 2),
]))
# sfx 11: percussion with an end-of-pattern fill.
SFX[11] = (15, seq(
    [(s, 10, NOI, 3) for s in (0, 8, 16, 24)] +
    [(s, 50, NOI, 2) for s in (2, 6, 10, 14, 18, 22, 26)] +
    [(28, 34, NOI, 3), (30, 26, NOI, 3)]))

# --- BOSS LOOP (music pattern 3, speed 11, tenser) --------------------
# sfx 12: driving bass with chromatic approach notes (Eb, C#).
SFX[12] = (11, seq(eighth_line(
    ["D2", "D2", "Eb2", "D2", "D2", "D2", "C#2", "D2",
     "D2", "D2", "Eb2", "D2", "F2", "E2", "Eb2", "D2"], TSAW, 5)))
# sfx 13: sharper saw lead, angular, with Bb tension from dorian.
SFX[13] = (11, seq([
    (0, "D4", SAW, 4), (2, "D4", SAW, 4), (4, "F4", SAW, 4),
    (6, "Eb4", SAW, 4), (8, "D4", SAW, 4), (10, "C#4", SAW, 4),
    (12, "D4", SAW, 4), (16, "A3", SAW, 4), (20, "Bb3", SAW, 4),
    (24, "A3", SAW, 4), (28, "F4", SAW, 4), (30, "Eb4", SAW, 4),
]))
# sfx 14: arp leaning on Bb for dread.
SFX[14] = (11, seq([
    (2, "D4", ORG, 2), (6, "F4", ORG, 2), (10, "A4", ORG, 2),
    (14, "Bb4", ORG, 2), (18, "A4", ORG, 2), (22, "F4", ORG, 2),
    (26, "D4", ORG, 2), (30, "Bb3", ORG, 2),
]))
# sfx 15: denser noise percussion, thud on every beat.
SFX[15] = (11, seq(
    [(s, 10, NOI, 3) for s in (0, 4, 8, 12, 16, 20, 24, 28)] +
    [(s, 50, NOI, 2) for s in (2, 6, 10, 14, 18, 22, 26, 30)] +
    [(s, 44, NOI, 2) for s in (7, 15, 23, 31)]))

# --- WIN STING components (music pattern 4, speed 8, plays once) -----
# sfx 16: lead, a rising D major-feel arp that lands and rings.
SFX[16] = (8, seq([
    (0, "D4", PLS, 5), (4, "F4", PLS, 5), (8, "A4", PLS, 5),
    (12, "D5", PLS, 5), (16, "C5", PLS, 5), (20, "D5", PLS, 4),
    (24, "A4", PLS, 4), (28, "D5", PLS, 5),
]))
# sfx 17: bass, roots under the arp.
SFX[17] = (8, seq([
    (0, "D2", TRI, 5), (8, "A2", TRI, 4), (16, "D3", TRI, 5),
    (24, "D3", TRI, 4),
]))
# sfx 18: soft organ shimmer above.
SFX[18] = (8, seq([
    (0, "F4", ORG, 2), (8, "A4", ORG, 2), (16, "D5", ORG, 2),
    (24, "D5", ORG, 2),
]))

# --- LOSE STING components (music pattern 5, speed 10, plays once) ----
# sfx 19: lead, a slow sinking line that settles on the tonic.
SFX[19] = (10, seq([
    (0, "A3", TRI, 5), (6, "F3", TRI, 5), (12, "D3", TRI, 5),
    (18, "C3", TRI, 4), (24, "D3", TRI, 5),
]))
# sfx 20: bass, sparse and low.
SFX[20] = (10, seq([
    (0, "D2", TRI, 5), (12, "F2", TRI, 4), (24, "D2", TRI, 5),
]))
# sfx 21: organ shadow with the dorian Bb for dread.
SFX[21] = (10, seq([
    (0, "D4", ORG, 2), (12, "Bb3", ORG, 2), (24, "A3", ORG, 2),
]))

# --- sfx 32: all-silent sequence (title pattern's 4th channel) --------
SFX[32] = (24, {})

# --- ONE-SHOT EFFECTS (40+) -------------------------------------------
# sfx 40: level-up, fast rising 6-note arp, bright.
SFX[40] = (3, seq([
    (0, "D3", PLS, 5), (1, "F3", PLS, 5), (2, "A3", PLS, 5),
    (3, "D4", PLS, 5), (4, "F4", PLS, 5), (5, "A4", PLS, 5),
]))
# sfx 41: pickup, short two-note blip.
SFX[41] = (3, seq([(0, "A4", PLS, 5), (2, "D5", PLS, 5)]))
# sfx 42: player hurt, short low noise burst.
SFX[42] = (2, seq([(0, 18, NOI, 6), (1, 14, NOI, 6), (2, 10, NOI, 5)]))
# sfx 43: boss death, falling dorian cascade, 16 notes.
SFX[43] = (3, seq([
    (i, n, SAW, 5) for i, n in enumerate(
        ["D5", "C5", "A4", "G4", "F4", "E4", "D4", "C4",
         "A3", "G3", "F3", "E3", "D3", "C3", "A2", "D2"])
]))
# sfx 44: shrine chime, three soft high notes, slowly ringing.
SFX[44] = (8, seq([
    (0, "F4", TRI, 3), (6, "A4", TRI, 3), (12, "D5", TRI, 3),
]))

LAST_SFX = 44

# ------------------------------------------------------------- music
# (flags, [ch0, ch1, ch2, ch3]); flags bit0 = loop begin, bit1 = loop end.
MUSIC = [
    (0x03, [0, 1, 2, 32]),      # 0 title/rebirth, loops on itself
    (0x01, [4, 5, 6, 7]),       # 1 life loop A, loop begin
    (0x02, [8, 9, 10, 11]),     # 2 life loop B, loop end (back to 1)
    (0x03, [12, 13, 14, 15]),   # 3 boss loop, loops on itself
    (0x04, [16, 17, 18, 32]),   # 4 win sting, stop flag: plays once
    (0x04, [19, 20, 21, 32]),   # 5 lose sting, stop flag: plays once
]


def encode_sfx(speed, notes):
    assert 0 <= speed <= 255
    line = "00%02x0000" % speed  # mode 00, speed, loop start 00, loop end 00
    for step in range(32):
        pitch, wave, vol = notes.get(step, (0, 0, 0))
        assert 0 <= pitch <= 63 and 0 <= wave <= 7 and 0 <= vol <= 7
        line += "%02x%x%x0" % (pitch, wave, vol)  # effect 0 = none
    assert len(line) == 168, len(line)
    return line


def main():
    lines = ["__sfx__"]
    for idx in range(LAST_SFX + 1):
        if idx in SFX:
            speed, notes = SFX[idx]
            lines.append(encode_sfx(speed, notes))
        else:
            lines.append("00" * 4 + "00000" * 32)  # untouched/empty sfx
    lines.append("__music__")
    for flags, chans in MUSIC:
        assert len(chans) == 4 and all(0 <= c <= 0x7f for c in chans)
        lines.append("%02x " % flags + "".join("%02x" % c for c in chans))
    OUT.write_text("\n".join(lines) + "\n")
    print("wrote", OUT, "| sfx lines:", LAST_SFX + 1,
          "| music patterns:", len(MUSIC))


if __name__ == "__main__":
    main()
