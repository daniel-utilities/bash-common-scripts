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
# func_name {required_arg} [optional_arg]
#   Description
# Inputs:
#   $GLOBALVAR  - Required global variable read by the function.
#   required_arg - desc
#   optional_arg - (Optional)
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


# get_script_dir
#   Returns the full path containing the currently-running script.
# Example:
#   SCRIPT_DIR=$(get_script_dir)
# Inputs:
#   $0          - Script directory is recovered from the $0 command line argument
# Outputs:
#   &1 (stdout) - Function prints to standard output channel.
#
function get_script_dir(){
    dirname "$(readlink -f "$0")"
}


# print_ifs
#   Prints the $IFS variable, making whitespace characters visible. Useful for debugging.
# Inputs:
#   $IFS        - Typically defaults to ' ', '\n', '\t'
# Outputs:
#   &1 (stdout) - Function prints to standard output channel.
#
function print_ifs(){
    printf "%s" "$IFS" | od -bc
}


# is_root
#   Checks if script is being run by root user.
# Example:
#   is_root && echo yes || echo no
# Outputs:
#   $?          - Numeric exit value; 0 indicates this script is being run by root.
#
function is_root(){
    [ "$EUID" -eq 0 ] && return 0 || return 1
}


# require_root
#   Returns from the calling function if not being run by root user.
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
#   Returns from the calling function if being run by root user.
# Inputs:
#   None
# Outputs:
#   &2 (stderr) - Function prints to standard error channel.
#   $?          - Numeric exit value; 0 indicates this script is not root.
#
function require_non_root() {
    is_root && return_error "Script can not be run by root. Retry without sudo."
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


# trim:  Trims leading and trailing whitespace from a string
# Inputs:
#   trim "\t string_with_whitespace \n  "
# Outputs:
#   echo string_without_whitespace
#
function trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
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


function search_replace_line_in_file()
{
    local SEARCH="$1"
    local REPLACE="$2"
    local FILE="$3"
    local SUDO="$4"

    sed -i "s#$SEARCH#$REPLACE#" "$FILE"
}


function newlines_to_spaces()
{
    echo "$1" | tr '\n' ' '
}

# Read parameter values with "${params[$name]}"
function parse_name_value_pairs(){
    declare -A params
    while IFS=$'[ \t]*=[ \t]*' read -r name value
    do
        echo "Read name=$name, value=$value" >&2
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
_COMMON_FUNCS_AVAILABLE="y"