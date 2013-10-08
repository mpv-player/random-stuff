#!/bin/sh

exit_status=0

check_program () {
    program="$1"
    shift

    printf "Looking for %s..." "$program"
    if command -v "$program" >/dev/null 2>/dev/null; then
        echo "found."
    else
        echo "not found."
        exit_status=1
    fi
}

check_program mpv
check_program convert
check_program mkvmerge
check_program mkvinfo

exit "$exit_status"
