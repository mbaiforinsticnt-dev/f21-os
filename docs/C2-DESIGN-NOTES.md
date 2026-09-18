# C2 Reborn design notes

Read-only inspection of the frozen C2 Reborn source was used for this baseline.

- The display is split into a black status bar, main content, and black softkey bar.
- The frozen home theme uses a pale blue to deep blue field, blue home text, a bright active strip and a small shortcut strip.
- Main menu is a three-column grid. The selected cell is a dark gradient with a light border and rounded corners.
- Grid view can suppress labels; other menu view modes preserve labels.
- Menu softkeys are `Options`, `Select`, `Exit`; editing changes them to `Move` and `Done`.
- Softkey labels change with the screen and are treated as state, not decoration.

The Android launcher keeps these rules while scaling them to the F21 Pro's 480x640 screen. Pixel-level parity remains provisional until rendered screenshots are compared and then checked on the physical F21.
