<p align="center">
  <img src="assets/logo.svg" alt="voronoi_asm logo" width="140">
</p>

<h1 align="center">voronoi_asm</h1>

<p align="center">
   <strong>Voronoi diagram generator written in 8086/8087 assembly.</strong><br>
   <em>A 340-byte DOS program that colors every pixel of VGA mode 13h by its closest point.</em>
</p>

<p align="center">
  <a href="https://www.nasm.us"><img alt="NASM" src="https://shieldcn.dev/badge/NASM-assembly-0066cc.svg?variant=secondary"></a>
  <img alt="8086/8087" src="https://shieldcn.dev/badge/CPU-8086%2F8087-171717.svg?variant=secondary">
  <img alt="VGA mode 13h" src="https://shieldcn.dev/badge/VGA-mode_13h-171717.svg?variant=secondary">
  <a href="https://www.dosbox.com"><img alt="DOSBox" src="https://shieldcn.dev/badge/DOSBox-supported-f59e0b.svg?variant=secondary"></a>
  <a href="https://github.com/kacigaya/voronoi_asm/blob/main/LICENSE"><img alt="MIT License" src="https://shieldcn.dev/github/license/kacigaya/voronoi_asm.svg?variant=secondary"></a>
</p>

## How It Works

The program uses brute force. It is slow on purpose, so the method stays easy to read.

1. Switches to VGA mode 13h (320x200, 256 colors)
2. Generates 50 random points, seeded from the BIOS clock
3. For each of the 64,000 pixels, finds the closest point with the Euclidean distance on the 8087 FPU
4. Colors the pixel from the index of that point
5. Draws each point as a black 2x2 square
6. Waits for a key, then exits to DOS

A Voronoi diagram splits a plane into regions. Each region, or cell, holds every location that is closer to its point than to any other point.

## Requirements

- [NASM](https://www.nasm.us) to build the program
- [DOSBox](https://www.dosbox.com) to run it, because it is a real-mode DOS `.com` program

The repository includes a prebuilt `voronoi.com`. You need NASM only if you change the source.

## Build

```bash
nasm voronoi.asm -o voronoi.com -f bin
```

## Install

### macOS

```bash
brew install nasm dosbox
```

### Linux

```bash
sudo apt-get install nasm dosbox    # Ubuntu, Debian
sudo dnf install nasm dosbox        # Fedora
sudo pacman -S nasm dosbox          # Arch Linux
```

### Windows

1. Install DOSBox from the [DOSBox downloads page](https://www.dosbox.com/download.php?main=1).
2. Install NASM from the [NASM website](https://www.nasm.us) and add it to your `PATH`.

## Usage

1. Build `voronoi.com` on your host, or use the prebuilt one.
2. Start DOSBox.
3. Mount the folder that holds `voronoi.com`:

   ```dos
   mount c ~/path/to/voronoi_asm
   c:
   ```

   On Windows, use a Windows path such as `mount c C:\voronoi_asm`.

4. Run the program:

   ```dos
   voronoi.com
   ```

5. Press any key to exit.

## Configuration

Edit the constant at the top of `voronoi.asm`, then build again.

| Constant | Default | Meaning |
| --- | --- | --- |
| `POINTS_COUNT` | `50` | Number of random points |

Keep `POINTS_COUNT` at 97 or less. The color is `(index + 30) * 2` in one byte, so higher values wrap around and reuse colors.

## Troubleshooting

- **The drawing is slow.** Each pixel checks all 50 points with a square root. Press `Ctrl+F12` in DOSBox to raise the CPU cycles, or `Ctrl+F11` to lower them.
- **`nasm` is not found.** Check that NASM is installed and on your `PATH`. Build on your host system, not inside DOSBox.
- **The graphics look wrong.** Check the display settings in your DOSBox configuration file (`dosbox.conf`).

## Technical Details

| Item | Value |
| --- | --- |
| Resolution | 320x200, VGA mode 13h |
| Output format | Flat `.com` binary, loaded at `100h` |
| Math | 8087 FPU (`fsqrt`) for the distances |
| Random numbers | BIOS clock ticks (`int 1Ah`) mixed with a running seed |
| Video output | Direct writes to `A000:0000` |

## License

[MIT](LICENSE)
