#####################################################################################################
#
#       BASH WSL-2 FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-functions/common-functions.sh
#
#####################################################################################################
#
# func_name {required_arg} [optional_arg] [REF]
#   Description
# Inputs:
#   $GLOBALVAR  - Required global variable read by the function.
#   required_arg - desc
#   optional_arg - (Optional)
#   REF         - Variable name (non-quoted) for pass-by-reference.
# Outputs:
#   $GLOBALVAR  - Global variable written to by the function.
#   &1 (stdout) - Function prints to standard output channel.
#   &2 (stderr) - Function prints to standard error channel.
#   $?          - Numeric exit value; 0 indicates success.
#
#####################################################################################################


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


# is_systemd
#   Checks if system has been initialized with systemd.
# Outputs:
#   $__SYSTEMD   - 
#   $?          - Numeric exit value; 0 indicates systemd has been started.
#
function is_systemd() {
    if [ -z "$__SYSTEMD" ]; then
        systemctl list-units --type=service > /dev/null 2> /dev/null
        export __SYSTEMD=$?
    fi
    return $__SYSTEMD
}


# require_systemd
#   Returns from the calling function with an error message if systemd is not available.
# Inputs:
#   None
# Outputs:
#   &2 (stderr) - Function prints to standard error channel.
#   $?          - Numeric exit value; 0 indicates this script is being run by root.
#
function require_systemd() {
    is_systemd || return_error "SystemD init is required, but not available on this system."
}


# print_octal str
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


# get_script_dir
#   Returns the full path containing the currently-running script.
# Inputs:
#   $0              - Script directory is recovered from the $0 command line argument.
# Outputs:
#   $_SCRIPT_DIR    - Global var containing parent directory of the script.
#
function get_script_dir(){
    _SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
}


# get_user_home {user}
#   Gets the home directory of the specified user.
# Inputs:
#   user        - Username
# Outputs:
#   $_HOME      - Variable containing the home directory of the user, or "" (empty) if not found.
#
function get_user_home() {
    _HOME="$( getent passwd "$USER" | cut -d: -f6 )"
}


# auto_install:  Copies files from SOURCE to DESTINATION and applies chmod +x to scripts.
# Inputs:
#   auto_install "SOURCE_1 : DEST_1     Copies files, creating new folders if necessary.
#                 SOURCE_2 : DEST_2 "   Will use 'sudo' if necessary to gain write privilege.
# Outputs:
#   None
#
function auto_install() {
    IFS=$'\n' declare -a 'ARR=($*)'
    for LINE in "${ARR[@]}"; do
        IFS=':' declare -a 'PAIR=($LINE)'
        local SRC=$(trim "${PAIR[0]}")
        local DST=$(trim "${PAIR[1]}")
        local DST_DIR=$(dirname "$DST")
        echo "$SRC --> $DST"
        mkdir -p "$DST_DIR" 2> /dev/null || sudo mkdir -p "$DST_DIR"
        cp -f "$SRC" "$DST" 2> /dev/null || sudo cp -f "$SRC" "$DST"
        if [[ "$SRC" == *.sh ]]; then 
            chmod +x "$DST" 2> /dev/null || sudo chmod +x "$DST"
        fi
    done
}

# operate_on_each {function_call} {tokenize=stdin}        [in_delim [out_delim]]
# operate_on_each {function_call} {tokenize=string} {REF} [in_delim [out_delim]] 
# operate_on_each {function_call} {tokenize=array}  {REF}
#   Runs the specified function on every token of input.
#   Three operating modes:
#       tokenize=stdin :   Scans stdin, separates into tokens according to in_delim.
#                          Applies function_call to each token, then writes each modified token to stdout.
#       tokenize=string :  Assumes REF is a string. Separates REF into tokens according to in_delim.
#                          Applies function_call to each token, then writes each modified token back to REF in sequence.
#       tokenize=array :   Assumes REF is an array. Applies function_call to each element of REF.
# Inputs:
#   function_call - String containing function call to run on each token of input.
#                   Function must support at least one REF (pass-by-reference) argument.
#                   Write a literal REF (unquoted) as the operator function's REF argument.
#                   Format:
#                       "func_name \"arg1\" ... \"arg2\" REF \"arg3\" ... "
#   tokenize=...  - Select an operating mode. See above.
#   in_delim      - (Optional): Character to split the input into tokens. Defaults to $'\n'.
#   out_delim     - (Optional): String to place between each modified token in the output. Defaults to $'\n' .
#   REF           - Variable name for pass-by-reference (unquoted).
#                   If REF is supplied, operate_on_each reads from REF's contents instead of stdin.
#                   The REF variable CANNOT be named any of the following: _ref _out _in
#   <&0           - If REF not supplied, reads from stdin.
# Outputs:
#   REF           - If variable name supplied, returns output directly into REF.
#   >&1           - If REF not supplied, outputs to stdout.
#
function operate_on_each(){
    if [[ "$1" == "" ]]; then return_error "No function specified."
    else                      local function_call=$1
    fi
    if [[ "$2" == "" ]]; then return_error "No tokenization specified."
    elif [[ "$2" == "tokenize=stdin" ]];  then local tokenize="stdin"
        if [[ "$3" == "" ]]; then local in_delim=$'\n'
        else                      local in_delim="$3"
        fi
        if [[ "$4" == "" ]]; then local out_delim=$'\n'
        else                      local out_delim="$4"
        fi
    elif [[ "$2" == "tokenize=string" ]]; then local tokenize="string"
        if [[ "$3" == "" ]]; then return_error "No string variable REF specified."
        else                      local -n _ref=$3
        fi
        if [[ "$4" == "" ]]; then local in_delim=$'\n'
        else                      local in_delim="$4"
        fi
        if [[ "$5" == "" ]]; then local out_delim=$'\n'
        else                      local out_delim="$5"
        fi
    elif [[ "$2" == "tokenize=array" ]];  then local tokenize="array"
        if [[ "$3" == "" ]]; then return_error "No array variable REF specified."
        else                      local -n _ref=$3
        fi
    else                      return_error "Invalid tokenization parameter."
    fi

    if [[ "$tokenize" == "stdin" ]]; then
        local REF

        while IFS="$in_delim" read -r REF || [ -n "$REF" ]; do
            $function_call
            builtin printf '%s%s' "$REF" "$out_delim"
        done

    elif [[ "$tokenize" == "string" ]]; then
        local REF _out _in="$_ref"

        while IFS="$in_delim" read -d "$in_delim" -r REF || [ -n "$REF" ]; do
            $function_call
            builtin printf -v _out '%s%s%s' "$_out" "$REF" "$out_delim"
        done < <(printf '%s' "$_in")
        _ref="$_out"

    elif [[ "$tokenize" == "array" ]]; then
        local REF idx

        for idx in ${!_ref[@]}; do
            REF="${_ref[$idx]}"
            $function_call
            _ref[$idx]="$REF"
        done

    fi
}

# str_to_arr {ARR_REF} [in_delim [STR_REF]]
#   Splits a string into tokens, then appends each token to an array variable.
# Inputs:
#   ARR_REF     - Name of array variable (unquoted) on which to append the new elements.
#                 CANNOT be named: _arrref, _out
#   in_delim    - Optional: Character to split the input into tokens. Defaults to $'\n'.
#   STR_REF     - Optional: Name of string variable (unquoted) to tokenize.
#                 CANNOT be named: _strref, _in
#   &0 (stdin)  - If STR_REF is not specified, stdin is used instead.
# Outputs:
#   ARR_REF     - Tokens from the string are appended to ARR_REF.
#
function str_to_arr(){
    if [[ "$1" == "" ]]; then return_error "No array variable specified"
    else                      local -n _arrref=$1
                              local -a _out=()
    fi
    if [[ "$2" == "" ]]; then local in_delim=$'\n'
    else                      local in_delim="$2"
    fi
    if [[ "$3" == "" ]]; then local _strref="__unset"
                              local fid=0
    else                      local -n _strref=$3
                              local fid=3
    fi

    local tok
    while IFS="$in_delim" read -d "$in_delim" -r tok <&${fid} || [ -n "$tok" ]; do
        _out+=( "$tok" )
    done 3< <(printf '%s' "$_strref")
    exec 3<&-
    _arrref=("${_arrref[@]}" "${_out[@]}")
}


# arr_to_str {ARR_REF} [out_delim [STR_REF]]
#   Converts an array variable to a string, separating each element with out_delim.
# Inputs:
#   ARR_REF     - Name of array variable (unquoted).
#                 CANNOT be named: _arrref
#   out_delim   - Optional: String to separate each array element in the resulting string. Defaults to \n.
#   STR_REF     - Optional: Name of string variable (unquoted) in which to store the resulting string.
#                 CANNOT be named: _strref
# Outputs:
#   &1 (stdout) - If STR_REF is not specified, prints the resulting string to stdout.
#   STR_REF     - If STR_REF is specified, passes the resulting string by-reference.
#
function arr_to_str(){
    if [[ "$1" == "" ]]; then return_error "No array variable specified"
    else                      local -n _arrref=$1
    fi
    if [[ "$2" == "" ]]; then local out_delim=$'\n'
    else                      local out_delim="$2"
    fi
    if [[ "$3" != "" ]]; then local -n _strref=$3
                              local printf_args="-v _strref"
    fi

    builtin printf $printf_args "%s$out_delim" "${_arrref[@]}"
}

# print_arr {ARR_REF} [out_delim]
#   Prints the contents of an array element-by-element, numbering each one (for visual purposes)
# Inputs:
#   ARR_REF     - Name of array variable (unquoted).
#                 CANNOT be named: _arrref
#   out_delim   - Optional: String to separate each array element in the resulting string. Defaults to \n.
# Outputs:
#   &1 (stdout) - Prints the array's contents to stdout.
#
function print_arr(){
    if [[ "$1" == "" ]]; then return_error "No array variable specified"
    else                      local -n _arrref=$1
    fi
    if [[ "$2" == "" ]]; then local out_delim=$'\n'
    else                      local out_delim="$2"
    fi

    local idx
    for idx in ${!_arrref[@]}; do
        printf '%4d: [%s]%s' "$idx" "${_arrref[$idx]}" "$out_delim"
    done
}


# trim [STR_REF]
#   Removes leading and trailing whitespace from a string (including newlines)
# Inputs:
#   STR_REF     - Optional: Name of variable (unquoted) to trim.
#                 CANNOT be named: _strref _out _in
#   &0 (stdin)  - If STR_REF is not specified, stdin is used instead.
# Outputs:
#   STR_REF     - Returns trimmed string back into REF.
#   &1 (stdout) - Prints the array's contents to stdout.
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

function git_reset_pull()
{
    local URL="$1"
    local BRANCH="$2"
    
    local EXT="${URL##*.}"
    local DIR="$(basename "$URL" .$EXT)"

    if [ -d "$DIR" ]; then
        cd "$DIR"
        git fetch --all
        git reset --hard origin/$BRANCH
        git pull
        cd ..
    else
        git clone "$URL"
    fi
}


# replace_line {file} {search_str} {replace_str} [match=whole/partial [sudo=true/false]]
#   Scans for a line matching str, then replaces the entire line in-place.
# Inputs:
#   file        - File to edit.
#   search_str  - String to search for in file. Can be a regex.
#   replace_str - String to replace line with, on every line matching search_str.
#   match=whole/partial - (Optional) Whole line must match str, or only part. Defaults to match=whole.
#   sudo=true/false - (Optional); use sudo to read and write file.
# Outputs:
#   &1 (stdout) - Function prints to standard output channel.
#   $?          - Numeric exit value; 0 indicates success.
#
function ensure_line(){
    if [[ "$1" == "" ]]; then return_error "No file specified"
    else                      local FILE="$1"
    fi
    if [[ "$2" == "" ]]; then return_error "No string specified"
    else                      local LINE="$2"
    fi
    if [[ "$3" == "" ]]; then local GREP_FLAGS="-x"
    elif [[ "$3" == "match=whole" ]];   then local GREP_FLAGS="-x"
    elif [[ "$3" == "match=partial" ]]; then local GREP_FLAGS=""
    else                      return_error "Invalid match parameter: $3"
    fi
    if [[ "$4" == "sudo=true" ]]; then local SUDO_COMMAND="sudo"
    else                      local SUDO_COMMAND=""
    fi

    $SUDO_COMMAND touch "$FILE" 2>/dev/null || return_error "$FILE is not writeable."
    $SUDO_COMMAND test -r "$FILE" || return_error "$FILE is not readable."

    $SUDO_COMMAND sed -i "s#$SEARCH#$REPLACE#" "$FILE"
    if ! $SUDO_COMMAND grep $GREP_FLAGS -qF "$LINE" "$FILE"; then
        echo "Appending line to $FILE:"
        echo "$LINE"
        echo "$LINE" | $SUDO_COMMAND tee -a "$FILE" > /dev/null
    else
        echo "$FILE already contains at least one line matching:"
        echo "$LINE"
    fi
}

# Read parameter values with "${params[$name]}"
function parse_name_value_pairs(){
    declare -A params
    while IFS=$'[ \t]*=[ \t]*' read -r name value
    do
        params[$name]="$value"
    done
}


# ensure_line {file} {str} [match=whole/partial [sudo=true/false]]
#   Appends a line to the file, if line does not exist. Whole line must match.
#   Creates file if it does not exist. Does not create parent directories.
# Inputs:
#   file        - File to append line; creates file if it does not exist.
#   str         - String to append to the file. Newline character not needed. (Not a regex)
#   match=whole/partial - (Optional) Whole line must match str, or only part. Defaults to match=whole.
#   sudo=true/false - (Optional); use sudo to read and write file.
# Outputs:
#   &1 (stdout) - Function prints to standard output channel.
#   $?          - Numeric exit value; 0 indicates success.
#
function ensure_line(){
    if [[ "$1" == "" ]]; then return_error "No file specified"
    else                      local FILE="$1"
    fi
    if [[ "$2" == "" ]]; then return_error "No string specified"
    else                      local LINE="$2"
    fi
    if [[ "$3" == "" ]]; then local GREP_FLAGS="-x"
    elif [[ "$3" == "match=whole" ]];   then local GREP_FLAGS="-x"
    elif [[ "$3" == "match=partial" ]]; then local GREP_FLAGS=""
    else                      return_error "Invalid match parameter: $3"
    fi
    if [[ "$4" == "sudo=true" ]]; then local SUDO_COMMAND="sudo"
    else                      local SUDO_COMMAND=""
    fi

    $SUDO_COMMAND touch "$FILE" 2>/dev/null || return_error "$FILE is not writeable."
    $SUDO_COMMAND test -r "$FILE" || return_error "$FILE is not readable."

    if ! $SUDO_COMMAND grep $GREP_FLAGS -qF "$LINE" "$FILE"; then
        echo "Appending line to $FILE:"
        echo "$LINE"
        echo "$LINE" | $SUDO_COMMAND tee -a "$FILE" > /dev/null
    else
        echo "$FILE already contains at least one line matching:"
        echo "$LINE"
    fi
}


# ensure_line_visudo {file} {str} [match=whole/partial]
#   Appends a line to the file using the "visudo" utility, if line does not exist. Whole line must match.
#   visudo is the intended method for editing /etc/sudoers and /etc/sudoers.d/*.
#   Creates file if it does not exist.
# Inputs:
#   file        - File to append line; creates file if it does not exist. Should be /etc/sudoers or /etc/sudoers.d/...
#   str         - String to append to the file. Newline character not needed.
#   match=whole/partial - (Optional) Whole line must match str, or only part. Defaults to match=whole.
# Outputs:
#   &1 (stdout) - Function prints to standard output channel.
#   $?          - Numeric exit value; 0 indicates success.
#
function ensure_line_visudo(){
    if [[ "$1" == "" ]]; then return_error "No file specified"
    else                      local FILE="$1"
    fi
    if [[ "$2" == "" ]]; then return_error "No string specified"
    else                      local LINE="$2"
    fi
    if [[ "$3" == "" ]]; then local GREP_FLAGS="-x"
    elif [[ "$3" == "match=whole" ]];   then local GREP_FLAGS="-x"
    elif [[ "$3" == "match=partial" ]]; then local GREP_FLAGS=""
    else                      return_error "Invalid match parameter: $3"
    fi
    local SUDO_COMMAND="sudo"

    $SUDO_COMMAND touch "$FILE" 2>/dev/null || return_error "$FILE is not writeable."
    if ! $SUDO_COMMAND grep $GREP_FLAGS -qF "$LINE" "$FILE"; then
        echo "Appending line to $FILE:"
        echo "$LINE"
        echo "$LINE" | $SUDO_COMMAND EDITOR='tee -a' visudo -f "$FILE" > /dev/null
    else
        echo "$FILE already contains at least one line matching:"
        echo "$LINE"
    fi
}


# delete_lines_matching {file} {str} [match=whole/partial [sudo=true/false]]
#   Removes a single line from the file.
# Inputs:
#   file        - File to append line; creates file if it does not exist.
#   str         - String to match against each line in the file. (Not a regex)
#   match=whole/partial - (Optional) Whole line must match str, or only part. Defaults to match=whole.
#   sudo=true/false - (Optional); use sudo to read and write file.
# Outputs:
#   &1 (stdout) - Function prints to standard output channel.
#   $?          - Numeric exit value; 0 indicates success.
#
function delete_lines_matching(){
    if [[ "$1" == "" ]]; then return_error "No file specified"
    else                      local FILE="$1"
    fi
    if [[ "$2" == "" ]]; then return_error "No string specified"
    else                      local LINE="$2"
    fi
    if [[ "$3" == "" ]]; then local GREP_FLAGS="-x"
    elif [[ "$3" == "match=whole" ]];   then local GREP_FLAGS="-x"
    elif [[ "$3" == "match=partial" ]]; then local GREP_FLAGS=""
    else                      return_error "Invalid match parameter: $3"
    fi
    if [[ "$4" == "sudo=true" ]]; then local SUDO_COMMAND="sudo"
    else                      local SUDO_COMMAND=""
    fi

    $SUDO_COMMAND test -e "$FILE" || return_error "$FILE does not exist."
    $SUDO_COMMAND test -w "$FILE" || return_error "$FILE is not writeable."
    $SUDO_COMMAND test -r "$FILE" || return_error "$FILE is not readable."

    if $SUDO_COMMAND grep $GREP_FLAGS -qF "$LINE" "$FILE"; then
        echo "Removing matching lines from $FILE:"
        echo "$LINE"
        $SUDO_COMMAND grep $GREP_FLAGS -v "$LINE" "$FILE" | $SUDO_COMMAND tee "$FILE.tmp" > /dev/null
        $SUDO_COMMAND mv "$FILE.tmp" "$FILE"
    else
        echo "$FILE does not contain any line matching:"
        echo "$LINE"
    fi
}


# sysd_config_user_service {service} {enable/disable} [boot=false/true]
#   Configures a SystemD (systemctl) service to start automatically when the current user logs in.
#   Service is run as the current user, inheriting privilege.
# Inputs:
#   service         - Name of SystemD service. Must have a .service config file in "$HOME/.config/systemd/user/"
#   enable/disable  - Enable: sets service to autostart. Disable: removes service from autostarting.
#   boot=false/true - (Optional): if true, all of this user's services will start on system boot instead of when the user logs in.
#                       It will still run with the user's privilege level. It will continue running when the user logs out.
# Outputs:
#   $?              - Numeric exit value; 0 indicates success.
#
function sysd_config_user_service() {
    require_non_root
    require_systemd

    if [[ "$1" == "" ]]; then            return_error "No service specified."
    else                                 local SERVICE="$1"
    fi
    if [[ "$2" == "" ]]; then            return_error "Need to specify enable/disable."
    elif [[ "$2" == "enable" ]]; then    local MODE="enable"
    elif [[ "$2" == "disable" ]]; then   local MODE="disable"
    else                                 return_error "Need to specify enable/disable."
    fi
    if [[ "$3" == "" ]]; then            local LINGER="disable-linger"
    elif [[ "$3" == "boot=false" ]]; then local LINGER="disable-linger"
    elif [[ "$3" == "boot=true" ]]; then local LINGER="enable-linger"
    else                                 return_error "Invalid boot parameter."
    fi

    SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE.service"
    [ ! -e "$SERVICE_FILE" ] && return_error "Required file $SERVICE_FILE does not exist."

    systemctl --user $MODE $SERVICE
    systemctl --user daemon-reload

    loginctl $LINGER $USER
}

# sysv_config_user_service {service} {enable/disable}
#   Configures a SystemV (init.d) service to start automatically when the current user logs in.
#   Service is always run with root privilege, not with the user privilege.
#   Required for systems without systemctl (Such as WSL).
# Inputs:
#   service         - Name of SystemV service. Must have a launch script in /etc/init.d.
#   enable/disable  - Enable: sets service to autostart. Disable: removes service from autostarting.
# Outputs:
#   $?              - Numeric exit value; 0 indicates success.
#
function sysv_config_user_service() {
    require_non_root

    if [[ "$1" == "" ]]; then   return_error "No service specified."
    else                        local SERVICE="$1"
    fi
    if [[ "$2" == "" ]]; then   return_error "Need to specify enable/disable."
    elif [[ "$2" == "enable" ]]; then   local MODE="enable"
    elif [[ "$2" == "disable" ]]; then  local MODE="disable"
    else                        return_error "Need to specify enable/disable."
    fi

    local SUDOER_FILE="/etc/sudoers.d/$USER"
    local SUDOER_ENTRY="$USER ALL=(ALL) NOPASSWD: /usr/sbin/service $SERVICE *"
    local AUTORUN_FILE="$HOME/.profile"
    local AUTORUN_COMMAND="(nohup sudo service $SERVICE start </dev/null >/dev/null 2>&1 &)"

    if [[ "$MODE" == "enable" ]]; then
        # Need to be able to run "sudo service SERVICE start/stop" passwordlessly
        ensure_line_visudo "$SUDOER_FILE" "$SUDOER_ENTRY" match=whole
        # Launch service in background using ~/.profile
        ensure_line "$AUTORUN_FILE" "$AUTORUN_COMMAND" match=whole
    else
        # Remove permissions from sudoer file
        delete_lines_matching "$SUDOER_FILE" "$SUDOER_ENTRY" match=partial sudo=true
        # Remove autostart entry in ~/.profile
        delete_lines_matching "$AUTORUN_FILE" "$AUTORUN_COMMAND" match=whole
    fi
}




#####################################################################################################
__COMMON_FUNCS_AVAILABLE=0
