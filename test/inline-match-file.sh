# Inline matching method: --file
# Matches the contents of the informed file

# Just inform the file path (no quotes, no escapes)

$ printf '$ echo ok\nok\n'      #=> --file ok-1.sh

# Absolute paths are also supported

$ echo 'ok' > /tmp/foo.txt
$ echo 'ok'                     #=> --file /tmp/foo.txt
$ rm /tmp/foo.txt
$

# Syntax: Must be exactly one space before and after --file

$ echo 'fail'                   #=>   --file fail-with-2-spaces.txt
$ echo 'fail'                   #=> --file	fail-with-tab.txt

# Syntax: The extra space after '--file ' is already part of the filename

#$ echo 'fail'                   #=> --file  file-with-leading-space-in-name.txt

# Syntax: The space after --file is required.
# When missing, the '--file' is considered a normal text.

$ echo '--file'                 #=> --file

# Syntax: Make sure we won't catch partial matches.

$ echo '--filer'                #=> --filer

# Syntax: To insert a literal text that begins with '--file '
#         just prefix it with --text.

$ echo '--file is cool'         #=> --text --file is cool

# Syntax: Empty inline output contents are considered an error
# Note: Tested in a separate file: inline-match-file-error-1.sh
#
# $ echo 'no contents'          #=> --file 
