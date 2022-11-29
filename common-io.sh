#####################################################################################################
#
#       BASH COMMON-IO FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-scripts/common-functions.sh
#       source ./bash-common-scripts/common-io.sh
#
#####################################################################################################
#       REQUIRES COMMON-FUNCTIONS
#
if [ ! $__COMMON_FUNCS_AVAILABLE ]; then
    echo "ERROR: This script requires \"common-functions.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-functions.sh\" before sourcing this script."
    return 1
fi
#####################################################################################################
#       FUNCTION REFERENCE:
#
# multicopy {arrayname}
#  Copies files from multiple sources to multiple destinations and applies chmod +x to scripts.
# extract {SOURCE} {DESTINATION}
#   Extracts an archive file to a destination directory. Supports tar, gz, bz2, xz, zip.
# git_latest {URL} {BRANCH}
#   Clones or pulls a git repository in the current directory (with recursive submodules).
# ensure_line {file} {str} [match=whole/partial [sudo=true/false]]
#   Appends a line to the file, if line does not exist. Choose whole or partial line match.
# ensure_line_visudo {file} {str} [match=whole/partial]
#   Appends a line to the file using the "visudo" utility, if line does not exist.
# delete_lines_matching {file} {str} [match=whole/partial [sudo=true/false]]
#   Removes a lines from the file matching str.
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



# multicopy {arrayname}
#  Copies files from multiple sources to multiple destinations and applies chmod +x to scripts.
# Inputs:
#   arrayname  - Name of source/destination array (unquoted), containing strings formatted as:
#                declare -a ( "SOURCE_1 : DEST_1"
#                             "SOURCE_2 : DEST_2" )        
#                Copies source files to destination. Will use 'sudo' if necessary to gain write privilege.
# Outputs:
#   None
#
function multicopy() {
    local -n _arrref=$1
    for LINE in "${_arrref[@]}"; do
        IFS=':' declare -a 'PAIR=($LINE)'
        local SRC="${PAIR[0]}"
        trim SRC
        local DST="${PAIR[1]}"
        trim DST
        local DST_DIR=$(dirname "$DST")
        if [[ ! -d "$DST_DIR" ]]; then
            return_error "Directory does not exist: \"$DST_DIR\""
        fi
        echo "Copying \"$SRC\" --> \"$DST\""
        cp -f "$SRC" "$DST" 2> /dev/null || sudo cp -f "$SRC" "$DST"
        if [[ "$SRC" == *.sh ]]; then 
            chmod +x "$DST" 2> /dev/null || sudo chmod +x "$DST"
        fi
    done
}


# extract {SOURCE} {DESTINATION}
#   Extracts an archive file to a destination directory. Supports tar, gz, bz2, xz, zip.
# Inputs:
#   SOURCE      - Archive filename to extract
#   DESTINATION - Destination directory
# Outputs:
#   None
#
function extract() {
    local SRC="$1"
    local DST_DIR="$2"

    if [[ ! -d "$DST_DIR" ]]; then
        return_error "Directory does not exist: \"$DST_DIR\""
    fi

    local EXT=${SRC##*.}
    if [ "$EXT" = "gz" ]; then
        tar -zxf "$SRC" -C "$DST_DIR" || sudo tar -zxf "$SRC" -C "$DST_DIR"
    elif [ "$EXT" = "bz2" ]; then
        tar -jxf "$SRC" -C "$DST_DIR" || sudo tar -jxf "$SRC" -C "$DST_DIR"
    elif [ "$EXT" = "xz" ]; then
        tar -Jxf "$SRC" -C "$DST_DIR" || sudo tar -Jxf "$SRC" -C "$DST_DIR"
    elif [ "$EXT" = "tar" ]; then
        tar -xf "$SRC" -C "$DST_DIR" || sudo tar -xf "$SRC" -C "$DST_DIR"
    elif [ "$EXT" = "zip" ]; then
        unzip "$SRC" -d "$DST_DIR" || sudo unzip "$SRC" -d "$DST_DIR"
    else
      return_error "Unknown archive format ($EXT) for file: \"$SRC\""
    fi
}


# git_latest {URL} {BRANCH}
#   Clones or pulls a git repository in the current directory (with recursive submodules).
#   If repo already exists, resets local changes and pulls the latest version.
# Inputs:
#   URL         - URL to Git repository
#   BRANCH      - Branch to clone/pull
#
function git_latest()
{
    local URL="$1"
    local BRANCH="$2"
    
    local EXT="${URL##*.}"
    local DIR="$(basename "$URL" .$EXT)"
    local DIR_OG="$PWD"

    if [ -d "$DIR" ]; then
        cd "$DIR"
        git fetch --all
        git reset --hard origin/$BRANCH
        git pull
        git submodule update --init --recursive
        cd "$DIR_OG"
    else
        git clone --single-branch "$BRANCH" --recurse-submodules "$URL"
    fi
}


# ensure_line {file} {str} [match=whole/partial [sudo=true/false]]
#   Appends a line to the file, if line does not exist. Choose whole or partial line match.
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
#   Appends a line to the file using the "visudo" utility, if line does not exist.
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
#   Removes a lines from the file matching str.
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




#####################################################################################################

__COMMON_IO_AVAILABLE=0
