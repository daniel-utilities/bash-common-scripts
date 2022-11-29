#####################################################################################################
#
#       BASH COMMON-SYSCONFIG FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-scripts/common-functions.sh
#       source ./bash-common-scripts/common-io.sh
#       source ./bash-common-scripts/common-sysconfig.sh
#
#####################################################################################################
#       REQUIRES COMMON-FUNCTIONS, COMMON-IO
#
if [ ! $__COMMON_FUNCS_AVAILABLE ]; then
    echo "ERROR: This script requires \"common-functions.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-functions.sh\" before sourcing this script."
    return 1
fi
if [ ! $__COMMON_IO_AVAILABLE ]; then
    echo "ERROR: This script requires \"common-io.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-io.sh\" before sourcing this script."
    return 1
fi
#####################################################################################################
#       FUNCTION REFERENCE:
#
# is_systemd
#   Checks if system has been initialized with systemd.
# require_systemd
#   Returns from the calling function with an error message if systemd is not available.
# sysd_config_user_service {service} {enable/disable} [boot=false/true [start/stop]]
#   Configures a SystemD (systemctl) service to start automatically when the current user logs in.
# sysd_config_system_service {service} {enable/disable} [start/stop]
#   Configures a SystemD (systemctl) service to start automatically when the system boots.
# sysv_config_user_service {service} {enable/disable} [start/stop]
#   Configures a SystemV (init.d) service to start automatically when the current user logs in.
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


# sysd_config_user_service {service} {enable/disable} [boot=false/true [start/stop]]
#   Configures a SystemD (systemctl) service to start automatically when the current user logs in.
#   Service is run as the current user, inheriting privilege.
# Inputs:
#   service         - Name of SystemD service. Must have a .service config file in "$HOME/.config/systemd/user/"
#   enable/disable  - Enable: sets service to autostart. Disable: removes service from autostarting.
#   boot=false/true - (Optional): if true, all of this user's services will start on system boot instead of when the user logs in.
#                       It will still run with the user's privilege level. It will continue running when the user logs out.
#   start/stop      - Start or stop the service in the background after applying the configuration.
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
    if [[ "$3" == "" ]]; then            local LINGER="__unset"
    elif [[ "$3" == "boot=false" ]]; then local LINGER="disable-linger"
    elif [[ "$3" == "boot=true" ]]; then local LINGER="enable-linger"
    else                                 return_error "Invalid boot parameter."
    fi
    if [[ "$4" == "" ]]; then            local STARTSTOP=""
    elif [[ "$4" == "start" ]]; then     local STARTSTOP="start"
    elif [[ "$4" == "stop" ]]; then      local STARTSTOP="stop"
    else                                 return_error "Invalid start parameter."
    fi

    SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE.service"
    [ ! -e "$SERVICE_FILE" ] && return_error "Required file $SERVICE_FILE does not exist."

    systemctl --user $MODE $SERVICE
    systemctl --user daemon-reload

    if [[ "$LINGER" == "__unset" ]]; then
        loginctl $LINGER $USER
    fi

    if [[ "$STARTSTOP" == "start" ]]; then
        sudo systemctl --user start $SERVICE
    elif [[ "$STARTSTOP" == "stop" ]]; then
        sudo systemctl --user stop $SERVICE
    fi
}


# sysd_config_system_service {service} {enable/disable} [start/stop]
#   Configures a SystemD (systemctl) service to start automatically when the system boots.
#   Service is run as root.
# Inputs:
#   service         - Name of SystemD service. Must have a .service config file in "/etc/systemd/system"
#   enable/disable  - Enable: sets service to autostart. Disable: removes service from autostarting.
#   start/stop      - Start or stop the service in the background after applying the configuration.
# Outputs:
#   $?              - Numeric exit value; 0 indicates success.
#
function sysd_config_system_service() {
    require_systemd

    if [[ "$1" == "" ]]; then            return_error "No service specified."
    else                                 local SERVICE="$1"
    fi
    if [[ "$2" == "" ]]; then            return_error "Need to specify enable/disable."
    elif [[ "$2" == "enable" ]]; then    local MODE="enable"
    elif [[ "$2" == "disable" ]]; then   local MODE="disable"
    else                                 return_error "Need to specify enable/disable."
    fi
    if [[ "$3" == "" ]]; then            local STARTSTOP=""
    elif [[ "$3" == "start" ]]; then     local STARTSTOP="start"
    elif [[ "$3" == "stop" ]]; then      local STARTSTOP="stop"
    else                                 return_error "Invalid start parameter."
    fi

    sudo systemctl $MODE $SERVICE
    sudo systemctl daemon-reload

    if [[ "$STARTSTOP" == "start" ]]; then
        sudo systemctl start $SERVICE
    elif [[ "$STARTSTOP" == "stop" ]]; then
        sudo systemctl stop $SERVICE
    fi
}


# sysv_config_user_service {service} {enable/disable} [start/stop]
#   Configures a SystemV (init.d) service to start automatically when the current user logs in.
#   Service is always run with root privilege, not with the user privilege.
#   Required for systems without systemctl (Such as WSL).
# Inputs:
#   service         - Name of SystemV service. Must have a launch script in /etc/init.d.
#   enable/disable  - Enable: sets service to autostart. Disable: removes service from autostarting.
#   start/stop      - Start or stop the service in the background after applying the configuration.
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
    if [[ "$3" == "" ]]; then            local STARTSTOP=""
    elif [[ "$3" == "start" ]]; then     local STARTSTOP="start"
    elif [[ "$3" == "stop" ]]; then      local STARTSTOP="stop"
    else                                 return_error "Invalid start parameter."
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

    if [[ "$STARTSTOP" == "start" ]]; then
        (nohup sudo service $SERVICE start </dev/null >/dev/null 2>&1 &)
    elif [[ "$STARTSTOP" == "stop" ]]; then
        (nohup sudo service $SERVICE stop </dev/null >/dev/null 2>&1 &)
    fi
}





#####################################################################################################

__COMMON_SYSCONFIG_AVAILABLE=0
