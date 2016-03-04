# Inline matching method: --exit
# Matches the exit code of the command. It should be exactly equal to
# the code specified inline.

$ /bin/true                     #→ --exit 0
$ /bin/false                    #→ --exit 1
$ /bin/sh -c 'exit 2'           #→ --exit 2
$ /bin/sh -c 'exit 3'           #→ --exit 3
$ /bin/sh -c 'exit 4'           #→ --exit 4
