# All results assume a trailing newline (\n) at the last line.
# Outputs with no \n at the end cannot be tested directly.

$ printf 'ok\n'
ok
$ printf 'fail'
fail
$ printf 'ok\nok\nfail'
ok
ok
fail
$

# The same applies for inline output.

$ printf 'ok\n'    #=> ok
$ printf 'fail'    #=> fail

# An easy workaround is to add an empty 'echo' at the end:

$ printf 'ok'; echo   #=> ok

# Another workaround is to use --regex

$ printf 'ok'         #=> --regex ^ok$
