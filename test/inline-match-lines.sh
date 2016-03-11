# Inline matching method: --lines
# Count the number of lines in the output

$ a=1                           #=> --lines 0
$ echo 'ok'                     #=> --lines 1
$ printf '1\n2\n3\n'            #=> --lines 3

# Lines without the final \n count as one full line

$ printf 'no-nl'                #=> --lines 1
$ printf '1\n2\nno-nl'          #=> --lines 3

# The error message is a short sentence, not a diff
# Example: Expected 99 lines, got 1.

$ echo 'fail'                   #=> --lines 99
$ echo 'fail'                   #=> --lines 0

# Syntax: Must be exactly one space before and after --lines

$ echo 'fail'                   #=>   --lines fail with 2 spaces
$ echo 'fail'                   #=> --lines	fail with tab

# Syntax: The space after --lines is required.
# When missing, the '--lines' is considered a normal text.

$ echo '--lines'                 #=> --lines

# Syntax: Make sure we won't catch partial matches.

$ echo '--linesout'             #=> --linesout

# Syntax: To insert a literal text that begins with '--lines '
#         just prefix it with --text.

$ echo '--lines is cool'         #=> --text --lines is cool


# Note: The following are tested in separate files:
#       inline-match-lines-error-?.sh
#
# Syntax: Empty inline output contents are considered an error
#
# $ echo 'no contents'          #=> --lines 
#
# Syntax: Must be an integer number
# 
# $ echo 'fail'                 #=> --lines -1
# $ echo 'fail'                 #=> --lines 1.0
# $ echo 'fail'                 #=> --lines foo

