#!/usr/bin/env bash
# Render an ASCII Magic piece (MIT, https://www.ascii-magic.com/ascii) into a
# frames file the shell banner plays inline. Needs Node; the banner doesn't.
#   ascii/make-frames.sh icosahedron [seconds=4] [fps=15]
# Output: ascii/<piece>.frames: frame height, the frames, then an end marker.
set -euo pipefail
piece=$1 secs=${2:-4} fps=${3:-15}
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

n=$(awk -v s="$secs" -v f="$fps" 'BEGIN{print int(s*f)}')
for ((i = 0; i < n; i++)); do
  t=$(awk -v i="$i" -v f="$fps" 'BEGIN{printf "%.4f", i/f}')
  npx --yes ascii-magic-art@1.1.0 "$piece" --frame --color --truecolor --t="$t" < /dev/null \
    > "$tmp/$(printf %04d "$i")"
done

# Keep the piece's own colors. Crop every frame to the rows any frame uses
# (ignoring color codes), so all frames are the same height.
awk -v n="$n" '
  FNR == 1 { f++ }
  { line[f, FNR] = $0; s = $0; gsub(/\033\[[0-9;]*m|[ \t]/, "", s)
    if (s != "") { if (!top || FNR < top) top = FNR; if (FNR > bot) bot = FNR } }
  END {
    print bot - top + 1
    for (k = 1; k <= n; k++) for (r = top; r <= bot; r++) print line[k, r] "\033[0m"
    print "-- end --"   # keeps trailing blank rows from being dropped on read
  }' "$tmp"/* > "$dir/$piece.frames"
echo "wrote $dir/$piece.frames ($n frames)"
