#!/usr/bin/env bash
# Waybar audio visualizer: streams cava's raw output as block-bar glyphs.
# The glyphs ▁▂▃▄▅▆▇█ are generated from their UTF-8 bytes at runtime so
# this script file stays pure ASCII (avoids any glyph-encoding issues).

b0=$(printf '\342\226\201'); b1=$(printf '\342\226\202'); b2=$(printf '\342\226\203'); b3=$(printf '\342\226\204')
b4=$(printf '\342\226\205'); b5=$(printf '\342\226\206'); b6=$(printf '\342\226\207'); b7=$(printf '\342\226\210')

# map cava's ascii levels 0-7 to the bar glyphs (and strip any delimiters)
dict="s/;//g;s/0/$b0/g;s/1/$b1/g;s/2/$b2/g;s/3/$b3/g;s/4/$b4/g;s/5/$b5/g;s/6/$b6/g;s/7/$b7/g"

config_file="$HOME/.config/waybar/cava-config"
cava -p "$config_file" | sed -u "$dict"
