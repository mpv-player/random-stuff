Speaker test
============
The files named speaker_test*.avi are intended to test surround setups, as well
as media player audio downmixing. The file gen.py was used to generates these
files. The avi file format is used, because it seems to be the only format that
ffmpeg can read/write correctly and which supports all possible audio channel
layouts, even extremely obscure ones.

The file channel_layout_order_tred.png additionally show the relation between
multiple layouts. Each edge means you have to add some speakers (without
removing any) to get the new layout. The edges are labeled with the short names
of the speaker which are added.
