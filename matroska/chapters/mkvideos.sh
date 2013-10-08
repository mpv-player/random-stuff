#!/bin/sh

# Image settings
image_format="png"
size="100x100"

# Video settings
seconds="2"
fps="20"
codec="libtheora"

create_image () {
    color="$1"
    shift

    convert -size "$size" "xc:$color" "$color.$image_format"
}

create_list () {
    color="$1"
    shift

    count="$(( $fps * $seconds ))"
    printf "%${count}s" "" | sed -e "s/ /$color.$image_format\n/g" > "$color.txt"
}

create_video () {
    color="$1"
    shift

    mpv -v "mf://@$color.txt" -o "$color.mkv" \
        -fps "$fps" \
        -ofps "$fps" \
        -vo null \
        -vf scale \
        -ovc "$codec"
}

for_each_color () {
    cmd="$1"
    shift

    "$cmd" red "$@"
    "$cmd" blue "$@"
    "$cmd" yellow "$@"
    "$cmd" white "$@"
    "$cmd" black "$@"
}

# Create small videos of each color.
for_each_color create_image
for_each_color create_list
for_each_color create_video
