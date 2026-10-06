#!/usr/bin/env bash
# 產生所有列印件 STL（需要 OpenSCAD 2021.01 以上）
# 用法：./build_stl.sh              → 正式零件＋試配套件全部
#       ./build_stl.sh fit          → 只產生試配套件（stl/fit/）
#       ./build_stl.sh tub sprocket → 指定零件
# 改了 ares1_params.scad 的 tol 或 insertD 之後，整個重跑一次。
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl stl/fit
MAIN=(tub sprocket idler track_link track_links_16 battery_tray bank_spacer upper_frame neck_deck body_shell speaker_ring head_floor head_hood head_back eye_ring pupil eyelid)
FIT=(fit_tol fit_motor fit_hub fit_track fit_neck fit_pcb fit_drv fit_insert)
if [ $# -eq 0 ]; then PARTS=("${MAIN[@]}" "${FIT[@]}")
elif [ "$1" = "fit" ]; then PARTS=("${FIT[@]}")
else PARTS=("$@"); fi
for p in "${PARTS[@]}"; do
  out="stl/$p.stl"
  [[ $p == fit_* ]] && out="stl/fit/$p.stl"
  echo "== $p"
  openscad -q -D "part=\"$p\"" -o "$out" ares1.scad
done
echo "完成：正式零件 $(ls stl/*.stl | wc -l) 個、試配套件 $(ls stl/fit/*.stl 2>/dev/null | wc -l) 個"
