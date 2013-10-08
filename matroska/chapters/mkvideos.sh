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

# Create small videos of each color.
for_each_color create_image
for_each_color create_list
for_each_color create_video

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

        cat >> "$country.xml" <<CHAPTER
    <ChapterAtom>
      <ChapterUID>$RANDOM</ChapterUID>
      <ChapterTimeStart>00:00:00.000000000</ChapterTimeStart>
      <ChapterTimeEnd>00:00:$seconds.000000000</ChapterTimeEnd>
      <ChapterSegmentUID format="hex">$segment_uid</ChapterSegmentUID>
      <ChapterDisplay>
        <ChapterString>$color</ChapterString>
        <ChapterLanguage>eng</ChapterLanguage>
      </ChapterDisplay>
    </ChapterAtom>
CHAPTER
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
