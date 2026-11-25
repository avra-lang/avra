#!/usr/bin/env python3
"""Draws sample text in a real terminal emulator (tmux, a detached pane) and
prints the cells it advanced next to the cells `@std.text.cells` answers.
A row marked `differs` is a terminal that adds each code point's width
instead of segmenting by cluster; it is reported, never failed.

    python3 tools/term_width.py
"""
import subprocess
import time

SERVER = ["tmux", "-L", "avra-term-width"]

# (name, code points, cells @std.text.cells answers)
CASES = [
    ("ascii", [104, 101, 108, 108, 111], 5),
    ("precomposed e-acute", [233], 1),
    ("e + combining acute", [101, 769], 1),
    ("lone combining acute", [769], 0),
    ("han pair", [20013, 25991], 4),
    ("hangul syllable", [54620], 2),
    ("hangul jamo L V T", [4352, 4449, 4520], 2),
    ("fullwidth A", [65313], 2),
    ("halfwidth kana", [65398], 1),
    ("emoji", [128512], 2),
    ("zwj family", [128104, 8205, 128105, 8205, 128103], 2),
    ("flag", [127471, 127477], 2),
    ("lone regional indicator", [127471], 2),
    ("heart, text style", [10084], 1),
    ("heart + emoji selector", [10084, 65039], 2),
    ("sun + text selector", [9728, 65038], 1),
    ("keycap 1", [49, 65039, 8419], 2),
    ("han + combining", [20013, 769], 2),
    ("zero-width space", [8203], 0),
    ("zwj alone", [8205], 0),
    ("skin-toned thumb", [128077, 127997], 2),
    ("woman technologist", [128105, 127997, 8205, 128187], 2),
    ("devanagari conjunct", [2325, 2381, 2359], 1),
    ("thai sara am", [3585, 3635], 1),
    ("plane-two han", [131072], 2),
]


def tmux(*args):
    return subprocess.run(SERVER + list(args), capture_output=True, text=True).stdout


def advanced(codes):
    tmux("send-keys", "-t", "w", "-l", "\r")
    time.sleep(0.02)
    tmux("send-keys", "-t", "w", "-l", "".join(chr(c) for c in codes))
    time.sleep(0.04)
    return int(tmux("display-message", "-p", "-t", "w", "#{cursor_x}").strip())


def main():
    tmux("kill-server")
    tmux("new-session", "-d", "-s", "w", "-x", "200", "-y", "50", "stty -echo -icanon; exec cat")
    time.sleep(0.5)
    differs = 0
    for name, codes, want in CASES:
        got = advanced(codes)
        mark = "" if got == want else "  differs"
        differs += got != want
        print("%-26s model %d  terminal %d%s" % (name, want, got, mark))
    tmux("kill-server")
    print("%d of %d differ" % (differs, len(CASES)))


if __name__ == "__main__":
    main()
