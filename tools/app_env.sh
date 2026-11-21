# Environment for building the Android app. Use it with:   source tools/app_env.sh
# Java 17 and the Android SDK live in ~/Android (installed in step 0 of the app, without sudo).
# The system's default Java is left alone; only shells that source this file use Java 17.
export JAVA_HOME="$HOME/Android/jdk-17"
export ANDROID_HOME="$HOME/Android/Sdk"
# The SDK's own adb comes first: mixing it with the older /usr/bin/adb makes the two restart
# each other's server and drop the phone.
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
# Node comes from nvm on this PC and is not on the PATH of a plain shell.
if ! command -v node >/dev/null 2>&1 && [ -s "$HOME/.nvm/nvm.sh" ]; then
  . "$HOME/.nvm/nvm.sh"
fi
