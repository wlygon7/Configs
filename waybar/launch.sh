#!/bin/bash
pkill waybar
sleep 0.3
setsid waybar >/dev/null 2>&1 &
