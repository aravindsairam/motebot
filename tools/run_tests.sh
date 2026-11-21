#!/bin/bash
# Run acceptance tests, each on a freshly started simulator (and robot stack where the test needs it).
#   tools/run_tests.sh            all thirty-two phases, about four and a half hours
#   tools/run_tests.sh 8          only the safety test
#   tools/run_tests.sh 4 5 6      several, in the order given
#   tools/run_tests.sh cleaning   the cleaning phases 18 to 26 (about 75 minutes, half of it phase 20)
#   tools/run_tests.sh exploring  the exploring phases 28 to 32 (about an hour, half of it phase 30)
#   tools/run_tests.sh home       the home world's phases 33 and 35 to 39 (about two hours; not part of the everyday run)
# Everything runs headless and without RViz. Whatever is running is stopped first, and
# everything is stopped again at the end.
# Full output: logs/tests.log. A one-line result per check is printed as the tests run.
# Close the Android emulator first: it takes a CPU core and 4 GB, and with it running the dock tag
# detector fell behind the camera (phase 10 "parked": tag in 83% of frames instead of 100%).
R="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
OUT="$R/logs/tests.log"; mkdir -p "$R/logs"; : > "$OUT"
[ $# -eq 0 ] && set -- 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32
[ "$1" = cleaning ] && set -- 18 19 20 21 22 23 24 25 26
[ "$1" = exploring ] && set -- 28 29 30 31 32
[ "$1" = home ] && set -- 33 39 35 36 38 37
failed=0

show() { grep -E "^\[(PASS|FAIL)\]|^SUMMARY" | cut -c1-200; }

run() {  # name, needs stack (yes/no), test file, simulator arguments...  (PHASE_WORLD=home for the home's phases)
  local name=$1 stack=$2 test=$3 world=${PHASE_WORLD:-house}; shift 3
  echo "=== $name" | tee -a "$OUT"
  "$R/tools/stop_all.sh" >/dev/null 2>&1; sleep 2
  if ! "$R/tools/start_sim.sh" --headless --world "$world" "$@" >> "$OUT" 2>&1; then
    echo "simulator did not start" | tee -a "$OUT"; failed=1; return
  fi
  sleep 3
  # STACK_ARGS: more launch arguments for one phase (phase 28 leaves the exploration node out)
  if [ "$stack" = yes ] && ! "$R/tools/start_stack.sh" rviz:=false $STACK_ARGS >> "$OUT" 2>&1; then
    echo "robot stack did not start (see logs/stack.log)" | tee -a "$OUT"; failed=1; return
  fi
  ( source /opt/ros/humble/setup.bash
    [ "$stack" = yes ] && source "$R/ros2_ws/install/setup.bash"
    cd "$R" && VACUUM_WORLD=$world timeout "${TEST_TIMEOUT:-1500}" python3 -u "$test" ) 2>&1 | tee -a "$OUT" | show
  [ "${PIPESTATUS[0]}" -ne 0 ] && failed=1
}

for phase in "$@"; do
  case $phase in
    1) run "phase 1: driving" no sim/tests/phase1_drive_test.py --no-noise ;;
    2) run "phase 2: sensors" no sim/tests/phase2_sensor_test.py --no-noise ;;
    3) run "phase 3: sensor noise" no sim/tests/phase3_noise_test.py ;;
    4) run "phase 4: mapping" yes sim/tests/phase4_mapping_test.py ;;
    5) run "phase 5: localization" yes sim/tests/phase5_localization_test.py ;;
    6) run "phase 6: navigation" yes sim/tests/phase6_navigation_test.py ;;
    7) run "phase 7: mode manager" yes sim/tests/phase7_mode_manager_test.py ;;
    8) run "phase 8: safety gate" yes sim/tests/phase8_safety_test.py ;;
    9) run "phase 9: dock detection" yes sim/tests/phase9_dock_detection_test.py ;;
    10) run "phase 10: docking" yes sim/tests/phase10_docking_test.py ;;
    11) run "phase 11: app gateway" yes sim/tests/phase11_gateway_test.py ;;
    12) run "phase 12: app commands" yes sim/tests/phase12_app_commands_test.py ;;
    13) run "phase 13: live map" yes sim/tests/phase13_live_map_test.py ;;
    14) run "phase 14: go to a point" yes sim/tests/phase14_go_to_test.py ;;
    15) run "phase 15: joystick" yes sim/tests/phase15_joystick_test.py ;;
    16) run "phase 16: new map from the app" yes sim/tests/phase16_new_map_test.py ;;
    17) run "phase 17: camera video" yes sim/tests/phase17_camera_test.py ;;
    18) run "phase 18: cleaning mode and preview" yes sim/tests/phase18_cleaning_mode_test.py ;;
    19) run "phase 19: cleaning a small area" yes sim/tests/phase19_small_area_test.py ;;
    20) TEST_TIMEOUT=4200 run "phase 20: cleaning the whole house" yes sim/tests/phase20_whole_house_test.py ;;
    21) run "phase 21: pause, resume, stop" yes sim/tests/phase21_pause_resume_test.py ;;
    22) run "phase 22: cleaning from the app gateway" yes sim/tests/phase22_cleaning_gateway_test.py ;;
    23) run "phase 23: areas and spots" yes sim/tests/phase23_area_spot_test.py ;;
    24) run "phase 24: saved cleaning plans" yes sim/tests/phase24_saved_plans_test.py ;;
    25) run "phase 25: cleaning history" yes sim/tests/phase25_history_test.py ;;
    26) TEST_TIMEOUT=2400 run "phase 26: edges and two passes" yes sim/tests/phase26_edges_passes_test.py ;;
    27) run "phase 27: changing the no-go zones" yes sim/tests/phase27_zones_test.py ;;
    28) STACK_ARGS=exploration:=false run "phase 28: exploring mode" yes sim/tests/phase28_exploring_mode_test.py ;;
    29) run "phase 29: the exploration node, a first run" yes sim/tests/phase29_first_exploration_test.py ;;
    30) TEST_TIMEOUT=2700 run "phase 30: the whole house, explored" yes sim/tests/phase30_whole_house_exploration_test.py ;;
    31) run "phase 31: exploring when things go wrong" yes sim/tests/phase31_exploration_failures_test.py ;;
    32) run "phase 32: exploring from the app gateway" yes sim/tests/phase32_exploration_gateway_test.py ;;
    # --- the home world (docs/2026-11-19-bigger-home-plan.md) ---
    33) PHASE_WORLD=home run "phase 33: the home itself" no sim/tests/phase33_home_world_test.py --no-noise ;;
    35) PHASE_WORLD=home TEST_TIMEOUT=3600 run "phase 35: the home, explored" yes sim/tests/phase35_home_exploration_test.py ;;
    36) PHASE_WORLD=home run "phase 36: going places in the home" yes sim/tests/phase36_home_going_places_test.py ;;
    37) PHASE_WORLD=home TEST_TIMEOUT=6000 run "phase 37: the whole home cleaned" yes sim/tests/phase37_whole_home_test.py ;;
    38) PHASE_WORLD=home run "phase 38: speed in the home" yes sim/tests/phase38_home_speed_test.py ;;
    39) PHASE_WORLD=home run "phase 39: two worlds, one switch" no sim/tests/phase39_world_switch_test.py ;;
    *) echo "unknown phase '$phase' (use 1 to 33, 35 to 39, cleaning, exploring or home)"; failed=1 ;;
  esac
done
"$R/tools/stop_all.sh" >/dev/null 2>&1
[ $failed -eq 0 ] && echo "ALL REQUESTED PHASES PASSED" || echo "SOMETHING FAILED (see logs/tests.log)"
exit $failed
