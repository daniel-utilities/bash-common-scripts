#####################################################################################################
#
#       BASH WSL-2 FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-functions/common-functions.sh
#       source ./bash-common-functions/wsl-functions.sh
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


# is_wsl2
#   Checks if script is being run within WSL2.
# Example:
#   is_wsl2 && echo yes || echo no
# Outputs:
#   $__WSL2      - Numeric global var; 0 indicates this system is WSL2
#   $?          - Numeric exit value; 0 indicates this system is WSL2.
#
function is_wsl2() {
    if [ -z "$__WSL2" ]; then
        grep -q "WSL2" /proc/version
        export __WSL2=$?
    fi
    return $__WSL2
}


# require_wsl2
#   Returns from the function which called this if not being run with WSL2.
# Outputs:
#   &2 (stderr) - Function prints to standard error channel.
#   $?          - Numeric exit value; 0 indicates this system is WSL2.
#
function require_wsl2() {
    is_wsl2 || return_error "Script can only be run on WSL 2."
}


# wsl2_get_distro_name
#   Determine the name of this WSL distro on the system. Each WSL installation has a unique name associated with it.
# Outputs:
#   $__WSL2_DISTRO - Name of WSL2 distro.
#   $?            - Numeric exit value; 0 indicates success.
#
function wsl2_get_distro_name(){
    require_wsl2

    if [ -z "$__WSL2_DISTRO" ]; then
        export __WSL2_DISTRO="$(IFS='\'; x=($(wslpath -w /)); echo "${x[${#x[@]}-1]}")"
    fi
}


# wsl2_get_cmd_path
#   Get the wsl-equivalent path to cmd.exe.
# Outputs:
#   $__WSL2_CMD_PATH - WSL path to cmd.exe
#   $?              - Numeric exit value; 0 indicates success.
#
function wsl2_get_cmd_path(){
    require_wsl2

    if [ -z "$__WSL2_CMD_PATH" ]; then
        export __WSL2_CMD_PATH="cmd.exe"
        [[ ! $(type -P "cmd.exe") ]] && __WSL2_CMD_PATH="$(wslpath 'C:\Windows\System32\cmd.exe')"
    fi
}


# wsl2_get_powershell_path
#   Get the wsl-equivalent path to powershell.exe.
# Outputs:
#   $__WSL2_POWERSHELL_PATH  - WSL path to powershell.exe
#   $?                      - Numeric exit value; 0 indicates success.
#
function wsl2_get_powershell_path(){
    require_wsl2

    if [ -z "$__WSL2_POWERSHELL_PATH" ]; then
        export __WSL2_POWERSHELL_PATH="powershell.exe"
        [[ ! $(type -P "$__WSL2_POWERSHELL_PATH") ]] && __WSL2_POWERSHELL_PATH="$(wslpath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe')"
    fi
}


# wsl2_get_version
#   Get the installed version of WSL by running "wsl --version". At the moment, only works for Windows Store versions of WSL.
# Outputs:
#   $__WSL2_VERSION - WSL version number, or 0.0 if could not be determined.
#
function wsl2_get_version(){
    require_wsl2

    if [ -z "$__WSL2_VERSION" ]; then
        export __WSL2_VERSION="$( cmd_exec "wsl --version" | grep "WSL version" | cut -d':' -f2  2>/dev/null || echo "0.0" )"
        __WSL2_VERSION="$( trim "$__WSL2_VERSION" )"
    fi
}

# ps_exec {exepath} {args} [elevated=false/true [hidden=false/true]]
#   Start a Windows process in a new Powershell window, from within WSL.
# Example: Shows an error in CMD window unless elevated=true.
#   ps_exec "C:\\Windows\\System32\\cmd.exe" "/k net session && pause" elevated=true hidden=true
# Inputs:
#   $__WSL2_POWERSHELL_PATH  - WSL path to powershell.exe (or cmd /c powershell.exe)
#   exepath             - Windows path (uses backslashes) to executable file
#   args                - String containing list of arguments to pass to executable
#   elevated=false/true - (Optional): Defaults to false. If true, EXE will be launched as Administrator.
#                           UAC will be invoked (if enabled on the system).
#   hidden=false/true   - (Optional): Defaults to false. If true, Powershell window will be hidden.
# Outputs:
#   $?                  - Numeric exit value of the Windows process. 0 indicates success.
#
function ps_exec() {
    require_wsl2

    if [[ "$1" == "" ]]; then   return_error "No executable specified."
    else                        local EXE="$1"
    fi
                                local ARGS="$2"
    if [[ "$3" == "" ]]; then   local ELEVATED="false"
    elif [[ "$3" == "elevated=true" ]]; then    local ELEVATED="true"
    elif [[ "$3" == "elevated=false" ]]; then   local ELEVATED="false"
    else                        return_error "Invalid parameter 3: $3"
    fi
    if [[ "$4" == "" ]]; then   local HIDE_WINDOW="false"
    elif [[ "$4" == "hidden=true" ]]; then      local HIDE_WINDOW="true"
    elif [[ "$4" == "hidden=false" ]]; then     local HIDE_WINDOW="false"
    else                        return_error "Invalid parameter 4: $4"
    fi

    wsl2_get_powershell_path  # ensures $__WSL2_POWERSHELL_PATH  is set

    local FIXEDARGS=${ARGS//\'/\'\'}
    local PARAMS="\"$EXE\" -ArgumentList '$FIXEDARGS' -Wait -PassThru"
    if [[ "$HIDE_WINDOW" == true ]]; then PARAMS="$PARAMS -WindowStyle Hidden"; fi
    if [[ "$ELEVATED" == true ]]; then PARAMS="$PARAMS -Verb RunAs"; fi
    local CMDLET="\$PROC=Start-Process $PARAMS; \$PROC.hasExited | Out-Null; \$PROC.GetType().GetField('exitCode', 'NonPublic, Instance').GetValue(\$PROC); exit"
    local EXITCODE=$("$__WSL2_POWERSHELL_PATH" -NoProfile -ExecutionPolicy Bypass -Command "$CMDLET" | tr -d '[:space:]')
    return $EXITCODE
}


# cmd_exec {command} [working_dir]
#   Start a Windows process using cmd /c, from within WSL.
# Example: Shows an error in CMD window unless elevated=true.
#   cmd_exec "ipconfig"
# Inputs:
#   $__WSL2_CMD_PATH               - WSL path to cmd.exe
#   command             - CMD-executable command. Combine multiple commands in one line with '&&'.
#   working_dir         - (Optional): Windows path (uses backslashes) to execute command from.
# Outputs:
#   &1 (stdout)         - cmd.exe output is routed to the standard output channel.
#   $?                  - Numeric exit value of the Windows process. 0 indicates success.
#
function cmd_exec() {
    require_wsl2

    if [[ "$1" == "" ]]; then   return_error "No command specified."
    else                        local COMMAND="$1"
    fi
    if [[ "$2" == "" ]]; then   local WIN_DIR="$(wslpath 'C:\Windows\System32')"
    else                        local WIN_DIR="$(wslpath "$2")"
    fi

    wsl2_get_cmd_path  # ensures $__WSL2_CMD_PATH  is set

    local ORIGINAL_PWD="$PWD"
    cd "$WIN_DIR"
    "$__WSL2_CMD_PATH" /c $COMMAND | iconv -f UTF-16 -t UTF-8
    local EXITCODE=$?
    cd "$ORIGINAL_PWD"
    return $EXITCODE
}



#####################################################################################################

if ! $__COMMON_FUNCS_AVAILABLE; then
    echo "ERROR: This script requires \"common-functions.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-functions.sh\" before sourcing this script."
    return 1
fi

export __WSL2_FUNCS_AVAILABLE=0
