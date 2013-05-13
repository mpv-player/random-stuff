FFMPEG_PATH="ffmpeg"
# needed by ffmpeg's vf_drawtext
FONTFILE="/usr/share/fonts/truetype/msttcorefonts/Verdana.ttf"
CLIP_LEN=1

import subprocess
import os

# Warning: the speakers are implicitly assumed to be in order, otherwise the
#          generated files will be incorrect
layouts = [
    ["mono",            "fc"],
    ["stereo",          "fl-fr"],
    ["2.1",             "fl-fr-lfe"],
    ["3.0",             "fl-fr-fc"],
    ["3.0(back)",       "fl-fr-bc"],
    ["4.0",             "fl-fr-fc-bc"],
    ["quad",            "fl-fr-bl-br"],
    ["quad(side)",      "fl-fr-sl-sr"],
    ["3.1",             "fl-fr-fc-lfe"],
    ["5.0",             "fl-fr-fc-bl-br"],
    ["5.0(side)",       "fl-fr-fc-sl-sr"],
    ["4.1",             "fl-fr-fc-lfe-bc"],
    ["5.1",             "fl-fr-fc-lfe-bl-br"],
    ["5.1(side)",       "fl-fr-fc-lfe-sl-sr"],
    ["6.0",             "fl-fr-fc-bc-sl-sr"],
    ["6.0(front)",      "fl-fr-flc-frc-sl-sr"],
    ["hexagonal",       "fl-fr-fc-bl-br-bc"],
    ["6.1",             "fl-fr-fc-lfe-bc-sl-sr"],
    ["6.1(back)",       "fl-fr-fc-lfe-bl-br-bc"],
    ["6.1(front)",      "fl-fr-lfe-flc-frc-sl-sr"],
    ["7.0",             "fl-fr-fc-bl-br-sl-sr"],
    ["7.0(front)",      "fl-fr-fc-flc-frc-sl-sr"],
    ["7.1",             "fl-fr-fc-lfe-bl-br-sl-sr"],
    ["7.1(wide)",       "fl-fr-fc-lfe-bl-br-flc-frc"],
    ["7.1(wide-side)",  "fl-fr-fc-lfe-flc-frc-sl-sr"],
    ["octagonal",       "fl-fr-fc-bl-br-bc-sl-sr"],
    ["downmix",         "dl-dr"],
]

long_names = {
    "fl":   "front left",
    "fr":   "front right",
    "fc":   "front center",
    "lfe":  "low frequency",
    "bl":   "back left",
    "br":   "back right",
    "flc":  "front left-of-center",
    "frc":  "front right-of-center",
    "bc":   "back center",
    "sl":   "side left",
    "sr":   "side right",
    "tc":   "top center",
    "tfl":  "top front left",
    "tfc":  "top front center",
    "tfr":  "top front right",
    "tbl":  "top back left",
    "tbc":  "top back center",
    "tbr":  "top back right",
    "dl":   "downmix left",
    "dr":   "downmix right",
    "wl":   "wide left",
    "wr":   "wide right",
    "sdl":  "surround direct left",
    "sdr":  "surround direct right",
    "lfe2": "low frequency 2",
}

for name, speakers_str in layouts:
    print("Generating " + name)
    speakers = speakers_str.split("-")
    speaker_files = []
    for idx, speaker in enumerate(speakers):
        # why avi? it can carry pcm with _all_ waveext channel layouts
        speaker_file = "tmp_clip" + name + "_" + speaker + ".avi"
        long_name = long_names[speaker]
        parts = (["0" for i in range(0, idx)] +
                 ["sin(440*2*PI*t)"] +
                 ["0" for i in range(idx + 1, len(speakers))])
        display = "\\'" + name + ": " + speaker + " (" + long_name + ")\\'"
        lavc_layout = "+".join(speakers).upper()
        agraph = "aevalsrc=exprs=" + "|".join(parts) + ":s=8000:c=" + lavc_layout
        vgraph = ("color=s=1024x128:c=white," +
                  "drawtext=text=" + display + ":fontfile=" + FONTFILE + ":box=1:fontsize=72:x=20:y=(h-text_h)/2")
        graph = agraph + " [out0] ; " + vgraph + " [out1]"
        subprocess.check_call([FFMPEG_PATH, "-f", "lavfi", "-i", graph,
            "-codec:a:0", "pcm_u8", "-codec:v:0", "rawvideo", "-t", str(CLIP_LEN),
            "-y", speaker_file])
        speaker_files.append(speaker_file)
    # now concatenate the clips (doing this separately in 2 phases is much simpler)
    # for some retarded reasons, ffmpeg can concat files only if they're in a text file (sigh...)
    concat_file = "tmp_concat_" + name + ".txt"
    f = file(concat_file, "w")
    for entry in speaker_files:
        f.write("file " + entry + "\n")
    f.close()
    outfile = "speaker_test_" + name + ".avi"
    subprocess.check_call([FFMPEG_PATH, "-f", "concat", "-i", concat_file,
        "-codec:a:0", "pcm_s16le", "-y", outfile])
    os.unlink(concat_file)
    for entry in speaker_files:
        os.unlink(entry)

