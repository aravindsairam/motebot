#!/bin/bash
# Start the robot software stack in the background and wait until the mode manager is ready.
#   tools/start_stack.sh              with RViz
#   tools/start_stack.sh rviz:=false  without
# The stack is started for the world the running simulator announces (/sim/world), with that
# world's maps folder: ros2_ws/maps for the house, ros2_ws/maps_<world> for any other.
# Log: logs/stack.log
R="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
LOG="$R/logs/stack.log"; mkdir -p "$R/logs"
# Two stacks at once means two mode managers fighting over the robot. Refuse to start a second.
if ps -eo comm,args | awk '($1=="ros2" && /launch vacuum_bringup/) || /lib\/vacuum_mode_manager\/mode_manager/ || /lib\/vacuum_safety\/safety_gate/ {found=1} END {exit !found}'; then
  echo "The robot stack (or part of it) is already running. Stop it first: tools/stop_all.sh --keep-sim"
  exit 1
fi
source /opt/ros/humble/setup.bash
source "$R/ros2_ws/install/setup.bash"
# A map of one world loaded in another leaves the robot lost in a place it believes it knows.
world=$(timeout 20 ros2 topic echo --once --qos-durability transient_local --qos-reliability reliable \
          /sim/world std_msgs/msg/String 2>/dev/null | sed -n 's/^data: //p' | tr -d "'\"")
if [ -z "$world" ]; then
  echo "The simulator announced no world on /sim/world. Is it running? Start it first: tools/start_sim.sh"
  exit 1
fi
asked=$(printf '%s\n' "$@" | sed -n 's/^world:=//p' | tail -1)
if [ -n "$asked" ] && [ "$asked" != "$world" ]; then
  echo "The simulator runs the world '$world', not '$asked'. Start the simulator with --world $asked, or leave world:= out."
  exit 1
fi
[ -z "$asked" ] && set -- "$@" "world:=$world"
echo "world: $world"
(nohup ros2 launch vacuum_bringup vacuum.launch.py "$@" > "$LOG" 2>&1 &)
for i in $(seq 1 90); do
  grep -q -E "ready in idle|FAILSAFE" "$LOG" 2>/dev/null && break
  sleep 1
done
grep -E "mode_manager.*(ready in idle|FAILSAFE)" "$LOG" | sed -E 's/\[[0-9.]+\] //' | cut -c1-240
grep -q "ready in idle" "$LOG"
