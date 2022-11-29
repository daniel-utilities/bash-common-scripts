#####################################################################################################
#
#       BASH COMMON FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-scripts/common-functions.sh
#
#####################################################################################################
#       FUNCTION REFERENCE:
#
# fast_argparse {returnarray} {positionalargs} {flaggedargs} {"$@"}
#   Collects positional and flagged arguments into an associative array.
# return_error [message]
#   Prints an error message then returns from the function which called this.
# is_root
#   Checks if script is being run by root user.
# require_root
#   Returns from the calling function with an error message if not being run by root user.
# require_non_root
#   Returns from the calling function with an error message if being run by root user.
# confirmation_prompt [prompt]
#   Prompts the user for a Y/N input.
# require_confirmation [prompt]
#   Prompts the user for a Y/N input, then returns from the function which called this if the user responds negatively.
# function_select_menu {optarrayname} {funcarrayname} {title} {description}
#   Displays a selection menu to the user. Options map directly to function calls.
# get_script_dir {strname}
#   Returns the full path containing the currently-running script.
# get_user_home {strname} [user]
#   Gets the home directory of the specified user.
# print_octal {str}
#   Prints the octal representation of the string over top of its ASCII counterpart.
# trim [strname]
#   Removes leading and trailing whitespace from a string (including newlines)
# print_arr {arrayname}
#   Prints the contents of an indexed or associative array to stdout.
# has_value {arrayname} {value}
#   Checks if value is a member of the array.
# has_key {arrayname} {key}
#   Checks if "key" is a key in the array.
# str_to_arr {arrayname} [strname] [-e element_sep] [-p pair_sep]
#   Splits a string into tokens and appends each one to an array.
# arr_to_str {arrayname} [strname] [-e element_sep] [-p pair_sep]
#   Prints an array as a string. Prints members only, or as key/value pairs.
# foreach {function_call} [-in invarname] [-out outvarname] [-e 'elem_sep'] [-p 'pair_sep'] 
#   Runs the specified function on every token of input.
# are_arrays_equal {arrname1} {arrname2}
#   Compares the contents of two arrays.
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
    while [ "$#" -gt 0 ]; do
        flag="${1##*-}"
        if [[ "$1" == -* ]]; then   # it's a flag argument
            if has_value flg "$flag" && [ "$#" -ge 2 ]; then   # it's a recognized flag
                _args["$flag"]="$2"
                shift 2
            else
                return_error "Invalid argument: $1 $2"
            fi
        else                        # it's a positional argument
            if [ $poscnt -lt "${#pos[@]}" ]; then   # it's a recognized positional arg
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


# is_root
#   Checks if script is being run by root user.
# Example:
#   is_root && echo yes || echo no
# Outputs:
#   $?          - Numeric exit value; 0 indicates this script is being run by root.
#
function is_root() {
    [ "$EUID" -eq 0 ] && return 0 || return 1
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


# confirmation_prompt [prompt]
#   Prompts the user for a Y/N input.
# Inputs:
#   prompt          - Optional prompt text. Defaults to "Continue?"
#   &0 (stdin)      - Reads user input from stdin
#   $_AUTOCONFIRM   - If $_AUTOCONFIRM == "true", will immediately return 0 without prompt.
# Outputs:
#   &1 (stdout)     - Writes prompt to stdout
#   $?              - Numeric exit value; Returns 0 (success) if user has provided confirmation, 1 if not.
#
function confirmation_prompt() {
    if [[ "$_AUTOCONFIRM" == "true" ]]; then return 0; fi
    if [[ "$1" == "" ]]; then local prompt="Continue? [Y/N]: "
    else                      local prompt="$1 [Y/N]: "
    fi
    unset REPLY
    read -r -p "$prompt" 
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then return 0; else return 1; fi
}


# require_confirmation [prompt]
#   Prompts the user for a Y/N input, then returns from the function which called this if the user responds negatively.
# Inputs:
#   prompt          - Optional prompt text. Defaults to "Continue?"
#   &0 (stdin)      - Reads user input from stdin
#   $_AUTOCONFIRM   - If $_AUTOCONFIRM == "true", will immediately return 0 without prompt.
# Outputs:
#   &1 (stdout)     - Writes prompt to stdout
#   $?              - Numeric exit value; Returns 0 (success) if user has provided confirmation, 1 if not.
#
function require_confirmation() {
    confirmation_prompt "$1"
    if [ $? == 0 ]; then 
        return 0
    else
        "${__CONFIRM:?FALSE}"
    fi
}


# function_select_menu {optarrayname} {funcarrayname} {title} {description}
#   Displays a selection menu to the user. Options map directly to function calls.
# Inputs:
#   optarrayname  - Name of OPTIONS associative array. CANNOT be named: _options
#                   Keys are menu options and values are menu descriptions.
#   funcarrayname - Name of FUNCTIONS associative array. CANNOT be named: _fncalls
#                   Keys are menu options and values are function calls to be interpreted by 'eval'.
#   $_AUTOCONFIRM - If $_AUTOCONFIRM == "true", will run all functions in order without waiting for user input.
#
function function_select_menu() {
    local -n _options=$1
    local -n _fncalls=$2
    local title="$3"
    local description="$4"

    # Add some additional options to the menu
    _options[0]="Run All In Order"
    _fncalls[0]="run_all"
    _options[r]="Return"
    _fncalls[r]="return"
    #_options[x]="Exit"
    #_fncalls[x]="exit"

    # run_all
    function run_all() {
        local _AUTOCONFIRM="true"
        local command=""
        keys=( $( echo ${!_fncalls[@]} | tr ' ' $'\n' | sort ) )
        for opt in "${keys[@]}"; do
            command="${_fncalls[$opt]}"

            if [[ "$command" == "run_all"* || "$command" == "exit"* || "$command" == "return"* ]]; then
                continue
            fi

            echo "Running command:"
            echo "$command"
            echo ""

            eval "$command"
        done
    }

    clear
    while true; do
        # Display menu
        echo ""
        echo "****************************************"
        echo "  $title"
        echo "****************************************"
        echo ""
        echo "$description"
        echo ""
        keys=( $( echo ${!_options[@]} | tr ' ' $'\n' | sort ) )
        for opt in "${keys[@]}"; do
            echo "$opt) ${_options[$opt]}"
        done
        echo ""

        # Skip user input if _AUTOCONFIRM
        if [[ "$_AUTOCONFIRM" == true ]]; then
            run_all
            return 0;
        done

        # User option selection and function execution
        prompt="Enter an option: "
        unset REPLY
        command=""
        while [[ "$command" == "" ]]; do
            read -r -p "$prompt"
            if [ "$REPLY" != "" ]; then command="${_fncalls[$REPLY]}"
            else                        command=""
            fi
            eval "$command"
        done
    done

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
function trim(){
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


# print_arr {arrayname}
#   Prints the contents of an indexed or associative array to stdout.
# Inputs:
#   arrayname   - Name of array variable (unquoted).
#                 CANNOT be named: __arr
#   out_delim   - Optional: String to separate each array element in the resulting string. Defaults to \n.
# Outputs:
#   &1 (stdout) - Prints the array's contents to stdout.
#
function print_arr(){
    if [[ "$1" == "" ]]; then return_error "No array variable specified"
    else                      local -n __arr=$1
    fi

    local key
    if [[ "${__arr@a}" == *A* ]]; then  # array is associative
        local len maxlen=0
        for key in ${!__arr[@]}; do       # get length of longest string (+2)
            ((len="${#key}"+2))
            if [ $len -gt $maxlen ]; then maxlen=$len; fi
        done
        for key in ${!__arr[@]}; do
            printf "%${maxlen}s: \"%s\"\n" "[$key]" "${__arr[$key]}"
        done
    else                                # array is non-associative
        for key in ${!__arr[@]}; do
            printf '%4d: [%s]\n' "$key" "${__arr[$key]}"
        done
    fi
}


# has_value {arrayname} {value}
#   Checks if value is a member of the array.
# Inputs:
#   arrayname   - Name of array variable. CANNOT be named __arr.
#   value       - Value to test
# Outputs:
#   $?          - Exit code. 0 (success) indicates value was found inside the array.
#   
function has_value() {
    local -n __arr=$1
    local elem="$2" list_elem
    for list_elem in "${__arr[@]}"; do
        if [[ "$elem" == "$list_elem" ]]; then return 0; fi
    done
    return 1
}


# has_key {arrayname} {key}
#   Checks if "key" is a key in the array.
# Inputs:
#   arrayname   - Name of array variable. CANNOT be named __arr.
#   key         - key to test
# Outputs:
#   $?          - Exit code. 0 (success) indicates value was found inside the array.
#   
function has_key() {
    local -n __arr=$1
    local key="$2" arr_key
    for arr_key in "${!__arr[@]}"; do
        if [[ "$key" == "$arr_key" ]]; then return 0; fi
    done
    return 1
}


# are_arrays_equal {arrname1} {arrname2}
#   Compares the contents of two arrays.
# Inputs:
#   arrname1   - Name of array variable (unquoted).
#                 CANNOT be named: _arrref1
#   arrname2   - Name of array variable (unquoted).
#                 CANNOT be named: _arrref2
# Outputs:
#   $?         - Numeric exit code. 0 if every array element in ARR_1 is the same as ARR_2, 1 if otherwise.
#
function are_arrays_equal(){
    if [[ "$1" == "" ]]; then return_error "No array variable specified"
    else                      local -n _arrref1=$1
                              if [[ "${_arrref1@a}" == *a* ]]; then local type1=a;    # nonassociative array
                              elif [[ "${_arrref1@a}" == *A* ]]; then local type1=A;  # associative array
                              else return_error "$1 is not an array"; fi
    fi
    if [[ "$2" == "" ]]; then return_error "No array variable specified"
    else                      local -n _arrref2=$2
                              if [[ "${_arrref2@a}" == *a* ]]; then local type2=a;    # nonassociative array
                              elif [[ "${_arrref2@a}" == *A* ]]; then local type2=A;  # associative array
                              else return_error "$2 is not an array"; fi
    fi

    # check if same type
    if [[ $type1 != $type2 ]]; then echo here1; return 1; fi

    # check if same size
    if [[ "${#_arrref1[@]}" != "${#_arrref2[@]}" ]]; then echo here2; return 1; fi

    # check elements match 1-1 
    local key elem1 elem2
    for key in ${!_arrref1[@]}; do
        has_key _arrref2; if [ ! $? ]; then echo here3; return 1; fi    # Check if key exists in array 2
        elem1="${_arrref1[$key]}"
        elem2="${_arrref2[$key]}"
        if [[ "$elem1" != "$elem2" ]]; then echo here4; return 1; fi    # Check if key maps to same element in both arrays
    done
    return 0
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
    if [[ "${args[arrname]}" != "" ]]; then local -n __arr=${args[arrname]} # output array
    else                                    return_error "No array variable specified"
    fi
    if [[ "${args[strname]}" != "" ]]; then local -n __str=${args[strname]} # read from pass-by-ref (fid 3)
                                            local fid=3
    else                                    local __str=""                  # read from stdin (fid 0)
                                            local fid=0
    fi
    if [[ "${__arr@a}" == *A* ]]; then      local p="${args[p]}"            # array is associative
    else                                    local p=""
    fi
    local e="${args[e]}"            
    local tok key val

    while IFS="$e" read -d "$e" -r tok <&${fid} || [ -n "$tok" ]; do
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
    else                                    return_error "No array variable specified"
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


# foreach {function_call} [-in invarname] [-out outvarname] [-e 'elem_sep'] [-p 'pair_sep'] 
#   Runs the specified function on every token of input.
#   WARNING: nameref variables do not work when pipes are connected to the function's stdin!
#   Always use process substitution instead.
# Examples:
#     foreach 'trim VAL' -out mystring < <(some_other -process)      # input from stdin, output to string
#     foreach 'trim VAL' -in myassociativearray -out modifiedarray   # input from array, output to array
#     foreach 'echo "$KEY:$VAL" -in string -e ' ' -p '='             # Neither KEY nor VAL are modified, but prints to stdout as a side effect
# Inputs:
#   function_call - String containing function call to run on each token of input.
#                   The variables KEY and VAL are defined here.
#                   If either KEY or VAL is modified, either directly or by pass-by-reference to another function,
#                   the output will reflect the change.
#   invarname     - Name of input variable. CANNOT be named: __in __out __arr __str __inarr __outarr
#                       If string, the string is parsed by str_to_arr using -e and -p.
#                       If array, the array elements are accessed directly (but not modified).
#   &0 (stdin)    - If invarname not supplied, stdin is parsed by str_to_arr using -e and -p.
#   element_sep   - String which separates each array member. Ignored by input or output if nameref points to an array.
#                   Default: $'\n'.
#   pair_sep      - String to separate each key and value. Ignored by input or output if nameref points to a nonassociative array
#                   Default: "="
# Outputs:
#   outvarname    - Name of output variable containing modified KEY and VAL for each token.
#                   CANNOT be named: __in __out __arr __str
#                       If string, the string is built by arr_to_str using -e and -p.
#                       If array, the array elements are modified directly.
#   &1 (stdout)   - If outvarname not supplied, arr_to_str prints to stdout using -e and -p.
#
function foreach() {
    local -A args=( [e]=$'\n' )
    fast_argparse args "fncall" "in out e p" "$@"
    if [[ "${args[in]}" != "" ]]; then      local -n __in=${args[in]} # input variable
    fi
    if [[ "${args[out]}" != "" ]]; then     local -n __out=${args[out]} # output variable
    fi
    local command="${args[fncall]}"
    local e="${args[e]}"

    # Create input array
    if [[ "${args[in]}" == "" ]] && [[ "${args[p]}" != "" ]]; then   # __inarr should be parsed from stdin as associative array
        #echo "here in 1"
        local p="${args[p]}"
        local -A __inarr=()
        str_to_arr __inarr -e "$e" -p "$p"
    elif [[ "${args[in]}" == "" ]] && [[ "${args[p]}" == "" ]]; then # __inarr should be parsed from stdin as non-associative array
        #echo "here in 2"
        local p='='
        local -a __inarr=()
        str_to_arr __inarr -e "$e"
    elif [[ "${__in@a}" == *A* ]]; then     # __inarr a reference to (associative array) pass-by-ref input
        #echo "here in 3"
        [[ "${args[p]}" != "" ]] && local p="${args[p]}" || local p='='
        local -n __inarr=__in
    elif [[ "${__in@a}" == *a* ]]; then     # __inarr a reference to (nonassociative array) pass-by-ref input
        #echo "here in 4"
        [[ "${args[p]}" != "" ]] && local p="${args[p]}" || local p='='
        local -n __inarr=__in
    elif [[ "${args[p]}" != "" ]]; then     # __inarr should be parsed from string pass-by-ref as associative array
        #echo "here in 5"
        local p="${args[p]}"
        local -A __inarr=()
        str_to_arr __inarr __in -e "$e" -p "$p"
    elif [[ "${args[p]}" == "" ]]; then     # __inarr should be parsed from string pass-by-ref as non-associative array
        #echo "here in 6"
        local p='='
        local -a __inarr=()
        str_to_arr __inarr __in -e "$e"
    else
        return_error "BUG: Invalid combination of inputs"
    fi

    # Create output array
    if [[ "${args[out]}" == "" ]] && [[ "${__inarr@a}" == *A* ]]; then   # __outarr should be written to stdout as associative array
        #echo "here out 1"
        local -A __outarr=()
        #arr_to_str __outarr -e "$e" -p "$p"
    elif [[ "${args[out]}" == "" ]] && [[ "${__inarr@a}" == *a* ]]; then # __outarr should be written to stdout as non-associative array
        #echo "here out 2"
        local -a __outarr=()
        #arr_to_str __outarr -e "$e"
    elif [[ "${__out@a}" == *A* ]]; then     # __outarr a reference to (associative array) pass-by-ref output
        #echo "here out 3"
        local -n __outarr=__out
    elif [[ "${__out@a}" == *a* ]]; then     # __outarr a reference to (nonassociative array) pass-by-ref output
        #echo "here out 4"
        local -n __outarr=__out
    elif [[ "${__inarr@a}" == *A* ]]; then   # __outarr should be written to string pass-by-ref as associative array
        #echo "here out 5"
        local -A __outarr=()
        #arr_to_str __outarr __out -e "$e" -p "$p"
    elif [[ "${__inarr@a}" == *a* ]]; then   # __outarr should be written to string pass-by-ref as non-associative array
        #echo "here out 6"
        local -a __outarr=()
        #arr_to_str __outarr __out -e "$e"
    else
        return_error "BUG: Invalid combination of inputs"
    fi

    #echo "INARR:"
    #print_arr __inarr
    #echo ""

    # Operate on each element of input array
    local KEY VAL
    for KEY in ${!__inarr[@]}; do
        VAL="${__inarr[$KEY]}"
        #echo "KEY=$KEY,  VAL=$VAL,  FNCALL=$command"
        eval $command
        __outarr["$KEY"]="$VAL"
    done

    #echo "OUTARR:"
    #print_arr __outarr
    #echo ""

    # Return modified array
    if [[ "${args[out]}" == "" ]] && [[ "${__inarr@a}" == *A* ]]; then   # __outarr should be written to stdout as associative array
        #local -A __outarr=()
        arr_to_str __outarr -e "$e" -p "$p"
    elif [[ "${args[out]}" == "" ]] && [[ "${__inarr@a}" == *a* ]]; then # __outarr should be written to stdout as non-associative array
        #local -a __outarr=()
        arr_to_str __outarr -e "$e"
    elif [[ "${__out@a}" == *A* ]]; then     # __outarr a reference to (associative array) pass-by-ref output
        #local -n __outarr=__out
        :
    elif [[ "${__out@a}" == *a* ]]; then     # __outarr a reference to (nonassociative array) pass-by-ref output
        #local -n __outarr=__out
        :
    elif [[ "${__inarr@a}" == *A* ]]; then              # __outarr should be written to string pass-by-ref as associative array
        #local -A __outarr=()
        arr_to_str __outarr __out -e "$e" -p "$p"
    elif [[ "${__inarr@a}" == *a* ]]; then              # __outarr should be written to string pass-by-ref as non-associative array
        #local -a __outarr=()
        arr_to_str __outarr __out -e "$e"
    else
        return_error "BUG: Invalid combination of inputs"
    fi
}



#####################################################################################################
__COMMON_FUNCS_AVAILABLE=0
