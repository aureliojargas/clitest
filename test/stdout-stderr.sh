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

$ ./clitest foo
clitest: Error: cannot read input file: foo
$ ./clitest foo > /dev/null
clitest: Error: cannot read input file: foo
$

# Redirecting STDERR to STDOUT

$ ./clitest foo 2>&1
clitest: Error: cannot read input file: foo
$

# Closing STDERR

$ ./clitest foo 2> /dev/null
$ ./clitest foo > /dev/null 2>&1
$
