#!/bin/sh
sleep 2
setxkbmap -print -layout custom -option lv3:ralt_switch -I"$HOME/.config/xkb" | xkbcomp -I"$HOME/.config/xkb" -w 0 - "$DISPLAY"
