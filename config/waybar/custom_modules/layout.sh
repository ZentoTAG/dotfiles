#!/usr/bin/env bash

# Проверяем текущую раскладку
current=$(setxkbmap -query 2>/dev/null | grep layout | awk '{print $2}')

if [[ "$current" == "us" ]]; then
    setxkbmap -layout ru 2>/dev/null
else
    setxkbmap -layout us 2>/dev/null
fi
