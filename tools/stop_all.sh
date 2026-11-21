#!/bin/bash
# Stop the robot software stack and (unless --keep-sim is given) the simulator.
# Anything that ignores the first signal is force-killed, so no stale node survives to confuse
# the next launch.
# frontier_explor: the explorer, a child of the exploration node, not started by the launch file
ros_pat='^(async_slam_tool|robot_state_pub|rviz2|amcl|map_server|lifecycle_manag|controller_serv|planner_server|behavior_server|bt_navigator|costmap_filter_|mode_manager|safety_gate|apriltag_node|opennav_docking|dock_pose_publi|frontier_explor)'
ros_pids() { ps -eo pid,comm,args | awk -v pat="$ros_pat" '($2=="ros2" && /launch vacuum_bringup/) || $2 ~ pat || /lib\/vacuum_mode_manager\/mode_manager/ || /lib\/vacuum_gateway\/gateway/ || /lib\/vacuum_video\/video/ || /lib\/vacuum_coverage\/cleaning_node/ || /lib\/vacuum_exploration\/exploration_node/ {print $1}'; }
sim_pids() { ps -eo pid,comm,args | awk '$2 ~ /^(python|kit)/ && /sim\/scripts\// {print $1}'; }

pids=$(ros_pids); [ -n "$pids" ] && kill $pids 2>/dev/null
[ "$1" != "--keep-sim" ] && { pids=$(sim_pids); [ -n "$pids" ] && kill $pids 2>/dev/null; }
sleep 4
pids=$(ros_pids); [ -n "$pids" ] && { echo "force-killing leftover ROS processes: $pids"; kill -9 $pids 2>/dev/null; }
if [ "$1" != "--keep-sim" ]; then
  sleep 3
  pids=$(sim_pids); [ -n "$pids" ] && { echo "force-killing simulator: $pids"; kill -9 $pids 2>/dev/null; }
fi
exit 0
