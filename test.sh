#!/usr/bin/env bash

source common-functions.sh
source common-io.sh
source common-sysconfig.sh
source common-tables.sh
source common-ui.sh
source common-wsl.sh

clear

function failure_report() {
    local fnname="$1"
    local -n __input=$2
    local -n __output=$3
    local -n __correct=$4
    echo ""
    echo "TEST FAILED: $fnname"
    print_var __input
    print_var __output
    print_var __correct
    echo ""
}

declare -a months=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
declare -a months2=("Jan2" "Feb2" "Mar2" "Apr2" "May2" "Jun2" "Jul2" "Aug2" "Sep2" "Oct2" "Nov2" "Dec2")
declare -A birthdays=( ["Daniel K"]="Jan" ["Shelley"]="Oct" ["Hana"]="Oct" )
declare -A birthdays2=( ["Daniel K"]="Jan2" ["Shelley"]="Oct2" ["Hana"]="Oct2" )



#####################################################################################################
#
#       BASH COMMON FUNCTIONS
#
#####################################################################################################



# fast_argparse {returnarray} {positionalargs} {flaggedargs} {"$@"}
fnname="fast_argparse"; echo "Starting tests for: $fnname"
unset input;    declare -a input=( "val1" "val2" )
unset output;   declare -A output=()
unset correct;  declare -A correct=( [var1]="val1" [var2]="val2" )
fast_argparse output "var1 var2" "var3 var4" "${input[@]}"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input=( "--var4" "val4" "val1" "val2" "-var3" "val3"  )
unset output;   declare -A output=()
unset correct;  declare -A correct=( [var1]="val1" [var2]="val2" [var3]="val3" [var4]="val4" )
fast_argparse output "var1 var2" "var3 var4" "${input[@]}"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi

# return_error [message]

# get_type {varname} {typevarname}
fnname="get_type"; echo "Starting tests for: $fnname"
unset input;    declare -A input=()
unset output;   output=""
unset correct;  correct="A"
get_type input output
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input=()
unset output;   output=""
unset correct;  correct="a"
get_type input output
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=""
unset output;   output=""
unset correct;  correct="s"
get_type input output
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi

# require_type_a {varname} [typevarname]

# require_type_A {varname} [typevarname]

# require_type_s {varname} [typevarname]

# is_root
fnname="is_root"; echo "Starting tests for: $fnname"
unset input;    input="no sudo"
unset output;
unset correct;  correct=1
is_root; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="with sudo"
unset output;
unset correct;  correct=0
sudo bash -c "source common-functions.sh; is_root"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi

# require_root

# require_non_root

# get_script_dir {strname}

# get_user_home {strname} [user]

# compare_string_lt {str1} {str2}

# compare_numeric_lt {num1} {num2}

# compare_modtime_older {file1} {file2}

# equal_arrays {arrname1} {arrname2}
fnname="equal_arrays"; echo "Starting tests for: $fnname"
unset input;    declare -a input; copy_array months input
unset output;   
unset correct;  correct=0
equal_arrays months input; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input; copy_array months input
unset output;   
unset correct;  correct=0
equal_arrays input months; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input; copy_array months input; input+=( "newmonth" )
unset output;   
unset correct;  correct=1
equal_arrays months input; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input; copy_array months input; input+=( "newmonth" ) 
unset output;   
unset correct;  correct=1
equal_arrays input months; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input; copy_array months input; remove_value input "Jan"
unset output;   
unset correct;  correct=1
equal_arrays months input; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input; copy_array months input; remove_value input "Jan"
unset output;   
unset correct;  correct=1
equal_arrays input months; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input=()
unset output;   
unset correct;  correct=0
equal_arrays input input; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input=()
unset output;   
unset correct;  correct=1
equal_arrays input months; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input; copy_array birthdays input
unset output;   
unset correct;  correct=0
equal_arrays birthdays input; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input; copy_array birthdays input
unset output;   
unset correct;  correct=0
equal_arrays input birthdays; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input; copy_array birthdays input; input[newkey]="newval"
unset output;   
unset correct;  correct=1
equal_arrays birthdays input; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input; copy_array birthdays input; input[newkey]="newval"
unset output;   
unset correct;  correct=1
equal_arrays input birthdays; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input; copy_array birthdays input; remove_value input "Jan"
unset output;   
unset correct;  correct=1
equal_arrays birthdays input; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input; copy_array birthdays input; remove_value input "Jan"
unset output;   
unset correct;  correct=1
equal_arrays input birthdays; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input; copy_array birthdays input; input["Daniel K"]="Feb"
unset output;   
unset correct;  correct=1
equal_arrays birthdays input; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input; copy_array birthdays input; input["Daniel K"]="Feb"
unset output;   
unset correct;  correct=1
equal_arrays input birthdays; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input=()
unset output;   
unset correct;  correct=0
equal_arrays input input; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input=()
unset output;   
unset correct;  correct=1
equal_arrays input birthdays; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi

# equal_sets {set1} {set2}

# is_subset {set1} {set2}

# is_numeric {str}

# is_integer {str}

# is_integer_ge_0 {str}

# is_integer_gt_0 {str}

# trim [strname]
fnname="trim"; echo "Starting tests for: $fnname"
unset input;    input=$'string without leading or trailing whitespace'
unset output;   output="$input"
unset correct;  correct=$'string without leading or trailing whitespace'
trim output;
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=$'\n\t string with leading whitespace'
unset output;   output="$input"
unset correct;  correct=$'string with leading whitespace'
trim output;
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=$'string with trailing whitespace\n\t '
unset output;   output="$input"
unset correct;  correct=$'string with trailing whitespace'
trim output;
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=$'\n\t string with \n both\n\t '
unset output;   output="$input"
unset correct;  correct=$'string with \n both'
trim output;
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=$'\n\t string with \n both, but piped in\n\t '
unset output;   
unset correct;  correct=$'string with \n both, but piped in'
output="$(trim < <(echo "$input"))"
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi

# get_basename {varname} {path} [suffix]

# get_dirname {varname} {path}

# get_fileext {varname} {path}

# print_octal {str}

# print_var {arrayname}
fnname="print_var"; echo "Starting tests for: $fnname"
unset input;    declare -a input; copy_array months input
unset output;   
unset correct;  correct=0
print_var input > /dev/null; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input; copy_array birthdays input
unset output;   
unset correct;  correct=0
print_var input > /dev/null; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi

# str_to_arr {arrayname} [strname] [-e element_sep] [-p pair_sep]
fnname="str_to_arr"; echo "Starting tests for: $fnname"
unset input;    input=$'space separated string 1'
unset output;   declare -a output=()
unset correct;  declare -a correct=( 'space' 'separated' 'string' '1' )
str_to_arr output input -e $' '
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    input=$'tab \tseparated str\ting 1'
unset output;   declare -a output=()
unset correct;  declare -a correct=( 'tab' 'separated str' 'ing 1' )
str_to_arr output input -e $'\t'
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    input=$'\nnewline\nseparated\nstring\n1\n'
unset output;   declare -a output=()
unset correct;  declare -a correct=( 'newline' 'separated' 'string' '1' )
str_to_arr output input -e $'\n'
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    input=$'space separated pipe 1'
unset output;   declare -a output=()
unset correct;  declare -a correct=( 'space' 'separated' 'pipe' '1' )
str_to_arr output -e $' ' < <(printf "$input")
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    input=$'\nnewline\nseparated\npipe\n1'
unset output;   declare -a output=()
unset correct;  declare -a correct=( 'newline' 'separated' 'pipe' '1' )
str_to_arr output -e $'\n' < <(printf "$input")
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    input=$'space=A separated=B string=C 2=D'
unset output;   declare -A output=()
unset correct;  declare -A correct=( ['space']=A ['separated']=B ['string']=C ['2']=D )
str_to_arr output input -e $' ' -p '='
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    input=$'tab =A\tseparated str=B\ting 2=C'
unset output;   declare -A output=()
unset correct;  declare -A correct=( ['tab ']=A ['separated str']=B ['ing 2']=C )
str_to_arr output input -e $'\t' -p '='
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    input=$'\nnewline=A\nseparated=B\nstring=C\n2=D\n'
unset output;   declare -A output=()
unset correct;  declare -A correct=( ['newline']=A ['separated']=B ['string']=C ['2']=D )
str_to_arr output input -e $'\n' -p '='
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    input=$'space=A separated=B pipe=C 2=D'
unset output;   declare -A output=()
unset correct;  declare -A correct=( ['space']=A ['separated']=B ['pipe']=C ['2']=D )
str_to_arr output -e $' ' -p '=' < <(printf "$input")
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    input=$'\nnewline=A\nseparated=B\npipe=C\n2=D'
unset output;   declare -A output=()
unset correct;  declare -A correct=( ['newline']=A ['separated']=B ['pipe']=C ['2']=D )
str_to_arr output -e $'\n' -p '=' < <(printf "$input")
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi

# arr_to_str {arrayname} [strname] [-e element_sep] [-p pair_sep]
fnname="arr_to_str"; echo "Starting tests for: $fnname"
unset input;    declare -a input=( 'space' 'separated' 'string' '1' )
unset outstr;   outstr=""
unset outarr;   declare -a outarr;
unset correct;  correct=$'space separated string 1 '
arr_to_str input outstr -e $' '
str_to_arr outarr outstr -e $' '
if [[ "$outstr" != "$correct" ]]; then failure_report "$fnname" input outstr correct; fi
if ! equal_arrays outarr input; then failure_report "$fnname" input outarr input; fi
unset input;    declare -a input=( 'newline' 'separated' 'string' '1' )
unset outstr;   outstr=""
unset outarr;   declare -a outarr;
unset correct;  correct=$'newline\nseparated\nstring\n1\n'
arr_to_str input outstr -e $'\n'
str_to_arr outarr outstr -e $'\n'
if [[ "$outstr" != "$correct" ]]; then failure_report "$fnname" input outstr correct; fi
if ! equal_arrays outarr input; then failure_report "$fnname" input outarr input; fi
unset input;    declare -a input=( 'space' 'separated' 'pipe' '1' )
unset outstr;   outstr=""
unset outarr;   declare -a outarr;
unset correct;  correct=$'space separated pipe 1 '
outstr="$(arr_to_str input -e $' ')"
str_to_arr outarr outstr -e $' '
if [[ "$outstr" != "$correct" ]]; then failure_report "$fnname" input outstr correct; fi
if ! equal_arrays outarr input; then failure_report "$fnname" input outarr input; fi
unset input;    declare -a input=( 'newline' 'separated' 'pipe' '1' )
unset outstr;   outstr=""
unset outarr;   declare -a outarr;
unset correct;  correct=$'newline\nseparated\npipe\n1'
outstr="$(arr_to_str input -e $'\n')"
str_to_arr outarr outstr -e $'\n'
if [[ "$outstr" != "$correct" ]]; then failure_report "$fnname" input outstr correct; fi
if ! equal_arrays outarr input; then failure_report "$fnname" input outarr input; fi
unset input;    declare -A input=( ['space']=A ['separated']=B ['string']=C ['2']=D )
unset outstr;   outstr=""
unset outarr;   declare -A outarr;
unset correct;  declare -A correct; copy_array input correct
arr_to_str input outstr -e $' ' -p '='
str_to_arr outarr outstr -e $' ' -p '='
if ! equal_arrays outarr correct; then failure_report "$fnname" input outarr correct; fi
unset input;    declare -A input=( ['newline']=A ['separated']=B ['string']=C ['2']=D )
unset outstr;   outstr=""
unset outarr;   declare -A outarr;
unset correct;  declare -A correct; copy_array input correct
arr_to_str input outstr -e $'\n' -p '='
str_to_arr outarr outstr -e $'\n' -p '='
if ! equal_arrays outarr correct; then failure_report "$fnname" input outarr correct; fi
unset input;    declare -A input=( ['space']=A ['separated']=B ['pipe']=C ['2']=D )
unset outstr;   outstr=""
unset outarr;   declare -A outarr;
unset correct;  declare -A correct; copy_array input correct
outstr="$(arr_to_str input -e $' ' -p '=')"
str_to_arr outarr outstr -e $' ' -p '='
if ! equal_arrays outarr correct; then failure_report "$fnname" input outarr correct; fi
unset input;    declare -A input=( ['newline']=A ['separated']=B ['pipe']=C ['2']=D )
unset outstr;   outstr=""
unset outarr;   declare -A outarr;
unset correct;  declare -A correct; copy_array input correct
outstr="$(arr_to_str input -e $'\n' -p '=')"
str_to_arr outarr outstr -e $'\n' -p '='
if ! equal_arrays outarr correct; then failure_report "$fnname" input outarr correct; fi

# copy_array {sourcename} {destname}
fnname="copy_array"; echo "Starting tests for: $fnname"
unset input;    declare -a input=( "asdf1" "asdf 2" $'asdf\t3')
unset output;   declare -a output=()
unset correct;  declare -a correct=( "asdf1" "asdf 2" $'asdf\t3')
copy_array input output
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input=( ['var1']="asdf1" ['var 2']="asdf 2" [$'var\t3']=$'asdf\t3' )
unset output;   declare -A output=()
unset correct;  declare -A correct=( ['var1']="asdf1" ['var 2']="asdf 2" [$'var\t3']=$'asdf\t3' )
copy_array input output
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input=( "asdf1" "asdf 2" $'asdf\t3')
unset output;   declare -A output=()
unset correct;  declare -A correct=( ['0']="asdf1" ['1']="asdf 2" ['2']=$'asdf\t3' )
copy_array input output
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input=( [0]="asdf1" [1]="asdf 2" [2]=$'asdf\t3' ['-1']="invalididx" ['asdf']="invalididx" )
unset output;   declare -a output=()
unset correct;  declare -a correct=( "asdf1" "asdf 2" $'asdf\t3')
copy_array input output
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi

# sort_array {inarrname} {outarrname} [comparison]

# has_value {arrayname} {value}
fnname="has_value"; echo "Starting tests for: $fnname"
unset input;    input="Jan"
unset output;   
unset correct;  correct=0
has_value months "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Oct"
unset output;   
unset correct;  correct=0
has_value months "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="oct"
unset output;   
unset correct;  correct=1
has_value months "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=""
unset output;   
unset correct;  correct=1
has_value months "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Jan"
unset output;   
unset correct;  correct=0
has_value birthdays "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Oct"
unset output;   
unset correct;  correct=0
has_value birthdays "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="oct"
unset output;   
unset correct;  correct=1
has_value birthdays "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=""
unset output;   
unset correct;  correct=1
has_value birthdays "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi

# has_key {arrayname} {key}
fnname="has_key"; echo "Starting tests for: $fnname"
unset input;    input="0"
unset output;   
unset correct;  correct=0
has_key months "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="11"
unset output;   
unset correct;  correct=0
has_key months "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="12"
unset output;   
unset correct;  correct=1
has_key months "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="-1"
unset output;   
unset correct;  correct=1
has_key months "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Jan"
unset output;   
unset correct;  correct=1
has_key months "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=""
unset output;   
unset correct;  correct=1
has_key months "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Daniel K"
unset output;   
unset correct;  correct=0
has_key birthdays "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Shelley"
unset output;   
unset correct;  correct=0
has_key birthdays "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Hana"
unset output;   
unset correct;  correct=0
has_key birthdays "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Jan"
unset output;   
unset correct;  correct=1
has_key birthdays "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=""
unset output;   
unset correct;  correct=1
has_key birthdays "$input"; output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi

# find_value {arrayname} {value} {idxvarname} 
fnname="find_value"; echo "Starting tests for: $fnname"
unset input;    input="Jan"
unset output;   
unset correct;  correct=0
find_value months "$input" output
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Oct"
unset output;   
unset correct;  correct=9
find_value months "$input" output
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="oct"
unset output;   
unset correct;  correct=""
find_value months "$input" output
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=""
unset output;   
unset correct;  correct=""
find_value months "$input" output
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Jan"
unset output;   
unset correct;  correct="Daniel K"
find_value birthdays "$input" output
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Oct"
unset output;   
unset correct1;  correct1="Shelley"
unset correct2;  correct2="Hana"
find_value birthdays "$input" output
if [[ "$output" != "$correct1" && "$output" != "$correct2" ]]; then failure_report "$fnname" input output correct1; fi
unset input;    input="oct"
unset output;   
unset correct;  correct=""
find_value birthdays "$input" output
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=""
unset output;   
unset correct;  correct=""
find_value birthdays "$input" output
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi

# insert_value {arrayname} {idx} {value}
fnname="insert_value"; echo "Starting tests for: $fnname"
unset input;   input=5
unset output;  declare -a output; copy_array months output
unset correct; declare -a correct=("Jan" "Feb" "Mar" "Apr" "May" "newmonth" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
insert_value output "$input" "newmonth"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;   input=0
unset output;  declare -a output; copy_array months output
unset correct; declare -a correct=("newmonth" "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
insert_value output "$input" "newmonth"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;   input=15
unset output;  declare -a output; copy_array months output
unset correct; declare -a correct=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec" "newmonth")
insert_value output "$input" "newmonth"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;   input="-1"
unset output;  declare -a output; copy_array months output
unset correct; declare -a correct=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
insert_value output "$input" "newmonth"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;   input="asdf"
unset output;  declare -a output; copy_array months output
unset correct; declare -a correct=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
insert_value output "$input" "newmonth"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;   input=5
unset output;  declare -A output; copy_array birthdays output
unset correct; declare -A correct; copy_array birthdays correct; correct["$input"]="newmonth"
insert_value output "$input" "newmonth"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;   input="Daniel K"
unset output;  declare -A output; copy_array birthdays output
unset correct; declare -A correct; copy_array birthdays correct; correct["$input"]="newmonth"
insert_value output "$input" "newmonth"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;   input=""
unset output;  declare -A output; copy_array birthdays output
unset correct; declare -A correct; copy_array birthdays correct
insert_value output "$input" "newmonth"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi

# insert_value_before {arrayname} {insertbefore} {value}

# insert_value_after {arrayname} {insertafter} {value}

# remove_value {arrayname} {value} [removedkey_varname]
fnname="remove_value"; echo "Starting tests for: $fnname"
unset input;    input="Jan"
unset output;   declare -a output; copy_array months output
unset correct;  declare -a correct=("Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
unset output2;  output2=""
unset correct2; correct2="0"
remove_value output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input="Dec"
unset output;   declare -a output; copy_array months output
unset correct;  declare -a correct=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov")
unset output2;  output2=""
unset correct2; correct2="11"
remove_value output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input="1"
unset output;   declare -a output; copy_array months output
unset correct;  declare -a correct; copy_array months correct
unset output2;  output2=""
unset correct2; correct2=""
remove_value output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input=""
unset output;   declare -a output; copy_array months output
unset correct;  declare -a correct; copy_array months correct
unset output2;  output2=""
unset correct2; correct2=""
remove_value output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input="Jan"
unset output;   declare -A output; copy_array birthdays output
unset correct;  declare -A correct=( ["Shelley"]="Oct" ["Hana"]="Oct" )
unset output2;  output2=""
unset correct2; correct2="Daniel K"
remove_value output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input="Jan"
unset output;   declare -A output; copy_array birthdays output
unset correct;  declare -A correct=( ["Shelley"]="Oct" ["Hana"]="Oct" )
unset output2;  output2=""
unset correct2; correct2=""
remove_value output "$input" output2
remove_value output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input="Oct"
unset output;   declare -A output; copy_array birthdays output
unset correct;  declare -A correct=( ["Daniel K"]="Jan" )
remove_value output "$input" 
remove_value output "$input"
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi

# remove_key {arrayname} {key} [removedval_varname]
fnname="remove_key"; echo "Starting tests for: $fnname"
unset input;    input="0"
unset output;   declare -a output; copy_array months output
unset correct;  declare -a correct=("Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
unset output2;  output2=""
unset correct2; correct2="Jan"
remove_key output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input="11"
unset output;   declare -a output; copy_array months output
unset correct;  declare -a correct=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov")
unset output2;  output2=""
unset correct2; correct2="Dec"
remove_key output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input="Jan"
unset output;   declare -a output; copy_array months output
unset correct;  declare -a correct; copy_array months correct
unset output2;  output2=""
unset correct2; correct2=""
remove_key output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input=""
unset output;   declare -a output; copy_array months output
unset correct;  declare -a correct; copy_array months correct
unset output2;  output2=""
unset correct2; correct2=""
remove_key output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input="Daniel K"
unset output;   declare -A output; copy_array birthdays output
unset correct;  declare -A correct=( ["Shelley"]="Oct" ["Hana"]="Oct" )
unset output2;  output2=""
unset correct2; correct2="Jan"
remove_key output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input="Jan"
unset output;   declare -A output; copy_array birthdays output
unset correct;  declare -A correct; copy_array birthdays correct
unset output2;  output2=""
unset correct2; correct2=""
remove_key output "$input" output2
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi
unset input;    input=""
unset output;   declare -A output; copy_array birthdays output
unset correct;  declare -A correct; copy_array birthdays correct
unset output2;  output2=""
unset correct2; correct2=""
remove_key output "$input" 
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
if [[ "$output2" != "$correct2" ]]; then failure_report "$fnname" input output2 correct2; fi

# foreach {inarrayname} {function_call} [outarrayname]
fnname="foreach"; echo "Starting tests for: $fnname"
unset input;    declare -a input; copy_array months input
unset output;   declare -a output=()
unset correct;  declare -a correct; copy_array months2 correct
foreach input 'VAL="${VAL}2"' output
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input=()
unset output;   declare -a output; copy_array months output
unset correct;  declare -a correct; copy_array months2 correct
foreach output 'VAL="${VAL}2"'
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input; copy_array months input
unset output;   declare -A output=()
unset correct;  declare -A correct=( [1]=Jan [2]=Feb [3]=Mar [4]=Apr [5]=May [6]=Jun [7]=Jul [8]=Aug [9]=Sep [10]=Oct [11]=Nov [12]=Dec )
foreach input '((KEY=$KEY+1))' output
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input; copy_array birthdays input
unset output;   declare -A output=()
unset correct;  declare -A correct; copy_array birthdays2 correct
foreach input 'VAL="${VAL}2"' output
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi

# make_unique {source_arrname} {dest_arrname}
fnname="make_unique"; echo "Starting tests for: $fnname"
unset input;    declare -a input=( "asdf1" "asdf2" "asdf2" "asdf1")
unset output;   declare -a output=()
unset correct;  declare -a correct=( "asdf1" "asdf2" )
make_unique input output
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input=( [var1]=asdf1 [var2]=asdf2 [var3]=asdf2 )
unset output;   declare -A output=()
unset correct1; declare -A correct1=( [var1]=asdf1 [var2]=asdf2 )
unset correct2; declare -A correct2=( [var1]=asdf1 [var3]=asdf2 )
make_unique input output
if ! equal_arrays output correct1; then 
    if ! equal_arrays output correct2; then failure_report "$fnname" input output correct1; fi; fi

# set_diff {dest_arrname} {arrname_A} {arrname_B}
fnname="set_diff"; echo "Starting tests for: $fnname"
unset input;    declare -a input=( "Jan" "Mar" "May")
unset output;   declare -a output=()
unset correct;  declare -a correct=("Feb" "Apr" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
set_diff output months input
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input=( "asdf" "" )
unset output;   declare -a output=()
unset correct;  declare -a correct; copy_array months correct
set_diff output months input
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input=()
unset output;   declare -a output=()
unset correct;  declare -a correct; copy_array months correct
set_diff output months input
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -A input=( ["Shelley"]="Oct" ["Hana"]="Oct" )
unset output;   declare -A output=()
unset correct;  declare -A correct=( ["Daniel K"]="Jan" )
set_diff output birthdays input 
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input=( "Oct" )
unset output;   declare -A output=()
unset correct;  declare -A correct=( ["Daniel K"]="Jan" )
set_diff output birthdays input 
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi
unset input;    declare -a input=( "Oct" "Jan"  )
unset output;   declare -A output=()
unset correct;  declare -A correct=()
set_diff output birthdays input 
if ! equal_arrays output correct; then failure_report "$fnname" input output correct; fi

# set_union {dest_arrname} [arrname_A] [arrname_B] [arrname_C] ...

# set_intersection {dest_arrname} [arrname_A] [arrname_B] [arrname_C] ...



#####################################################################################################
#
#       BASH COMMON-IO FUNCTIONS
#
#####################################################################################################



#####################################################################################################
#
#       BASH COMMON-SYSCONFIG FUNCTIONS
#
#####################################################################################################



#####################################################################################################
#
#       BASH COMMON-TABLES FUNCTIONS
#
#####################################################################################################



#####################################################################################################
#
#       BASH COMMON-UI FUNCTIONS
#
#####################################################################################################



# confirmation_prompt [prompt]
fnname="confirmation_prompt"; echo "Starting tests for: $fnname"
unset input;    input="Y"
unset output;
unset correct;  correct=0
confirmation_prompt "heres a prompt" < <(echo "$input"); output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="y"
unset output;
unset correct;  correct=0
confirmation_prompt "heres a prompt" < <(echo "$input"); output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="N"
unset output;
unset correct;  correct=1
confirmation_prompt "heres a prompt" < <(echo "$input"); output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="n"
unset output;
unset correct;  correct=1
confirmation_prompt < <(echo "$input"); output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="Y"
unset output;
unset correct;  correct=0
confirmation_prompt < <(echo "$input"); output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input=""
unset output;
unset correct;  correct=1
confirmation_prompt < <(echo "$input"); output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi
unset input;    input="asdf"
unset output;
unset correct;  correct=1
confirmation_prompt < <(echo "$input"); output=$?
if [[ "$output" != "$correct" ]]; then failure_report "$fnname" input output correct; fi

# require_confirmation [prompt]

# function_select_menu {optarrayname} {funcarrayname} {title} {description}




#####################################################################################################
#
#       BASH COMMON-WSL FUNCTIONS
#
#####################################################################################################


