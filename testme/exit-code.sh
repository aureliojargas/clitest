$ echo "ok"            > /dev/null; echo $?
0
$ cp XXnotfoundXX foo 2> /dev/null; echo $?
1
