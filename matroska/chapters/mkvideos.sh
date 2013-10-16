#!/bin/sh

# Image settings
image_format="png"
size="100x100"

# Video settings
seconds="2"
fps="20"
codec="mpeg4"

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

extract_uids () {
    file="$1"
    shift

    mkv_info="$( mkvinfo -t "$file" )"

    segment_uid="$( printf "%s" "$mkv_info" | \
        grep -e "Segment UID" | \
        cut -d: -f2 | \
        cut -b2- )"
    edition_uids="$( printf "%s" "$mkv_info" | \
        grep -e " EditionUID" | \
        cut -d: -f2 | \
        cut -b2- )"
}

create_country_video () {
    country="$1"
    shift

    cat > "$country.xml" <<HEAD
<?xml version="1.0"?>
<!-- <!DOCTYPE Chapters SYSTEM "matroskachapters.dtd"> -->
<Chapters>
  <EditionEntry>
    <EditionUID>$RANDOM</EditionUID>
    <EditionFlagDefault>1</EditionFlagDefault>
    <EditionFlagOrdered>1</EditionFlagOrdered>
HEAD

    while [ "$#" -gt 0 ]; do
        color="$1"
        shift

        extract_uids "$color.mkv"

        if [ -n "$gap" ]; then
            cat >> "$country.xml" <<CHAPTER
    <ChapterAtom>
      <ChapterUID>$RANDOM</ChapterUID>
      <ChapterTimeStart>00:00:00.000000000</ChapterTimeStart>
      <ChapterTimeEnd>00:00:$end_gap</ChapterTimeEnd>
      <ChapterSegmentUID format="hex">$segment_uid</ChapterSegmentUID>
      <ChapterDisplay>
        <ChapterString>$color</ChapterString>
        <ChapterLanguage>eng</ChapterLanguage>
      </ChapterDisplay>
    </ChapterAtom>
    <ChapterAtom>
      <ChapterUID>$RANDOM</ChapterUID>
      <ChapterTimeStart>00:00:$start_gap</ChapterTimeStart>
      <ChapterTimeEnd>00:00:$seconds.000000000</ChapterTimeEnd>
      <ChapterSegmentUID format="hex">$segment_uid</ChapterSegmentUID>
      <ChapterDisplay>
        <ChapterString>$color</ChapterString>
        <ChapterLanguage>eng</ChapterLanguage>
      </ChapterDisplay>
    </ChapterAtom>
CHAPTER
        else
            begin="00.000000000"
            end="$seconds.000000000"

            [ -n "$begin_override" ] && \
                begin="$begin_override"

            [ -n "$end_override" ] && \
                end="$end_override"

            cat >> "$country.xml" <<CHAPTER
    <ChapterAtom>
      <ChapterUID>$RANDOM</ChapterUID>
      <ChapterTimeStart>00:00:$begin</ChapterTimeStart>
      <ChapterTimeEnd>00:00:$end</ChapterTimeEnd>
      <ChapterSegmentUID format="hex">$segment_uid</ChapterSegmentUID>
      <ChapterDisplay>
        <ChapterString>$color</ChapterString>
        <ChapterLanguage>eng</ChapterLanguage>
      </ChapterDisplay>
    </ChapterAtom>
CHAPTER
        fi
    done

    cat >> "$country.xml" <<TAIL
  </EditionEntry>
</Chapters>
TAIL

    mkvmerge "transparent.mkv" \
        --no-chapters \
        --chapters "$country.xml" \
        -o "$country.mkv"
}

create_continent_video () {
    continent="$1"
    shift

    cat > "$continent.xml" <<HEAD
<?xml version="1.0"?>
<!-- <!DOCTYPE Chapters SYSTEM "matroskachapters.dtd"> -->
<Chapters>
  <EditionEntry>
    <EditionUID>$RANDOM</EditionUID>
    <EditionFlagDefault>1</EditionFlagDefault>
    <EditionFlagOrdered>1</EditionFlagOrdered>
HEAD

    while [ "$#" -gt 1 ]; do
        country="$1"
        shift

        colors="$1"
        shift

        extract_uids "$country.mkv"
        edition_uid="$( echo "$edition_uids" | cut -d' ' -f1 )"

        for color_idx in $( seq 0 "$(( $colors - 1 ))" ); do
            begin="$(( $color_idx * $seconds ))"
            end="$(( $color_idx * $seconds + 2 ))"

            cat >> "$continent.xml" <<CHAPTER
    <ChapterAtom>
      <ChapterUID>$RANDOM</ChapterUID>
      <ChapterTimeStart>00:00:$begin.050000000</ChapterTimeStart>
      <ChapterTimeEnd>00:00:$end.000000000</ChapterTimeEnd>
      <ChapterSegmentUID format="hex">$segment_uid</ChapterSegmentUID>
      <ChapterSegmentEditionUID>$edition_uid</ChapterSegmentEditionUID>
      <ChapterDisplay>
        <ChapterString>$country-$color_idx</ChapterString>
        <ChapterLanguage>eng</ChapterLanguage>
      </ChapterDisplay>
    </ChapterAtom>
CHAPTER
        done
    done

    cat >> "$continent.xml" <<TAIL
  </EditionEntry>
</Chapters>
TAIL

    mkvmerge "transparent.mkv" \
        --no-chapters \
        --chapters "$continent.xml" \
        -o "$continent.mkv"
}

create_world_video () {
    cat > "world.xml" <<HEAD
<?xml version="1.0"?>
<!-- <!DOCTYPE Chapters SYSTEM "matroskachapters.dtd"> -->
<Chapters>
  <EditionEntry>
    <EditionUID>$RANDOM</EditionUID>
    <EditionFlagDefault>1</EditionFlagDefault>
    <EditionFlagOrdered>1</EditionFlagOrdered>
HEAD

    while [ "$#" -gt 1 ]; do
        continent="$1"
        shift

        colors="$1"
        shift

        extract_uids "$continent.mkv"
        edition_uid="$( echo "$edition_uids" | cut -d' ' -f1 )"

        for color_idx in $( seq 0 "$(( $colors - 1 ))" ); do
            begin="$(( $color_idx * $seconds ))"
            end="$(( $color_idx * $seconds + 1 ))"

            cat >> "world.xml" <<CHAPTER
    <ChapterAtom>
      <ChapterUID>$RANDOM</ChapterUID>
      <ChapterTimeStart>00:00:$begin.000000000</ChapterTimeStart>
      <ChapterTimeEnd>00:00:$end.000000000</ChapterTimeEnd>
      <ChapterSegmentUID format="hex">$segment_uid</ChapterSegmentUID>
      <ChapterSegmentEditionUID>$edition_uid</ChapterSegmentEditionUID>
      <ChapterDisplay>
        <ChapterString>$continent-$color_idx</ChapterString>
        <ChapterLanguage>eng</ChapterLanguage>
      </ChapterDisplay>
    </ChapterAtom>
CHAPTER
        done
    done

    cat >> "world.xml" <<TAIL
  </EditionEntry>
</Chapters>
TAIL

    mkvmerge "transparent.mkv" \
        --no-chapters \
        --chapters "world.xml" \
        -o "world.mkv"
}

create_videos () {
    variant="$1"
    shift

    mkdir -p "$variant"
    cd "$variant"

    # Create small videos of each color.
    for_each_color create_image
    for_each_color create_list
    for_each_color create_video

    # Create a dummy base video.
    create_image transparent
    echo "transparent.$image_format" > "transparent.txt"
    create_video transparent

    create_country_video america red white blue
    create_country_video canada red white red
    create_country_video germany black red yellow
    create_country_video france blue white red
    create_country_video japan white red
    create_country_video china red yellow

    create_continent_video north-america america 3 canada 3
    create_continent_video europe germany 3 france 3
    create_continent_video asia japan 2 china 2

    create_world_video north-america 6 europe 6 asia 4

    cd ..
}

# Create the standard videos.
create_videos "standard"

# Create videos which use countries after they start.
begin_override="$seconds.050000000"
end_override="$(( 2 * $seconds )).05000000"
create_videos "start-after-end"
begin_override=
end_override=

# Create videos which extend past the end of the source video.
end_override="$seconds.050000000"
create_videos "end-after-end"
end_override=

# Create videos in which chapters get stitched together into a single timeline
# part.
gap="yes"
end_gap="01.050000000"
start_gap="00.950000000"
create_videos "negative-gap"
end_gap="00.950000000"
start_gap="01.050000000"
create_videos "positive-gap"
gap=
end_gap=
start_gap=
