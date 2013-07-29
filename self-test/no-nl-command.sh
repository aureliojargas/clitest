# All results assume a trailing newline (\n) at the last line.
# Outputs with no \n at the end cannot be tested directly.

$ echo 'ok'
ok
$ printf 'ok\n'
ok
$ echo -n 'error'
error
$ printf 'error'
error
$ printf 'ok\nok\nerror'
ok
ok
error
$

# The same applies for inline output.

$ echo 'ok'        #→ ok
$ printf 'ok\n'    #→ ok
$ echo -n 'error'  #→ error
$ printf 'error'   #→ error

# An easy workaround is to add an empty 'echo' at the end:

$ echo -n 'ok'; echo  #→ ok
$ printf 'ok'; echo   #→ ok
