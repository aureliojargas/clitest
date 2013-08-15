#!/bin/sh
# doctest.sh - Automatic tests for shell script command lines
#              https://github.com/aureliojargas/doctest.sh
# License: MIT
# by Aurelio Jargas (http://aurelio.net), since 2013-07-24
#
# Exit codes:
#   0  All tests passed, or normal operation (--help, --list, ...)
#   1  One or more tests have failed
#   2  An error occurred (file not found, invalid range, ...)
#
# POSIX shell script:
#   This script was coded to be compatible with POSIX shells.
#   Tested in Bash 3.2, dash 0.5.5.1, ksh 93u 2011-02-08.


# Unfortunatelly I can't use $POSIXLY_CORRECT or set -o posix because
# I can't change anything in the environment, since the user tests
# are evaluated in the current shell. Subshells are not an option:
# variables, working directory, etc must persist between tests.
#
# # Force Bash into POSIX mode
# test -n "$BASH_VERSION" && set -o posix
# # Force system utilities into POSIX mode
# export POSIXLY_CORRECT=1

my_name="$(basename "$0")"
my_version='dev'
my_help="\
Usage: $my_name [options] <file ...>

Options:
  -1, --first                 Stop execution upon first failed test
  -l, --list                  List all the tests (no execution)
  -L, --list-run              List all the tests with OK/FAIL status
  -n, --number RANGE          Run specific tests, by number (1,2,4-7)
  -s, --skip RANGE            Skip specific tests, by number (1,2,4-7)
      --pre-flight COMMAND    Execute command before running the first test
      --post-flight COMMAND   Execute command after running the last test
  -q, --quiet                 Quiet operation, no output shown
  -v, --verbose               Show each test being executed
  -V, --version               Show program version and exit

Customization options:
      --color WHEN            Set when to use colors: always, never, auto
      --diff-options OPTIONS  Set options for the diff command (default: -u)
      --inline-prefix PREFIX  Set inline output prefix (default: '#→ ')
      --prefix PREFIX         Set command line prefix (default: '')
      --prompt STRING         Set prompt string (default: '$ ')"

# Customization (if needed), most may be altered by command line options
prefix=''
prompt='$ '
inline_prefix='#→ '
diff_options='-u'
color_mode='auto'
temp_dir="${TMPDIR:-/tmp}/doctest.$$"
# Note: using temporary files for compatibility, since <(...) is not portable.

# Flags (0=off, 1=on), some may be altered by command line options
debug=0
quiet=0
verbose=0
list_mode=0
list_run=0
use_colors=0
stop_on_first_fail=0
separator_line_shown=0

# Do not change these vars
nr_files=0
nr_total_tests=0
nr_total_fails=0
nr_total_skips=0
nr_file_tests=0
nr_file_fails=0
nr_file_skips=0
nr_file_ok=0
files_stats=
original_dir=$(pwd)
pre_command=
post_command=
run_range=
run_range_data=
skip_range=
skip_range_data=
failed_range=
line_number=0
test_number=0
test_line_number=0
test_command=
test_inline=
test_mode=
test_status=2
test_output=
test_diff=
test_ok_text=
test_ok_file="$temp_dir/ok.txt"
test_output_file="$temp_dir/output.txt"
temp_file="$temp_dir/temp.txt"

# Special useful chars
tab='	'
nl='
'

# Handle command line options
while test "${1#-}" != "$1"
do
	case "$1" in
		-q|--quiet      ) shift; quiet=1 ;;
		-v|--verbose    ) shift; verbose=1 ;;
		-l|--list       ) shift; list_mode=1;;
		-L|--list-run   ) shift; list_run=1;;
		-1|--first      ) shift; stop_on_first_fail=1 ;;
		-n|--number     ) shift; run_range="$1"; shift ;;
		-s|--skip       ) shift; skip_range="$1"; shift ;;
		--color|--colour) shift; color_mode="$1"; shift ;;
  		--debug         ) shift; debug=1 ;;
		--pre-flight    ) shift; pre_command="$1"; shift ;;
		--post-flight   ) shift; post_command="$1"; shift ;;
		--diff-options  ) shift; diff_options="$1"; shift ;;
		--inline-prefix ) shift; inline_prefix="$1"; shift ;;
		--prompt        ) shift; prompt="$1"; shift ;;
		--prefix        ) shift; prefix="$1"; shift ;;
		-V|--version    ) printf '%s\n' "$my_name $my_version"; exit 0 ;;
		-h|--help       ) printf '%s\n' "$my_help"; exit 0 ;;
		--) shift; break ;;
		*) break ;;
	esac
done

# Command line options consumed, now it's just the files
nr_files=$#

# No files? Show help.
if test $nr_files -eq 0
then
	printf '%s\n' "$my_help"
	exit 0
fi

### Utilities, prefixed by _ to avoid overwriting command names

_clean_up ()
{
	rm -rf "$temp_dir"
}
_message ()
{
	test $quiet -eq 1 && return 0
	printf '%s\n' "$*"
	separator_line_shown=0
}
_error ()
{
	printf '%s\n' "$my_name: Error: $1" >&2
	_clean_up
	exit 2
}
_debug ()  # $1=id, $2=contents
{
	test $debug -ne 1 && return 0
	if test INPUT_LINE = "$1"
	then
		# Original input line is all blue
		printf "${color_blue}[%10s: %s]${color_off}\n" "$1" "$2"
	else
		# Highlight tabs and #→
		printf "${color_blue}[%10s:${color_off} %s${color_blue}]${color_off}\n" "$1" "$2" |
			sed "/LINE_CMD:/ s/$inline_prefix/${color_red}&${color_off}/g" |
			sed "s/$tab/${color_green}<tab>${color_off}/g"
	fi
}
_separator_line ()
{
	printf "%${COLUMNS}s" ' ' | tr ' ' -
}
_list_test ()  # $1=ok|fail|verbose
{
	# Show the output lines for --verbose, --list and --list-run
	case "$1" in
		ok)
			# Green line or OK stamp (--list-run)
			if test $use_colors -eq 1
			then
				_message "${color_green}#${test_number}${tab}${test_command}${color_off}"
			else
				_message "#${test_number}${tab}OK${tab}${test_command}"
			fi
		;;
		fail)
			# Red line or FAIL stamp (--list-run)
			if test $use_colors -eq 1
			then
				_message "${color_red}#${test_number}${tab}${test_command}${color_off}"
			else
				_message "#${test_number}${tab}FAIL${tab}${test_command}"
			fi
		;;
		verbose)
			# Cyan line, no stamp (--verbose)
			_message "${color_cyan}#${test_number}${tab}${test_command}${color_off}"
		;;
		*)
			# Normal line, no color, no stamp (--list)
			_message "#${test_number}${tab}${test_command}"
		;;
	esac
}
_parse_range ()  # $1=range
{
	# Parse numeric ranges and output them in an expanded format
	#
	#     Supported formats             Expanded
	#     ------------------------------------------------------
	#     Single:  1                    :1:
	#     List:    1,3,4,7              :1:3:4:7:
	#     Range:   1-4                  :1:2:3:4:
	#     Mixed:   1,3,4-7,11,13-15     :1:3:4:5:6:7:11:13:14:15:
	#
	#     Reverse ranges and repeated/unordered numbers are ok.
	#     Later we will just grep for :number: in each test.

	case "$1" in
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

	part=
	n1=
	n2=
	operation=
	range_data=':'  # :1:2:4:7:

	# Loop each component: a number or a range
	for part in $(echo "$1" | tr , ' ')
	do
		# If there's an hyphen, it's a range
		case "$part" in
			*-*)
				# Error: Invalid range format, must be: number-number
				echo "$part" | grep '^[0-9][0-9]*-[0-9][0-9]*$' > /dev/null || return 1

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
		test $part != 0 && range_data=$range_data$part:
	done

	test $range_data != ':' && echo $range_data
	return 0
}
_reset_test_data ()
{
	test_command=
	test_inline=
	test_mode=
	test_status=2
	test_output=
	test_diff=
	test_ok_text=
}
_run_test ()
{
	test_number=$(($test_number + 1))
	nr_total_tests=$(($nr_total_tests + 1))
	nr_file_tests=$(($nr_file_tests + 1))

	# Run range on: skip this test if it's not listed in $run_range_data
	if test -n "$run_range_data" && test "$run_range_data" = "${run_range_data#*:$test_number:}"
	then
		nr_total_skips=$(($nr_total_skips + 1))
		nr_file_skips=$(($nr_file_skips + 1))
		_reset_test_data
		return 0
	fi

	# Skip range on: skip this test if it's listed in $skip_range_data
	# Note: --skip always wins over --number, regardless of order
	if test -n "$skip_range_data" && test "$skip_range_data" != "${skip_range_data#*:$test_number:}"
	then
		nr_total_skips=$(($nr_total_skips + 1))
		nr_file_skips=$(($nr_file_skips + 1))
		_reset_test_data
		return 0
	fi

	# List mode: just show the command and return (no execution)
	if test $list_mode -eq 1
	then
		_list_test
		_reset_test_data
		return 0
	fi

	# Verbose mode: show the command that will be tested
	if test $verbose -eq 1
	then
		_list_test verbose
	fi

	#_debug EVAL "$test_command"

	# Execute the test command, saving output (STDOUT and STDERR)
	eval "$test_command" > "$test_output_file" 2>&1

	#_debug OUTPUT "$(cat "$test_output_file")"

	# The command output matches the expected output?
	case $test_mode in
		output)
			printf %s "$test_ok_text" > "$test_ok_file"
			test_diff=$(diff $diff_options "$test_ok_file" "$test_output_file")
			test_status=$?
		;;
		text)
			# Inline OK text represents a full line, with \n
			printf '%s\n' "$test_inline" > "$test_ok_file"
			test_diff=$(diff $diff_options "$test_ok_file" "$test_output_file")
			test_status=$?
		;;
		eval)
			eval "$test_inline" > "$test_ok_file"
			test_diff=$(diff $diff_options "$test_ok_file" "$test_output_file")
			test_status=$?
		;;
		lines)
			test_output=$(sed -n '$=' "$test_output_file")
			test -z "$test_output" && test_output=0
			test "$test_output" -eq "$test_inline"
			test_status=$?
			test_diff="Expected $test_inline lines, got $test_output."
		;;
		file)
			# Abort when ok file not found/readable
			if test ! -f "$test_inline" || test ! -r "$test_inline"
			then
				_error "cannot read inline output file '$test_inline', from line $line_number of $test_file"
			fi

			test_diff=$(diff $diff_options "$test_inline" "$test_output_file")
			test_status=$?
		;;
		regex)
			egrep "$test_inline" "$test_output_file" > /dev/null
			test_status=$?

			# Failed, now we need a real file to make the diff
			if test $test_status -eq 1
			then
				printf %s "$test_inline" > "$test_ok_file"
				test_diff="egrep '$test_inline' failed in:$nl$(cat "$test_output_file")"

			# Regex errors are common and user must take action to fix them
			elif test $test_status -eq 2
			then
				_error "egrep: check your inline regex at line $line_number of $test_file"
			fi
		;;
		*)
			_error "unknown test mode '$test_mode'"
		;;
	esac

	# Test failed :(
	if test $test_status -ne 0
	then
		nr_file_fails=$(($nr_file_fails + 1))
		nr_total_fails=$(($nr_total_fails + 1))
		failed_range="$failed_range$test_number,"

		# Decide the message format
		if test $list_run -eq 1
		then
			# List mode
			_list_test fail
		else
			# Normal mode: show FAILED message and the diff
			if test $separator_line_shown -eq 0  # avoid dups
			then
				_message "${color_red}$(_separator_line)${color_off}"
			fi
			_message "${color_red}[FAILED #$test_number, line $test_line_number] $test_command${color_off}"
			_message "$test_diff" | sed '1 { /^--- / { N; /\n+++ /d; }; }'  # no ---/+++ headers
			_message "${color_red}$(_separator_line)${color_off}"
			separator_line_shown=1
		fi

		# Should I abort now?
		if test $stop_on_first_fail -eq 1
		then
			_clean_up
			exit 1
		fi

	# Test OK
	else
		test $list_run -eq 1 && _list_test ok
	fi

	_reset_test_data
}
_process_test_file ()
{
	# Reset counters
	nr_file_tests=0
	nr_file_fails=0
	nr_file_skips=0
	line_number=0
	test_line_number=0

	# Loop for each line of input file
	# Note: changing IFS to avoid right-trimming of spaces/tabs
	# Note: read -r to preserve the backslashes
	while IFS='' read -r input_line || test -n "$input_line"
	do
		line_number=$(($line_number + 1))
		#_debug INPUT_LINE "$input_line"

		case "$input_line" in

			# Prompt alone: closes previous command line (if any)
			"$prefix$prompt" | "$prefix${prompt% }" | "$prefix$prompt ")
				#_debug 'LINE_$' "$input_line"

				# Run pending tests
				test -n "$test_command" && _run_test
			;;

			# This line is a command line to be tested
			"$prefix$prompt"*)
				#_debug LINE_CMD "$input_line"

				# Run pending tests
				test -n "$test_command" && _run_test

				# Remove the prompt
				test_command="${input_line#"$prefix$prompt"}"

				# Save the test's line number for future messages
				test_line_number=$line_number

				# This is a special test with inline output?
				if printf '%s\n' "$test_command" | grep "$inline_prefix" > /dev/null
				then
					# Separate command from inline output
					test_command="${test_command%"$inline_prefix"*}"
					test_inline="${input_line##*"$inline_prefix"}"

					#_debug NEW_CMD "$test_command"
					#_debug OK_INLINE "$test_inline"

					# Maybe the OK text has options?
					case "$test_inline" in
						'--regex '*)
							test_inline=${test_inline#--regex }
							test_mode='regex'
						;;
						'--file '*)
							test_inline=${test_inline#--file }
							test_mode='file'
						;;
						'--lines '*)
							test_inline=${test_inline#--lines }
							test_mode='lines'
						;;
						'--eval '*)
							test_inline=${test_inline#--eval }
							test_mode='eval'
						;;
						'--text '*)
							test_inline=${test_inline#--text }
							test_mode='text'
						;;
						*)
							test_mode='text'
						;;
					esac

					#_debug OK_TEXT "$test_inline"

					# There must be a number in --lines
					if test "$test_mode" = 'lines'
					then
						case "$test_inline" in
							'' | *[!0-9]*)
								_error "--lines requires a number. See line $line_number of $test_file"
							;;
						esac
					fi

					# An empty inline parameter is an error user must see
					if test -z "$test_inline" && test "$test_mode" != 'text'
					then
						_error "missing inline output $test_mode at line $line_number of $test_file"
					fi

					# Since we already have the command and the output, run test
					_run_test
				else
					# It's a normal command line, output begins in next line
					test_mode='output'

					#_debug NEW_CMD "$test_command"
				fi
			;;

			# Test output, blank line or comment
			*)
				#_debug 'LINE_*' "$input_line"

				# Ignore this line if there's no pending test
				test -n "$test_command" || continue

				# Required prefix is missing: we just left a command block
				if test -n "$prefix" && test "${input_line#"$prefix"}" = "$input_line"
				then
					#_debug BLOCK_OUT "$input_line"

					# Run the pending test and we're done in this line
					_run_test
					continue
				fi

				# This line is a test output, save it (without prefix)
				test_ok_text="$test_ok_text${input_line#"$prefix"}$nl"

				#_debug OK_TEXT "${input_line#"$prefix"}"
			;;
		esac
	done < "$temp_file"

	#_debug LOOP_OUT "\$test_command=$test_command"

	# Run pending tests
	test -n "$test_command" && _run_test
}


### Init process

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

# Will we use colors in the output?
case "$color_mode" in
	always | yes | y)
		use_colors=1
	;;
	never | no | n)
		use_colors=0
	;;
	auto | a)
		# The auto mode will use colors if the output is a terminal
		# Note: test -t is in POSIX
		if test -t 1
		then
			use_colors=1
		else
			use_colors=0
		fi
	;;
	*)
		_error "invalid value '$color_mode' for --color. Use: auto, always or never."
	;;
esac

# Set colors
# Remember: colors must be readable in dark and light backgrounds
# Tweak the numbers after [ to adjust the colors
if test $use_colors -eq 1
then
	color_red=$(  printf '\033[31m')  # fail
	color_green=$(printf '\033[32m')  # ok
	color_blue=$( printf '\033[34m')  # debug
	color_cyan=$( printf '\033[36m')  # verbose
	color_off=$(  printf '\033[m')
fi

# Find the terminal width
# The COLUMNS env var is set by Bash (must be exported in ~/.bashrc).
# In other shells, try to use tput cols (not POSIX).
# If not, defaults to 50 columns, a conservative amount.
: ${COLUMNS:=$(tput cols 2> /dev/null)}
: ${COLUMNS:=50}

# Parse and validate --number option value, if informed
run_range_data=$(_parse_range "$run_range")
if test $? -ne 0
then
	_error "invalid argument for -n or --number: $run_range"
fi

# Parse and validate --skip option value, if informed
skip_range_data=$(_parse_range "$skip_range")
if test $? -ne 0
then
	_error "invalid argument for -s or --skip: $skip_range"
fi

# Create temp dir, protected from others
umask 077 && mkdir "$temp_dir" || _error "cannot create temporary dir: $temp_dir"


### Real execution begins here

# Some preparing command to run before all the tests?
if test -n "$pre_command"
then
	eval "$pre_command" ||
		_error "pre-flight command failed with status=$?: $pre_command"
fi

# For each input file in $@
for test_file
do
	# Some tests may "cd" to another dir, we need to get back
	# to preserve the relative paths of the input files
	cd "$original_dir"

	# Abort when test file not found/readable
	if test ! -f "$test_file" || test ! -r "$test_file"
	then
		_error "cannot read input file: $test_file"
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

	# Convert Windows files (CRLF) to the Unix format (LF)
	# Note: the temporary file is required, because doing "sed | while" opens
	#       a subshell and global vars won't be updated outside the loop.
	sed "s/$(printf '\r')$//" "$test_file" > "$temp_file"

	# The magic happens here
	_process_test_file

	# Abort when no test found
	if test $nr_file_tests -eq 0 && test -z "$run_range_data" && test -z "$skip_range_data"
	then
		_error "no test found in input file: $test_file"
	fi

	# Save file stats
	nr_file_ok=$(($nr_file_tests - $nr_file_fails - $nr_file_skips))
	files_stats="$files_stats$nr_file_ok $nr_file_fails $nr_file_skips$nl"
done

_clean_up

# Some clean up command to run after all the tests?
if test -n "$post_command"
then
	eval "$post_command"
fi

### From this point, it's safe to use non-prefixed global vars

# Range active, but no test matched :(
if test $nr_total_tests -eq $nr_total_skips
then
	if test -n "$run_range_data" && test -n "$skip_range_data"
	then
		_error "no test found. The combination of -n and -s resulted in no tests."
	elif test -n "$run_range_data"
	then
		_error "no test found for the specified number or range '$run_range'"
	elif test -n "$skip_range_data"
	then
		_error "no test found. Maybe '--skip $skip_range' was too much?"
	fi
fi

# List mode has no stats
if test $list_mode -eq 1 || test $list_run -eq 1
then
	if test $nr_total_fails -eq 0
	then
		exit 0
	else
		exit 1
	fi
fi

### Show stats
# Data:
#   $files_stats -> "100 0 23 \n 12 34 0"
#   $@ -> foo.sh bar.sh
# Output:
# ====    OK  FAIL  SKIP
# ====   100     0    23  foo.sh
# ====    12    34     0  bar.sh
if test $nr_files -gt 1 && test $quiet -ne 1
then
	echo
	printf '==== %5s %5s %5s\n' OK FAIL SKIP
	printf %s "$files_stats" | while read ok fail skip
	do
		printf '==== %5s %5s %5s    %s\n' $ok $fail $skip "$1"
		shift
	done
	echo
fi

### The final message: OK or FAIL?
# OK: 123 of 123 tests passed
# OK: 100 of 123 tests passed (23 skipped)
# FAIL: 123 of 123 tests failed
# FAIL: 100 of 123 tests failed (23 skipped)
skips=
if test $nr_total_skips -gt 0
then
	skips=" ($nr_total_skips skipped)"
fi
if test $nr_total_fails -eq 0
then
	stamp="${color_green}OK:${color_off}"
	stats="$(($nr_total_tests - $nr_total_skips)) of $nr_total_tests tests passed"
	_message "$stamp $stats$skips"
	exit 0
else
	test $nr_files -eq 1 && _message  # separate from previous FAILED message

	stamp="${color_red}FAIL:${color_off}"
	stats="$nr_total_fails of $nr_total_tests tests failed"
	_message "$stamp $stats$skips"
	test $test_file = 'self-test.sh' && _message "-n ${failed_range%,}"  # XXX dev helper, remove before release
	exit 1
fi
