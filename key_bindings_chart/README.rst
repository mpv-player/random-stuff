Chart of default keybindings
============================
Based on the key bindings chart of some other project (see left/bottom in the
SVG). Edited with Inkscape. Also, I'm not very inkscape proficient, and there
are some issues, such as text and key boxes not being properly aligned.

Basically, this is waiting for someone to finish it properly.

Compression
-----------
Some images in this repository are compressed to save bandwidth with serving
files from the GitHub repository. Those files have the ``_compressed`` suffix.

The PNG image is compressed with `pngquant <https://github.com/pornel/pngquant>`_.
The SVG image with `scour <http://www.codedread.com/scour/>`_.

A shell script named ``compress.sh`` is made for making the process more convenient.

Contributing
------------

As already stated, the chart is edited with Inkscape. The steps necessary for making a contribution:

1. Make your changes with Inkscape and save the file.
2. Export it as PNG. Make sure to export the whole page and not just the drawing.
3. Run the ``compress.sh`` shell script.
4. Commit and push your changes.
5. Make a pull request.
