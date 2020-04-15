#!/usr/bin/env python3

#
# This file is part of mpv.
#
# mpv is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# mpv is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with mpv.  If not, see <http://www.gnu.org/licenses/>.
#

import binascii
import io
import os
import sys

class Elem:

    def __init__(self, ebml_id, sub = None):
        self.ebml_id = ebml_id
        self.sub = sub

files = []
outfile = None
fps = 25
for i in sys.argv[1:]:
    if i.startswith("--o="):
        assert outfile is None
        outfile = open(i[4:], "wb")
    elif i.startswith("--fps="):
        fps = float(i[6:])
    elif i.startswith("-"):
        print("Unknown option '%s'" % i)
        print("Usage: %s --fps=25 --o=outfile.mkv infile1.png infile2.png ..." %
              sys.argv[0])
        exit(1)
    else:
        files.append(open(i, "rb").read())

if outfile is None or not files:
    print("no")
    exit(1)

global duration
duration = 0

global clusters
clusters = []

for f in files:
    # Making each image its own cluster is slightly wasteful, but simpler.
    data = io.BytesIO()
    data.write((0x80 | 1).to_bytes(1, "big")) # Track Number
    data.write((0).to_bytes(2, "big")) # block Timestamp (relative to cluster's)
    data.write((0).to_bytes(1, "big")) # Block Header flags
    data.write(f)

    block_duration = 1.0 / fps

    clusters.append(
        Elem('1f43b675', [ # Cluster
            Elem('e7', int(duration * 1e9 / 1000000)), # Timestamp
            Elem('a0', [ # BlockGroup
                Elem('a1', data.getvalue()), # Block
                Elem('9b', int(block_duration  * 1e9 / 1000000)), # BlockDuration
            ])
        ])
    )

    duration += block_duration

def write_elem(dst, elem):
    dst.write(binascii.unhexlify(elem.ebml_id))

    content = io.BytesIO()

    val = elem.sub
    if type(val) == int:
        # EBML/Matroska does have signed integers. But whether a value is signed
        # or unsigned (i.e. meaning of the MSB) depends on the element ID.
        # The Python type is ambiguous for this purpose. Fortunately, we use
        # only unsigned elements.
        assert(val >= 0)
        blen = max((val.bit_length() + 7) // 8, 1)
        assert(blen <= 8)
        #debug print(val, val.to_bytes(blen, "big"))
        content.write(val.to_bytes(blen, "big"))
    elif type(val) == float:
        # Why the fuck do integers have to_bytes, but floats don't?
        import struct
        content.write(struct.pack(">f", val))
    elif type(val) == str:
        content.write(val.encode("utf-8"))
    elif type(val) == bytes:
        content.write(val)
    elif type(val) == list:
        for sub in val:
            write_elem(content, sub)
    else:
        assert False, "Unknown type %s" % type(val)

    buf = content.getvalue()

    # element length
    e_len = len(buf)
    num_bytes = -1
    for i in range(1, 9):
        if e_len < 2 ** (i * 8 - i) - 1:
            num_bytes = i
            break
    assert(num_bytes >= 0 and num_bytes <= 8)
    mask = 2 ** (8 - num_bytes)
    len_bytes = e_len.to_bytes(num_bytes, "big")
    dst.write((len_bytes[0] | mask).to_bytes(1, "big"))
    dst.write(len_bytes[1:])

    dst.write(buf)

header = Elem('1a45dfa3', [ # EMBL
    Elem('4286', 1), # EBMLVersion
    Elem('42f7', 1), # EBMLReadVersion
    Elem('42f2', 4), # EBMLMaxIDLength
    Elem('42f3', 8), # EBMLMaxSizeLength
    Elem('4282', "matroska"), # DocType
    Elem('4287', 2), # DocTypeVersion
    Elem('4285', 2), # DocTypeReadVersion
])

segment = Elem('18538067', [ # Segment
    Elem('1549a966', [ # Info
        Elem('4d80', "shitty python script"), # MuxingApp
        Elem('5741', "sorry I don't know"), # WritingApp
        Elem('2ad7b1', 1000000), # TimestampScale
        # The stuff the Matroska devs smoked, was it xiph-laced with lead?
        Elem('4489', duration * 1e9 / 1000000), # Duration
    ]),
    Elem('1654ae6b', [ # Tracks
        Elem('ae', [ # TrackEntry
            Elem('d7', 1), # TrackNumber
            Elem('73c5', 1), # TrackUID
            Elem('83', 1), # TrackType
            Elem('23e383', int((1.0 / fps) * 1e9)), # DefaultDuration
            Elem('86', "V_PNG"), # CodecID
            # Note: elements like video dimension are probably required normally,
            # but I can't be arsed.
            Elem('e0', []), # Video
        ]),
    ]),
    # Note: you could avoid buffering all clusters in memory by picking smaller
    # clusters, and using "unknown size" for the segment EBML size, or reserve
    # the maximum for it.
] + clusters)

write_elem(outfile, header)
write_elem(outfile, segment)
outfile.close()

exit(1)
