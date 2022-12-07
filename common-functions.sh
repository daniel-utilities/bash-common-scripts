#####################################################################################################
#
#       BASH COMMON FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-scripts/common-functions.sh
#
#####################################################################################################
#       GLOBAL VARIABLES:
#
TRUE=0
FALSE=1
unset __COMMON_FUNCS_AVAILABLE  # Set to TRUE at the end of this file.
#
#####################################################################################################
#       FUNCTION REFERENCE:
#
# fast_argparse {returnarray} {positionalargs} {flaggedargs} {"$@"}
#   Collects positional and flagged arguments into an associative array.
# return_error [message]
#   Prints an error message then returns from the function which called this.
# get_type {varname} {typevarname}
#   Returns a single character representing the type of data contained in varname: a, A, s
# require_type_a {varname} [typevarname]
#   Returns from the calling function with an error message if the variable is not an indexable array (type 'a')
# require_type_A {varname} [typevarname]
#   Returns from the calling function with an error message if the variable is not an associative array (type 'A')
# require_type_s {varname} [typevarname]
#   Returns from the calling function with an error message if the variable is not a string (type 's').
# is_root
#   Returns TRUE ($?==0) if script is being run by root user.
# require_root
#   Returns from the calling function with an error message if not being run by root user.
# require_non_root
#   Returns from the calling function with an error message if being run by root user.
# get_script_dir {strname}
#   Returns the full path containing the currently-running script.
# get_user_home {strname} [user]
#   Gets the home directory of the specified user.
# compare_string_lt {str1} {str2}
#   Returns TRUE ($?==0) if str1 is alphabetically before str2
# compare_numeric_lt {num1} {num2}
#   Returns TRUE ($?==0) if num1 < num2
# compare_modtime_older {file1} {file2}
#   Returns TRUE ($?==0) if file1 is older than file2
# equal_arrays {arrname1} {arrname2}
#   Returns TRUE ($?==0) if array1 has the same keys and values as array2.
# equal_sets {set1} {set2}
#   Returns TRUE ($?==0) if set1 and set2 are equal (contain same elements, ordering doesn't matter)
# is_subset {set1} {set2}
#   Returns TRUE ($?==0) if set1 is a subset of set2 (set2 contains all elements of set1)
# is_numeric {str}
#   Returns TRUE ($?==0) if str is an real number
# is_integer {str}
#   Returns TRUE ($?==0) if str is an integer
# is_integer_ge_0 {str}
#   Returns TRUE ($?==0) if str is an integer >= 0
# is_integer_gt_0 {str}
#   Returns TRUE ($?==0) if str is an integer > 0
# trim [strname]
#   Removes leading and trailing whitespace from a string (including newlines)
# get_basename {varname} {path} [suffix]
#   Returns the base name of the file or directory. Similar to 'basename' command.
# get_dirname {varname} {path}
#   Returns the parent path to the file or folder. Similar to 'dirname' command.
# get_fileext {varname} {path}
#   Returns the file extension of the specified file, or nothing if the filename has no extension.
# print_octal {str}
#   Prints the octal representation of the string over top of its ASCII counterpart.
# printvar {variablename}
# print_var {variablename}
#   Prints the contents of a string or array to stdout.
# str_to_arr {arrayname} [strname] [-e element_sep] [-p pair_sep]
#   Splits a string into tokens and appends each one to an array.
# arr_to_str {arrayname} [strname] [-e element_sep] [-p pair_sep]
#   Prints an array as a string. Prints members only, or as key/value pairs.
# copy_array {sourcename} {destname}
#   Each element of the source array is copied into the destination array.
# sort_array {inarrname} {outarrname} [comparison]
#   Sorts the elements of a (nonassociative) array.
# has_value {arrayname} {value}
#   Returns TRUE ($?==0) if value is a member of the array.
# has_key {arrayname} {key}
#   Returns TRUE ($?==0) if key is a set key or index in the array.
# find_value {arrayname} {value} {idxvarname} 
#   Searches an array for a value, then returns the corresponding key or index.
# insert_value {arrayname} {idx} {value}
#   Inserts the value into the array at the specified index, shifting over all following elements.
# insert_value_before {arrayname} {insertbefore} {value}
#   Inserts the value into the array before the first instance of another value.
# insert_value_after {arrayname} {insertafter} {value}
#   Inserts the value into the array after the first instance of another value.
# remove_value {arrayname} {value} [removedkey_varname]
#   Removes first occurrance of 'value' (and its associated key) from the array.
# remove_key {arrayname} {key} [removedval_varname]
#   Removes the key/idx (and its associated value) from the array.
# foreach {inarrayname} {function_call} [outarrayname]
#   Runs the specified function on every element of the input array.
# make_unique {source_arrname} {dest_arrname}
#   Dest array is erased and replaced with only the unique elements from the source. 
# set_diff {dest_arrname} {arrname_A} {arrname_B}
#   Dest array is set equal to A - B ; the elements of A, removing the elements of B.
# set_union {dest_arrname} [arrname_A] [arrname_B] [arrname_C] ...
#   Stores the union of elements of the arrays; dest = A U B U ...
# set_intersection {dest_arrname} [arrname_A] [arrname_B] [arrname_C] ...
#   Stores the intersection of elements of the arrays; dest = A int B int ...
#
#####################################################################################################
#       FORMAT:
# func_name {required_arg} [optional_arg]
#   Description
# Inputs:
#   $GLOBALVAR   - Required global variable read by the function.
#   required_arg - desc
#   optional_arg - (Optional)
#   &0 (stdin)   - Function reads from stdin
# Outputs:
#   $GLOBALVAR   - Global variable written to by the function.
#   &1 (stdout)  - Function prints to standard output channel.
#   &2 (stderr)  - Function prints to standard error channel.
#   $?           - Numeric exit value; 0 indicates success.
#
#####################################################################################################


# fast_argparse {returnarray} {positionalargs} {flaggedargs} {"$@"}
#   Collects positional and flagged arguments into an associative array.
# Inputs:
#   positionalargs - String containing space-separated list of positional argument variable names.
#   flaggedargs    - String containing space-separated list of acceptable flags
#   "$@"           - Quoted string of all arguments.
# Outputs:
#   returnarray    - Name of associative array (declare -A name) in which to return the collected values.
#                    CANNOT be named: _args
#
function fast_argparse() {
    local -n _args=$1
    local -a pos=($2)
    local -a flg=($3)
    shift 3
    local flag poscnt=0
    while [[ "$#" -gt 0 ]]; do
        flag="${1##*-}"
        if [[ "$1" == -* ]]; then   # it's a flag argument
            if has_value flg "$flag" && [[ "$#" -ge 2 ]]; then   # it's a recognized flag
                _args["$flag"]="$2"
                shift 2
            else
                return_error "Invalid argument: $1 $2"
            fi
        else                        # it's a positional argument
            if [[ $poscnt -lt "${#pos[@]}" ]]; then   # it's a recognized positional arg
                _args["${pos[poscnt]}"]="$1"
                ((poscnt=poscnt+1))
                shift 1
            else
                return_error "Provided too many positional arguments"
            fi
        fi
    done
}


# return_error [message]
#   Prints an error message then returns from the function which called this.
# Outputs:
#   &2 (stderr) - Function prints message to standard error channel
#   $?          - Numeric exit value; always 1 (error has occurred)
#
function return_error(){
    if [[ "$1" == "" ]]; then local MSG="unspecified"
    else                      local MSG="$1"
    fi
    "${__ERROR:?$MSG ($0)}"
}


# get_type {varname} {typevarname}
#   Returns a single character representing the type of data contained in varname: a, A, s
# Inputs:
#   varname     - Name of variable to get type.
#                 CANNOT be named: __var
# Outputs:
#   typevarname - Name of variable to store type character
#                   's' : string
#                   'a' : non-associative array (declare -a varname)
#                   'A' : associative array (declare -A varname)
#                 CANNOT be named: __vartype
#
function get_type(){
    local -n var_=$1
    local -n vartype_=$2

    vartype_="${var_@a}"
    if [[ "$vartype_" == *a* ]];   then vartype_=a # is non-associative array
    elif [[ "$vartype_" == *A* ]]; then vartype_=A # is associative array
    else                                vartype_=s # is string
    fi
}


# require_type_a {varname} [typevarname]
#   Returns from the calling function with an error message if the variable is not an indexable array (type 'a')
# Inputs:
#   varname     - Name of variable to get type.
# Outputs:
#   typevarname - Name of variable to store type character.
#   &2 (stderr) - Function prints to standard error channel.
#   $?          - Numeric exit value; 0 indicates the variable is an indexable array.
#
function require_type_a() {
    local -n __var=$1
    if [[ "$2" == "" ]]; then local __vartype
    else                      local -n __vartype="$2"
    fi

    __vartype="${__var@a}"
    if [[ "$__vartype" == *a* ]];   then __vartype=a; return 0
    elif [[ "$__vartype" == *A* ]]; then __vartype=A
    else                                 __vartype=s
    fi
    return_error "variable '$1' (of type '$__vartype') is not an indexable array (type 'a')."
}


# require_type_A {varname} [typevarname]
#   Returns from the calling function with an error message if the variable is not an associative array (type 'A')
# Inputs:
#   varname     - Name of variable to get type.
# Outputs:
#   typevarname - Name of variable to store type character.
#   &2 (stderr) - Function prints to standard error channel.
#   $?          - Numeric exit value; 0 indicates the variable is an associative array.
#
function require_type_A() {
    local -n __var=$1
    if [[ "$2" == "" ]]; then local __vartype
    else                      local -n __vartype="$2"
    fi

    __vartype="${__var@a}"
    if [[ "$__vartype" == *A* ]];   then __vartype=A; return 0
    elif [[ "$__vartype" == *a* ]]; then __vartype=a 
    else                                 __vartype=s
    fi
    return_error "variable '$1' (of type '$__vartype') is not an associative array (type 'A')."
}


# require_type_s {varname} [typevarname]
#   Returns from the calling function with an error message if the variable is not a string (type 's').
# Inputs:
#   varname     - Name of variable to get type.
# Outputs:
#   typevarname - Name of variable to store type character.
#   &2 (stderr) - Function prints to standard error channel.
#   $?          - Numeric exit value; 0 indicates the variable is a string.
#
function require_type_s() {
    local -n __var=$1
    if [[ "$2" == "" ]]; then local __vartype
    else                      local -n __vartype="$2"
    fi

    __vartype="${__var@a}"
    if [[ "$__vartype" == *s* ]];   then __vartype=s; return 0
    elif [[ "$__vartype" == *a* ]]; then __vartype=a
    elif [[ "$__vartype" == *A* ]]; then __vartype=A 
    else                                 __vartype=s; return 0
    fi
    return_error "variable '$1' (of type '$__vartype') is not a string (type 's')."
}


# is_root
#   Returns TRUE ($?==0) if script is being run by root user.
# Example:
#   is_root && echo yes || echo no
# Outputs:
#   $?          - Numeric exit value; 0 indicates this script is being run by root.
#
function is_root() {
    [[ "$EUID" -eq 0 ]] && return 0 || return 1
}


# require_root
#   Returns from the calling function with an error message if not being run by root user.
# Inputs:
#   None
# Outputs:
#   &2 (stderr) - Function prints to standard error channel.
#   $?          - Numeric exit value; 0 indicates this script is being run by root.
#
function require_root() {
    is_root || return_error "Script can only be run by root. Retry with sudo."
}


# require_non_root
#   Returns from the calling function with an error message if being run by root user.
# Inputs:
#   None
# Outputs:
#   &2 (stderr) - Function prints to standard error channel.
#   $?          - Numeric exit value; 0 indicates this script is not root.
#
function require_non_root() {
    is_root && return_error "Script can not be run by root. Retry without sudo."
}


# get_script_dir {strname}
#   Returns the full path containing the currently-running script.
# Inputs:
#   $0              - Script directory is recovered from the $0 command line argument.
# Outputs:
#   strname         - Name of string variable to store the parent directory of the currently-running script.
#
function get_script_dir() {
    local -n __str=$1
    __str="$(dirname "$(readlink -f "$0")")"
}


# get_user_home {strname} [user]
#   Gets the home directory of the specified user.
# Inputs:
#   user        - Username. Defaults to $USER
# Outputs:
#   strname     - Name of string variable to store the home directory of the user, or "" (empty) if not found.
#
function get_user_home() {
    local -n __str=$1
    if [[ "$2" != "" ]]; then local username="$2"
    else                      local username="$USER"
    fi;
    __str="$( getent passwd "$username" | cut -d: -f6 )"
}


# compare_string_lt {str1} {str2}
#   Returns TRUE ($?==0) if str1 is alphabetically before str2.
# Inputs:
#   str1        - First string to compare
#   str2        - Second string to compare
# Outputs:
#   $?          - Numeric exit code; Returns 0 (success) if str1 < str2
#
function compare_string_lt() {
    [[ "$1" < "$2" ]];
}


# compare_numeric_lt {num1} {num2}
#   Returns TRUE ($?==0) if num1 < num2
# Inputs:
#   num1        - First number to compare
#   num2        - Second number to compare
# Outputs:
#   $?          - Numeric exit code; Returns 0 (success) if num1 < num2
#
function compare_numeric() {
    (($1 < $2));
}


# compare_modtime_older {file1} {file2}
#   Returns TRUE ($?==0) if file1 is older than file2
# Inputs:
#   file1       - First file to compare
#   file2       - Second file to compare
# Outputs:
#   $?          - Numeric exit code; Returns 0 (success) if file1 is older than file2
#
function compare_modtime_older() {
    [[ "$1" -ot "$2" ]];
}


# equal_arrays {arrname1} {arrname2}
#   Returns TRUE ($?==0) if array1 has the same keys and values as array2.
# Inputs:
#   arrname1   - Name of array variable (unquoted).
#                 CANNOT be named: _arrref1
#   arrname2   - Name of array variable (unquoted).
#                 CANNOT be named: _arrref2
# Outputs:
#   $?         - Numeric exit code. 0 (success) if every array element in array 1 is the same as array 2, 1 if otherwise.
#
function equal_arrays(){
    if [[ "$1" == "" ]]; then return_error "No array variable specified in position 1."
    else                      local -n _arrref1=$1
                              local type1; get_type _arrref1 type1
                              [[ "$type1" == s ]] && return_error "$1 must be an array";
    fi
    if [[ "$2" == "" ]]; then return_error "No array variable specified in position 2."
    else                      local -n _arrref2=$2
                              local type2; get_type _arrref2 type2
                              [[ "$type2" == s ]] && return_error "$2 must be an array.";
    fi

    # check if same type
    if [[ $type1 != $type2 ]]; then return 1; fi

    # check if same size
    if [[ "${#_arrref1[@]}" != "${#_arrref2[@]}" ]]; then return 1; fi

    # check elements match 1-1 
    local key elem1 elem2
    for key in "${!_arrref1[@]}"; do
        if ! has_key _arrref2 "$key"; then return 1; fi    # Check if key exists in array 2
        elem1="${_arrref1[$key]}"
        elem2="${_arrref2[$key]}"
        if [[ "$elem1" != "$elem2" ]]; then return 1; fi    # Check if key maps to same element in both arrays
    done
    return 0
}


# equal_sets {set1} {set2}
#   Returns TRUE ($?==0) if set1 and set2 are equal (contain same elements, ordering doesn't matter)
# Inputs:
#   set1   - Name of array variable
#   set2   - Name of array variable
# Outputs:
#   $?     - Numeric exit code. 0 (success) if set1 is equal to set2.
#
function equal_sets(){
    if [[ "$1" == "" ]]; then return_error "No array variable specified in position 1."
    else                      local -n _arrref1=$1
    fi
    if [[ "$2" == "" ]]; then return_error "No array variable specified in position 2."
    else                      local -n _arrref2=$2
    fi

    # check if same size
    if [[ "${#_arrref1[@]}" != "${#_arrref2[@]}" ]]; then return 1; fi

    # check that set 2 contains every value of set 1
    local elem1
    for elem1 in "${_arrref1[@]}"; do
        has_value _arrref2 "$elem1" || return 1
    done
    # check that set 1 contains every value of set 2
    local elem2
    for elem2 in "${_arrref2[@]}"; do
        has_value _arrref1 "$elem2" || return 1
    done
    return 0
}


# is_subset {set1} {set2}
#   Returns TRUE ($?==0) if set1 is a subset of set2 (set2 contains all elements of set1)
# Inputs:
#   set1   - Name of array variable
#   set2   - Name of array variable
# Outputs:
#   $?     - Numeric exit code. 0 (success) if set1 is a subset of set2.
#
function is_subset(){
    if [[ "$1" == "" ]]; then return_error "No array variable specified in position 1."
    else                      local -n _arrref1=$1
    fi
    if [[ "$2" == "" ]]; then return_error "No array variable specified in position 2."
    else                      local -n _arrref2=$2
    fi

    # check size(set1) <= size(set2)
    [[ "${#_arrref1[@]}" -le "${#_arrref2[@]}" ]] || return 1

    # check that set 2 contains every value of set 1
    local elem1
    for elem1 in "${_arrref1[@]}"; do
        has_value _arrref2 "$elem1" || return 1
    done
    return 0
}


# is_numeric {str}
#   Returns TRUE ($?==0) if str is an real number
# Inputs:
#   val     - String value
# Outputs:
#   $?      - Numeric exit code; 0 if str is a real number; 1 otherwise
#
function is_numeric() {
    local regex='^(0|-?[1-9][0-9]*)(\.[0-9]+)?$'
    [[ "$1" =~ $regex ]];
}


# is_integer {str}
#   Returns TRUE ($?==0) if str is an integer
# Inputs:
#   val     - String value
# Outputs:
#   $?      - Numeric exit code; 0 if str is an integer, 1 otherwise
#
function is_integer() {
    local regex='^(0|-?[1-9][0-9]*)$'
    [[ "$1" =~ $regex ]];
}


# is_integer_ge_0 {str}
#   Returns TRUE ($?==0) if str is an integer >= 0
# Inputs:
#   val     - String value
# Outputs:
#   $?      - Numeric exit code; 0 if str is an integer >=0, 1 otherwise
#
function is_integer_ge_0() {
    local regex='^(0|[1-9][0-9]*)$'
    [[ "$1" =~ $regex ]];
}


# is_integer_gt_0 {str}
#   Returns TRUE ($?==0) if str is an integer > 0
# Inputs:
#   val     - String value
# Outputs:
#   $?      - Numeric exit code; 0 if str is a positive integer, 1 otherwise
#
function is_integer_gt_0() {
    local regex='^[1-9][0-9]*$'
    [[ "$1" =~ $regex ]];
}


# trim [strname]
#   Removes leading and trailing whitespace from a string (including newlines)
#   WARNING: REF variables do not work when pipes are connected to the function's stdin!
#   Always use process substitution instead.
#   Example:
#       trim < <(printf "$str")
# Inputs:
#   strname     - Name of string variable to trim. CANNOT be named: _strref _out _in
#   &0 (stdin)  - If strname is not specified, stdin is used instead.
# Outputs:
#   strname     - Returns trimmed string back into the nameref.
#   &1 (stdout) - If strname is not specified, prints trimmed string to stdout.
#
function trim() {
    if [[ "$1" == "" ]]; then local _strref="__unset"
    else                      local -n _strref=$1
                              local printf_args="-v _strref"
    fi

    local _in _out  # Set _in from stdin or the pass-by-reference
    if [[ "$_strref" == "__unset" ]]; then
        read -d '' -r _in
    else
        _in="$_strref"
    fi

    # _out is a function of _in
    _in="${_in#"${_in%%[![:space:]]*}"}"
    _in="${_in%"${_in##*[![:space:]]}"}"
    _out="$_in"

    # Print _out to either stdout or the pass-by-reference
    builtin printf $printf_args "%s" "$_out"
}


# get_basename {varname} {path} [suffix]
#   Returns the base name of the file or directory. Similar to 'basename' command.
# Examples:
#   get_basename name "/path/to/a/file.txt"         # variable 'name' now contains "file.txt"
#   get_basename name "/path/to/a/file.txt" ".txt"  # variable 'name' now contains "file"
# Inputs:
#   path        - Path to a file or directory.
#   suffix      - If provided, trim this suffix from the basename as well.
#                 Useful for removing the file extension.
# Outputs:
#   varname     - Returns the base name into this variable.
#                 Base name is the name of the file or directory without its path.
#
function get_basename() {
    local -n __outstr=$1
    local __instr="$2"
    local suffix="$3"
    __instr="${__instr#"${__instr%%[![:space:]]*}"}" # trim leading and trailing whitespace
    __instr="${__instr%"${__instr##*[![:space:]]}"}"
    __instr="${__instr%"${__instr##*[!/]}"}"         # trim trailing slash(s)
    __instr="${__instr##*/}"                         # trim path
    __instr="${__instr%"$suffix"}"                   # trim suffix

    __outstr="$__instr"
}


# get_dirname {varname} {path}
#   Returns the parent path to the file or folder. Similar to 'dirname' command.
# Example:
#   get_dirname dir "/path/to/a/file.txt"   # variable 'dir' now contains "/path/to/a"
# Inputs:
#   path        - Path to a file or directory.
# Outputs:
#   varname     - Returns the directory name into this variable.
#
function get_dirname() {
    local -n __outstr=$1
    local __instr="$2"
    __instr="${__instr#"${__instr%%[![:space:]]*}"}" # trim leading and trailing whitespace
    __instr="${__instr%"${__instr##*[![:space:]]}"}"
    __instr="${__instr%"${__instr##*[!/]}"}"         # trim trailing slash(s)
    __instr="${__instr%/*}"                          # trim basename
    __instr="${__instr%"${__instr##*[!/]}"}"         # trim trailing slash(s) (again, for some weird edge cases)

    __outstr="$__instr"
}


# get_fileext {varname} {path}
#   Returns the file extension of the specified file, or nothing if the filename has no extension.
# Example:
#   get_fileext ext "/path/to/a/file.txt"   # variable 'ext' now contains ".txt"
# Inputs:
#   path        - Path to a file.
# Outputs:
#   varname     - Returns the file extension into this variable.
#                 The file extension (if it exists) always contains the leading '.' .
#
function get_fileext() {
    local -n __outstr=$1
    local __instr="$2"
    __instr="${__instr#"${__instr%%[![:space:]]*}"}" # trim leading and trailing whitespace
    __instr="${__instr%"${__instr##*[![:space:]]}"}"
    __instr="${__instr##*/}"                         # trim path; this eliminates the string if it ends in a /
    __instr="${__instr#"${__instr%.*}"}"             # trim everything before the last '.', or everything if no '.'

    __outstr="$__instr"
}


# print_octal {str}
#   Prints the octal representation of the string over top of its ASCII counterpart.
# Example:
#   print_octal "$IFS"
# Inputs:
#   str         - String to print.
# Outputs:
#   &1 (stdout) - Function prints to standard output channel.
#
function print_octal() {
    printf '%s' "$1" | od -bc
}


# printvar {variablename}
# print_var {variablename}
#   Prints the contents of a string or array to stdout.
# Inputs:
#   variablename  - Name of array variable (unquoted).
#                   CANNOT be named: __var
# Outputs:
#   &1 (stdout)   - Prints the array's contents to stdout.
#
function printvar() {
    print_var "$@"
}
function print_var() {
    if [[ "$1" == "" ]]; then return_error "No variable specified in position 1."
    else                      local -n __var=$1
                              local varname=$1
                              local vartype; get_type $1 vartype
    fi

    if [[ "$vartype" == s ]]; then    # is string
        printf "%s=\"%s\"\n" "$varname" "$__var"

    elif [[ "$vartype" == A ]]; then  # is associative array
        local key len maxlen=0
        local -a keys=("${!__var[@]}") sortedkeys=()
        sort_array keys sortedkeys

        for key in "${sortedkeys[@]}"; do       # get length of longest string (+2)
            ((len="${#key}"+2))
            if [[ $len -gt $maxlen ]]; then maxlen=$len; fi
        done

        printf "%s=\n" "$varname"
        for key in "${sortedkeys[@]}"; do
            printf "%${maxlen}s: \"%s\"\n" "[$key]" "${__var[$key]}"
        done

    elif [[ "$vartype" == a ]]; then  # is associative array
        local key
        local -a keys=("${!__var[@]}") 

        printf "%s=\n" "$varname"
        for key in "${keys[@]}"; do
            printf '%4d: [%s]\n' "$key" "${__var[$key]}"
        done

    fi
}


# str_to_arr {arrayname} [strname] [-e element_sep] [-p pair_sep]
#   Splits a string into tokens and appends each one to an array.
#   WARNING: REF variables do not work when pipes are connected to the function's stdin!
#   Always use process substitution instead.
#   Example:
#       $str_to_arr arr ' ' < <(printf "$str")
# Inputs:
#   strname     - Name of string to read from.
#                 CANNOT be named: __str
#   element_sep - String which separates each array member.
#                 Default: $'\n'.
#   pair_sep    - String to separate each key and value. Ignored if output array is non-associative.
#                 Default: "="
#   &0 (stdin)  - If strname is not specified, reads stdin until EOF is reached.
# Outputs:
#   arrayname   - Name of array variable to store tokens into.
#                 CANNOT be named: __arr
#
function str_to_arr(){
    local -A args=( [e]=$'\n' [p]='=' )
    fast_argparse args "arrname strname" "e p" "$@"
    if [[ "${args[arrname]}" == "" ]]; then return_error "No array variable specified in position 1."
    else                                    local -n __arr=${args[arrname]} # output array
                                            local vartype; get_type __arr vartype
    fi
    if [[ "${args[strname]}" == "" ]]; then local __str=""                  # read from stdin (fid 0)
                                            local fid=0
    else                                    local -n __str=${args[strname]} # read from pass-by-ref (fid 3)
                                            local fid=3
    fi
    if [[ "$vartype" == A ]]; then          local p="${args[p]}"            # array is associative
    else                                    local p=""
    fi
    local e="${args[e]}"            
    local tok key val

    while IFS="$e" read -d "$e" -r tok <&${fid} || [[ -n "$tok" ]]; do
        trim tok
        #echo "tok: [$tok]"
        if [[ "$tok" != "" ]] && [[ "$p" != "" ]]; then   # split token on 'p' for associative array

            if [[ "$tok" =~ .+"$p" ]]; then                # but first check that token actually has a p
                key="${tok%${p}*}"
                val="${tok#*${p}}"
                __arr["$key"]="$val"
                #echo "found associative token: $tok   has key/val: $key/$val"
            fi

        elif [[ "$tok" != "" ]] && [[ "$p" == "" ]]; then # store token directly if non-associative array
             __arr+=( "$tok" )
        fi
    done 3< <(printf '%s' "$__str")
    exec 3<&-
}


# arr_to_str {arrayname} [strname] [-e element_sep] [-p pair_sep]
#   Prints an array as a string. Prints members only, or as key/value pairs.
# Inputs:
#   arrayname   - Name of array variable to print.
#                 CANNOT be named: __arr _args
#   element_sep - String to separate each array member in the resulting string.
#                 Default: '\n'.
#   pair_sep    - String to separate each key and value. If empty, prints values only.
#                 Default: ""
# Outputs:
#   strname     - Name of string in which to store result.
#                 CANNOT be named: __str _args
#   &1 (stdout) - If strname is not specified, prints the resulting string to stdout.
#
function arr_to_str() {
    local -A args=( [e]=$'\n' )
    fast_argparse args "arrname strname" "e p" "$@"
    if [[ "${args[arrname]}" != "" ]]; then local -n __arr=${args[arrname]}
    else                                    return_error "No array variable specified in position 1."
    fi
    if [[ "${args[strname]}" != "" ]]; then local -n __str=${args[strname]}
                                            local printf_args="-v __str"
    else                                    local __str=""
                                            local printf_args=""
    fi

    local e="${args[e]}"
    local p="${args[p]}"
    local key

    if [[ "$p" == "" ]]; then
        for key in "${!__arr[@]}"; do
            builtin printf $printf_args "%s%s$e" "$__str" "${__arr[$key]}"
        done
    else
        for key in "${!__arr[@]}"; do
            builtin printf $printf_args "%s%s$p%s$e" "$__str" "$key" "${__arr[$key]}"
        done
    fi
}


# copy_array {sourcename} {destname}
#   Each element of the source array is copied into the destination array.
#   If copying from associative array (A) to nonassociative array (a),
#     an element will only be copied if the key is a valid index (positive integer).
# Inputs:
#   sourcename   - Name of source array. CANNOT be named: ___in
# Outputs:
#   destname     - Name of output array. CANNOT be named: ___out
# 
function copy_array() {
    if [[ "$1" == "" ]]; then return_error "No array variable specified in position 1."
    else                      local -n ___in=$1
                              local intype; get_type ___in intype
                              [[ "$intype" == s ]] && return_error "$1 is not an array";
    fi
    if [[ "$2" == "" ]]; then return_error "No array variable specified in position 2."
    else                      local -n ___out=$2
                              local outtype; get_type ___out outtype
                              [[ "$outtype" == s ]] && return_error "$2 is not an array";
    fi
    ___out=() # clear destination

    # copy contents
    local key val
    for key in "${!___in[@]}"; do
        val="${___in[$key]}"

        if [[ "$outtype" == a ]]; then
            is_integer_ge_0 "$key" && ___out["$key"]="$val"
        else
            ___out["$key"]="$val"
        fi
    done
}


# sort_array {inarrname} {outarrname} [comparison]
#   Sorts the elements of a (nonassociative) array.
# Inputs:
#   inarrname   - Name of array to sort. Must be a non-associative array.
#                   CANNOT be named: __inarr
#   comparison  - Name of function taking two values and returning exitcode 0 (success) if $1 < $2
#                   Defaults to compare_string_lt
# Outputs:
#   outarrname  - Name of array to store sorted values.
#                   CANNOT be named: __outarr
#
function sort_array() {
    if [[ "$1" == "" ]]; then return_error "No array variable specified in position 1."
    else                      local -n __inarr=$1
                              local type1; get_type __inarr type1
                              [[ "$type1" != a ]] && return_error "$1 must be a non-associative array, but is actually type '$s'";
    fi
    if [[ "$2" == "" ]]; then return_error "No array variable specified in position 2."
    else                      local -n __outarr=$2
                              local type2; get_type __outarr type2
                              [[ "$type2" != a ]] && return_error "$2 must be a non-associative array, but is actually type '$s'";
    fi
    if [[ "$3" == "" ]]; then compare_fcn="compare_string_lt"
    else                      local compare_fcn=$3
    fi

    # bubblesort
    local newval compareval idx
    for newval in "${__inarr[@]}"; do
        idx=0   # insertion index
        for compareval in "${__outarr[@]}"; do
            if $compare_fcn "$newval" "$compareval" ; then    # if A < B, store A here
                break
            else
                ((idx+=1))
            fi
        done
        __outarr=( "${__outarr[@]:0:$idx}" "$newval" "${__outarr[@]:$idx}" )
    done

}



# has_value {arrayname} {value}
#   Returns TRUE ($?==0) if value is a member of the array.
# Inputs:
#   arrayname   - Name of array variable. CANNOT be named ___arr.
#   value       - String; Value to test
# Outputs:
#   $?          - Exit code. 0 (success) indicates value was found inside the array.
#   
function has_value() {
    local -n ___arr=$1
    local elem="$2" list_elem
    for list_elem in "${___arr[@]}"; do
        if [[ "$elem" == "$list_elem" ]]; then return 0; fi
    done
    return 1
}


# has_key {arrayname} {key}
#   Checks if "key" is a valid key (or index) in the array.
# Inputs:
#   arrayname   - Name of array variable. CANNOT be named ___arr.
#   key         - String; key or index to test
# Outputs:
#   $?          - Exit code. 0 (success) indicates value was found inside the array.
#   
function has_key() {
    if [[ "$1" == "" ]]; then return 1
    else                      local -n ___arr=$1
                              local vartype; get_type ___arr vartype;
    fi
    if [[ "$2" == "" ]]; then return 1
    else                      local key="$2"
    fi

    if [[ "$vartype" == A ]]; then  # array is associative
        [[ -v "___arr[$key]" ]];
        return $?
    elif [[ "$vartype" == a ]]; then  # array is non-associative
        is_integer_ge_0 "$key" && [[ -v "___arr[$key]" ]];
        return $?
    else            # not an array
        return 1
    fi
}


# find_value {arrayname} {value} {idxvarname} 
#   Searches an array for a value, then returns the corresponding key or index.
# Inputs:
#   arrayname   - Name of array to search. CANNOT be named: ___arr
#   value       - String; value to search for. CANNOT be named: ___ret, ___key
# Outputs:
#   idxvarname  - Name of variable to store the key/index.
#   $?          - Numeric exit code; Returns 0 (success) if value was found in the array
#
function find_value() {
    local -n ___arr=$1
    local val="$2"
    local -n ___ret=$3

    local ___key
    for ___key in "${!___arr[@]}"; do 
        if [[ "${___arr[$___key]}" == "$val" ]]; then
            ___ret="$___key"
            return 0
        fi
    done
    
    ___ret=""
    return 1
}


# insert_value {arrayname} {idx} {value}
#   Inserts the value into the array at the specified index, shifting over all following elements.
#   If idx is greater than the number of elements in the array, the value is simply appended to the end.
#   For an associative array, idx represents the key at which value is placed.
# Inputs:
#   arrayname   - Name of array to modify
#                 CANNOT be named: ___arr
#   idx         - Array index (or key) at which to insert the new value
#   value       - Value to insert
# Outputs:
#   arrayname   - Name of array in which to insert the new element
#
function insert_value() {
    local -n ___arr=$1
    local vartype; get_type ___arr vartype;
    if [[ "$2" == "" ]]; then return 1
    else                      local idx="$2"
    fi
    local val="$3"

    if [[ "$vartype" == A ]]; then  # array is associative; don't need to do anything special
        ___arr["$idx"]="$val"

    elif [[ "$vartype" == a ]]; then # array is non-associative
        if is_integer_ge_0 "$idx"; then
            ___arr=( "${___arr[@]:0:$idx}" "$val" "${___arr[@]:$idx}" )
        else
            return 1
        fi
    else
        return_error "$1 is not an array."
    fi
}


# insert_value_before {arrayname} {insertbefore} {value}
#   Inserts the value into the array before the first instance of another value.
#   If the insertbefore value is not present in the array, value is inserted at the beginning of the array.
#   For an associative array, the array is not modified.
# Inputs:
#   arrayname     - Name of array to modify
#   insertbefore  - Value to search and insert before
#   value         - Value to insert
# Outputs:
#   arrayname     - Array is modified directly.
#
function insert_value_before() {
    local -n ___arr=$1;    local vartype; get_type ___arr vartype
    local insertbefore="$2"
    local val="$3"

    [[ "$vartype" == A ]] && return 1

    local ___idx;
    for ___idx in "${!___arr[@]}"; do
        if [[ "${___arr[$___idx]}" == "$insertbefore" ]]; then
            ___arr=( "${___arr[@]:0:$___idx}" "$val" "${___arr[@]:$___idx}" )
            return
        fi
    done
    ___arr=( "$val" "${___arr[@]}" )
}


# insert_value_after {arrayname} {insertafter} {value}
#   Inserts the value into the array after the first instance of another value.
#   If the insertafter value is not present in the array, value is inserted at the end of the array.
#   For an associative array, the array is not modified.
# Inputs:
#   arrayname     - Name of array to modify
#   insertafter   - Value to search and insert after
#   value         - Value to insert
# Outputs:
#   arrayname     - Array is modified directly.
#
function insert_value_after() {
    local -n ___arr=$1;    local vartype; get_type ___arr vartype
    local insertafter="$2"
    local val="$3"

    [[ "$vartype" == A ]] && return 1

    local ___idx;
    for ___idx in "${!___arr[@]}"; do
        [[ "${___arr[$___idx]}" == "$insertafter" ]] && break
    done
    ((___idx+=1))
    ___arr=( "${___arr[@]:0:$___idx}" "$val" "${___arr[@]:$___idx}" )
}


# remove_value {arrayname} {value} [removedkey_varname]
#   Removes first occurrance of 'value' (and its associated key) from the array.
# Inputs:
#   arrayname   - Name of array to modify
#                 CANNOT be named: __arr
#   value       - String; value to search and remove
# Outputs:
#   arrayname   - Array variable is modified directly.
#   removedkey_varname  - Variable in which to store the key/idx which corresponded to the removed value
#                         CANNOT be named: __ret, __key
#   $?          - Exit code; 0 (success) if a value was removed, 1 if nothing was removed.
#
function remove_value() {
    local -n __arr=$1
    local val="$2"
    if [[ "$3" != "" ]]; then   local -n __ret="$3"
    else                        local __ret
    fi

    local __key
    for __key in "${!__arr[@]}"; do 
        if [[ "${__arr[$__key]}" == "$val" ]]; then
            __ret="$__key"
            remove_key __arr "$__key"
            return 0
        fi
    done
    
    __ret=""
    return 1
}


# remove_key {arrayname} {key} [removedval_varname]
#   Removes the key/idx (and its associated value) from the array.
# Inputs:
#   arrayname   - Name of array to modify.
#                 CANNOT be named: ___arr
#   value       - String; value to search and remove
# Outputs:
#   arrayname   - Array variable is modified directly.
#   removedval_varname  - Variable in which to store the key/idx which corresponded to the removed value
#               - CANNOT be named: ___ret
#   $?          - Exit code; 0 (success) if a key was removed, 1 if nothing was removed.
#
function remove_key() {
    local -n ___arr=$1
    local vartype; get_type ___arr vartype
    if [[ "$2" != "" ]]; then   local key="$2"
    else                        return 1
    fi
    if [[ "$3" != "" ]]; then   local -n ___ret=$3
    fi

    if [[ "$vartype" == A ]] && \
       [[ -v "___arr[$key]" ]];     then    # array is associative and key exists
        ___ret="${___arr[$key]}"
        unset -v "___arr[$key]"

    elif [[ "$vartype" == a ]] && \
         is_integer_ge_0 "$key" && \
         [[ -v "___arr[$key]" ]];   then    # array is non-associative and key is positive integer and exists
        ___ret="${___arr[$key]}"
        ___arr=( "${___arr[@]:0:$key}" "${___arr[@]:$((key+1))}" )

    else
        ___ret=""
        return 1
    fi

    return 0
}


# foreach {inarrayname} {function_call} [outarrayname]
#   Runs the specified function on every element of the input array.
# Examples:
#   foreach myarray 'trim VAL'           # Trims whitespace from every value in the array
#   foreach myarray 'trim VAL' newarray  # Trims whitespace, stores modified values to a new array
#   foreach myarray '[[ "$VAL" == "someval"]] && KEY="" '
#                                        # Removes all elements where VAL == "someval"
#   foreach myarray 'echo $KEY:$VAL'     # Neither KEY nor VAL are modified, but prints to stdout as a side effect
# Inputs:
#   invarname     - Name of input array. CANNOT be named: __in __out __arr ___arr
#   function_call - String containing function call to run on each array element.
#                   The variables KEY and VAL are defined here.
#                   If either KEY or VAL is modified the output will reflect the change.
#                   If KEY is set to empty "", the  to the output array.
# Outputs:
#   invarname     - If outvarname not provided, elements of invarname are modified directly
#   outvarname    - Name of output array. Modified keys&values are stored here.
#                   CANNOT be named: __in __out __arr ___arr
#
function foreach() {
    if [[ "$1" == "" ]]; then return_error "No array variable specified in position 1."
    else                      local -n __in=$1
    fi
    if [[ "$2" == "" ]]; then return_error "No function call specified in position 2."
    else                      local command="$2"
    fi
    if [[ "$3" == "" ]]; then local -n __out=$1
    else                      local -n __out=$3
    fi
    
    # Operate on each element of input array
    local oldkey KEY VAL
    for oldkey in "${!__in[@]}"; do
        KEY="$oldkey"
        VAL="${__in[$KEY]}"
        #echo "KEY=$KEY,  VAL=$VAL,  FNCALL=$command"
        eval $command
        #echo "NEW KEY=$KEY,  NEW VAL=$VAL"
        if [[ "$KEY" != "" ]]; then
            __out["$KEY"]="$VAL"
        else
            remove_key __out "$oldkey"
        fi
    done
}


# make_unique {source_arrname} {dest_arrname}
#   Dest array is erased and replaced with only the unique elements from the source. 
#   Only values are considered for uniqueness; keys are already inherently unique.
# Inputs:
#   source_arrname   - Name of source array. CANNOT be named: __arr1
# Outputs:
#   dest_arrname     - Name of output array. CANNOT be named: __arr2
# 
function make_unique() {
    if [[ "$1" == "" ]]; then return_error "No array variable specified in position 1."
    else                      local -n __arr1=$1
                              local type1; get_type __arr1 type1
                              [[ "$type1" == s ]] && return_error "$1 is not an array";
    fi
    if [[ "$2" == "" ]]; then return_error "No array variable specified in position 2."
    else                      local -n __arr2=$2
                              local type2; get_type __arr2 type2
                              [[ "$type2" == s ]] && return_error "$2 is not an array";
    fi

    # check if same type
    if [[ $type1 != $type2 ]]; then return_error "$1 and $2 are not the same type of array."; fi

    # clear array2
    __arr2=()

    # copy contents
    local key val
    for key in "${!__arr1[@]}"; do
        val="${__arr1[$key]}"
        if ! has_value __arr2 "$val"; then
            if [[ $type2 == A ]]; then
                __arr2["$key"]="$val"
            else
                __arr2+=( "$val" )
            fi
        fi
    done
}


# set_diff {dest_arrname} {arrname_A} {arrname_B}
#   Dest array is set equal to A - B ; the elements of A, removing the elements of B.
#   A and dest must be the same type of array (associative or non-associative).
#   A and B do NOT need to be the same type, as only values are compared.
# Inputs:
#   arrname_A      - Name of array A. CANNOT be named: __arr1
#   arrname_B      - Name of array A. CANNOT be named: __arr2
# Outputs:
#   dest_arrname   - Name of output array, containing A - B. CANNOT be named: __diff
# 
function set_diff() {
    if [[ "$1" == "" ]]; then return_error "No array variable specified in position 1."
    else                      local -n __diff=$1
                              local typeD; get_type __diff typeD
                              [[ "$typeD" == s ]] && return_error "$1 is not an array";
    fi
    if [[ "$2" == "" ]]; then return_error "No array variable specified in position 2."
    else                      local -n __arr1=$2
                              local type1; get_type __arr1 type1
                              [[ "$type1" == s ]] && return_error "$2 is not an array";
    fi
    if [[ "$3" == "" ]]; then return_error "No array variable specified in position 3."
    else                      local -n __arr2=$3
                              local type2; get_type __arr2 type2
                              [[ "$type2" == s ]] && return_error "$3 is not an array";
    fi
    # check if same type
    if [[ $typeD != $type1 ]]; then return_error "$1 and $2 are not the same type of array."; fi

    # set diff = A
    copy_array __arr1 __diff

    # delete elements of B from A
    local key val success
    for key in "${!__arr2[@]}"; do
        success=0
        val="${__arr2[$key]}"
        while [[ $success -eq 0 ]]; do  # loop to subtract all occurances of the given value
            remove_value __diff "$val"
            success=$?
        done
    done
}


# set_union {dest_arrname} [arrname_A] [arrname_B] [arrname_C] ...
#   Stores the union of elements of the arrays; dest = A U B U ...
#   If arrays are associative, keys are carried over to dest, but keys from earlier inputs are preferred.
# Inputs:
#   arrname_A     - Name of array A. CANNOT be named: __union, __arr, or same name as any other input
# Outputs:
#   dest_arrname  - Name of array to store union. CANNOT be named: __union, __arr
# 
function set_union() {
    if [[ "$1" == "" ]]; then return_error "No array variable specified in position 1."
    else                      local -n __union=$1
                              local typeD; get_type __union typeD
                              [[ "$typeD" == s ]] && return_error "$1 is not an array";
    fi
    shift 1
    __union=()

    while [[ "$#" -gt 0 ]]; do

        if [[ "$1" == "" ]]; then return_error "Empty positional argument is not allowed here."
        else                    local -n __arr=$1
                                local typeS; get_type __arr typeS
                                [[ "$typeS" == s ]] && return_error "$1 is not an array";
        fi

        # check if same type
        if [[ $typeD != $typeS ]]; then return_error "$1 is an incompatible array type."; fi

        # copy unique values of array into __union
        local key val
        for key in "${!__arr[@]}"; do
            val="${__arr[$key]}"
            if ! has_value __union "$val"; then
                [[ $typeD == A ]] && __union["$key"]="$val" || __union+=( "$val" )
            fi
        done

        shift 1
    done
}


# set_intersection {dest_arrname} [arrname_A] [arrname_B] [arrname_C] ...
#   Stores the intersection of elements of the arrays; dest = A int B int ...
#   If arrays are associative, keys are carried over to dest, but keys from earlier inputs are preferred.
# Inputs:
#   arrname_A     - Name of array A. CANNOT be named: __union, __intersect, __arr, or same name as any other input
# Outputs:
#   dest_arrname  - Name of array to store union. CANNOT be named: __union, __intersect, __arr
# 
function set_intersection() {
    if [[ "$1" == "" ]]; then return_error "No array variable specified in position 1."
    else                      local -n __intersect=$1
                              local typeD; get_type __intersect typeD
                              [[ "$typeD" == s ]] && return_error "$1 is not an array";
    fi
    shift 1

    # Start with the union of all the arrays
    set_union __intersect "$@"    

    while [[ "$#" -gt 0 ]]; do

        if [[ "$1" == "" ]]; then return_error "Empty positional argument is not allowed here."
        else                    local -n __arr=$1
                                local typeS; get_type __arr typeS
                                [[ "$typeS" == s ]] && return_error "$1 is not an array"; 
        fi

        # check if same type
        if [[ $typeD != $typeS ]]; then return_error "$1 is an incompatible array type."; fi

        # remove the complement of the intersection of __arr with the union
        local key val
        local -a complement=()
        for key in "${!__intersect[@]}"; do
            val="${__arr[$key]}"
            if ! has_value __arr "$val"; then
                complement+=( "$val" )
            fi
        done

        set_diff __intersect __intersect complement

        shift 1
    done
}




#####################################################################################################

__COMMON_FUNCS_AVAILABLE="$TRUE"
