#!/bin/bash
# doctest.sh - Automatic tests for shell script command lines
#              https://github.com/aureliojargas/doctest.sh
# License: MIT
# by Aurelio Jargas (http://aurelio.net), since 2013-07-24

my_name="$(basename "$0")"
my_version='dev'
my_help="\
Usage: $my_name [OPTIONS] <FILES>

Options:
  -1, --abort                 Abort the tests on the first error
      --diff-options STRING   Customize options for diff (default: -u)
      --inline-prefix STRING  Set inline output prefix (default: '#→ ')
  -l, --list                  List all the tests (no execution)
  -L, --list-run              List all the tests with OK/FAIL status
      --no-color              Turn off colors in the program output
  -n, --number RANGE          Run specific tests, by number (1,2,4-7)
      --prefix STRING         Set command line prefix (default: none)
      --prompt STRING         Set prompt string (default: '$ ')
  -q, --quiet                 Quiet operation, no output shown
  -v, --verbose               Show each test being executed
  -V, --version               Show program version and exit"

# Customization (if needed), some may be altered by command line options
prefix=''
prompt='$ '
inline_prefix='#→ '
diff_options='-u'
user_range=''
ok_file="${TMPDIR:-/tmp}/doctest.ok.$$.txt"
test_output_file="${TMPDIR:-/tmp}/doctest.output.$$.txt"
temp_file="${TMPDIR:-/tmp}/doctest.temp.$$.txt"
# Note: using temporary files for compatibility, since <(...) is not portable.

# Flags (0=off, 1=on), may be altered by command line options
debug=0
quiet=0
verbose=0
list_mode=0
list_run=0
use_colors=1
abort_on_first_error=0

# Do not change these vars
file_counter=0
test_number=0
line_number=0
nr_files=0
nr_total_tests=0          # count only executed tests
nr_total_errors=0
nr_file_tests=0           # count only executed tests
nr_file_errors=0
test_range=''
separator_line_shown=0
files_stat_message=''
original_dir=$(pwd)

# Special chars
tab='	'
nl='
'

# Handle command line options
while test "${1#-}" != "$1"
do
	case "$1" in
		-q|--quiet     ) shift; quiet=1 ;;
		-v|--verbose   ) shift; verbose=1 ;;
		-l|--list      ) shift; list_mode=1;;
		-L|--list-run  ) shift; list_run=1;;
		-1|--abort     ) shift; abort_on_first_error=1 ;;
		-n|--number    ) shift; user_range="$1"; shift ;;
		--no-color     ) shift; use_colors=0 ;;
  		--debug        ) shift; debug=1 ;;
		--diff-options ) shift; diff_options="$1"; shift ;;
		--inline-prefix) shift; inline_prefix="$1"; shift ;;
		--prompt       ) shift; prompt="$1"; shift ;;
		--prefix       ) shift; prefix="$1"; shift ;;
		-V|--version   ) echo "$my_name $my_version"; exit 0 ;;
		-h|--help      ) echo "$my_help"; exit 0 ;;
		*) break ;;
	esac
done

# Command line options consumed, now it's just the files
nr_files=$#

# No files? Show help.
if test $nr_files -eq 0
then
	echo "$my_help"
	exit 0
fi

# Handy shortcuts for prefixes
case "$prefix" in
	tab)
		prefix="$tab"
	;;
	0)
		prefix=''
	;;
	[1-9] | [1-9][0-9])  # 1-99
		# convert number to spaces: 2 => '  '
		prefix=$(printf "%${prefix}s" ' ')
	;;
	*\\*)
		prefix="$(printf %b "$prefix")"  # expand \t and others
	;;
esac

# Utilities, prefixed by _ to avoid overwriting command names
_clean_up ()
{
	rm -f "$ok_file" "$test_output_file" "$temp_file"
}
_message ()
{
	local color_code

	test $quiet -eq 1 && return

	case "$1" in
		@red  ) color_code=31; shift;;
		@green) color_code=32; shift;;
		@blue ) color_code=34; shift;;
		@pink ) color_code=35; shift;;
		@cyan ) color_code=36; shift;;
	esac
	# Note: colors must be readable in dark and light backgrounds

	if test $use_colors -eq 1 && test -n "$color_code"
	then
		printf '%b%s%b\n' "\033[${color_code}m" "$*" '\033[m'
	else
		echo "$*"
	fi

	separator_line_shown=0
}
_debug ()
{
	test $debug -eq 1 && _message @blue "$@"
}
_separator_line ()
{
	# Occupy the full terminal width if the $COLUMNS environment
	# variable is available (it needs to be exported in ~/.bashrc).
	# If not, defaults to 50 columns, a conservative amount.
	printf "%${COLUMNS:-50}s" ' ' | tr ' ' -
}
_list_line ()  # $1=command $2=ok|fail
{
	# Compose the output lines for --list and --list-run

	local cmd="$1"
	local n=$test_number

	case "$2" in
		ok)
			# Green line or OK stamp (--list-run)
			if test $use_colors -eq 1
			then
				_message @green "${n}${tab}${cmd}"
			else
				_message "${n}${tab}OK${tab}${cmd}"
			fi
		;;
		fail)
			# Red line or FAIL stamp (--list-run)
			if test $use_colors -eq 1
			then
				_message @red "${n}${tab}${cmd}"
			else
				_message "${n}${tab}FAIL${tab}${cmd}"
			fi
		;;
		*)
			# Normal line, no color, no stamp (--list)
			_message "${n}${tab}${cmd}"
		;;
	esac
}
_parse_range ()
{
	# Parse -n, --number ranges and save results to $test_range
	#
	#     Supported formats            Parsed
	#     ------------------------------------------------------
	#     Single:  1                    :1:
	#     List:    1,3,4,7              :1:3:4:7:
	#     Range:   1-4                  :1:2:3:4:
	#     Mixed:   1,3,4-7,11,13-15     :1:3:4:5:6:7:11:13:14:15:
	#
	#     Reverse ranges and repeated/unordered numbers are ok.
	#     Later we will just grep for :number: in each test.

	local part
	local n1
	local n2
	local operation
	local numbers=':'  # :1:2:4:7:

	case "$user_range" in
		# No range, nothing to do
		0 | '')
			return 0
		;;
		# Error: strange chars, not 0123456789,-
		*[!0-9,-]*)
			return 1
		;;
	esac

	# OK, all valid chars in range, let's parse them

	# Loop each component: a number or a range
	for part in $(echo $user_range | tr , ' ')
	do
		# If there's an hyphen, it's a range
		case $part in
			*-*)
				# Error: Invalid range format, must be: number-number
				echo $part | grep '^[0-9][0-9]*-[0-9][0-9]*$' > /dev/null || return 1

				n1=${part%-*}
				n2=${part#*-}

				operation='+'
				test $n1 -gt $n2 && operation='-'

				# Expand the range (1-4 => 1:2:3:4)
				part=$n1:
				while test $n1 -ne $n2
				do
					n1=$(($n1 $operation 1))
					part=$part$n1:
				done
				part=${part%:}
			;;
		esac

		# Append the number or expanded range to the holder
		test $part != 0 && numbers=$numbers$part:
	done

	# Save parsed range
	test $numbers != ':' && test_range=$numbers
	return 0
}
_run_test ()  # $1=command [$2=ok_text] [$3=match_method]
{
	# If ok_text is not informed, we'll get it from $ok_file

	local diff
	local exit_code
	local output_text
	local output_mode
	local cmd="$1"
	local ok_text="$2"
	local match_method="$3"

	test_number=$(($test_number + 1))

	# Test range on: skip this test if it's not listed in $test_range
	if test -n "$test_range" && test "$test_range" = "${test_range#*:$test_number:}"
	then
		return 0
	fi

	nr_total_tests=$(($nr_total_tests + 1))
	nr_file_tests=$(($nr_file_tests + 1))

	# List mode: just show the command and return (no execution)
	if test $list_mode -eq 1
	then
		_list_line "$cmd"
		return 0
	fi

	# Verbose mode: show the command that will be tested
	if test $verbose -eq 1
	then
		_message @cyan "=======[$test_number] $cmd"
	fi

	#_debug "[ EVAL  ] $cmd"

	# To execute the test command and compare the results, we can use
	# files (slow, trustable) or variables (quick, hacky). Variables
	# are the preferred way for inline output with #→, unless you're
	# inlining a file name with '#→ --file ...'.
	if test -z "$ok_text" || test "$match_method" = 'file'
	then
		output_mode='file'
	else
		output_mode='var'
	fi

	# Execute the test command, saving output (STDOUT and STDERR)
	if test "$output_mode" = 'file'
	then
		eval "$cmd" > "$test_output_file" 2>&1

		#_debug "[OUTPUT ] $(cat "$test_output_file")"		
	else
		output_text="$(eval "$cmd" 2>&1; printf x)"
		output_text=${output_text%x}

		# Note: The 'print x' trick is to avoid losing the \n's
		#       at the output's end when using $(...)

		#_debug "[OUTPUT ] $output_text"
	fi

	# The command output matches the expected output?
	case $match_method in
		text)
			# Inline OK text represents a full line, with \n
			ok_text="$ok_text$nl"

			test "$output_text" = "$ok_text"
			exit_code=$?
		;;
		regex)
			printf %s "$output_text" | egrep "$ok_text" > /dev/null
			exit_code=$?

			# Regex errors are common and user must take action to fix them
			if test $exit_code -eq 2
			then
				_message "$(basename "$0"): egrep Error: check your inline regex at line $line_number of $test_file"
				exit 1
			fi
		;;
		file)
			# Abort when ok file not found/readable
			if test ! -f "$ok_text" || test ! -r "$ok_text"
			then
				_message "$(basename "$0"): Error: cannot read inline output file '$ok_text', from line $line_number of $test_file"
				exit 1
			fi

			diff=$(diff $diff_options "$ok_text" "$test_output_file")
			exit_code=$?
		;;
		*)
			diff=$(diff $diff_options "$ok_file" "$test_output_file")
			exit_code=$?
		;;
	esac

	# If the var test failed, we'll have to run diff using real files
	if test $exit_code -ne 0 && test "$output_mode" = 'var'
	then
		printf %s "$output_text" > "$test_output_file"
		printf %s "$ok_text" > "$ok_file"
		diff=$(diff $diff_options "$ok_file" "$test_output_file")
	fi

	# Test failed :(
	if test $exit_code -ne 0
	then
		nr_file_errors=$(($nr_file_errors + 1))
		nr_total_errors=$(($nr_total_errors + 1))

		# Decide the message format
		if test $list_run -eq 1
		then
			# List mode
			_list_line "$cmd" fail
		else
			# Normal mode: show FAILED message and the diff
			if test $separator_line_shown -eq 0  # avoid dups
			then
				_message @red $(_separator_line)
			fi
			_message @red "#$test_number FAILED: $cmd"
			test $quiet -eq 1 || echo "$diff" | sed '1,2 d'  # no +++/--- headers
			_message @red $(_separator_line)
			separator_line_shown=1
		fi

		# Should I abort now?
		if test $abort_on_first_error -eq 1
		then
			_clean_up
			exit 1
		fi

	# Test OK
	else
		test $list_run -eq 1 && _list_line "$cmd" ok
	fi

	# Reset holder for the OK output
	if test $exit_code -ne 0 || test -z "$ok_text"
	then
		> "$ok_file"
	fi
}
_process_test_file ()  # $1=filename
{
	local test_command
	local ok_text
	local match_method
	local file="$1"

	# reset globals
	nr_file_tests=0
	nr_file_errors=0
	line_number=0

	# Loop for each line of input file
	# Note: changing IFS to avoid right-trimming of spaces/tabs
	# Note: read -r to preserve the backslashes (also works in dash shell)
	while IFS='' read -r input_line
	do
		line_number=$(($line_number + 1))
		case "$input_line" in

			# Prompt alone: closes previous command line (if any)
			"$prefix$prompt" | "$prefix${prompt% }" | "$prefix$prompt ")
				#_debug "[ CLOSE ] $input_line"

				# Run pending tests
				test -n "$test_command" && _run_test "$test_command"

				# Reset current command holder
				test_command=
			;;

			# This line is a command line to be tested
			"$prefix$prompt"*)
				#_debug "[CMDLINE] $input_line"

				# Run pending tests
				test -n "$test_command" && _run_test "$test_command"

				# Remove the prompt
				test_command="${input_line#$prefix$prompt}"

				# This is a special test with inline output?
				if echo "$test_command" | grep "$inline_prefix" > /dev/null
				then
					# Separate command from inline output
					test_command="${test_command%$inline_prefix*}"
					ok_text="${input_line##*$inline_prefix}"

					#_debug "[NEW CMD] $test_command"
					#_debug "[OK TEXT] $ok_text$"

					# Maybe the OK text has options?
					case "$ok_text" in
						'--regex '*)
							ok_text=${ok_text#--regex }
							match_method='regex'
						;;
						'--file '*)
							ok_text=${ok_text#--file }
							match_method='file'
						;;
						'--text '*)
							ok_text=${ok_text#--text }
							match_method='text'
						;;
						*)
							match_method='text'
						;;
					esac

					# An empty inline output is an error user must see
					if test -z "$ok_text"
					then
						_message "$(basename "$0"): Error: missing inline output $match_method at line $line_number of $test_file"
						exit 1
					fi

					# Save the output and run test
					_run_test "$test_command" "$ok_text" "$match_method"

					# Reset current command holder, since we're done
					test_command=
				else
					# It's a normal command line, output begins in next line

					# Reset holder for the OK output
					> "$ok_file"

					#_debug "[NEW CMD] $test_command"
				fi
			;;

			# Test output, blank line or comment
			*)
				#_debug "[ ? LINE] $input_line"

				# Ignore this line if there's no pending test
				test -n "$test_command" || continue

				# Required prefix is missing: we just left a command block
				if test -n "$prefix" && test "${input_line#$prefix}" = "$input_line"
				then
					#_debug "[BLOKOUT] $input_line"

					# Run the pending test and reset
					_run_test "$test_command"
					test_command=
				fi

				# This line is a test output, save it (without prefix)
				echo "${input_line#$prefix}" >> "$ok_file"

				#_debug "[OK LINE] $input_line"
			;;
		esac
	done < "$file"

	#_debug "[LOOPOUT] test_command: $test_command"

	# Run pending tests
	test -n "$test_command" && _run_test "$test_command"
}

# Parse and validate --number option value, if informed
_parse_range
if test $? -eq 1
then
	_message "$(basename "$0"): Error: invalid argument for -n or --number: $user_range"
	exit 1
fi


# Loop for each input file
while test $# -gt 0
do
	file_counter=$(($file_counter + 1))
	test_file="$1"
	shift

	# Some tests may "cd" to another dir, we need to get back
	# to preserve the relative paths of the input files
	cd "$original_dir"

	# Abort when test file not found/readable
	if test ! -f "$test_file" || test ! -r "$test_file"
	then
		_message "$(basename "$0"): Error: cannot read input file: $test_file"
		exit 1
	fi

	# In multifile mode, identify the current file
	if test $nr_files -gt 1
	then
		if test $list_mode -ne 1 && test $list_run -ne 1
		then
			# Normal mode, show a message
			_message "Testing file $test_file"
		else
			# List mode, show ------ and the filename
			_message $(_separator_line | cut -c 1-40) $test_file
		fi
	fi

	### Prepare input file
	#
	# This sed has two purposes:
	# 1. add \n to last line (if missing), otherwise while loop will ignore it
	# 2. convert Windows files (CRLF) to the Unix format (LF)
	#
	# Note: the temporary file is required, because doing "sed | while" opens
	#       a subshell and global vars won't be updated outside the loop.
	#
	sed "s/$(printf '\r')$//" "$test_file" > "$temp_file"

	# The magic happens here
	_process_test_file "$temp_file"

	# Abort when no test found
	if test $nr_file_tests -eq 0 && test -z "$test_range"
	then
		_message "$(basename "$0"): Error: no test found in input file: $test_file"
		exit 1
	fi

	# Compose file stats message
	nr_file_ok=$(($nr_file_tests - $nr_file_errors))
	if test $nr_file_errors -eq 0
	then
		msg=$(printf '%2d ok           %s' $nr_file_ok "$test_file")
	else
		msg=$(printf '%2d ok, %2d fail  %s' $nr_file_ok $nr_file_errors "$test_file")
	fi

	# Append file stats to global holder
	files_stat_message=$(printf '%s\n%s' "$files_stat_message" "$msg")
done

_clean_up

# List mode has no stats
if test $list_mode -eq 1 || test $list_run -eq 1
then
	exit 0
fi

# Range active, but no test matched :(
if test $nr_total_tests -eq 0 && test -n "$test_range"
then
	_message "$(basename "$0"): Error: no test found for the specified number or range '$user_range'"
	exit 1
fi

# Show stats
if test $nr_files -gt 1
then
	_message
	_message $(_separator_line | tr - =)
	_message "${files_stat_message#?}"  # remove \n at start
	_message $(_separator_line | tr - =)
	_message
fi

# The final message: WIN or FAIL?
if test $nr_total_errors -eq 0
then
	if test $nr_total_tests -eq 1
	then
		_message "$(_message @green OK!) The single test has passed."
	elif test $nr_total_tests -lt 50
	then
		_message "$(_message @green OK!) All $nr_total_tests tests have passed."
	elif test $nr_total_tests -lt 100
	then
		_message "$(_message @green YOU WIN!) All $nr_total_tests tests have passed."
	else
		_message "$(_message @green YOU WIN! PERFECT!) All $nr_total_tests tests have passed."
	fi
	exit 0
else
	test $nr_files -eq 1 && _message  # separate from previous error message

	if test $nr_total_tests -eq 1
	then
		_message "$(_message @red FAIL:) The single test has failed."
	elif test $nr_total_errors -eq $nr_total_tests && test $nr_total_errors -lt 50
	then
		_message "$(_message @red COMPLETE FAIL!) All $nr_total_tests tests have failed."
	elif test $nr_total_errors -eq $nr_total_tests
	then
		_message "$(_message @red EPIC FAIL!) All $nr_total_tests tests have failed."
	else
		_message "$(_message @red FAIL:) $nr_total_errors of $nr_total_tests tests have failed."
	fi
	exit 1
fi
# Note: Those messages are for FUN. When automating, check the exit code.

# Dev notes:
# - Comment   all debug lines: sed 's/	_debug/	#_debug/'
# - Uncomment all debug lines: sed 's/#_debug/_debug/'
