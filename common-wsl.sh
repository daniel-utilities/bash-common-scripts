#####################################################################################################
#
#       BASH COMMON-WSL FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-scripts/common-functions.sh
#       source ./bash-common-scripts/common-wsl.sh
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
# is_wsl2
#   Checks if script is being run within WSL2.
# require_wsl2
#   Returns from the function which called this if not being run with WSL2.
# wsl2_get_distro_name
#   Determine the name of this WSL distro on the system. Each WSL installation has a unique name associated with it.
# wsl2_get_cmd_path
#   Get the wsl-equivalent path to cmd.exe.
# wsl2_get_powershell_path
#   Get the wsl-equivalent path to powershell.exe.
# wsl2_get_version
#   Get the installed version of WSL by running "wsl --version". At the moment, only works for Windows Store versions of WSL.
# ps_exec {exepath} {args} [-elevated false|true] [hidden false|true]
#   Start a Windows process in a new Powershell window, from within WSL.
# cmd_exec {command} [-dir working_dir]
#   Start a Windows process using cmd /c, from within WSL.
# fix_garbled_cmd_output
#   If output of cmd_exec is garbled, it may be formatted as UTF-16. This reformats as UTF-8.
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
function wsl2_get_distro_name() {
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
function wsl2_get_cmd_path() {
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
function wsl2_get_powershell_path() {
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
function wsl2_get_version() {
    require_wsl2

    if [ -z "$__WSL2_VERSION" ]; then
        export __WSL2_VERSION="$( cmd_exec "wsl --version" | grep "WSL version" | cut -d':' -f2  2>/dev/null || echo "0.0" )"
        __WSL2_VERSION="$( trim "$__WSL2_VERSION" )"
    fi
}

# ps_exec {exepath} {args} [-elevated false|true] [hidden false|true]
#   Start a Windows process in a new Powershell window, from within WSL.
# Example: Shows an error in CMD window unless elevated=true.
#   ps_exec "C:\\Windows\\System32\\cmd.exe" "/k net session && pause" -elevated true -hidden true
# Inputs:
#   $__WSL2_POWERSHELL_PATH  - WSL path to powershell.exe (or cmd /c powershell.exe)
#   exepath   - Windows path (uses backslashes) to executable file
#   args      - String containing list of arguments to pass to executable
#   elevated  - Defaults to false. If true, EXE will be launched as Administrator.
#                 UAC will be invoked (if enabled on the system).
#   hidden    - Defaults to false. If true, Powershell window will be hidden.
# Outputs:
#   $?        - Numeric exit value of the Windows process. 0 indicates success.
#
function ps_exec() {
    require_wsl2
    local -A args=( [elevated]=false [hidden]=false )
    fast_argparse args "exepath exeargs" "elevated hidden" "$@"

    wsl2_get_powershell_path  # ensures $__WSL2_POWERSHELL_PATH  is set

    local EXEARGS="${args[exeargs]}"
    local FIXEDARGS="${EXEARGS//\'/\'\'}"
    local PARAMS="\"${args[exepath]}\" -ArgumentList '$FIXEDARGS' -Wait -PassThru"
    if [[ "${args[hidden]}" == true ]];   then PARAMS="$PARAMS -WindowStyle Hidden"; fi
    if [[ "${args[elevated]}" == true ]]; then PARAMS="$PARAMS -Verb RunAs"; fi
    local CMDLET="\$PROC=Start-Process $PARAMS; \$PROC.hasExited | Out-Null; \$PROC.GetType().GetField('exitCode', 'NonPublic, Instance').GetValue(\$PROC); exit"
    local EXITCODE=$("$__WSL2_POWERSHELL_PATH" -NoProfile -ExecutionPolicy Bypass -Command "$CMDLET" | tr -d '[:space:]')
    return $EXITCODE
}


# cmd_exec {command} [-dir working_dir]
#   Start a Windows process using cmd /c, from within WSL.
# Example: Shows an error in CMD window unless elevated=true.
#   cmd_exec "ipconfig"
# Inputs:
#   $__WSL2_CMD_PATH    - WSL path to cmd.exe
#   command             - CMD-executable command. Combine multiple commands in one line with '&&'.
#   working_dir         - Windows path (uses backslashes) to execute command from.
# Outputs:
#   &1 (stdout)         - cmd.exe output is routed to the standard output channel.
#   $?                  - Numeric exit value of the Windows process. 0 indicates success.
#
function cmd_exec() {
    require_wsl2
    local -A args
    fast_argparse args "command" "dir" "$@"
    wsl2_get_cmd_path  # ensures $__WSL2_CMD_PATH  is set
    local original_dir="$PWD"
    if [[ "${args[dir]}" != "" ]]; then cd "$(wslpath -u ${args[dir]})"; fi

    "$__WSL2_CMD_PATH" /c "${args[command]}"
    local EXITCODE=$?

    cd "$original_dir"
    return $EXITCODE
}


# fix_garbled_cmd_output
#   If output of cmd_exec is garbled, it may be formatted as UTF-16. This reformats as UTF-8.
# Inputs:
#   &0 (stdin)  - Reads from stdin
# Outputs:
#   &1 (stdout) - Writes to stdout
#
function fix_garbled_cmd_output() {
    iconv -f UTF-16 -t UTF-8
}



#####################################################################################################

__COMMON_WSL_AVAILABLE=0
