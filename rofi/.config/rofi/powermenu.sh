#!/usr/bin/env bash

dir="$HOME/.config/rofi"
theme='style-1'

options="󰌾 Lock\n󰍃 Logout\n󰤄 Suspend\n󰤆 Hibernate\n󰐥 Shutdown\n󰑓 Reboot"

chosen=$(echo -e "$options" | rofi -dmenu -i -theme ${dir}/${theme}.rasi -p "Power" -lines 1 -columns 6)

case $chosen in
    "󰌾 Lock") hyprlock & ;;
    "󰍃 Logout") loginctl terminate-user $USER ;;
    "󰤄 Suspend") systemctl suspend ;;
    "󰤆 Hibernate") systemctl hibernate ;;
    "󰐥 Shutdown") systemctl poweroff ;;
    "󰑓 Reboot") systemctl reboot ;;
esac