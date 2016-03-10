# Inline matching method: --exit
# Matches the test exit code.

$ true                          #=> --exit 0
$ false                         #=> --exit 1
$ sh -c 'exit 3'                #=> --exit 3
$ command-not-found             #=> --exit 127

# STDIN and STDOUT are ignored when using --exit

$ echo "STDOUT ignored"         #=> --exit 0
This output will be ignored.
$ cut                           #=> --exit 1
This output will be ignored.
$ 

# You can also safely omit the output in the test file

$ echo "STDOUT ignored"         #=> --exit 0
$ cut                           #=> --exit 1

# The error message is a short sentence, not a diff
# Example: Expected exit code 0, got 1.

$ echo 'fail'                   #=> --exit 99

# Syntax: Must be exactly one space before and after --exit

$ echo 'fail'                   #=>   --exit fail with 2 spaces
$ echo 'fail'                   #=> --exit	fail with tab

# Syntax: The space after --exit is required.
# When missing, the '--exit' is considered a normal text.

$ echo '--exit'                 #=> --exit

# Syntax: Make sure we won't catch partial matches.

$ echo '--exitout'             #=> --exitout

# Syntax: To insert a literal text that begins with '--exit '
#         just prefix it with --text.

$ echo '--exit is cool'         #=> --text --exit is cool


# Note: The following are tested in separate files:
#       inline-match-exit-error-?.sh
#
# Syntax: Empty inline output contents are considered an error
#
# $ echo 'no contents'          #=> --exit 
#
# Syntax: Must be an integer number
# 
# $ echo 'fail'                 #=> --exit -1
# $ echo 'fail'                 #=> --exit 1.0
# $ echo 'fail'                 #=> --exit foo
