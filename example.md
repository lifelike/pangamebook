---
title: Pangamebook Gamebook Example
author: Pelle Nilsson
gamebook-gap: 3
---
This is just an example to give new users and idea where to start. See [Pandoc
Getting Started Article](https://pandoc.org/getting-started.html) and
[PangamebookREADME](README.md) for more information.

The lines at the very top of this file are needed to add some metadata
for the book. Otherwise there are ugly warnings when creating EPUB files
and possibly for other formats as well. Good to always include some
lines like that. Normally they are invisible and should not show
up in the output at all.

It is also possible to configure some aspects of Pangamebook by setting
some other metadata variables. In this file the variable *gamebook-gap*
is set to 3. That configures how far to try to make the distance between
sections that are adjacent in this input document. For a long book
a good value is something that makes the gap between sections just enough
that they do not end up on the same page (or spread of pages) in a printed
version of the book. But it should always be much lower than
the total number of sections in the book, which is why it has been set
so low for this example file.

# Introduction
Sections with a header like this one will not be affected by the Pangamebook
filter, as described in the README.

# 1
This is where the story begins. That the header says just 1 like that means
that Pangamebook will keep that number and put this first in the
generated document. If there is no section numbered 1 the section
that is listed first will be used as 1 (the assumed starting section
of the book; although of course you are free to direct players to begin
reading some other section!).

From here you can move on to [second] or [third] section. If you read
this in the original Markdown file (example.md) you can tell that
the names of those sections are used as links (in square brackets).
Running Pandoc with the Pangamebook filter will change the links
to the correct numbers after shuffling all sections, so "second"
and "third" might end up not being 2 or 3 at all. When
*gamebook-gap* is set to 3, the second and third sections
will end up having numbers 4 and 7.

# second
This is the first header in the book that Pangamebook will see. Only
lower-case letters. It could have had some digits and underscores in
there as well, but anything else will make Pangamebook think it is
not part of the story you want to shuffle or number.
Here is another link to the third section: [third]. You
can also go on to [some_other_section].

# third
Just another example section. Did you know that you can put images and tables
and many other useful things in Pandoc Markdown files? There are no examples of
that here, but it can be useful to know. Guess the story ends here as there are
no links going out from this section.

# 5
Another header that is already a number. If you paid attention to
the description in the [README](README.md) you know that this
section will not be shuffled with other sections.

# some_other_section
This is just to continue the example with something after
section [5] that was fixed, and that this should always
have number 6 or higher. The story ends in section [10].

# unreached
There are not links to this section, but it should still
show up.

# 10
This ends the story. Most books have a best ending that has
the highest number in the book. Setting this to 10 here leaves
some margins if a few more sections are added before.

# Epilogue
Of course some non-gamebook sections like this can show up
later in the book as well. Remember Capitalized Headings
are ignored.

