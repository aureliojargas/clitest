# Output from both STDOUT and STDERR are catched by the tester.

### STDOUT

# Showing STOUT

$ echo "stdout"
stdout
$ echo "stdout" 2> /dev/null
stdout
$

# Redirecting STDOUT to STDERR

$ echo "stderr" 1>&2
stderr
$

# Closing STDOUT

$ echo "stdout" > /dev/null
$ echo "stdout" 2> /dev/null 1>&2
$

### STDERR

# Showing STDERR

$ cp XXnotfoundXX foo
cp: XXnotfoundXX: No such file or directory
$ cp XXnotfoundXX foo > /dev/null
cp: XXnotfoundXX: No such file or directory
$

# Redirecting STDERR to STDOUT

$ cp XXnotfoundXX foo 2>&1
cp: XXnotfoundXX: No such file or directory
$

# Closing STDERR

$ cp XXnotfoundXX foo 2> /dev/null
$ cp XXnotfoundXX foo > /dev/null 2>&1
$
