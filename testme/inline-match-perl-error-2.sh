$ echo "error: malformed regex"  #→ --perl (


# Some perl errors:

# $ echo | perl -0777 -ne 'exit(!/(/)' ; echo $?
# Unmatched ( in regex; marked by <-- HERE in m/( <-- HERE / at -e line 1.
# 255
# $ echo | perl -0777 -ne 'exit(!/[/)' ; echo $?
# Unmatched [ in regex; marked by <-- HERE in m/[ <-- HERE / at -e line 1.
# 255
# $ echo | perl -0777 -ne 'exit(!/**/)' ; echo $?
# Quantifier follows nothing in regex; marked by <-- HERE in m/* <-- HERE */ at -e line 1.
# 255
# $
