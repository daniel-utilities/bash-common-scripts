#!/bin/bash
source common-functions.sh
source wsl-functions.sh



declare -a months=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
echo "months:"
print_arr months
echo
echo


str=""
arr_to_str months $' | ' str
echo "arr_to_str \$' | '"
echo "str:"
echo "$str"
echo

trim str
echo "trim"
echo "str:"
echo "$str"
echo

declare -a arr=()
str_to_arr arr '|' str
echo "str_to_arr"
echo "arr:"
print_arr arr
echo
echo

operate_on_each "trim REF" tokenize=array arr
echo "operate_on_each trim"
echo "arr:"
print_arr arr
echo
echo


declare -a months=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
declare -a arr=()
arr_to_str months $' | ' | trim | operate_on_each "trim REF" tokenize=stdin '|' | str_to_arr arr '|'
echo "All operations piped together"
echo "arr:"
print_arr arr
echo
echo