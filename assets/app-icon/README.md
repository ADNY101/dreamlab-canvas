# DreamLab Canvas app icon

A **photo card with moonlit mountains**: a white-bordered photo, tilted slightly, showing a crescent
moon over two mountain ridges, with a sparkle at its corner. It is the image-editor sibling of the
DreamLab PDF icon (same tile, motif and sparkle).

## Palette

| Colour | Hex | Used for |
|---|---|---|
| Violet → pink | `#4c1d95` → `#db2777` | the tile gradient |
| Indigo → violet | `#312e81` → `#7c3aed` | the photo's sky |
| Paper | `#f8f7ff` | the photo border |
| Lilac | `#c4b5fd`, `#a78bfa` | the mountains |
| Gold | `#fde68a` | the moon and sparkle |

## Geometry

A 512-unit tile (`viewBox="0 0 512 512"`), rounded square with `rx=112`, no border. The macOS
renders pad it onto Apple's 824/1024 icon grid; the Windows and Linux renders crop 22 units off
each side so the motif reads at 16–48 px.

## Provenance

Original placeholder artwork for DreamLab Canvas, hand-written SVG. License: see `LICENSE.txt`.

## Files

- `dreamlab-canvas.svg`: canonical master.
- `dreamlab-canvas-small.svg`: copy of the master; also the hicolor scalable icon.
- `dreamlab-canvas-1024.png`: 1024 px render on the macOS grid.
- `dreamlab-canvas.icns`: macOS bundle icon (`CFBundleIconFile`).
- `dreamlab-canvas.ico`: Windows icon, 16–256 px, embedded in the `.exe` by `apps/dreamlab-canvas/build.rs`.
- `hicolor/<size>/apps/com.dreamlab.canvas.png` (16–512) and `hicolor/scalable/...svg`:
  Linux icon theme.

The app also sets the window icon and Wayland app ID at runtime (`apps/dreamlab-canvas/src/app_icon.rs`,
`main.rs`). On Windows the taskbar shows the icon of the Start Menu shortcut that launches the
exe, so the MSI's `<Icon Id>` keeps the `.exe` extension (ICE50); `app_icon.rs` documents the
details and tests the `.ico` sizes and the WiX icon references.

## Regenerate

Replace `dreamlab-canvas.svg` (and `dreamlab-canvas-small.svg`), then run `packaging/icons.sh`. It needs
`resvg`, plus `iconutil` on macOS; the `.ico` is packed by `cargo xtask ico`.
