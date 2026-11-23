# voronoi_asm

- Source: `voronoi.asm` (NASM syntax, 16-bit real mode, DOS `.com`).
- Build: `nasm voronoi.asm -o voronoi.com -f bin` (verified with NASM 2.16.01).
- `voronoi.com` is committed. Rebuild it after source changes and commit both.
- Check: a comment-only or label-only change must produce a byte-identical `voronoi.com` (`cmp`).
- Run: DOSBox. No automated tests or CI.
