#!/bin/bash
echo "TEST: $1" > /tmp/waybar_test.log
hyprctl dispatch "hl.dsp.focus({ workspace = $1 })"
