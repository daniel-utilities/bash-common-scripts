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
#   $?          - Numeric exit value; 0 indicates this system is WSL2.
#
function is_wsl2() {
    grep -q "WSL2" /proc/version && return 0 || return 1
    export _WSL2="y"
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
#   $_DISTRO    - Name of WSL2 distro.
#   $?          - Numeric exit value; 0 indicates success.
#
function wsl2_get_distro_name(){
    export _DISTRO="$(IFS='\'; x=($(wslpath -w /)); echo "${x[${#x[@]}-1]}")"
}


# wsl2_get_cmd_path
#   Get the wsl-equivalent path to cmd.exe.
# Outputs:
#   $_CMD       - WSL path to cmd.exe
#   $?          - Numeric exit value; 0 indicates success.
#
function wsl2_get_cmd_path(){
    export _CMD="cmd.exe"
    [[ ! $(type -P "cmd.exe") ]] && _CMD="$(wslpath 'C:\Windows\System32\cmd.exe')"
}


# wsl2_get_powershell_path
#   Get the wsl-equivalent path to powershell.exe.
# Outputs:
#   $_POWERSHELL - WSL path to powershell.exe
#   $?           - Numeric exit value; 0 indicates success.
#
function wsl2_get_powershell_path(){
    export _POWERSHELL="powershell.exe"
    [[ ! $(type -P "$_POWERSHELL") ]] && _POWERSHELL="$(wslpath 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe')"
}


# ps_exec {exepath} {args} [elevated=false/true [hidden=false/true]]
#   Start a Windows process in a new Powershell window, from within WSL.
# Example: Shows an error in CMD window unless elevated=true.
#   ps_exec "C:\\Windows\\System32\\cmd.exe" "/k net session && pause" elevated=true hidden=true
# Inputs:
#   $_POWERSHELL        - WSL path to powershell.exe (or cmd /c powershell.exe)
#   exepath             - Windows path (uses backslashes) to executable file
#   args                - String containing list of arguments to pass to executable
#   elevated=false/true - (Optional): Defaults to false. If true, EXE will be launched as Administrator.
#                           UAC will be invoked (if enabled on the system).
#   hidden=false/true   - (Optional): Defaults to false. If true, Powershell window will be hidden.
# Outputs:
#   $?                  - Numeric exit value of the Windows process. 0 indicates success.
#
function ps_exec() {
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

    local FIXEDARGS=${ARGS//\'/\'\'}
    local PARAMS="\"$EXE\" -ArgumentList '$FIXEDARGS' -Wait -PassThru"
    if [[ "$HIDE_WINDOW" == true ]]; then PARAMS="$PARAMS -WindowStyle Hidden"; fi
    if [[ "$ELEVATED" == true ]]; then PARAMS="$PARAMS -Verb RunAs"; fi
    local CMDLET="\$PROC=Start-Process $PARAMS; \$PROC.hasExited | Out-Null; \$PROC.GetType().GetField('exitCode', 'NonPublic, Instance').GetValue(\$PROC); exit"
    local EXITCODE=$("$_POWERSHELL" -NoProfile -ExecutionPolicy Bypass -Command "$CMDLET" | tr -d '[:space:]')
    return $EXITCODE
}


# cmd_exec {command} [working_dir]
#   Start a Windows process using cmd /c, from within WSL.
# Example: Shows an error in CMD window unless elevated=true.
#   cmd_exec "ipconfig"
# Inputs:
#   $_CMD               - WSL path to cmd.exe
#   command             - CMD-executable command. Combine multiple commands in one line with '&&'.
#   working_dir         - (Optional): Windows path (uses backslashes) to execute command from.
# Outputs:
#   &1 (stdout)         - cmd.exe output is routed to the standard output channel.
#   $?                  - Numeric exit value of the Windows process. 0 indicates success.
#
function cmd_exec() {
    if [[ "$1" == "" ]]; then   return_error "No command specified."
    else                        local COMMAND="$1"
    fi
    if [[ "$2" == "" ]]; then   local WIN_DIR="$(wslpath 'C:\Windows\System32')"
    else                        local WIN_DIR="$(wslpath "$2")"
    fi
    local ORIGINAL_PWD="$PWD"
    cd "$WIN_DIR"
    "$_CMD" /c $COMMAND
    local EXITCODE=$?
    cd "$ORIGINAL_PWD"
    return $EXITCODE
}



# wsl2_enable_service {service} [user]
#   Configures an init.d service to autostart with the rest of the WSL2 instance.
# Inputs:
#   service     - Name of init.d service to autostart.
#   user        - (Optional) User for which the service will autostart. Defaults to $USER if not specified.
#                   User must have sudo privilege.
# Outputs:
#   $?          - Numeric exit value; 0 indicates success.
#
function wsl2_enable_service(){
    require_non_root

    if [[ "$1" == "" ]]; then return_error "No service specified."
    else                      local SERVICE="$1"
    fi
    if [[ "$2" == "" ]]; then local _USER="$USER"
    else                      local _USER="$2"
    fi

    # Need to be able to run "sudo service SERVICE start/stop" passwordlessly
    local SUDOER_FILE="/etc/sudoers.d/$_USER"
    local SUDOER_ENTRY="$_USER ALL=(ALL) NOPASSWD: /usr/sbin/service $SERVICE *"
    ensure_line_visudo "$SUDOER_FILE" "$SUDOER_ENTRY" match=whole

    # Launch service in background using ~/.profile
    local _HOME="$( getent passwd "$_USER" | cut -d: -f6 )"
    local AUTORUN_FILE="$_HOME/.profile"
    local COMMAND="(nohup sudo service $SERVICE start </dev/null >/dev/null 2>&1 &)"
    ensure_line "$AUTORUN_FILE" "$COMMAND" match=whole
}


# wsl2_disable_service {service} [user]
#   Disables an init.d service from autostarting with the rest of the system.
# Inputs:
#   service     - Name of init.d service to disable autostart.
#   user        - (Optional) User for which the service was enabled with. Defaults to $USER if not specified.
# Outputs:
#   $?          - Numeric exit value; 0 indicates success.
#
function wsl2_disable_service(){
    require_non_root

    if [[ "$1" == "" ]]; then return_error "No service specified."
    else                      local SERVICE="$1"
    fi
    if [[ "$2" == "" ]]; then local _USER="$USER"
    else                      local _USER="$2"
    fi

    # Remove permissions from sudoer file
    local SUDOER_FILE="/etc/sudoers.d/$_USER"
    local SUDOER_ENTRY="$_USER ALL=(ALL) NOPASSWD: /usr/sbin/service $SERVICE *"
    delete_lines_matching "$SUDOER_FILE" "$SUDOER_ENTRY" match=partial sudo=true

    # Remove autostart entry in ~/.profile
    local _HOME="$( getent passwd "$_USER" | cut -d: -f6 )"
    local AUTORUN_FILE="$_HOME/.profile"
    local COMMAND="(nohup sudo service $SERVICE start </dev/null >/dev/null 2>&1 &)"
    delete_lines_matching "$AUTORUN_FILE" "$COMMAND" match=whole
}


#####################################################################################################

if [ -z "$_COMMON_FUNCS_AVAILABLE" ]; then
    echo "ERROR: This script requires \"common-functions.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-functions.sh\" before sourcing this script."
    exit 1
fi

require_wsl2

wsl2_get_distro_name
wsl2_get_cmd_path
wsl2_get_powershell_path
