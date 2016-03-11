# Inline matching method: --eval
# Matches the text output from an arbitrary shell command

# Run a simple command

$ folder=$(pwd)
$ echo $folder                  #=> --eval pwd

# Read the contents of a variable

$ var='abc'
$ echo abc                      #=> --eval echo $var

# Use arithmetic expansion

$ echo 4                        #=> --eval echo $((2+2))

# Run a subshell

$ today=$(date +%D)
$ echo "Today is $today"        #=> --eval echo "Today is $(date +%D)"

# You can also match lines without the final \n

$ printf 'ok'                   #=> --eval printf 'ok'

# Blanks are preserved

$ echo ' leading space'         #=> --eval echo ' leading space'
$ echo '    leading spaces'     #=> --eval echo '    leading spaces'
$ printf '\tleading tab\n'      #=> --eval printf '\tleading tab\n'
$ printf '\t\tleading tabs\n'   #=> --eval printf '\t\tleading tabs\n'
$ echo 'trailing space '        #=> --eval echo 'trailing space '
$ echo 'trailing spaces    '    #=> --eval echo 'trailing spaces    '
$ printf 'trailing tab\t\n'     #=> --eval printf 'trailing tab\t\n'
$ printf 'trailing tabs\t\t\n'  #=> --eval printf 'trailing tabs\t\t\n'
$ echo ' '                      #=> --eval echo ' '
$ echo '   '                    #=> --eval echo '   '
$ printf '\t\n'                 #=> --eval printf '\t\n'
$ printf '\t\t\t\n'             #=> --eval printf '\t\t\t\n'
$ printf ' \t  \t\t   \n'       #=> --eval printf ' \t  \t\t   \n'

# Syntax: Must be exactly one space before and after --eval

$ echo 'fail'                   #=>   --eval fail with 2 spaces
$ echo 'fail'                   #=> --eval	fail with tab

# Syntax: The space after --eval is required.
# When missing, the '--eval' is considered a normal text.

$ echo '--eval'                 #=> --eval

# Syntax: Make sure we won't catch partial matches.

$ echo '--evaluate'             #=> --evaluate

# Syntax: To insert a literal text that begins with '--eval '
#         just prefix it with --text.

$ echo '--eval is evil'         #=> --text --eval is evil

# Syntax: Empty inline output contents are considered an error
# Note: Tested in separate files: inline-match-eval-error-?.sh
#
# $ echo 'no contents'          #=> --eval 
