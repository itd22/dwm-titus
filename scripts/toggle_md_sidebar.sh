#!/bin/sh
# Toggle markdown sidebar using st (WM_CLASS = md_sidebar)
# Places a floating st window on the right side occupying 20% of screen width

set -eu

# Required commands: st, xdotool (or wmctrl), sleep, awk
command -v st >/dev/null 2>&1 || { echo "st is required but not found" >&2; exit 1; }

# Prefer xdotool for window operations; fall back to wmctrl if available
has_xdotool=0
has_wmctrl=0
if command -v xdotool >/dev/null 2>&1; then
  has_xdotool=1
fi
if command -v wmctrl >/dev/null 2>&1; then
  has_wmctrl=1
fi

if [ "$has_xdotool" -eq 0 ] && [ "$has_wmctrl" -eq 0 ]; then
  echo "Either xdotool or wmctrl is required to position the sidebar window." >&2
  echo "Install xdotool (recommended) and try again." >&2
  exit 1
fi

# Find existing sidebar windows (by WM_CLASS = md_sidebar)
if [ "$has_xdotool" -eq 1 ]; then
  existing=$(xdotool search --class md_sidebar 2>/dev/null || true)
else
  # wmctrl -lx output format: 0x01200007  0 hostname CLASS.NAME  title
  existing=$(wmctrl -lx | awk '$3 ~ /md_sidebar/ { print $1 }' || true)
fi

if [ -n "$existing" ]; then
  # Close all found sidebar windows
  if [ "$has_xdotool" -eq 1 ]; then
    for w in $existing; do
      xdotool windowkill "$w" 2>/dev/null || true
    done
  else
    for w in $existing; do
      wmctrl -ic "$w" || true
    done
  fi
  exit 0
fi

# No existing sidebar — spawn one
# Compute screen geometry
if [ "$has_xdotool" -eq 1 ]; then
  read screen_w screen_h <<EOF
$(xdotool getdisplaygeometry)
EOF
else
  # wmctrl + awk fallback to get primary monitor geometry
  # wmctrl -d gives lines like: 0* DG: 3840x2160  VP: 0,0  WA: 0,0 3840x2160  N/A
  read tmp screengeom <<EOF
$(wmctrl -d | awk '/\*/ { for (i=1;i<=NF;i++) if ($i ~ /[0-9]+x[0-9]+/) { print $i; exit } }')
EOF
  screen_w=$(echo "$screengeom" | awk -Fx '{print $1}')
  screen_h=$(echo "$screengeom" | awk -Fx '{print $2}')
fi

# Safety defaults
: ${screen_w:=1920}
: ${screen_h:=1080}

# Calculate sidebar width = max(200px, 20% of screen width)
sidebar_w=$(( screen_w * 20 / 100 ))
if [ "$sidebar_w" -lt 200 ]; then
  sidebar_w=200
fi
sidebar_h=$screen_h
sidebar_x=$(( screen_w - sidebar_w ))
sidebar_y=0

# Spawn st with WM_CLASS set to md_sidebar
# Use -c to set the class (instance) and class in st; -e is not used
# Start st in background
st -c md_sidebar &

# Wait for the window to appear and then position it
# Retry a few times
tries=0
maxtries=25
sleep_interval=0.04
while [ $tries -lt $maxtries ]; do
  if [ "$has_xdotool" -eq 1 ]; then
    winid=$(xdotool search --class md_sidebar 2>/dev/null || true)
  else
    winid=$(wmctrl -lx | awk '$3 ~ /md_sidebar/ { print $1 }' || true)
  fi
  if [ -n "$winid" ]; then
    break
  fi
  tries=$((tries + 1))
  sleep $sleep_interval
done

if [ -z "$winid" ]; then
  echo "Failed to find spawned sidebar window." >&2
  exit 1
fi

# Position and resize all matching windows
if [ "$has_xdotool" -eq 1 ]; then
  for w in $winid; do
    xdotool windowmove "$w" "$sidebar_x" "$sidebar_y" || true
    xdotool windowsize "$w" "$sidebar_w" "$sidebar_h" || true
  done
else
  # wmctrl expects geometry in percentage? use wmctrl -ir <win> -e <G>, G: gravity,X,Y,W,H
  # Format: gravity,X,Y,WIDTH,HEIGHT (all in pixels). gravity=-1 use default
  for w in $winid; do
    wmctrl -ir "$w" -e "0,$sidebar_x,$sidebar_y,$sidebar_w,$sidebar_h" || true
  done
fi

exit 0
