####################################################################################################
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
unset __COMMON_UI_AVAILABLE   # Set to $TRUE at the end of this file.
# REPLY                       # Set by any function which reads user input.
# __AUTOCONFIRM               # If == $TRUE, skips confirmation prompts (returns 0 automatically)
#
#####################################################################################################
#       FUNCTION REFERENCE:
#
# pause [prompt]
#   Waits until the user presses ENTER key.
# confirmation_prompt [prompt]
#   Prompts the user for a Y/N input.
# require_confirmation [prompt]
#   Prompts the user for a Y/N input, then returns from the function which called this if the user responds negatively.
# get_term_width [varname]
#   Returns the number of columns in the current terminal window
# get_repeated_string {varname} {"string"} {numcopies}
#   Returns a string which is n copies of the string
# get_center_justified_string {varname} {"string"} [len]
#   Returns a string in which "string" appears centered in the block of length 'len'.
# get_right_justified_string {varname} {"string"} [len]
#   Returns a string in which "string" appears right-justified in the block of length 'len'.
# wrap_string {varname} {"string"} [len]
#   Splits "string" into lines of length 'len', keeping words whole.
# crop_string {varname} {"string"} [len ["indicator"]]
#   If "string" is longer than 'len', it is cropped to (len-length(indicator)) and the indicator text is appended to the end.
# get_title_box {varname} {"title"} [-width numchars] [-top '-'] [-side '|'] [-corner '+']
#   Returns a multiline block with borders on all sides and "title" center-justified within.
# user_selection_menu {optionsarray} [-title "title"] [-subtitle "subtitle"] [-prefix "prefix"] [-prompt "prompt"]
#   Displays a selection menu to the user and returns the user's selection.
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


# pause [prompt]
#   Waits until the user presses ENTER key.
# Inputs:
#   prompt          - Optional prompt text.
#   &0 (stdin)      - Reads user input from stdin
#   $__AUTOCONFIRM   - If $__AUTOCONFIRM == $TRUE, will immediately return 0 without prompt.
# Outputs:
#   &1 (stdout)     - Writes prompt to stdout
#   $REPLY          - Global variable is set automatically. Contains user input.
#
function pause() {
    if [[ "$__AUTOCONFIRM" == $TRUE ]]; then return 0; fi
    if [[ "$1" == "" ]]; then local prompt="Press ENTER to continue... "
    else                      local prompt="$1 "
    fi
    unset REPLY
    read -r -p "$prompt" 
    return 0
}


# confirmation_prompt [prompt]
#   Prompts the user for a Y/N input.
# Inputs:
#   prompt          - Optional prompt text. Defaults to "Continue?"
#   &0 (stdin)      - Reads user input from stdin
#   $__AUTOCONFIRM   - If $__AUTOCONFIRM == $TRUE, will immediately return 0 without prompt.
# Outputs:
#   &1 (stdout)     - Writes prompt to stdout
#   $?              - Numeric exit value; Returns 0 (success) if user has provided confirmation, 1 if not.
#   $REPLY          - Global variable is set automatically. Contains user input.
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
#   $REPLY          - Global variable is set automatically. Contains user input.
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

# get_term_width {varname}
#   Returns the number of columns in the current terminal window
# Outputs:
#   varname         - Return number of columns into this variable
#
function get_term_width() {
    local -n _ret=$1
    _ret="$(tput cols)"
}


# get_repeated_string {varname} {"string"} {numcopies}
#   Returns a string which is n copies of the string
# Inputs:
#   string          - String to repeat.
#   numcopies       - Repeat the string this many times
# Outputs:
#   varname         - Returns repeated string into this variable
#
function get_repeated_string() {
    local -n _ret=$1
    local _str="$2"
    if [[ "$_str" == "" ]]; then _str=" "; fi
    local _num="$3"

    printf -v _ret "%${_num}s" ""
    printf -v _ret "%s" "${_ret// /$_str}"
}


# get_center_justified_string {varname} {"string"} [len]
#   Returns a string in which "string" appears centered in the block of length 'len'.
# Inputs:
#   string          - String to center-justify
#   len             - (Optional) Number of characters in the resulting string.
#                     If not provided, uses get_term_width to create a string which
#                     spans the current terminal window (slow).
# Outputs:
#   varname         - Return centered string into this variable
#
function get_center_justified_string() {
    local -n _ret=$1
    local _str="$2"
    local _len="$3"
    if [[ "$_len" == "" ]]; then get_term_width _len; fi

    local _left_pad_len=0; (( _left_pad_len=(${#_str}+_len)/2 ))
    local _right_pad_len=0; (( _right_pad_len=_len-_left_pad_len ))
    printf -v _ret "%${_left_pad_len}s%${_right_pad_len}s" "$_str" ""
}


# get_right_justified_string {varname} {"string"} [len]
#   Returns a string in which "string" appears right-justified in the block of length 'len'.
# Inputs:
#   string          - String to right-justify
#   len             - (Optional) Number of characters in the resulting string.
#                     If not provided, uses get_term_width to create a string which
#                     spans the current terminal window (slow).
# Outputs:
#   varname         - Return right-aligned string into this variable
#
function get_right_justified_string() {
    local -n _ret=$1
    local _str="$2"
    local _len="$3"
    if [[ "$_len" == "" ]]; then get_term_width _len; fi

    printf -v _ret "%${_len}s" "$_str"
}


# get_left_justified_string {varname} {"string"} [len]
#   Returns a string in which "string" appears left-justified in the block of length 'len'.
#   Useful for padding a string to a fixed length.
# Inputs:
#   string          - String to left-justify
#   len             - (Optional) Number of characters in the resulting string.
#                     If not provided, uses get_term_width to create a string which
#                     spans the current terminal window (slow).
# Outputs:
#   varname         - Return left-aligned string into this variable
#
function get_left_justified_string() {
    local -n _ret=$1
    local _str="$2"
    local _len="$3"
    if [[ "$_len" == "" ]]; then get_term_width _len; fi

    local _right_pad_len=0; (( _right_pad_len=_len-${#_str} ))
    printf -v _ret "%s%${_right_pad_len}s" "$_str" ""
}


# wrap_string {varname} {"string"} [len]
#   Splits "string" into lines of length 'len', keeping words whole.
#   Resulting multiline string is stored in varname.
# Inputs:
#   string          - String to word-wrap.
#   len             - (Optional) Number of characters in the resulting string.
#                     If not provided, uses get_term_width to create a string which
#                     spans the current terminal window (slow).
# Outputs:
#   varname         - Return word-wrapped lines into this variable.
#
function wrap_string() {
    local -n _ret=$1
    local _str="$2"
    local _len="$3"
    if [[ "$_len" == "" ]]; then get_term_width _len; fi

    _ret="$(fold -sw $_len <<< "$_str")"
}


# crop_string {varname} {"string"} [len ["indicator"]]
#   If "string" is longer than 'len', it is cropped to (len-length(indicator)) and the indicator is appended.
# Inputs:
#   string          - String to word-wrap.
#   len             - (Optional) Number of characters in the resulting string.
#                     If not provided, uses get_term_width to create a string which
#                     spans the current terminal window (slow).
#   indicator       - (Optional) Text to append to the end of the cropped string.
#                     Defaults to "..."
# Outputs:
#   varname         - Return cropped string into this variable.
#
function crop_string() {
    local -n _ret=$1
    local _str="$2"
    local _len="$3"
    if [[ "$_len" == "" ]]; then get_term_width _len; fi
    local _ind="$4"
    if [[ "$_ind" == "" ]]; then _ind="..."; fi

    if [[ "${#_str}" -gt "$_len" ]]; then 
        (( _len = _len - ${#_ind} ))
        printf -v _ret "%s%s" "${_str:0:$_len}" "$_ind"
    else
        _ret="$_str"
    fi
}


# get_title_box {varname} {"title"} [-width numchars] [-top '-'] [-side '|'] [-corner '+']
#   Returns a multiline block with borders on all sides and "title" center-justified within.
# Inputs:
#   title           - Text to display in the center of the title box.
#                     May be multiple lines.
#   width           - (Optional) Width of the title box in characters.
#                     If not provided, uses get_term_width to create a string which
#                     spans the current terminal window (slow).
#   top side corner - Characters to use for the top/bottom, sides, and corners of the box.
# Outputs:
#   varname         - Return title box into this variable.
#
function get_title_box() {
    local -A _fnargs=( [top]='-' [side]='|' [corner]='+' )
    fast_argparse _fnargs "varname title" "width top side corner" "$@"
    local -n _ret="${_fnargs[varname]}"
    local _title="${_fnargs[title]} "
    local _width="${_fnargs[width]}"
    if [[ "$_width" == "" ]]; then get_term_width _width; fi
    local _t="${_fnargs[top]}"
    local _s="${_fnargs[side]}"
    local _c="${_fnargs[corner]}"

    local _topline=""
    local _ctrlen=0; (( _ctrlen = _width - ${#_c} - ${#_c} ))
    get_repeated_string _topline "$_t" "$_ctrlen"
    printf -v _topline "%s%s%s\n" "$_c" "${_topline:0:_ctrlen}" "$_c"

    local _midlines=""
    local _ctrlen=0; (( _ctrlen = _width - ${#_s} - ${#_s} ))
    local _line;
    while IFS= read -r _line || [[ -n "$_line" ]]; do
        trim _line
        get_center_justified_string _line "$_line" "$_ctrlen"
        printf -v _line "%s%s%s\n" "$_s" "$_line" "$_s"
        _midlines="${_midlines}${_line}"
    done < <(printf '%s' "$_title")

    printf -v _ret "%s%s%s" "$_topline" "$_midlines" "$_topline"
}


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
#   description   - Text to display below title.
#   prefix        - Prefix text for each line of the menu. Defaults to "  ".
#   prompt        - Prompt text.
# Outputs:
#   $REPLY        - Global variable set to the index/key of the user's choice.
#
function user_selection_menu() {
    # Default values
    local -A __fnargs=([title]=""
                       [description]="Options:"
                       [prefix]="  "
                       [prompt]="Enter an option: " )
    fast_argparse __fnargs "optionsarray" "title description prefix prompt" "$@"

    local -n __opts="${__fnargs[optionsarray]}"
    local title="${__fnargs[title]}"
    local description="${__fnargs[description]}"
    local prefix="${__fnargs[prefix]}"
    local prompt="${__fnargs[prompt]}"
    local width=0; get_term_width width

    # Display menu and prompt
    printf "\n"
    if [[ "$title" != "" ]]; then
        local titlebox=""
        get_title_box titlebox "$title" -width "$width" -top '#' -side '#' -corner '#'
        printf "%s" "$titlebox"
    fi
    if [[ "$description" != "" ]]; then
        wrap_string description "$description" "$width"
        printf "%s\n" "$description"
    fi
#   if [[ "${title}" != "" ]]; then
#       local divider=""
#       printf -v divider "%${#title}s" ""
#       printf -v divider "##%s##" "${divider// /#}"
#       printf "%s\n" "$divider"
#       printf "  %s\n" "$title"
#       printf "%s\n" "$divider"
#       printf "\n"
#   fi
#   if [[ "${subtitle}" != "" ]]; then
#       printf "%s\n" "$subtitle"
#       printf "\n"
#   fi
    printvar __opts -showname false -prefix "$prefix" -wrapper ""
    printf "\n"
    unset REPLY
    while ! has_key __opts "$REPLY"; do
        read -r -p "$prompt"
    done
}




# table_print {table_name}
function table_print() {
    local -n __table=$1; require_table $1
    
    local __numrows="";     table_get_numrows  __table __numrows
    local -a __rownames=(); table_get_rownames __table __rownames
    local -a __rowdisplaynames=(); copy_array __rownames __rowdisplaynames
    local __numcols="";     table_get_numcols  __table __numcols
    local -a __colnames=(); table_get_colnames __table __colnames
    local -a __coldisplaynames=(); copy_array __colnames __coldisplaynames

    local __colsep=" | "
    local __colsep_width="${#__colsep}"
    local __width=0; get_term_width __width
    local __max_col_width=20
    local __rowname_col_width=0
    local -a __col_widths=()

    # Crop row and column names to the max size
    local i j __val __col_width
    for ((i = 0; i < __numrows; i++)); do
        crop_string __rowdisplaynames[$i] "${__rownames[$i]}" "$__max_col_width"
        __rowdisplaynames[$i]="[${__rowdisplaynames[$i]}]:"
        # Also determine the longest rowname to set the width of the rowname column
        if [[ "${#__rowdisplaynames[$i]}" -gt "$__rowname_col_width" ]]; then
            __rowname_col_width="${#__rowdisplaynames[$i]}"
        fi
    done
    for ((i = 0; i < __numcols; i++)); do
        crop_string __coldisplaynames[$i] "${__colnames[$i]}" "$__max_col_width"
        # Also determine the width of the column
        __col_width="${#__coldisplaynames[$i]}"
        for ((j = 0; j < __numrows; j++)); do
            table_get __table "${__rownames[$j]}" "${__colnames[$i]}" __val
            if [[ "${#__val}" -gt "$__col_width" ]]; then
                __col_width="${#__val}"
            fi
        done
        if [[ "$__col_width" -le "$__max_col_width" ]]; then
            __col_widths+=("$__col_width")
        else
            __col_widths+=("$__max_col_width")
        fi
    done

    # printvar __numrows
    # printvar __numcols
    # printvar __rowdisplaynames
    # printvar __coldisplaynames
    # printvar __rowname_col_width
    # printvar __col_widths

    # Display the table header
    local __colname="" __headerline="" __whitespace="" __rowsep=""
    get_repeated_string __whitespace " " "$__rowname_col_width"
    printf -v __headerline "%s" "$__whitespace"
    for ((i = 0; i < __numcols; i++)); do
        get_center_justified_string __colname "${__coldisplaynames[$i]}" "${__col_widths[$i]}"
        printf -v __headerline "%s%s%s" "$__headerline" "$__colsep" "$__colname"
    done
    crop_string __headerline "$__headerline" "$__width"
    get_repeated_string __rowsep "-" "${#__headerline}"
    printf "%s\n" "$__headerline"
    printf "%s\n" "$__rowsep"

    # Display the table contents
    local __rowname="" __line="" __val=""
    for ((i = 0; i < __numrows; i++)); do
        __line=""

        # Display the rowname first
        get_right_justified_string __rowname "${__rowdisplaynames[$i]}" "$__rowname_col_width"
        printf -v __line "%s" "$__rowname"

        # Loop through the row's values and print them
        for ((j = 0; j < __numcols; j++)); do
            table_get __table "${__rownames[$i]}" "${__colnames[$j]}" __val
            crop_string __val "$__val" "${__col_widths[$j]}"
            get_left_justified_string __val "$__val" "${__col_widths[$j]}"
            printf -v __line "%s%s%s" "$__line" "$__colsep" "$__val"
        done

        # Crop line to the terminal width and display it
        crop_string __line "$__line" "$__width"
        printf "%s\n" "$__line"
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
