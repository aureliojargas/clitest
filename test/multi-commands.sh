$ echo 1; echo 2; echo 3; echo 4; echo 5
1
2
3
4
5
$ (echo 1; echo 2; echo 3; echo 4; echo 5) | sed -n 3p
3
$ (echo 1; echo 2; echo 3; echo 4; echo 5) | sed -n 3p  #=> 3
