#!/bin/sh
scour -i mpbindings.svg -o mpbindings_compressed.svg
pngquant mpbindings.png --output mpbindings_compressed.png -f
