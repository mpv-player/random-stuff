#!/bin/sh

# Image settings
image_format="png"
size="100x100"

# Video settings
fps="30"
seconds="2"

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

for_each_color () {
    cmd="$1"
    shift

    "$cmd" red "$@"
    "$cmd" blue "$@"
    "$cmd" green "$@"
    "$cmd" yellow "$@"
    "$cmd" white "$@"
    "$cmd" black "$@"
}

for_each_color create_image
for_each_color create_list
