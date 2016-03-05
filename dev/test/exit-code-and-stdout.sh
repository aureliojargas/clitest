$ echo "zero"; echo $?
zero
0
$ echo "two"; sh -c "exit 2"; echo $?
two
2
$
