#!/usr/bin/env bash
hyprctl dispatch switchxkblayout 0 next 2>/dev/null || hyprctl dispatch switchxkblayout 1 next 2>/dev/null
