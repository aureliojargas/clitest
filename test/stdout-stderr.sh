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

$ ./clitest notfound
clitest: Error: cannot read input file: notfound
$ ./clitest notfound > /dev/null
clitest: Error: cannot read input file: notfound
$

# Redirecting STDERR to STDOUT

$ ./clitest notfound 2>&1
clitest: Error: cannot read input file: notfound
$

# Closing STDERR

$ ./clitest notfound 2> /dev/null
$ ./clitest notfound > /dev/null 2>&1
$
