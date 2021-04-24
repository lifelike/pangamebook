# Pangamebook
[Pandoc](https://pandoc.org) is a free tool that converts documents between a
large number of file formats. *Pangamebook* is a filter that can be used with
Pandoc to shuffle and number sections in the document being converted. The only
known use-case is to create a classic gamebook.

Pandoc and Pangamebook should run on most modern computers. It has been tested
on desktop computers running Linux (Lubuntu and Debian) and FreeBSD. Also on a
Raspberry Pi 4 running Raspberry Pi OS and on an Android phone (in Termux).

(TBD: Test in Windows 10 and OSX.)

# Installing
To use this filter you need to have Pandoc 2.1 or later installed (see
[https://pandoc.org/installing.html]). Also see the [Pandoc Getting Started
Article](https://pandoc.org/getting-started.html) if you never used Pandoc
before.

The Pangamebook filter itself does not have to be installed. The file
*pangamebook.lua* must be copied to somewhere on your computer and
named on the command-line when running pandoc (see examples below).

# Input Document
First you need to write your gamebook. The recommended format is [Pandoc's
Markdown](https://pandoc.org/MANUAL.html#pandocs-markdown). That is the format
used for this README file and there is also an *example.md* document in this
repository.

Other formats are also possible, but it can be tricky to make Pandoc and
Pangamebook to properly interpret cross-references in some formats. Also
Pandoc's Markdown supports inserting meta-data and inlining style information
that can be very useful for advanced users, so it can be a good idea to get used
to that format. Most modern text editors support Markdown, so
it should not be difficult to get started.

# What the Filter Does
Pangamebook looks for all top-level headers that contain of only lowercase
letters, digits, and underscores. Headers like *start*, *first_room*, or
*finding_some_loot_23* will be affected, but headers like *Introduction*, *How
To Play*, *Character Sheet*, or *Epilogue* will be ignored.

A top-level header that is a (positive) number will also be ignored, as that
number will be used as-is instead.

Pangamebook shuffles all affected headers together with everything that
follows it up until the next top-level header, including lower-level headers
and all text and images and tables etc. That collection of things that
is moved together with the header is considered a *section*.

Sections will never be moved from before an ignored top-level header to after
that header, or vice-versa. An important effect of this is that headers that are
numbers, like **1** will *stay where they are*, and will also naturally divide
the gamebook into parts that keeps the story from jump around too much. Most
books will probably have a **1** header to mark the beginning of the story, and
that will be guaranteed to remain the first one in the output as well. If the
last header has a sufficiently high number (say **400**) it will remain the
last. Any other header can also have a number to fix it in the story, but if
there are too many sections to shuffle in between fixed headers the filter will
not be happy (say if you fix **1** and **400**, but there are actually 410
sections in the book).

After shuffling all sections that are to be shuffled, all their headings
are numbered in sequence. There may be gaps created where there are
headers that were given a fixed number. Headers that were already numbers,
as mentioned above, will not be affected.

All cross-references in the document will lastly be updated to display
the number they refer to, so what was in the original document
"see first_room" (where *first_room* is a valid cross-reference, not just text)
will become someting like "see 12".

The best way to learn is probably to experiment with the included
*example.md* and skim some of Pandoc's documentation.

# Output Document
Most or all of the output formats Pandoc support should be possible (e.g. EPUB,
PDF, HTML). By default Pandoc is going to remove almost all styling from
documents as part of converting them, but see [Pandoc's User
Guide](https://pandoc.org/MANUAL.html) for information on all the ways you can
add style to the output document.

# Examples
The file *example.md* is a Pandoc Markdown example gamebook. Open your favorite
terminal and cd to this directory. The following commands can be used to
generate a PDF, EPUB, and HTML book:

    pandoc --lua-filter=pangamebook.lua -o example.html example.md
    pandoc --lua-filter=pangamebook.lua -o example.epub example.md
    pandoc --lua-filter=pangamebook.lua -o example.pdf example.md

(Pandoc needs *pdflatex* to be installed to generate a PDF. It will otherwise
complain loudly when you run that last line. How to install pdflatex is beyond
the scope of this README file.)

If you want to edit the generated book in a word processor it is also possible
to generate for instance a MS Word or LibreOffice Word document:

    pandoc --lua-filter=pangamebook.lua -o example.docx example.md
    pandoc --lua-filter=pangamebook.lua -o example.odt example.md

Manually editing the document after running Pandoc is probably a bad idea. Any
edits will have to be done again if the document is ever recreated. It is better
to read up on how to apply styles to the generated file, for instance by using a
template style Word document.

# Development
Bug reports and feature requests are welcome on GitHub. The goal is to keep this
tool very simple and focus on only numbering the sections. Additions are most
likely better done by creating additional Pandoc filters, leaving it to
end-users to decide what filters to combine.

Pangamebook is version managed using a private
[Fossil](https://fossil-scm.org/) repository. The git repository on GitHub is a
mirror that is updated with new releases.

# LICENSE
MIT License

Copyright (c) 2021 Pelle Nilsson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
