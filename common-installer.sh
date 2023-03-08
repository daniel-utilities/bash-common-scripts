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
if [[ -v __LOADER_BASE_NAME__ ]]; then
    if [[ ! -d "$COMMON_SCRIPTS_PATH" ]]; then
        echo "Error: invalid directory COMMON_SCRIPTS_PATH=\"$COMMON_SCRIPTS_PATH\""
        echo ""
        exit 1
    fi
    sources=(   "$COMMON_SCRIPTS_PATH/common-functions.sh" 
                "$COMMON_SCRIPTS_PATH/common-io.sh"        
                "$COMMON_SCRIPTS_PATH/common-tables.sh"
                "$COMMON_SCRIPTS_PATH/common-ui.sh"         )    
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
    unset sources
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
declare    __COMMON_TEMPLATE_VERSION__="1.0"
declare -A __DEFAULT_ARGS__=(
    ["install"]=""
    ["force"]="false"
    ["allowroot"]="false"
    ["logfile"]="./${__LOADER_BASE_NAME__:-common-installer}.log"
)
declare    __DEFAULT_ARGS_HELP_TEXT__=\
"--help                    Shows this help text.
--install \"module list\"   Space-separated list of module names to install.
                            Installs these modules (and their dependencies) in
                            unattended mode, suppressing all user input prompts.
                            By default, the loader skips modules which are
                            already installed (unless using --force true)
                            If left blank, displays the interactive menu.
                            Default: \"${__DEFAULT_ARGS__[install]}\"
--force false|true        Forces modules to install even if they are already installed.
                            Default: \"${__DEFAULT_ARGS__[force]}\"
--allowroot false|true    Allows the installer to run with superuser privilege.
                            If false, the installer will refuse to run with
                            superuser privilege. Modules which use 'sudo' will ask
                            for a sudo password if needed.
                            Default: \"${__DEFAULT_ARGS__[allowroot]}\"
--logfile \"/path/to/log\"  Specify a different log file. Log will be overwritten.
                            Default: \"${__DEFAULT_ARGS__[logfile]}\""
declare -a __LOADER_REQUIRED_PROPS__=(
    "__LOADER_TEMPLATE_VERSION__"
    "__LOADER_BASE_NAME__"
    "COMMON_SCRIPTS_PATH"
    "MODULE_PATHS"
    "MENU_TITLE"
    "MENU_DESCRIPTION"
    "MENU_PROMPT"
)
declare -a __LOADER_OPTIONAL_PROPS__=(
    "CUSTOM_MENU_COMMANDS"
    "CUSTOM_ARGS"
    "CUSTOM_ARGS_HELP_TEXT"
)
declare    __MODULE_HEADER_STRING__='\[common-installer module\]'
declare -a __MODULE_REQUIRED_PROPS__=(
    "MODULE"
    "TITLE"
)
declare -a __MODULE_OPTIONAL_PROPS__=(
    "REQUIRES"
    "AUTHOR"
    "EMAIL"
    "WEBSITE"
    "HIDDEN"
)
declare -a __MODULE_REQUIRED_FUNCS__=(
    "on_import"
    "on_status_check"
    "on_print"
    "on_install"
    "on_exit"
)
declare -a __MODULE_TABLE_COLUMNS__=(
    "FILEPATH"
    "STATUS"
    "COMMAND"
    "${__MODULE_REQUIRED_PROPS__[@]}"
    "${__MODULE_OPTIONAL_PROPS__[@]}"
)
declare -A __DEFAULT_MENU_COMMANDS__=(
    ["help"]="print_var __MENU_COMMANDS__"
    ["pause"]="printf \"Type 'exit' to return to the installer.\n\"; /usr/bin/env bash"
    ["showhidden"]="print_table module_table"
    ["x"]="exit 0"
    ["exit"]="exit 0"
)

declare -i __MODULE_STATUS_INSTALLED__=0
declare -i __MODULE_STATUS_NOT_INSTALLED__=110
declare -i __MODULE_STATUS_UNKNOWN__=111
declare -a __MODULE_STATUS_STRINGS__=(
     [$__MODULE_STATUS_INSTALLED__]="Installed"
 [$__MODULE_STATUS_NOT_INSTALLED__]="Not Installed"
       [$__MODULE_STATUS_UNKNOWN__]=""
)
declare -i __LOADER_ERROR_GENERIC__=80
declare -i __LOADER_ERROR_NOT_A_SUBSHELL__=81
declare -i __LOADER_ERROR_ILLEGAL_CALL__=82
declare -i __LOADER_ERROR_TEMP_DIR__=83
declare -i __LOADER_ERROR_INVALID_REQUIRES__=84
declare -i __LOADER_ERROR_INVALID_INPUT__=85
declare -i __LOADER_ERROR_VERSION__=86
declare -a __LOADER_ERROR_STRINGS__=(
         [$__LOADER_ERROR_GENERIC__]="Error: Loader %s failed (unknown reason)."
  [$__LOADER_ERROR_NOT_A_SUBSHELL__]="Error: Loader %s attempted to load a module without a subshell."
    [$__LOADER_ERROR_ILLEGAL_CALL__]="Error: Loader %s attempted to call a function from an uninitialized module."
        [$__LOADER_ERROR_TEMP_DIR__]="Error: Loader %s failed to create temporary directory."
[$__LOADER_ERROR_INVALID_REQUIRES__]="Error: Loader %s failed to load the module."
   [$__LOADER_ERROR_INVALID_INPUT__]="Error: Loader %s failed to load the module."
         [$__LOADER_ERROR_VERSION__]="Error: Loader %s is not using required template version $__COMMON_TEMPLATE_VERSION__."
)
declare -i __MODULE_ERROR_GENERIC__=90
declare -i __MODULE_ERROR_SOURCE__=91
declare -i __MODULE_ERROR_MISSING_PROPS__=92
declare -i __MODULE_ERROR_MISSING_FUNCS__=93
declare -i __MODULE_ERROR_INIT__=94
declare -i __MODULE_ERROR_STATUS__=95
declare -i __MODULE_ERROR_INFO__=96
declare -i __MODULE_ERROR_INSTALL__=97
declare -i __MODULE_ERROR_EXIT__=98
declare -i __MODULE_ERROR_USER__=99
declare -i __MODULE_ERROR_VERSION__=100
declare -a __MODULE_ERROR_STRINGS__=(
       [$__MODULE_ERROR_GENERIC__]="Error: Module %s failed to load (unknown reason)."
        [$__MODULE_ERROR_SOURCE__]="Error: Failed to source module %s; missing file or invalid syntax."
 [$__MODULE_ERROR_MISSING_PROPS__]="Error: Module %s is missing a required property."
 [$__MODULE_ERROR_MISSING_FUNCS__]="Error: Module %s is missing a required function."
          [$__MODULE_ERROR_INIT__]="Error: Module %s failed unexpectedly during on_import()."
        [$__MODULE_ERROR_STATUS__]="Error: Module %s failed unexpectedly during on_status_check()."
          [$__MODULE_ERROR_INFO__]="Error: Module %s failed unexpectedly during on_print()."
       [$__MODULE_ERROR_INSTALL__]="Error: Module %s failed unexpectedly during on_install()."
          [$__MODULE_ERROR_EXIT__]="Error: Module %s failed unexpectedly during on_exit()."
          [$__MODULE_ERROR_USER__]="Module %s was cancelled by user."
       [$__MODULE_ERROR_VERSION__]="Error: Module %s is not using required template version $__COMMON_TEMPLATE_VERSION__."
)
declare -i __MODULE_STATE_NOT_INITIALIZED__=0
declare -i __MODULE_STATE_INITIALIZED__=1
declare -a __MODULE_STATE_STRINGS__=(
[$__MODULE_STATE_NOT_INITIALIZED__]="Not Initialized"
    [$__MODULE_STATE_INITIALIZED__]="Initialized"
)
# __TERMINAL_WIDTH__              Width of the current terminal window, in characters. Set by loader_start.
# __TEMP_DIR__                    Temporary directory dedicated for use by this module. Set by loader_start.
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



###############################################################################
## MODULE FUNCTIONS
##   - Should only be run from within a subshell.
##   - Always call module_import before other module functions.
##   - Never call module callbacks directly; only use module_ - prefixed calls!
###############################################################################

# module_import {"module/script/path"}
function module_import() {
    # Global variables, defined for lifetime of module.
    declare -g __MODULE_DEFINITION_PATH__="$1"          # Contains path to module script
    declare -g __STATE__=$__MODULE_STATE_NOT_INITIALIZED__ # Contains the initialization state of the module
    declare -g __SECTION__=$__MODULE_ERROR_GENERIC__    # Contains an error code corresponding to what section of module code is running
    declare -g __STATUS__=$__MODULE_STATUS_UNKNOWN__    # Contains module installation status code
    declare -g __TERMINAL_WIDTH__                       # Contains the width in characters of the terminal window
    declare -g __TEMP_DIR__                             # Contains a temporary 'scratch' directory owned by the loader

    # On ERR, print error message and exit
    __SECTION__=$__MODULE_ERROR_GENERIC__
            trap - EXIT; __EXIT_TRAPS__=()
            set -E; trap 'loader_print_error "$__SECTION__"; exit $__SECTION__' ERR
    
    # Check environment is set up correctly
    __SECTION__=$__LOADER_ERROR_NOT_A_SUBSHELL__
            [[ "$BASH_SUBSHELL" -gt 0 ]];           # Must be running within subshell
    __SECTION__=$__MODULE_ERROR_GENERIC__
            [[ "$__TERMINAL_WIDTH__" != "" ]] || get_term_width __TERMINAL_WIDTH__
            [[ -d "$__TEMP_DIR__" ]] || __TEMP_DIR__="/tmp"

    # Source and validate the module definition script
    __SECTION__=$__MODULE_ERROR_SOURCE__
            source "$__MODULE_DEFINITION_PATH__"
    __SECTION__=$__MODULE_ERROR_VERSION__
            [[ "$__MODULE_TEMPLATE_VERSION__" == "$__COMMON_TEMPLATE_VERSION__" ]];
    __SECTION__=$__MODULE_ERROR_MISSING_PROPS__
            local _varname
            for _varname in "${__MODULE_REQUIRED_PROPS__[@]}"; do
                local -n _val=$_varname
                [[ "$_val" != "" ]];  # Required property can't be empty/undefined
            done
    __SECTION__=$__MODULE_ERROR_MISSING_FUNCS__
            local _funcname
            for _funcname in "${__MODULE_REQUIRED_FUNCS__[@]}"; do
                declare -F "$_funcname" &> /dev/null ; # Required function must be defined
            done

    # Initialize module
    __SECTION__=$__MODULE_ERROR_INIT__
            on_import &> /dev/null < /dev/null
    
    # Return to subshell
    __SECTION__=$__MODULE_ERROR_GENERIC__
            __STATE__=$__MODULE_STATE_INITIALIZED__
            return 0
}



# module_set_status
function module_set_status() {
    # Check module environment is set up correctly
    __SECTION__=$__LOADER_ERROR_NOT_A_SUBSHELL__
            [[ "$BASH_SUBSHELL" -gt 0 ]];
    __SECTION__=$__LOADER_ERROR_ILLEGAL_CALL__
            [[ "$__STATE__" == "$__MODULE_STATE_INITIALIZED__" ]];

    # Set installation status (__STATUS__ global variable)
    __SECTION__=$__MODULE_ERROR_STATUS__
            on_status_check &> /dev/null && __STATUS__=$? || __STATUS__=$?  # Ignore nonzero exit codes and set __STATUS__.
            has_key __MODULE_STATUS_STRINGS__ $__STATUS__ ;

    # Return to subshell
    __SECTION__=$__MODULE_ERROR_GENERIC__
            return 0

}



# module_install
function module_install() {
    # Check module environment is set up correctly
    __SECTION__=$__LOADER_ERROR_NOT_A_SUBSHELL__
            [[ "$BASH_SUBSHELL" -gt 0 ]];
    __SECTION__=$__LOADER_ERROR_ILLEGAL_CALL__
            [[ "$__STATE__" == "$__MODULE_STATE_INITIALIZED__" ]];

    # Check installation status
    __SECTION__=$__MODULE_ERROR_STATUS__
            module_set_status

    # Skip install if module is installed already and running in --install (unattended) mode.
    __SECTION__=$__MODULE_ERROR_GENERIC__
            if [[ $__STATUS__ -eq $__MODULE_STATUS_INSTALLED__ && "$__AUTOCONFIRM__" == "$TRUE" && "$__FORCE__" == "$FALSE" ]]; then
                printf "Skipping module [$MODULE] because it is already installed."
                return $__STATUS__
            fi

    # Print header 
    __SECTION__=$__MODULE_ERROR_GENERIC__
            local titlebox_width titlebox
            (( titlebox_width = "${#TITLE}" + 4 ))
            get_title_box titlebox "$TITLE" -width "$titlebox_width" -top '#' -side '#' -corner '#'
            printf "%s" "$titlebox"
            if [[ "$AUTHOR" != "" ]]; then  printf "  Author:  %s\n" "$AUTHOR";     fi
            if [[ "$EMAIL" != "" ]]; then   printf "  Email:   %s\n" "$EMAIL";      fi
            if [[ "$WEBSITE" != "" ]]; then printf "  Website: %s\n" "$WEBSITE";    fi
            printf "\n"

    # Print info text
    __SECTION__=$__MODULE_ERROR_INFO__;
            fold -sw $__TERMINAL_WIDTH__ <<< "$(on_print)"
            printf "\n"

    # Get user permission to continue
    __SECTION__=$__MODULE_ERROR_USER__
            if [[ $__STATUS__ -eq $__MODULE_STATUS_INSTALLED__ ]] ; then
                local prompt="Module [$MODULE] is already installed. Continue anyway?"
            else
                local prompt="Continue with installation?"
            fi
            if [[ "$__AUTOCONFIRM__" == "$FALSE" ]]; then
                confirmation_prompt "$prompt" || return $__STATUS__  # Skips this prompt if $__AUTOCONFIRM__==$TRUE
            else
                read -t 10 -p "Continuing in 10 seconds. Press ENTER to continue, or CTRL+C to exit..." || true
            fi


    # On EXIT, run callback: on_exit
    __SECTION__=$__MODULE_ERROR_GENERIC__
            push_exit_trap "trap - ERR ; set +E ; __SECTION__=$__MODULE_ERROR_EXIT__ ; on_exit" "Cleaning up [$MODULE]..."

    # Install module
    __SECTION__=$__MODULE_ERROR_INSTALL__
            printf "\nStarting module [%s] with args:\n" "$MODULE"
            print_var __ARGS__ -showname "false" -wrapper ""
            printf "\n"
            on_install  # Actual module code is defined here
            printf "\nModule [%s] completed.\n" "$MODULE"
    
    # Check installation status again
    __SECTION__=$__MODULE_ERROR_STATUS__
            module_set_status

    # Return to subshell
    __SECTION__=$__MODULE_ERROR_GENERIC__
            return 0
}

###############################################################################



###############################################################################
## LOADER ROUTINES
##   A loader routine creates a subshell to manage the lifecycle of a module
##   and collect/log its output.
##   All loader routines must guarantee:
##     - module_ function calls are only performed within a subshell
##     - module_import is called before any other module_ functions
###############################################################################

# loader_get_module_definition_from_file {module_table} {"module_filename"}
function loader_get_module_definition_from_file() {
    local -n _module_table=$1
    local __MODULE_DEFINITION_PATH__="$2"

    # Initialize module definition table
    if ! is_table _module_table ; then
        table_create _module_table -colnames "${__MODULE_TABLE_COLUMNS__[*]}"
    fi

    # Must have module identifier
    clean_path __MODULE_DEFINITION_PATH__ "$__MODULE_DEFINITION_PATH__"
    if ! has_line "$__MODULE_DEFINITION_PATH__" "$__MODULE_HEADER_STRING__" ; then return 1; fi

    # Source and init the module to retrieve its properties and installation status
    local _status="$__MODULE_STATUS_UNKNOWN__"
    local _module_props_str  # declaration must be on a separate line to preserve the subshell exit code $?
    _module_props_str="$(
        module_import "$__MODULE_DEFINITION_PATH__"   
        module_set_status  # Sets the __STATUS__ variable
        # Print all the [required] and [optional] properties (which ends up in _module_props_str)
        for _varname in "${__MODULE_REQUIRED_PROPS__[@]}" "${__MODULE_OPTIONAL_PROPS__[@]}"; do
            declare -n _val=$_varname
            printf "%s\t%s\n" "$_varname" "$_val"
        done
        exit $__STATUS__
    )"; _status=$?  # Error messages still print normally; only module properties end up in _module_props_str
    #print_var _status
    #print_var _module_props_str

    # Check if an error has occurred while loading the module
    if ! has_key __MODULE_STATUS_STRINGS__ "$_status" ; then
        # loader_print_error "$_status" # error message is printed by the subshell
        return 1
    fi

    # Add a new row to the table containing all the module properties
    local -A _module_props_arr=()
    str_to_arr _module_props_arr _module_props_str -e $'\n' -p $'\t'
    table_set     _module_table "${_module_props_arr[MODULE]}" "FILEPATH" "$__MODULE_DEFINITION_PATH__"
    table_set     _module_table "${_module_props_arr[MODULE]}" "STATUS" "$_status"
    table_set_row _module_table "${_module_props_arr[MODULE]}" _module_props_arr
    printf "Imported module: [%s]\n" "${_module_props_arr[MODULE]}"
    return 0
}



# loader_install_module {module_table} {module_name}
function loader_install_module() {
    local -n _module_table=$1
    local _module_name="$2"
    local _exitcode=0

    # If the module's "COMMAND" field is set, this is a menu command, not a script.
    local _command=""; table_get _module_table "$_module_name" "COMMAND" _command
    if [[ "$_command" != "" ]]; then
        eval "$_command; _exitcode=\$?"
        return $_exitcode
    fi

    # Otherwise, the module should be imported as a script (inside a subshell) and then installed.
    local _script_path=""; table_get _module_table "$_module_name" "FILEPATH" _script_path
    (
        module_import "$_script_path" # Sources and validates the module
        module_install  # Install and set __STATUS__
        exit $__STATUS__
    )> >(tee -a -- "$__LOGFILE__") 2>&1; _exitcode=$?
    table_set module_table "$MODULE" "STATUS" "$_exitcode"
    return $_exitcode
}

###############################################################################



###############################################################################
## UTILITY FUNCTIONS
##   Various utilities required by the module loader.
###############################################################################

# loader_print_error {errorcode}
function loader_print_error() {
    local __errorcode="$1"
    local __errorstring __infovar

    if [[ "$__errorcode" -eq 0 ]]; then
        return 0

    elif has_key __MODULE_STATUS_STRINGS__ "$__errorcode" ; then
        return 0

    elif has_key __MODULE_ERROR_STRINGS__ "$__errorcode" ; then
        __errorstring="${__MODULE_ERROR_STRINGS__[$__errorcode]}"

        if [[ "$__STATE__" == "$__MODULE_STATE_INITIALIZED__" ]]; then
            __infovar="[$MODULE]"
        elif [[ "$__MODULE_DEFINITION_PATH__" != "" ]]; then
            get_basename __infovar "$__MODULE_DEFINITION_PATH__" 
            __infovar="in file \"$__infovar\""
        else
            __infovar="UNKNOWN"
        fi
        
    elif has_key __LOADER_ERROR_STRINGS__ "$__errorcode" ; then
        __errorstring="${__LOADER_ERROR_STRINGS__[$__errorcode]}"
        __infovar="$__LOADER_BASE_NAME__"

    else
        __errorstring="Encountered unknown error: %s"
        __infovar="$__errorcode"
    fi

    printf "${__errorstring}\n" "$__infovar" >&2
}



# loader_print_modules_from_table {module_table} [-width "numchars"]
function loader_print_modules_from_table() {
    # Args
    local -A _fnargs=( [width]="" )
    fast_argparse _fnargs "modules" "width" "$@"

    local -n _modules="${_fnargs[modules]}"; require_table "${_fnargs[modules]}"
    local _width="${_fnargs[width]}"
    if [[ "$_width" == "" ]]; then get_term_width _width; fi

    # Default values
    local _colsep=" | "
    local _max_col_width="40"
    local _rowname_header=" Module: "
    local -a _display_cols_reorder=("TITLE"  "REQUIRES"  "STATUS")
    local -A _display_cols_rename=(["TITLE"]="Title:"  ["REQUIRES"]="Requires:"  ["STATUS"]="Status:" )

    # Only display specific columns
    local -A _display_table
    table_get_cols _modules _display_cols_reorder _display_table
    table_rename_cols _display_table _display_cols_rename

    # Sort modules alphabetically
    local -a _unsorted_rownames _sorted_rownames
    table_get_rownames _modules _unsorted_rownames
    sort_array _unsorted_rownames _sorted_rownames
    table_reorder_rows _display_table _sorted_rownames

    # Hide modules which have HIDDEN="true"
    local _rowname _hidden
    for _rowname in "${_sorted_rownames[@]}"; do
        table_get _modules "$_rowname" "HIDDEN" _hidden
        if [[ "${_hidden,,}" == "true" ]]; then
            # echo "HIDDEN: $_rowname"
            table_remove_row _display_table "$_rowname"
        fi
    done

    # Make the status code human-readable
    _sorted_rownames=(); table_get_rownames _display_table _sorted_rownames
    local _rowname _status
    for _rowname in "${_sorted_rownames[@]}"; do
        table_get _display_table "$_rowname" "Status:" _status
        if has_key __MODULE_STATUS_STRINGS__ "$_status"; then
            table_set _display_table "$_rowname" "Status:" "${__MODULE_STATUS_STRINGS__[$_status]}"
        else
            table_set _display_table "$_rowname" "Status:" "Errorcode: $_status"
        fi
    done

    # Print the display table
    print_table _display_table              \
        -rowname_header "$_rowname_header"  \
        -colsep "$_colsep"                  \
        -max_col_width "$_max_col_width"    \
        -width "$_width" 

}



# loader_print_header {"title"} [-width "numchars"]
function loader_print_header() {
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

    if [[ "$__AUTOCONFIRM__" == "$TRUE" ]]; then
        printf "\nWARNING: Unattended Mode skips all user prompts. Modules will install immediately on loading.\n\n"
    fi
}



# loader_print_help_text
function loader_print_help_text() {
    printf "USAGE:  %s [--opt1 \"val1\"] [--opt2 \"val2\"] ...\n\n" "${__LOADER_BASE_NAME__}.sh"
    printf "OPTIONS:\n"
    if [[ "$CUSTOM_ARGS_HELP_TEXT" == "" ]]; then
        printf "%s\n\n" "$__DEFAULT_ARGS_HELP_TEXT__"
    else
        printf "%s\n\n" "$CUSTOM_ARGS_HELP_TEXT"
    fi
}



# loader_get_module_definition_from_name {module_table} {"module_name"}
function loader_get_module_definition_from_name() {
    local -n __module_table=$1
    local __module_name="$2"
    local __module_filepath; table_get __module_table "$__module_name" "FILEPATH" __module_filepath
    loader_get_module_definition_from_file __module_table "$__module_filepath"
}



# loader_get_module_definition_from_path {module_table} {"search_dir" or "path/to/module.sh"}
function loader_get_module_definition_from_path() {
    local -n __module_table=$1
    local __searchpath="$2"
    clean_path __searchpath "$__searchpath"

    # Find all .sh files in the searchpath
    local -a __files=()
    if [[ -d "$__searchpath" ]]; then
        printf "Searching for common-installer modules in %s/...\n" "$__searchpath"
        find_files_matching_path __files "$__searchpath/*.sh"
    elif [[ -e "$__searchpath" && "$__searchpath" == *.sh ]]; then
        __files+=("$__searchpath")
    fi

    # Attempt to import each .sh file
    for ((i = 0; i < ${#__files[@]}; i++)); do
        loader_get_module_definition_from_file __module_table "${__files[$i]}"
    done
}



# loader_get_install_order_from_string {module_table} {"input string"} {module_list_array}
function loader_get_install_order_from_string() {
    local -n _module_table=$1;  require_table $1    # Table of module specs found by loader_get_module_definition_from_path
    local _install_list_str="$2"                     # List of module names provided by user (string)
    local -n _install_list=$3;  # Return list of modules to install, with dependencies
    _install_list=()

    local -a _module_names=()
    table_get_rownames _module_table _module_names

    local -a _install_list_unverified=()
    str_to_arr _install_list_unverified _install_list_str -e " "

    # Init _install_priority array with validated module names, initially set to priority 0 (bottom of dependency tree).
    local -A _install_priority=()
    local _module_name
    for _module_name in "${_install_list_unverified[@]}"; do
        trim _module_name
        if [[ "$_module_name" == "" ]]; then continue
        elif has_value _module_names "$_module_name"; then
            _install_priority["$_module_name"]=0
        else
            printf "Error: Invalid module name: [%s]\n" "$_module_name"
            return $__LOADER_ERROR_INVALID_INPUT__
        fi
    done

    # Starting with the validated module names in _install_priority, walk the dependency tree
    # (the "REQUIRES" column of module_table), adding each child module to the array.
    # Module names are keys of _install_priority, and tree depth are the values.
    # Algorithm (non-recursive):
    #   loop while _loop_again == TRUE
          # _loop_again = FALSE
          # loop through _install_priority. For each _parent:
              # loop through its _children. For each (valid) _child:
                  # If _child_priority > _parent_priority, ignore it
                  # Else, (_child is not in the list yet or _child_priority <= _parent_priority)
                  #   set _child_priority = _parent_priority+1.
                  #   set _loop_again flag
    local _loop_again=$TRUE
    local _parent _child _parent_priority _child_priority _child_status
    while [[ "$_loop_again" == "$TRUE" ]]; do
        _loop_again=$FALSE

        # Loop through the keys of _install_priority (names of parent modules).
        for _parent in "${!_install_priority[@]}"; do

            # Get _parent priority
            _parent_priority="${_install_priority[$_parent]}"
            # echo "PARENT: $_parent,  PRIORITY: $_parent_priority"

            # Get children (listed in the "REQUIRES" column in the _module_table)
            local _children_str=""; local -a _children=()
            table_get _module_table "$_parent" "REQUIRES" _children_str
            str_to_arr _children _children_str -e " "

            # Loop through all _children
            for _child in "${_children[@]}"; do

                # Check that a definition exists for _child
                if ! has_value _module_names "$_child"; then
                    printf "Error: Module [%s] requires [%s], but no module with that name is available.\n" "$_parent" "$_child"
                    return $__LOADER_ERROR_INVALID_REQUIRES__
                fi


                # Get _child priority (or set to 0 if not in the list yet)
                _child_priority="${_install_priority[$_child]}"
                if [[ "$_child_priority" == "" ]]; then 
                    _child_priority=0
                    # If _child is already installed, don't add it to the list.
                    table_get _module_table "$_child" "STATUS" _child_status
                    if [[ "$_child_status" == "$__MODULE_STATUS_INSTALLED__" && "$__FORCE__" == "$FALSE" ]]; then continue; fi
                fi

                # If _child has higher priority than _parent, skip to next _child
                if [[ "$_child_priority" -gt "$_parent_priority" ]]; then
                    #echo "    CHILD: $_child,  PRIORITY: $_child_priority"
                    continue
                
                # Otherwise, elevate the _child's priority to one higher than the _parent, and set _loop_again flag
                else
                    (( _child_priority="$_parent_priority"+1 ))
                    #echo "    ELEVATING CHILD: $_child,  NEW PRIORITY: $_child_priority"
                    _install_priority["$_child"]="$_child_priority"
                    _loop_again=$TRUE
                fi
            done
        done
    done
    #print_var _install_priority

    # Generate the final install list. Higher priorities should be installed first.
    local _highest_priority _highest_module _module_name _module_priority
    while [[ "${#_install_priority[@]}" -gt 0 ]]; do
        _highest_priority=-1
        _highest_module=""
        for _module_name in "${!_install_priority[@]}"; do
            _module_priority="${_install_priority[$_module_name]}"
            if [[ "$_module_priority" -gt "$_highest_priority" ]]; then
                _highest_priority="$_module_priority"
                _highest_module="$_module_name"
            fi
        done
        _install_list+=("$_highest_module")
        unset "_install_priority[$_highest_module]"
    done
    #print_var _install_list

    [[ "${#_install_list[@]}" -gt 0 ]];
}

###############################################################################



###############################################################################
## LOADER START
##   This function is called at the end of the loader definition template.
##     - Parses command-line arguments
##     - Sets required global variables
##     - Finds and imports module definitions
##     - Displays the user interface
###############################################################################

# loader_start {"$@"}
function loader_start() {

    #######################################################
    ##  VALIDATE LOADER TEMPLATE
    #######################################################

    if [[ "$__LOADER_TEMPLATE_VERSION__" != "$__COMMON_TEMPLATE_VERSION__" ]]; then
        loader_print_error $__LOADER_ERROR_VERSION__
        exit $__LOADER_ERROR_VERSION__
    fi
    if [[ "$__LOADER_BASE_NAME__" == "" ]]; then
        return_error "This function can only be called from a [common-installer loader] script."
    fi
    local _base_loader_name; get_basename _base_loader_name "$__LOADER_BASE_NAME__"
    if [[ "$__LOADER_BASE_NAME__" != "$_base_loader_name" ]]; then
        return_error "Invalid value of __LOADER_BASE_NAME__: \"$__LOADER_BASE_NAME__\""
    fi

    # Display help text
    local maybehelp="$1"; trim maybehelp
    if [[ "${maybehelp,,}" == "--help" ]]; then
        loader_print_help_text
        exit
    fi


    #######################################################
    ##  SET GLOBAL VARIABLES
    #######################################################

    # Set __ARGS__
    declare -gA __ARGS__=()
    copy_array __DEFAULT_ARGS__ __ARGS__    
    if [[ "${CUSTOM_ARGS[@]}" != "" ]]; then
        require_type_A CUSTOM_ARGS
        copy_array CUSTOM_ARGS __ARGS__ -merge   # overwrite defaults with user-specified values
    fi

    # Parse command-line arguments into __ARGS__ array
    local _params_str
    printf -v _params_str "%s " "${!__ARGS__[@]}"
    fast_argparse __ARGS__ "" "$_params_str" "$@"

    # Set __AUTOCONFIRM__
    if [[ "${__ARGS__[install]}" == "" ]]; then     declare -g __AUTOCONFIRM__="$FALSE"
    else                                            declare -g __AUTOCONFIRM__="$TRUE"
    fi

    # Set __ALLOW_ROOT__
    if [[ "${__ARGS__[allowroot],,}" == "true" ]]; then
                                                    declare -g __ALLOW_ROOT__="$TRUE"
                                                    echo "Requesting elevation..."
                                                    sudo echo "...granted."
    else                                            declare -g __ALLOW_ROOT__="$FALSE"
                                                    require_non_root
    fi

    # Set __FORCE__
    if [[ "${__ARGS__[force],,}" == "true" ]]; then declare -g __FORCE__="$TRUE"
    else                                            declare -g __FORCE__="$FALSE"
    fi

    # Set __LOGFILE__
    if [[ "${__ARGS__[logfile]}" == "" ]]; then     declare -g __LOGFILE__="./$__LOADER_BASE_NAME__.log"
    else                                            declare -g __LOGFILE__="${__ARGS__[logfile]}"
    fi
    echo "" > "$__LOGFILE__" || return_error "Logfile \"$__LOGFILE__\" is not writeable."

    # Set __TERMINAL_WIDTH__
    declare -g __TERMINAL_WIDTH__; get_term_width __TERMINAL_WIDTH__ || __TERMINAL_WIDTH__=0
    if [[ "$__TERMINAL_WIDTH__" -lt 20 ]]; then
        __TERMINAL_WIDTH__=80
    fi

    # Set __TEMP_DIR__
    declare -g __TEMP_DIR__="$(mktemp -d -t "$__LOADER_BASE_NAME__.XXXX")"
    if [[ ! -d "$__TEMP_DIR__" ]]; then
        __TEMP_DIR__="./$__LOADER_BASE_NAME__"
        mkdir "$__TEMP_DIR__"
    fi
    if [[ ! -d "$__TEMP_DIR__" ]]; then
        loader_print_error $__LOADER_ERROR_TEMP_DIR__; exit $__LOADER_ERROR_TEMP_DIR__
    fi
    push_exit_trap 'printf "Deleting temporary directory: %s\n\n" "$__TEMP_DIR__" ; rm -rf "$__TEMP_DIR__" || sudo rm -rf "$__TEMP_DIR__"'
    trap 'printf "\n"; exit' SIGINT

    # Set __MENU_COMMANDS__
    declare -gA __MENU_COMMANDS__=()
    copy_array __DEFAULT_MENU_COMMANDS__ __MENU_COMMANDS__
    if [[ "${CUSTOM_MENU_COMMANDS[@]}" != "" ]]; then
        require_type_A CUSTOM_MENU_COMMANDS
        copy_array CUSTOM_MENU_COMMANDS __MENU_COMMANDS__ -merge   # overwrite defaults with user-specified values
    fi


    #######################################################
    ##  FIND MODULE DEFINITIONS
    #######################################################

    # Add module definitions from module files
    local module_path
    local -A module_table=()
    for module_path in "${MODULE_PATHS[@]}"; do
        loader_get_module_definition_from_path module_table "$module_path"
    done
    printf "\n"

    # Add module definitions for menu commands
    local keyword
    for keyword in "${!__MENU_COMMANDS__[@]}"; do
        local -A moduledef=( ["MODULE"]="$keyword" ["COMMAND"]="${__MENU_COMMANDS__[$keyword]}" ["HIDDEN"]="true" )
        table_set_row module_table "$keyword" moduledef
    done


    #######################################################
    ##  START UI
    #######################################################

    # Reset the logfile
    loader_print_header "$MENU_TITLE" -width 80 > "$__LOGFILE__"

    # Display UI; loop until user exits the script, or until all modules are loaded (in auto mode only)
    while true; do
        # Print header title
        get_term_width __TERMINAL_WIDTH__ || __TERMINAL_WIDTH__=0
        if [[ "$__TERMINAL_WIDTH__" -lt 20 ]]; then
            __TERMINAL_WIDTH__=80
        fi

        loader_print_header "$MENU_TITLE" -width "$__TERMINAL_WIDTH__"

        # Print description and menu
        if [[ "$__AUTOCONFIRM__" == "$FALSE" ]]; then
            local wrapped_description
            wrap_string wrapped_description "$MENU_DESCRIPTION" "$__TERMINAL_WIDTH__"
            printf "%s\n\n" "$wrapped_description"
            loader_print_modules_from_table module_table -width "$__TERMINAL_WIDTH__"
        fi
        printf "\n"

        # Has a list of modules been provided with the -install argument?
        if [[ "$__AUTOCONFIRM__" == "$FALSE" ]]; then local module_list_str=""
        else                                          local module_list_str="${__ARGS__[install]}"
        fi

        # Collect and validate user input (normal mode) or validate the -install argument (unattended mode)
        local -a module_list=()
        while ! loader_get_install_order_from_string  module_table "$module_list_str" module_list ; do
            __AUTOCONFIRM__="$FALSE"    # Fall back to normal mode if the -install argument was invalid
            local wrapped_prompt=""
            wrap_string wrapped_prompt "$MENU_PROMPT" "$__TERMINAL_WIDTH__"
            printf "%s\n" "$wrapped_prompt"
            unset REPLY; read -r -p "  > " 
            module_list_str="${REPLY,,}"
            trim module_list_str
        done

        # Run each module sequentially
        printf "Loading the following modules:\n"
        print_var module_list -showname "false"
        printf "\n"
        if [[ "$__AUTOCONFIRM__" == "$TRUE" ]]; then
            read -t 10 -p "Continuing in 10 seconds. Press ENTER to continue, or CTRL+C to exit..." || true
        fi
        printf "\n"
        local module exitcode
        for module in "${module_list[@]}"; do
            loader_install_module module_table "$module"
            printf "\n"
            pause "Press ENTER to continue..."  # Skipped if $__AUTOCONFIRM__ == $TRUE
        done

        # Exit script (unattended mode only)
        if [[ "$__AUTOCONFIRM__" == "$TRUE" ]]; then exit 0; fi
    done
}



#####################################################################################################

__COMMON_INSTALLER_AVAILABLE__="$TRUE"
