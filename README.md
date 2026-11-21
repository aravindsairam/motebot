# MOTEbot

A robot vacuum cleaner, built from scratch and tested fully in simulation. It has the robot's own software, an Android app to control it, and simulated homes to clean.

![The six room home seen from above](https://raw.githubusercontent.com/aravindsairam/motebot_sim/main/assets/previews/home_overview.png)

## What it does

- **Maps a home.** You drive it around, or it explores every room alone.
- **Goes where you point.** Tap a spot on the map and it finds its way there.
- **Cleans.** Neat back and forth rows, one room at a time, around furniture and no-go zones.
- **Docks.** It drives home and parks on its charger, within half a centimetre.
- **Stays safe.** It stops at stairs and backs away from bumps, whoever is driving.
- **Has an app.** Live map, camera, joystick and cleaning controls on an Android phone.

Every feature has a test that checks the robot against what is really true in the simulator.

## The parts

| Part | What it is |
|---|---|
| [Robot software](https://github.com/aravindsairam/motebot_robot) | ROS 2 Humble and Nav2: modes, safety, mapping, navigation, cleaning, docking |
| [Simulator](https://github.com/aravindsairam/motebot_sim) | Isaac Sim 6.2: two homes, the robot with its sensors, and the tests |
| [App](https://github.com/aravindsairam/motebot_app) | Android, React Native: map, camera and controls |

It also uses forks of [slam_toolbox](https://github.com/aravindsairam/slam_toolbox) for mapping and [frontier_exploration_ros2](https://github.com/aravindsairam/frontier_exploration_ros2) for exploring.

## Setup

You need Ubuntu 22.04, an NVIDIA RTX graphics card, ROS 2 Humble and [Isaac Sim 6.2](https://docs.isaacsim.omniverse.nvidia.com) unpacked at `~/isaacsim`.

```bash
git clone --recursive https://github.com/aravindsairam/motebot
cd motebot/ros2_ws
source /opt/ros/humble/setup.bash
rosdep install --from-paths src --ignore-src -y
pip3 install --user 'websockets>=13' 'protobuf>=6.31' aiortc aiohttp
colcon build --symlink-install
cd ..
```

## Run

Start the simulator, then the robot:

```bash
tools/start_sim.sh      # the house and the robot, in Isaac Sim
tools/start_stack.sh    # the robot software, with RViz
```

Now tell the robot what to do:

```bash
source ros2_ws/install/setup.bash
ros2 run vacuum_mode_manager mode navigation    # then pick a goal in RViz with "2D Goal Pose"
ros2 run vacuum_coverage clean                  # clean the whole home, then dock
ros2 run vacuum_exploration explore             # make a new map without help
tools/stop_all.sh                               # stop everything
```

For the bigger home, start the simulator with `tools/start_sim.sh --world home`.

## The app

You need Node.js 22, Java 17 and the Android SDK with an emulator. If they are in `~/Android`, `source tools/app_env.sh` sets them up.

With the simulator and the robot running, start the emulator and run:

```bash
cd app
npm install
npx expo run:android
```

On the Connect screen, type the address of the PC. From the emulator that is `10.0.2.2`.

## Tests

```bash
tools/run_tests.sh 6       # one test: navigation
tools/run_tests.sh         # everything in the house, about four and a half hours
tools/run_tests.sh home    # everything in the home, about two and a half hours
```

## License

Apache 2.0
