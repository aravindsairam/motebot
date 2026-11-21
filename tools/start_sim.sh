#!/bin/bash
# Start the simulator in the background and wait until it is publishing.
#   tools/start_sim.sh              with the Isaac Sim window
#   tools/start_sim.sh --headless   no window
#   tools/start_sim.sh --no-noise   perfect sensors (any run_sim.py argument is passed through)
# Isaac Sim occasionally crashes at start-up; this retries up to three times.
# Log: logs/sim.log
R="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
ISAAC="${ISAACSIM_DIR:-$HOME/isaacsim}"
LOG="$R/logs/sim.log"; mkdir -p "$R/logs"
cd "$ISAAC" || { echo "Isaac Sim not found at $ISAAC"; exit 1; }
if ps -eo comm,args | awk '$1 ~ /^(python|kit)/ && /sim\/scripts\/run_sim/ {found=1} END {exit !found}'; then
  echo "The simulator is already running. Stop it first: tools/stop_all.sh"
  exit 1
fi
for attempt in 1 2 3; do
  # Isaac Sim brings its own ROS 2 libraries; a sourced ROS environment must not leak in.
  (nohup env -u PYTHONPATH -u AMENT_PREFIX_PATH -u COLCON_PREFIX_PATH -u CMAKE_PREFIX_PATH -u ROS_DISTRO -u LD_LIBRARY_PATH -u RMW_IMPLEMENTATION \
     ./python.sh "$R/sim/scripts/run_sim.py" "$@" > "$LOG" 2>&1 &)
  for i in $(seq 1 90); do
    grep -q "SIM_READY" "$LOG" 2>/dev/null && { echo "simulator ready (attempt $attempt): $(grep -o 'SIM_MODE.*' "$LOG" | head -1)"; exit 0; }
    grep -q -E "Segmentation fault|Traceback" "$LOG" 2>/dev/null && break
    sleep 2
  done
  echo "simulator did not start on attempt $attempt (see $LOG)"; sleep 5
done
exit 1
