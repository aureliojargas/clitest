# All results assume a trailing newline (\n) at the last line.
# Outputs with no \n at the end cannot be tested directly.

$ printf 'ok\n'
ok
$ printf 'error'
error
$ printf 'ok\nok\nerror'
ok
ok
error
$

# The same applies for inline output.

$ printf 'ok\n'    #→ ok
$ printf 'error'   #→ error

# An easy workaround is to add an empty 'echo' at the end:

$ printf 'ok'; echo   #→ ok
