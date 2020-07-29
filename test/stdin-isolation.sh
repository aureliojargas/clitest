#
# This was a bug found on early versions of clitest in which tests shared
# STDIN with clitest and with each other, causing unexpected results when
# a test read from STDIN. This was reported on issue #42 on Github.
#
# Testing for a regression. 
#

$ echo testing stdin isolation ; read stdin_isolation
testing stdin isolation
$ echo Failed\? Regression to stdin isolation added. ; unset stdin_isolation
Failed? Regression to stdin isolation added.
