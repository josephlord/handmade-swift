#!/bin/zsh

# These will get moved out of here eventually.
PLATFORM=osx
CONFIGURATION=debug
LANGUAGE=swift

function setTerminalColors {
    osascript \
        -e "tell application \"Terminal\"" \
        -e "tell selected tab of front window" \
        -e "set normal text color to $1" \
        -e "set background color to $2" \
        -e "end tell" \
        -e "end tell"
}

cd ~/Projects/owensd.io/handmade/$LANGUAGE

echo -n -e "\033]0;handmade hero ($LANGUAGE) ($PLATFORM) ($CONFIGURATION)\007\c"
setTerminalColors "{55289,55289,55289}" "{4352, 11776, 13568}"

clear
echo "\e[33mHandmade Hero build environment successfully initialized.\e[m"

# Required to keep the shell alive when double-clicking the command file.
$SHELL
