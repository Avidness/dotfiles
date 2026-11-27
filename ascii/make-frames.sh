#!/usr/bin/env bash
# Render an ASCII Magic piece (MIT, https://www.ascii-magic.com/ascii) into a
# frames file the shell banner plays inline. Needs Node; the banner doesn't.
#   ascii/make-frames.sh icosahedron [seconds=2.5] [fps=15]
# Output: ascii/<piece>.frames, first line = frame height, then the frames.
set -euo pipefail
piece=$1 secs=${2:-2.5} fps=${3:-15}
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

n=$(awk -v s="$secs" -v f="$fps" 'BEGIN{print int(s*f)}')
for ((i = 0; i < n; i++)); do
  t=$(awk -v i="$i" -v f="$fps" 'BEGIN{printf "%.4f", i/f}')
  npx --yes ascii-magic-art@1.1.0 "$piece" --frame --t="$t" < /dev/null \
    | sed -e 's/[[:space:]]*$//' > "$tmp/$(printf %04d "$i")"
done

# Crop every frame to the rows any frame uses, so all frames are the same
# height, and give each row one color of a rainbow gradient.
awk -v n="$n" '
  FNR == 1 { f++ }
  { line[f, FNR] = $0; if (FNR > rows) rows = FNR
    if ($0 != "") { if (!top || FNR < top) top = FNR; if (FNR > bot) bot = FNR } }
  END {
    h = bot - top + 1; print h
    for (k = 1; k <= n; k++) for (r = top; r <= bot; r++) {
      x = 0.3 * (r - top)
      printf "\033[38;2;%d;%d;%dm%s\033[0m\n", sin(x)*127+128, sin(x+2.094)*127+128, sin(x+4.189)*127+128, line[k, r]
    }
  }' "$tmp"/* > "$dir/$piece.frames"
echo "wrote $dir/$piece.frames ($n frames)"
