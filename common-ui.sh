#####################################################################################################
#
#       BASH COMMON-UI FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-scripts/common-functions.sh
#       source ./bash-common-scripts/common-ui.sh
#
#####################################################################################################
#       REQUIRES COMMON-FUNCTIONS
#
if [[ "$__COMMON_FUNCS_AVAILABLE" != "$TRUE" ]]; then
    echo "ERROR: This script requires \"common-functions.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-functions.sh\" before sourcing this script."
    return 1
fi
#
#####################################################################################################
#       GLOBAL VARIABLES:
#
# ___AUTOCONFIRM              # If == $TRUE, skips confirmation prompts (returns 0 automatically)
unset __COMMON_UI_AVAILABLE  # Set to $TRUE at the end of this file.
#
#####################################################################################################
#       FUNCTION REFERENCE:
#
# confirmation_prompt [prompt]
#   Prompts the user for a Y/N input.
# require_confirmation [prompt]
#   Prompts the user for a Y/N input, then returns from the function which called this if the user responds negatively.
# function_select_menu {optarrayname} {funcarrayname} {title} {description}
#   Displays a selection menu to the user. Options map directly to function calls.
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




###############################################################################
# LEVEL 0 FUNCTIONS
#   Functions take no namerefs as arguments, so name conflicts are not possible
###############################################################################


# confirmation_prompt [prompt]
#   Prompts the user for a Y/N input.
# Inputs:
#   prompt          - Optional prompt text. Defaults to "Continue?"
#   &0 (stdin)      - Reads user input from stdin
#   $__AUTOCONFIRM   - If $__AUTOCONFIRM == $TRUE, will immediately return 0 without prompt.
# Outputs:
#   &1 (stdout)     - Writes prompt to stdout
#   $?              - Numeric exit value; Returns 0 (success) if user has provided confirmation, 1 if not.
#
function confirmation_prompt() {
    if [[ "$__AUTOCONFIRM" == $TRUE ]]; then return 0; fi
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
#   $__AUTOCONFIRM   - If $__AUTOCONFIRM == $TRUE, will immediately return 0 without prompt.
# Outputs:
#   &1 (stdout)     - Writes prompt to stdout
#   $?              - Numeric exit value; Returns 0 (success) if user has provided confirmation, 1 if not.
#
function require_confirmation() {
    confirmation_prompt "$1"
    if [[ $? == 0 ]]; then 
        return 0
    else
        "${__CONFIRM:?FALSE}"
    fi
}



###############################################################################
# LEVEL 1 FUNCTIONS
#   Functions take namerefs as arguments, but do not pass the namerefs to
#   another function.
#   All local variables are prefixed with '_', therefore passing a nameref of
#   the format '_NAME' may cause errors.
###############################################################################


###############################################################################
# LEVEL 2 FUNCTIONS
#   Functions take namerefs as arguments and pass the nameref to a level 1 fcn.
#   All local variables are prefixed with '__', therefore passing a nameref arg
#   of the format '__NAME' may cause errors.
###############################################################################


# user_selection_menu {optionsarray} [-title "title"] [-subtitle "subtitle"] [-prefix "prefix"] [-prompt "prompt"]
#   Displays a selection menu to the user and returns the user's selection.
# Inputs:
#   optionsarray  - Name of array containing menu options. Indexed or associative.
#                   Keys are menu options and values are menu descriptions.
#   title         - Title to display at top of menu.
#   subtitle      - Text to display below title.
#   prefix        - Prefix text for each line of the menu. Defaults to "  ".
#   prompt        - Prompt text.
# Outputs:
#   $REPLY        - Global variable set to the index/key of the user's choice.
#
function user_selection_menu() {
    # Default values
    local -A __fnargs=([title]=""
                       [subtitle]="Options:"
                       [prefix]="  "
                       [prompt]="Enter an option: " )
    fast_argparse __fnargs "optionsarray" "title subtitle prefix prompt" "$@"

    local -n __opts="${__fnargs[optionsarray]}"
    local title="${__fnargs[title]}"
    local subtitle="${__fnargs[subtitle]}"
    local prefix="${__fnargs[prefix]}"
    local prompt="${__fnargs[prompt]}"

    # Display menu and prompt
    printf "\n"
    if [[ "${title}" != "" ]]; then
        local divider=""
        printf -v divider "%${#title}s" ""
        printf -v divider "##%s##" "${divider// /#}"
        printf "%s\n" "$divider"
        printf "  %s\n" "$title"
        printf "%s\n" "$divider"
        printf "\n"
    fi
    if [[ "${subtitle}" != "" ]]; then
        printf "%s\n" "$subtitle"
        printf "\n"
    fi
    printvar __opts -showname false -prefix "$prefix"
    printf "\n"
    unset REPLY
    while ! has_key __opts "$REPLY"; do
        read -r -p "$prompt"
    done
}





# parse_args {argspec} {outargs} {"$@"}
#   Parses input arguments according to the specification
# Inputs:
#   argspec - Name of associative array containing argument specification, in the format:
#               declare -A argspec=(
#                   ["pos1|positional1"]=""       # corresponds to {required_value}
#                   ["pos2|positional2"]=""       # corresponds to {second_required_value}
#                   ["opt|optional1"]="default"   # corresponds to [--optional1 'userstring']
#                   ["flg|flag1"]="false"         # corresponds to [--flag1]
#                   ["sel|selection1"]="default alt1 alt2"
#                   ...                           # corresponds to [--selection1=default|alt1|alt2]
#               )
#   "$@"    - Quoted string of all program arguments.
# Outputs:
#   outargs - Name of associative array in which to store the parsed arguments.
#               declare -A outargs
#             The outargs array resulting from the previous argspec will be:
#                   ["positional1"] == "required_value"
#                   ["positional2"] == "second_required_value"
#                   ["optional1"]   == "default" or "userstring" if supplied
#                   ["flag1"]       == "false" or "true" if flag was supplied
#                   ["selection1"]  == "default" or "alt1" or "alt2"
#                   ...
#
#   function parse_args() {
#       local -n _argspec=$1    # Input argspec associative array (not modified)
#       local -n _outargs=$2    # Output associative array for parsed args
#       shift 2         # All the remaining program arguments should be passed in as well

#       local argfield argname argval

#       # Check that argspec has a valid format
#       for argfield in "${!_argspec[@]}"; do
#           case "$argfield" in
#               pos*) ;;
#               opt*) ;;
#               sel*) ;;
#               flg*) ;;
#               *)    echo "BUG: invalid arg type: $argfield"; exit 1
#           esac
#       done

#       # Check for --help
#       if [[ "$1" == "--help" ]]; then
#           print_usage _argspec; exit 0
#       fi

#       # Initialize the output array to default values for all non-positional arguments
#       for argfield in "${!_argspec[@]}"; do
#           argval=
#           case "$argfield" in
#               opt*) argval="${_argspec[$argfield]}" ;;
#               sel*) IFS=' ' read -r argval __trash <<< "${_argspec[$argfield]}" ;;
#               flg*) argval="false" ;;
#               *)    argval="" ;;
#           esac
#           format_output_args _outargs "$argfield" "$argval"
#       done

#       # Create a separate (sorted) list of all required positional arguments
#       local -a pos_args
#       for argfield in "${!_argspec[@]}"; do
#           if [[ "$argfield" == "pos"* ]]; then
#               pos_args+=( "$argfield" )
#           fi
#       done
#       pos_args=( $( echo ${pos_args[@]} | tr ' ' $'\n' | sort ) )
#       local total_pos=${#pos_args[@]}
#       local found_pos=0

#       # Parse arguments one by one and add them to the output array
#       while [ "$#" -gt 0 ]; do
#           # Parse one arg
#           argfield=""
#           argval=""
#           parse_arg _argspec pos_args "$1" "$2" argfield argval found_pos
#           local consumed=$? # parse_arg exit code is the number of consumed arguments
#           [ "$#" -ge $consumed ] && shift $consumed || echo "BUG: Not enough arguments (Tried to parse: $argfield)"

#           # Detect parsing errors
#           if   [[ $consumed == 0 && "$argval" == "" ]]; then
#               print_usage _argspec "Unknown or incomplete argument: $argfield"; exit 1
#           elif [[ $consumed == 0 && "$argval" != "" ]]; then
#               print_usage _argspec "Invalid value '$argval' in argument '$argfield'"; exit 1
#           fi

#           # Add to output args array, overwriting default value
#           format_output_args _outargs "$argfield" "$argval"
#       done

#       # Ensure all positional arguments have been filled
#       if [ $found_pos -lt $total_pos ]; then 
#           print_usage _argspec "Not enough positional arguments; Found $found_pos, needed $total_pos."; exit 1
#       fi

#       ######################################################
#       ## LOCAL FUNCTIONS
#       ######################################################


#       function parse_arg() {  # Exit code = Number of consumed arguments. 0 indicates error.
#           local -n __argspec=$1  # argspec associative array
#           local -n _pos_args=$2  # non-associative list of (sorted) positional argument names
#           local _1="$3"          # arg to parse
#           local _2="$4"          # next arg (sometimes arg1 arg2 are a key+value pair)
#           local -n _argfield=$5  # return argument name as type|name
#           local -n _argval=$6    # return argument value, or "" if no match was found.
#           local -n _found_pos=$7 # return total number of parsed positional parguments
#           local _total_pos=${#_pos_args[@]} # total pos args in the argspec

#           _argname="${_1##*-}"      # trim leading -
#           _argname="${_argname%=*}" # trim trailing =*
#           _argfield="$_argname"   # Now we need to guess the type to complete the field
#           _argval=""

#           case "$_1" in
#               --*=*|-*=*) # argtype is sel; search for matching name and val in argspec
#                   if   [[ "${__argspec[sel|$_argname]}" != "" ]]; then _argfield="sel|$_argname";  _argval="${_1#*=}"
#                       if has_value_of_list "${__argspec[$_argfield]}" "$_argval"; then return 1
#                       else _argfield="$_argname"; return 0 # error: invalid selection value
#                       fi
#                   fi;;
#               --*|-*)     # argtype is opt or flg; search for match in argspec
#                   if   [[ "${__argspec[opt|$_argname]}" != "" && "$_2" != "-"* ]]; then _argfield="opt|$_argname";  _argval="$_2"
#                       if [[ "$_argval" != "" ]]; then return 2
#                       else _argfield="$_argname"; return 0 # error: empty opt value is not allowed
#                       fi
#                   elif [[ "${__argspec[flg|$_argname]}" != "" ]]; then _argfield="flg|$_argname";  _argval="true"
#                       return 1
#                   fi;;
#               *)          # argname is posN|name if it fits in the argspec, or just 'overflow' if it should go to overflow
#                   ((_found_pos=_found_pos+1));
#                   if [ $_found_pos -le $_total_pos ]; then _argfield="${_pos_args[$_found_pos-1]}"; _argval="$_1"
#                       return 1
#                   else                                     _argfield="overflow";                    _argval="$_1"
#                       return 1
#                   fi;;
#           esac
#           return 0
#       }

#       function has_value_of_list() {
#           local list_str="$1"
#           local elem="$2"
#           for list_elem in $list_str; do
#               if [[ "$elem" == "$list_elem" ]]; then return 0; fi
#           done
#           return 1
#       }

#       function format_output_args() {
#           local -n __outargs=$1
#           local argfield="$2"
#           local argval="$3"
#           local argname="${argfield#*|}"
#           if [[ "$argfield" == "overflow"* ]]; then
#               if [[ "${__outargs[overflow]}" == "" ]]; then
#                   __outargs["overflow"]="$argval"
#               else
#                   __outargs["overflow"]="${__outargs[overflow]} $argval"
#               fi
#           else
#               __outargs["$argname"]="$argval"
#           fi
#       }

#   }   # parse_args




#   function print_usage() {
#       local script="$(basename "$(readlink -f "$0")")"
#       local -n __argspec=$1
#       local err="$2"


#       local argfield argname argval
#       local -a argfields=( $( echo ${!__argspec[@]} | tr ' ' $'\n' | sort ) ) #sort alphabetically
#       local -a posargs optargs selargs flgargs    # sort into categories
#       for argfield in "${argfields[@]}"; do
#           case "$argfield" in
#               pos*) posargs+=( "$argfield" );;
#               opt*) optargs+=( "$argfield" );;
#               sel*) selargs+=( "$argfield" );;
#               flg*) flgargs+=( "$argfield" );;
#               *)    echo "BUG: invalid arg type: $argfield"; exit 1
#           esac
#       done

#       if [[ "$err" != "" ]]; then
#       echo "Error: $err";
#       fi
#       echo "Usage:"
#       printf "  $script "
#       for argfield in "${posargs[@]}"; do
#       printf             "{${argfield#*|}} "
#       done
#       printf                               "[optional_args]\n"
#       echo   "  $script --help"
#       echo ""
#       echo "  Positional arguments (Required, in order):"
#       for argfield in "${posargs[@]}"; do
#       echo "    {${argfield#*|}}"
#       done
#       echo ""
#       echo "  Optional arguments:"
#       for argfield in "${optargs[@]}"; do
#       echo "    [--${argfield#*|} \"val\"]"
#       echo "        Default: ${__argspec[$argfield]}"
#       done
#       for argfield in "${selargs[@]}"; do
#       echo "    [--${argfield#*|}=$( echo ${__argspec[$argfield]} | tr ' ' '|' )]"
#       done
#       for argfield in "${flgargs[@]}"; do
#       echo "    [--${argfield#*|}]"
#       done
#       echo ""

#   }



#   declare -A argspec=(
#       ["pos1|positional1"]=""
#       ["opt|optional1"]="default_value"
#       ["opt|optional2"]="default_value"
#       ["flg|flag1"]="false"
#       ["flg|flag2"]="false"
#       ["sel|selection1"]="default_sel alt_sel_1 alt_sel_2"
#       ["pos2|positional2"]=""
#   )
#   declare -A outargs

#   parse_args argspec outargs "$@"

#   echo ""
#   echo "PARSED ARGS:"
#   for argfield in "${!outargs[@]}"; do
#       argval="${outargs[$argfield]}"
#       echo "  $argfield = $argval"
#   done
#   echo ""



#####################################################################################################

__COMMON_UI_AVAILABLE="$TRUE"
