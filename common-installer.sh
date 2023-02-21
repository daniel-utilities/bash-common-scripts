#####################################################################################################
#
#       BASH COMMON-INSTALLER-LOADER FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-scripts/common-functions.sh
#       source ./bash-common-scripts/common-io.sh
#       source ./bash-common-scripts/common-tables.sh
#       source ./bash-common-scripts/common-ui.sh
#       source ./bash-common-scripts/common-installer-loader.sh
#
#####################################################################################################
#       REQUIRES COMMON-FUNCTIONS, COMMON-IO, COMMON-TABLES, COMMON-UI
#
# Import dependencies (if sourced by a [common-installer] script )
if [[ -v __COMMON_INSTALLER_LOADER__ || -v __COMMON_INSTALLER_MODULE__ ]]; then
    if [[ ! -d "$__COMMON_SCRIPTS_PATH__" ]]; then
        echo "Error: invalid directory __COMMON_SCRIPTS_PATH__=\"$__COMMON_SCRIPTS_PATH__\""
        echo ""
        exit 1
    fi
    sources=(   "$__COMMON_SCRIPTS_PATH__/common-functions.sh" 
                "$__COMMON_SCRIPTS_PATH__/common-io.sh"        
                "$__COMMON_SCRIPTS_PATH__/common-tables.sh"
                "$__COMMON_SCRIPTS_PATH__/common-ui.sh"         )    
    for i in "${sources[@]}"; do
        source "$i"
        if [[ "$?" -ne 0 ]]; then
            echo "Error loading required source: $i"
            echo "Please run:"
            echo "  git submodule update --init --recursive"
            echo ""
            exit 1
        fi
    done
fi

# Dependency checks
if [[ "$__COMMON_FUNCS_AVAILABLE__" != "$TRUE" ]]; then
    echo "ERROR: This script requires \"common-functions.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-functions.sh\" before sourcing this script."
    return 1
fi
if [[ "$__COMMON_IO_AVAILABLE__" != "$TRUE" ]]; then
    echo "ERROR: This script requires \"common-io.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-io.sh\" before sourcing this script."
    return 1
fi
if [[ "$__COMMON_TABLES_AVAILABLE__" != "$TRUE" ]]; then
    echo "ERROR: This script requires \"common-tables.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-tables.sh\" before sourcing this script."
    return 1
fi
if [[ "$__COMMON_UI_AVAILABLE__" != "$TRUE" ]]; then
    echo "ERROR: This script requires \"common-ui.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-ui.sh\" before sourcing this script."
    return 1
fi
#
#####################################################################################################
#       GLOBAL VARIABLES:
#
unset __COMMON_INSTALLER_AVAILABLE__  # Set to TRUE at the end of this file.
declare -a __COMMON_INSTALLER_LOADER_REQUIRED_KEYS__=(
    "__COMMON_INSTALLER_LOADER__"
    "__COMMON_SCRIPTS_PATH__"
)
declare -a __COMMON_INSTALLER_MODULE_REQUIRED_KEYS__=(
    "module"
    "title"
)
declare -a __COMMON_INSTALLER_MODULE_OPTIONAL_KEYS__=(
    "requires"
    "author"
    "email"
    "website"
    "hidden"
)
declare -A __DEFAULT_MENU_COMMANDS__=(
    ["help"]="print_var MENU_COMMANDS"
    ["pause"]="printf \"Type 'exit' to return to the installer.\n\"; /usr/bin/env bash"
    ["r"]=":"
    ["refresh"]=":"
    ["show-hidden"]="print_table module_table"
    ["x"]="exit 0"
    ["exit"]="exit 0"
)
declare -A __DEFAULT_LOADER_ARGS__=(
    ["unattended"]=""
    ["logfile"]=""
)

declare -i __MODULE_STATUS_INSTALLED__=0
declare -i __MODULE_STATUS_NOT_INSTALLED__=1
declare -i __MODULE_STATUS_UNKNOWN__=255
declare __MODULE_STATUS_INSTALLED_STRING__="Installed"
declare __MODULE_STATUS_NOT_INSTALLED_STRING__="Missing"
declare __MODULE_STATUS_UNKNOWN_STRING__=""
# __TERMINAL_WIDTH__              Width of the current terminal window, in characters. Set by begin_module
# __TEMP_DIR__                    Temporary directory dedicated for use by this module. Set by begin_module
#
#####################################################################################################
#       FUNCTION REFERENCE:
#
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



# find_installer_modules {tablevar} {"search_dir" or "path/to/module.sh"}
function find_installer_modules() {
    local -n _tab=$1
    local _searchpath="$2"
    clean_path _searchpath "$_searchpath"

    # Initialize the table
    local _properties="filepath status command ${__COMMON_INSTALLER_MODULE_REQUIRED_KEYS__[@]} ${__COMMON_INSTALLER_MODULE_OPTIONAL_KEYS__[@]}"
    if ! is_table _tab; then
        table_create _tab -colnames "$_properties"
    fi

    # Find .sh files in the searchpath
    local -a _files=()
    if [[ -d "$_searchpath" ]]; then
        printf "Searching for common-installer modules in %s/...\n" "$_searchpath"
        find_files_matching_path _files "$_searchpath/*.sh"
    elif [[ -e "$_searchpath" && "$_searchpath" == *.sh ]]; then
        _files+=("$_searchpath")
    fi

    # Check each .sh file for common-installer module identifiers
    for ((i = 0; i < ${#_files[@]}; i++)); do
        local _file="${_files[$i]}"
        local -A _required_keys=()
        local -A _optional_keys=()

        # Must have module identifier
        if ! has_line "$_file" '\[common-installer module\]' ; then continue; fi

        # Scan file for the required keys; skip file if it is missing any
        local _key="" _val=""
        for _key in "${__COMMON_INSTALLER_MODULE_REQUIRED_KEYS__[@]}"; do
            find_key_value_pair _val "$_file" "$_key"
            _required_keys["$_key"]="$_val"
        done
        if has_value _required_keys "" ; then
            printf "WARNING: Script identifies as an installer module but is missing some required keys: %s\n" "$_file"
            continue
        fi
        printf "Found installer module: %s\n" "${_required_keys[module]}"

        # Scan file for the optional keys
        local _key="" _val=""
        for _key in "${__COMMON_INSTALLER_MODULE_OPTIONAL_KEYS__[@]}"; do
            find_key_value_pair _val "$_file" "$_key"
            _optional_keys["$_key"]="$_val"
        done

        # Add a new row to the table
        table_set     _tab "${_required_keys[module]}" "filepath" "$_file"
        table_set_row _tab "${_required_keys[module]}" _required_keys
        table_set_row _tab "${_required_keys[module]}" _optional_keys
    done
}

# list_installer_modules_from_string {module_table} {"input string"} {module_list_array}
function list_installer_modules_from_string() {
    local -n _module_table=$1;  require_table $1    # Table of module specs found by find_installer_modules
    local _module_list_str="$2"                     # List of module names provided by user (string)
    local -n _module_list=$3;   require_type_a $3   # List of corrected, validated module names

    local -a _valid_names=()    # List of valid module names
    table_get_rownames _module_table _valid_names

    local -a _module_list_unvalidated=()    # List of module names provided by user (array)
    str_to_arr _module_list_unvalidated _module_list_str -e ' '

    local _module=""
    for _module in "${_module_list_unvalidated[@]}"; do
        trim _module
        if has_value _valid_names "${_module,,}"; then  # if valid module name
            if ! has_value _module_list "${_module,,}"; then # if unique
                _module_list+=("${_module,,}")
            fi
        else
            printf "WARNING: No module found for argument '%s'.\n" "$_module"
        fi
    done

    [[ "${#_module_list[@]}" -gt 0 ]];
}


# verify_installer_module {tablevar} {module} [logfile]
function verify_installer_module() {
    local -n _tab=$1
    local _module="$2"
    local _logfile="$3"

    local _script=""; table_get _tab "$_module" "filepath" _script

    run_and_log "/usr/bin/env bash \"$_script\" -verify-only" -logfile "$__LOGFILE__"
    if [[ $? -eq 0 ]]; then table_set _tab "$_module" "verified" "$TRUE";  return 0
    else                    table_set _tab "$_module" "verified" "$FALSE"; return 1
    fi
}



# load_installer_module {module_table} {module_name} [module_args_array]
function load_installer_module() {
    # Args
    local -n _module_table=$1
    local _module_name="$2"
    if [[ "$3" != "" ]]; then local -n _module_args=$3
    else                      local -A _module_args=(); fi

    # Convert args array to a string
    local _module_args_str="" _param _val
    for _param in "${!_module_args[@]}"; do
        _val="${_module_args[$_param]}"
        _module_args_str="$_module_args_str -$_param \"$_val\""
    done

    # Check if the "command" field is set.
    local _exitcode=0
    local _command=""; table_get _module_table "$_module_name" "command" _command
    if [[ "$_command" == "" ]]; then
        
        # Normal mode: the module is a script, which should be run with bash
        local _script_path=""; table_get _module_table "$_module_name" "filepath" _script_path
        _command="/usr/bin/env bash \"$_script_path\" $_module_args_str"
        eval "$_command ; _exitcode=\$?"
        printf "\nModule [%s] exited with code: %s\n\n" "$module" "$_exitcode" >> "$__LOGFILE__"
        printf "  Exit code: %s\n\n" "$_exitcode"
    
    else
        # Alt mode: the "command" field is nonempty, which means this module is a menu command
        eval "$_command ; _exitcode=\$?"
    fi

    return $_exitcode
}



# print_installer_modules
function print_installer_modules() {
    # Args
    local -A _fnargs=( [width]="" )
    fast_argparse _fnargs "modules" "width" "$@"

    local -n _modules="${_fnargs[modules]}"; require_table "${_fnargs[modules]}"
    local _width="${_fnargs[width]}"
    if [[ "$_width" == "" ]]; then get_term_width _width; fi

    # Defaults
    local _colsep=" | "
    local _max_col_width="40"
    local _rowname_header=" Module: "
    local -a _display_cols_reorder=("title"  "requires"  "status")
    local -A _display_cols_rename=(["title"]="Title:"  ["requires"]="Requires:"  ["status"]="Status:" )

    # Only display specific columns
    local -A _display_table
    table_get_cols _modules _display_cols_reorder _display_table
    table_rename_cols _display_table _display_cols_rename

    # Sort modules alphabetically
    local -a _unsorted_rownames _sorted_rownames
    table_get_rownames _modules _unsorted_rownames
    sort_array _unsorted_rownames _sorted_rownames
    table_reorder_rows _display_table _sorted_rownames

    # Hide modules which have hidden="true"
    local _rowname _hidden
    for _rowname in "${_sorted_rownames[@]}"; do
        table_get _modules "$_rowname" "hidden" _hidden
        if [[ "${_hidden,,}" == "true" ]]; then
            # echo "HIDDEN: $_rowname"
            table_remove_row _display_table "$_rowname"
        fi
    done

    # Print the display table
    print_table _display_table -rowname_header "$_rowname_header" -colsep "$_colsep" -max_col_width "$_max_col_width" -width "$_width" 

}



function print_install_header() {
    local -A _fnargs=()
    fast_argparse _fnargs "title" "width" "$@"

    local _width="${_fnargs[width]}"
    if [[ "$_width" == "" ]]; then
        get_term_width _width
    fi

    local _title="${_fnargs[title]}"
    local _titlebox=""
    get_title_box _titlebox "$_title" -width "$_width"
    printf "\n%s\n" "$_titlebox"

    if [[ "$____AUTOCONFIRM____" == "$TRUE" ]]; then
        printf "\nWARNING: Unattended Mode skips all user prompts. Modules will install immediately on loading.\n\n"
    fi
}



# *************************************************************************************************
# [common-installer loader]
# *************************************************************************************************

# begin_module_loader {"$@"}
function begin_module_loader() {
    if [[ ! -v __COMMON_INSTALLER_LOADER__ ]]; then
        return_error "This function can only be called from a [common-installer loader] script."
    fi

    # Require that the script was not run as a root user
    require_non_root

    # Parse Command-line Arguments
    local -A _args_tmp
    copy_array __ARGS__ _args_tmp
    copy_array __DEFAULT_LOADER_ARGS__ __ARGS__         # clear __ARGS__ and set to library-specified default values
    copy_array _args_tmp __ARGS__ -merge                # overwrite __ARGS__ with user-specified default values
    local _params_str
    printf -v _params_str "%s " "${!__ARGS__[@]}"
    fast_argparse __ARGS__ "" "$_params_str" "$@"       # overwrite __ARGS__ with command-line values

    # Set unattended mode
    if [[ "${__ARGS__[unattended]}" == "" ]]; then export __AUTOCONFIRM__="$FALSE"
    else                                       export __AUTOCONFIRM__="$TRUE";   fi

    # Set logfile
    if [[ "${__ARGS__[logfile]}" == "" ]]; then    export __LOGFILE__="./$__COMMON_INSTALLER_LOADER__.log"
    else                                       export __LOGFILE__="${__ARGS__[logfile]}";   fi

    # Add module definitions from module files
    local module_path
    local -A module_table=()
    for module_path in "${MODULE_PATHS[@]}"; do
        find_installer_modules module_table "$module_path"
    done
    printf "\n"

    # Add module definitions for menu commands
    local keyword
    local -A menu_commands_tmp
    copy_array MENU_COMMANDS menu_commands_tmp
    copy_array __DEFAULT_MENU_COMMANDS__ MENU_COMMANDS  # clear array and overwrite with default values
    copy_array menu_commands_tmp MENU_COMMANDS -merge   # overwrite again with user-specified values
    for keyword in "${!MENU_COMMANDS[@]}"; do
        local -A moduledef=( ["module"]="$keyword" ["command"]="${MENU_COMMANDS[$keyword]}" ["hidden"]="true" )
        table_set_row module_table "$keyword" moduledef
    done

    # Reset the logfile
    print_install_header "$MENU_TITLE" -width 80 > "$__LOGFILE__"

    # Display UI; loop until user exits the script, or until all modules are loaded (in auto mode only)
    while true; do
        # Print header title
        get_term_width terminal_width
        print_install_header "$MENU_TITLE" -width "$terminal_width"

        # Print description and menu (normal mode only)
        if [[ "$__AUTOCONFIRM__" == "$FALSE" ]]; then
            local wrapped_description
            wrap_string wrapped_description "$MENU_DESCRIPTION" "$terminal_width"
            printf "%s\n\n" "$wrapped_description"
            print_installer_modules module_table -width "$terminal_width"
        fi
        printf "\n"

        # Has a list of modules been provided with the -unattended argument?
        if [[ "$__AUTOCONFIRM__" == "$FALSE" ]]; then local module_list_str=""
        else                                          local module_list_str="${__ARGS__[unattended]}"
        fi

        # Collect and validate user input (normal mode) or validate the -unattended argument (unattended mode)
        local -a module_list=()
        while ! list_installer_modules_from_string  module_table "$module_list_str" module_list ; do
            __AUTOCONFIRM__="$FALSE"    # Fall back to normal mode if the -unattended argument was invalid
            local wrapped_prompt=""
            wrap_string wrapped_prompt "$MENU_PROMPT" "$terminal_width"
            printf "%s\n" "$wrapped_prompt"
            unset REPLY; read -r -p "  > " 
            module_list_str="${REPLY,,}"
            trim module_list_str
        done

        # Run each module sequentially
        printf "Loading the following modules:\n"
        print_var module_list -showname "false"
        printf "\n\n"
        local module exitcode
        for module in "${module_list[@]}"; do
            load_installer_module module_table "$module" __ARGS__   ; exitcode=$?

            # Update status based on the exitcode
            if [[ $exitcode -eq $__MODULE_STATUS_INSTALLED__ ]] ; then
                table_set module_table "$module" "status" "$__MODULE_STATUS_INSTALLED_STRING__"
            elif [[ $exitcode -eq $__MODULE_STATUS_NOT_INSTALLED__ ]]; then
                table_set module_table "$module" "status" "$__MODULE_STATUS_NOT_INSTALLED_STRING__"
            else
                table_set module_table "$module" "status" "$__MODULE_STATUS_UNKNOWN_STRING__"
            fi
        done

        # Exit script (unattended mode only)
        [[ "$__AUTOCONFIRM__" == "$TRUE" ]] && exit 0
    done
}



# *************************************************************************************************
# [common-installer module]
# *************************************************************************************************

# begin_module {"$@"}
function begin_module() {
    if [[ ! -v __COMMON_INSTALLER_MODULE__ ]]; then
        return_error "This function can only be called from a [common-installer module] script."
    fi

    # Parse command-line arguments into an associative array
    declare -gA __ARGS__=()
    while [[ "$#" -gt 0 ]]; do
        if [[ "$1" == -* ]]; then   # is a flagged parameter; grab the next argument as its value
            __ARGS__["${1##*-}"]="$2"
            shift 2
        else    # Not a flagged parameter, discard it.
            shift 1
        fi
    done

    # Create temporary directory
    declare -g  __TEMP_DIR__="$(mktemp -d -t "module_${module}_XXXX")"

    # Register callbacks
    push_exit_trap "" "Unloading module [$module]"
    push_exit_trap "if [[ -d '$__TEMP_DIR__' ]]; then echo '  Deleting temp directory $__TEMP_DIR__' ; rm -rf '$__TEMP_DIR__' ; fi"
    push_exit_trap "module_exit"

    # Set __TERMINAL_WIDTH__
    declare -g __TERMINAL_WIDTH__
    get_term_width __TERMINAL_WIDTH__
    if [[ "$__TERMINAL_WIDTH__" == "" || "$__TERMINAL_WIDTH__" -lt 10 ]]; then
        __TERMINAL_WIDTH__=80
    fi

    # Initialize module, then check installation status
    local status=$__MODULE_STATUS_UNKNOWN__
    run_and_log "module_init ; module_check && status=\$? || status=\$?" \
        -logfile "$__LOGFILE__" \
        -append "true"          \
        -set "eEo pipefail"
    if ! read -t 0.5; then : ; fi # delay so IO buffers are more likely to be clear before continuing

    # Exit early if module is installed already and running in -unattended mode
    if [[ $status -eq $__MODULE_STATUS_INSTALLED__ && "$__AUTOCONFIRM__" == "$TRUE" ]]; then
        printf "Skipping module [$module] because it is already installed." | tee -a -- "$__LOGFILE__"
        exit $status
    fi

    # Print header 
    local titlebox_width titlebox
    (( titlebox_width = "${#title}" + 4 ))
    get_title_box titlebox "$title" -width "$titlebox_width" -top '#' -side '#' -corner '#'
    printf "%s" "$titlebox"
    if [[ "$author" != "" ]]; then  printf "  Author:  %s\n" "$author";     fi
    if [[ "$email" != "" ]]; then   printf "  Email:   %s\n" "$email";      fi
    if [[ "$website" != "" ]]; then printf "  Website: %s\n" "$website";    fi
    printf "\n"

    # Print info text
    fold -sw $__TERMINAL_WIDTH__ <<< "$(module_info)"
    printf "\n"

    # Get user permission to continue
    if [[ $status -eq $__MODULE_STATUS_INSTALLED__ ]] ; then
        prompt="Module [$module] is already installed. Continue anyway?"
    else
        prompt="Continue with installation?"
    fi
    if ! confirmation_prompt "$prompt"; then exit $status ; fi

    # Run module
    function run_module() {
        printf "\nStarting module [%s] with args:\n" "$module"
        print_var __ARGS__ -showname "false" -wrapper ""
        printf "\n"
        module_run  # Actual module code is defined here
        printf "\nModule [%s] completed.\n" "$module"

        # Check install status
        printf "Checking installation status... "
        module_check && status=$? || status=$?
        if [[ $status -eq $__MODULE_STATUS_INSTALLED__ ]] ; then        printf "INSTALLED\n"
        elif [[ $status -eq $__MODULE_STATUS_NOT_INSTALLED__ ]]; then   printf "NOT INSTALLED\n"
        else                                                            printf "UNKNOWN\n"
        fi
    }
    run_and_log "run_module"    \
        -logfile "$__LOGFILE__" \
        -append "true"          \
        -set "eEo pipefail"
    if ! read -t 0.5; then : ; fi # delay so IO buffers are more likely to be clear before continuing

    # Exit script.
    exit $status
}




#####################################################################################################

__COMMON_INSTALLER_AVAILABLE__="$TRUE"
