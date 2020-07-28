# If multiple markers, only the last one is identified as such
# There are 4 ' #=> ' marker-like occurrences in this test.

$ echo "a #=> b #=> c"  #=> --lines 99 #=> --lines 1
