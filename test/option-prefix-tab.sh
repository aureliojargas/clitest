# Test file for the --prefix option
# Command blocks here are prefixed by a tab
# Run with --prefix '\t' or --prefix tab

	$ echo "1"  #=> 1
	$ echo "2"
	2

# Any non-prefixed line closes the previous command block.
# The empty $ line is not needed.

# All other non-indented text is just ignored:

$ echo "ignored"  # not indented
$ echo "ignored"  #=> not indented

# Lines with the wrong indentation are also ignored

		$ echo "ignored"  # 2 tabs
        $ echo "ignored"  # 8 spaces
    $ echo "ignored"  # 4 spaces

# Multiple blocks supported in a single file

	$ echo "3"
	3

# What about prefixed blocks with no commands?

	Prefixed line with no prompt: ignored.
	But wait, here comes a command:
	$ echo "4"
	4
	$
	Last command closed by the empty prompt.
	$ echo "5"  #=> 5
	Last command is auto-closed (inline output).

# Blank lines in the output are supported

	$ echo; echo "6"; echo; echo "7"
	
	6
	
	7

# Nice.
