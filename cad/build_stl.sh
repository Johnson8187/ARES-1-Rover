#!/usr/bin/env bash
# 產生所有列印件 STL（需要 OpenSCAD 2021.01 以上）
# 用法：./build_stl.sh            → 全部
#       ./build_stl.sh tub sprocket  → 指定零件
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl
PARTS=("$@")
if [ ${#PARTS[@]} -eq 0 ]; then
  PARTS=(tub sprocket idler track_link track_links_16 battery_tray bank_spacer upper_frame neck_deck body_shell speaker_ring head_floor head_hood head_back eye_ring pupil eyelid)
fi
for p in "${PARTS[@]}"; do
  echo "== $p"
  openscad -q -D "part=\"$p\"" -o "stl/$p.stl" ares1.scad
done
echo "完成：$(ls stl/*.stl | wc -l) 個 STL"
