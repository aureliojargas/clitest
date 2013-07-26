#!/bin/bash
# doctest.sh - Automatic tests for shell script command lines
#              https://github.com/aureliojargas/doctest.sh
# License: MIT
# by Aurelio Jargas (http://aurelio.net), since 2013-07-25

# Customization (if needed), some may be altered by command line options
prompt='$ '
inline_mark='#→ '
diff_options='-u'
ok_file="${TMPDIR:-/tmp}/doctest.ok.$$.txt"
test_output_file="${TMPDIR:-/tmp}/doctest.output.$$.txt"
temp_file="${TMPDIR:-/tmp}/doctest.temp.$$.txt"

# Flags, may be altered by command line options
debug=0
quiet=0
verbose=0
use_colors=1
abort_on_first_error=0

# Handle command line options
while test "${1#-}" != "$1"
do
	case "$1" in
		-d|--debug    ) shift; debug=1 ;;
		-q|--quiet    ) shift; quiet=1 ;;
		-v|--verbose  ) shift; verbose=1 ;;
		--no-color    ) shift; use_colors=0 ;;
		--abort       ) shift; abort_on_first_error=1 ;;
		--diff-options) shift; diff_options="$1"; shift ;;
		--prompt      ) shift; prompt="$1"; shift ;;
		*) break ;;
	esac
done

# Utilities, prefixed by _ to avoid overwriting command names
_clean_up ()
{
	rm -f "$ok_file" "$test_output_file" "$temp_file"
}
_message ()
{
	local color_code

	test "$quiet" = 1 && return

	case "$1" in
		@red  ) color_code=31; shift;;
		@green) color_code=32; shift;;
		@blue ) color_code=34; shift;;
		@pink ) color_code=35; shift;;
		@cyan ) color_code=36; shift;;
	esac
	# Note: colors must be readable in dark and light backgrounds

	if test "$use_colors" = 1 -a -n "$color_code"
	then
		printf '%b%s%b\n' "\033[${color_code}m" "$*" '\033[m'
	else
		echo "$*"
	fi
}
_debug ()
{
	test "$debug" = 1 && _message @blue "$@"
}
_verbose ()
{
	test "$verbose" = 1 && _message @cyan "$@"
}
_get_file_stats ()
{
	local nr_ok=$((nr_file_tests - nr_file_errors))

	if test $nr_file_errors -eq 0
	then
		printf '%2d ok           %s' $nr_ok "$test_file"
	else
		printf '%2d ok, %2d fail  %s' $nr_ok $nr_file_errors "$test_file"
	fi
}
_run_test ()
{
	local diff
	local cmd="$1"; shift

	_verbose "======= $cmd"
	_debug "[ EVAL  ] $cmd"

	nr_total_tests=$((nr_total_tests + 1))
	nr_file_tests=$((nr_file_tests + 1))

	# Execute the command, saving STDOUT and STDERR
	eval "$cmd" > "$test_output_file" 2>&1

	_debug "[OUTPUT ] $(cat "$test_output_file")"

	diff=$(diff $diff_options "$ok_file" "$test_output_file")

	# Test failed
	if test $? -eq 1
	then
		nr_file_errors=$((nr_file_errors + 1))
		nr_total_errors=$((nr_total_errors + 1))

		_message
		_message @red "FAILED: $cmd"
		test "$quiet" = 1 || echo "$diff" | sed '1,2 d'  # no +++/--- headers

		if test $abort_on_first_error -eq 1
		then
			_clean_up
			exit 1
		fi
	fi

	# Reset holder for the OK output
	> "$ok_file"
}
_process_test_file ()
{
	local ok_text
	local file="$1"

	# Loop for each line of input file
	# Note: changing IFS to avoid right-trimming of spaces/tabs
	# Note: read -r to preserve the backslashes (also works in dash shell)
	while IFS='\n' read -r input_line
	do
		case "$input_line" in

			# Prompt alone: closes previous command line (if any)
			"$prompt" | "${prompt% }" | "$prompt ")
				_debug "[ CLOSE ] $input_line"

				# Run pending tests
				test -n "$test_command" && _run_test "$test_command"

				# Reset current command holder
				test_command=
			;;

			# This line is a command line to be tested
			"$prompt"*)
				_debug "[CMDLINE] $input_line"

				# Run pending tests
				test -n "$test_command" && _run_test "$test_command"

				# Remove the prompt
				test_command="${input_line#$prompt}"

				# This is a special test with inline output?
				if echo "$test_command" | grep "$inline_mark" > /dev/null
				then
					# Separate command from inline output
					test_command="${test_command%$inline_mark*}"
					ok_text="${input_line##*$inline_mark}"

					_debug "[NEW CMD] $test_command"
					_debug "[OK TEXT] $ok_text"

					# Save the output and run test
					echo "$ok_text" > "$ok_file"
					_run_test "$test_command"

					# Reset current command holder, since we're done
					test_command=
				else
					# It's a normal command line, output begins in next line

					# Reset holder for the OK output
					> "$ok_file"

					_debug "[NEW CMD] $test_command"
				fi
			;;

			# Test output, blank line or comment
			*)
				_debug "[ ? LINE] $input_line"

				# Ignore this line if there's no pending test
				test -n "$test_command" || continue

				# This line is a test output, save it
				echo "$input_line" >> "$ok_file"

				_debug "[OK LINE] $input_line"
			;;
		esac
	done < "$file"

	_debug "[LOOPOUT] test_command: $test_command"

	# Run pending tests
	test -n "$test_command" && _run_test "$test_command"
}

# Do not change these vars
nr_files=$#
nr_total_tests=0
nr_total_errors=0
files_stat_message=''
original_dir=$(pwd)

# Loop for each input file
while test -n "$1"
do
	test_file="$1"
	test_command=
	nr_file_tests=0
	nr_file_errors=0

	shift

	# Some tests may "cd" to another dir, we need to get back
	# to preserve the relative paths of the input files
	cd "$original_dir"

	# Abort when test file not found/readable
	if ! test -f "$test_file" -a -r "$test_file"
	then
		_message "$(basename "$0"): Error: cannot read input file: $test_file"
		exit 1
	fi

	# In multifile mode, identify the current file
	test $nr_files -gt 1 && _message "Testing file $test_file"

	### Prepare input file
	#
	# This sed has two purposes:
	# 1. add \n to last line (if missing), otherwise while loop will ignore it
	# 2. convert Windows files (CRLF) to the Unix format (LF)
	#
	# Note: the temporary file is required, because doing "sed | while"
	# will isolate in a subshell all the variables inside the loop.
	#
	sed "s/$(printf '\r')$//" "$test_file" > "$temp_file"

	# The magic happens here
	_process_test_file "$temp_file"

	# Abort when no test found
	if test $nr_file_tests -eq 0
	then
		_message "$(basename "$0"): Error: no test found in input file: $test_file"
		exit 1
	fi

	# Append file stats to global holder
	files_stat_message=$(printf '%s\n%s' "$files_stat_message" "$(_get_file_stats)")
done

_clean_up

# Show stats
if test $nr_files -gt 1
then
	_message
	_message '--------------------------------------------------'
	_message "${files_stat_message#?}"  # remove \n at start
	_message '--------------------------------------------------'
	_message
fi

# The final message: WIN or FAIL?
if test $nr_total_errors -eq 0
then
	if test $nr_total_tests -eq 1
	then
		_message "$(_message @green YOU WIN!) The single test has passed."
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
	elif test $nr_total_errors -gt 1 -a $nr_total_errors -eq $nr_total_tests
	then
		_message "$(_message @red EPIC FAIL!) All $nr_total_tests tests have failed."
	else
		_message "$(_message @red FAIL:) $nr_total_errors of $nr_total_tests tests have failed."
	fi
	exit 1
fi
