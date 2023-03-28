#####################################################################################################
#
#       BASH COMMON-INSTALLER FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-scripts/common-functions.sh
#       source ./bash-common-scripts/common-io.sh
#       source ./bash-common-scripts/common-tables.sh
#       source ./bash-common-scripts/common-ui.sh
#       source ./bash-common-scripts/common-installer.sh
#
#####################################################################################################
#       REQUIRES COMMON-FUNCTIONS, COMMON-IO, COMMON-TABLES, COMMON-UI
#####################################################################################################
 
set -e
declare __COMMON_SCRIPTS_DIR__="${COMMON_SCRIPTS_DIR:-./scripts/bash-common-scripts}"
declare -a __LOADER_SOURCES__=(
    "$__COMMON_SCRIPTS_DIR__/common-functions.sh" 
    "$__COMMON_SCRIPTS_DIR__/common-io.sh"        
    "$__COMMON_SCRIPTS_DIR__/common-tables.sh"
    "$__COMMON_SCRIPTS_DIR__/common-ui.sh"
)
for __LOADER_SOURCE__ in "${__LOADER_SOURCES__[@]}"; do
    if ! source "$__LOADER_SOURCE__" ; then
        echo "Error loading required source: $__LOADER_SOURCE__"
        echo "Please run:"
        echo "  git submodule update --init --recursive"
        echo ""
        return 1
    fi
    unset __LOADER_SOURCE__
done
set +e

#####################################################################################################
 


#####################################################################################################
#       GLOBAL VARIABLES
#####################################################################################################
 
unset __COMMON_INSTALLER_AVAILABLE__  # Set to TRUE at the end of this file.

####    Loader Identifiers
declare __LOADER_TEMPLATE_VERSION__="${LOADER_TEMPLATE_VERSION:-testmode}"
declare __LOADER_SCRIPT_PATH__="${LOADER_SCRIPT_PATH:-$__COMMON_SCRIPTS_DIR__/common-installer.sh}"
declare __LOADER_BASENAME__; get_basename __LOADER_BASENAME__ "$__LOADER_SCRIPT_PATH__" ".sh"


####    Argument Format Spec
declare -A __ARGS__=(
    ["install"]=""
    ["force"]="false"
    ["allowroot"]="false"
    ["logfile"]="./${__LOADER_BASENAME__:-common-installer}.log"
)
if [[ "${ARGSPEC[*]}" != "" ]]; then copy_array ARGSPEC __ARGS__ -merge || return 1 ; fi


####    Argument Help Text
declare __DEFAULT_HELP_TEXT__=\
"--help                    Shows this help text.
--install \"module list\"   Space-separated list of module names to install.
                            Installs these modules (and their dependencies) in
                            unattended mode, suppressing all user input prompts.
                            By default, the loader skips modules which are
                            already installed (unless using --force true)
                            If left blank, displays the interactive menu.
                            Default: \"${__ARGS__[install]}\"
--force false|true        Forces modules to reinstall even if they are already installed.
                          Continues installation even if modules fail to install.
                            Default: \"${__ARGS__[force]}\"
--allowroot false|true    Allows the installer to run with superuser privilege.
                            If false, the installer will refuse to run with
                            superuser privilege. Modules which use 'sudo' will ask
                            for a sudo password if needed.
                            Default: \"${__ARGS__[allowroot]}\"
--logfile \"/path/to/log\"  Specify a different log file. Log will be overwritten.
                            Default: \"${__ARGS__[logfile]}\""
declare __ARGS_HELP_TEXT__="${ARGS_HELP_TEXT:-$__DEFAULT_HELP_TEXT__}"
unset __DEFAULT_HELP_TEXT__


####    Parse Command-line Arguments (sets values of __ARGS__)
if [[ "$__LOADER_TEMPLATE_VERSION__" != "testmode" ]]; then
    if [[ "$1" == "--help" ]]; then
        printf "USAGE:  %s [--opt1 \"val1\"] [--opt2 \"val2\"] ...\n\n" "${__LOADER_BASENAME__}.sh"
        printf "OPTIONS:\n"
        printf "%s\n\n" "$__ARGS_HELP_TEXT__"
        exit 0
    elif [[ "$1" == "--version" ]]; then
        printf "[common-installer loader]\n  Template Version: %s\n" "$__LOADER_TEMPLATE_VERSION__"
        exit 0
    fi
    fast_argparse __ARGS__ "" "${!__ARGS__[*]}" "$@"
fi


####    Boolean flags
[[ "${__ARGS__[install]}" != "" ]]          && declare __AUTOCONFIRM__="$TRUE"  || declare __AUTOCONFIRM__="$FALSE"
[[ "${__ARGS__[allowroot],,}" == "true" ]]  && declare __ALLOW_ROOT__="$TRUE"   || declare __ALLOW_ROOT__="$FALSE"
[[ "${__ARGS__[force],,}" == "true" ]]      && declare __FORCE__="$TRUE"        || declare __FORCE__="$FALSE"


####    Paths
declare __LOADER_DIR__="${LOADER_DIR:-$PWD}"
declare -a __MODULE_PATHS__=( "$__LOADER_DIR__/modules" )
if [[ "${MODULE_PATHS[*]}" != "" ]]; then copy_array MODULE_PATHS __MODULE_PATHS__ -merge || return 1 ; fi
declare __LOGFILE__="${__ARGS__[logfile]:-./${__LOADER_BASENAME__}.log}"
declare __TEMP_DIR__="${__TEMP_DIR__:-/tmp}"


####    User Interface Strings
declare __LOADER_TITLE__="${LOADER_TITLE:-common-installer loader}"
declare __LOADER_DESCRIPTION__="${LOADER_DESCRIPTION:-This loader is running in test mode.}"
declare __MENU_PROMPT__=\
" Usage:
  Enter a module name for more information. The system will not be modified without your permission.
  Enter 'help' for a full list of commands.
  Press CTRL+C to exit the script at any time."


####    User Interface Properties
declare __TERMINAL_WIDTH__=0; get_term_width __TERMINAL_WIDTH__ || __TERMINAL_WIDTH__=0
    if [[ "$__TERMINAL_WIDTH__" -lt 20 ]]; then __TERMINAL_WIDTH__=80; fi
declare -A __MENU_COMMANDS__=(
    ["help"]="print_var __MENU_COMMANDS__"
    ["pause"]="printf \"Type 'exit' to return to the installer.\n\"; /usr/bin/env bash"
    ["showhidden"]="print_table module_table"
    ["x"]="exit 0"
    ["exit"]="exit 0"
)
if [[ "${MENU_COMMANDS[*]}" != "" ]]; then copy_array MENU_COMMANDS __MENU_COMMANDS__ -merge || return 1 ; fi


####    Loader Template Definition
declare __LOADER_HEADER_STRING__='\[common-installer loader\]'
declare __LOADER_TEMPLATE_REQUIRED_VERSION__="1.1"
declare -a __LOADER_REQUIRED_PROPS__=(
    "LOADER_TEMPLATE_VERSION"
    "LOADER_SCRIPT_PATH"
    "LOADER_DIR"
    "COMMON_SCRIPTS_DIR"
    "MODULE_PATHS"
    "LOADER_TITLE"
    "LOADER_DESCRIPTION"
)
declare -a __LOADER_OPTIONAL_PROPS__=(
    "MENU_COMMANDS"
    "ARGSPEC"
    "ARGS_HELP_TEXT"
)


####    Module Template Definition
declare __MODULE_HEADER_STRING__='\[common-installer module\]'
declare __MODULE_TEMPLATE_REQUIRED_VERSION__="1.1"
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


####    Module Status Codes
declare -i __MODULE_STATUS_INSTALLED__=0
declare -i __MODULE_STATUS_NOT_INSTALLED__=110
declare -i __MODULE_STATUS_UNKNOWN__=111
declare -i __COMMAND_STATUS_SUCCESS__=$__MODULE_STATUS_INSTALLED__
declare -i __COMMAND_STATUS_FAILURE__=$__MODULE_STATUS_NOT_INSTALLED__
declare -a __MODULE_STATUS_STRINGS__=(
     [$__MODULE_STATUS_INSTALLED__]="Installed"
 [$__MODULE_STATUS_NOT_INSTALLED__]="Not Installed"
       [$__MODULE_STATUS_UNKNOWN__]=""
)


####    Error Codes
declare -i __LOADER_ERROR_GENERIC__=80
declare -i __LOADER_ERROR_NOT_A_SUBSHELL__=81
declare -i __LOADER_ERROR_ILLEGAL_CALL__=82
declare -i __LOADER_ERROR_TEMP_DIR__=83
declare -i __LOADER_ERROR_INVALID_REQUIRES__=84
declare -i __LOADER_ERROR_INVALID_INPUT__=85
declare -i __LOADER_ERROR_VERSION__=86
declare -i __LOADER_ERROR_MISSING_SOURCE__=87
declare -i __LOADER_ERROR_MISSING_PROPS__=88
declare -a __LOADER_ERROR_STRINGS__=(
         [$__LOADER_ERROR_GENERIC__]="Error: Loader %s failed (unknown reason)."
  [$__LOADER_ERROR_NOT_A_SUBSHELL__]="Error: Loader %s attempted to load a module without a subshell."
    [$__LOADER_ERROR_ILLEGAL_CALL__]="Error: Loader %s attempted to call a function from an uninitialized module."
        [$__LOADER_ERROR_TEMP_DIR__]="Error: Loader %s failed to create temporary directory."
[$__LOADER_ERROR_INVALID_REQUIRES__]="Error: Loader %s failed to load the module."
   [$__LOADER_ERROR_INVALID_INPUT__]="Error: Loader %s failed to load the module."
         [$__LOADER_ERROR_VERSION__]="Error: Loader %s is not using required template version $__LOADER_TEMPLATE_REQUIRED_VERSION__ ."
  [$__LOADER_ERROR_MISSING_SOURCE__]="Error: Loader %s could not find one or more required source files."
   [$__LOADER_ERROR_MISSING_PROPS__]="Error: Loader %s is missing a required property."
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
declare -i __MODULE_ERROR_INVALID_NAME__=101
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
       [$__MODULE_ERROR_VERSION__]="Error: Module %s is not using required template version $__MODULE_TEMPLATE_REQUIRED_VERSION__ ."
  [$__MODULE_ERROR_INVALID_NAME__]="Error: Module %s has invalid value for required property: MODULE"
)
declare -i __MODULE_STATE_NOT_INITIALIZED__=0
declare -i __MODULE_STATE_INITIALIZED__=1
declare -a __MODULE_STATE_STRINGS__=(
[$__MODULE_STATE_NOT_INITIALIZED__]="Not Initialized"
    [$__MODULE_STATE_INITIALIZED__]="Initialized"
)

###############################################################################



###############################################################################
## LOADER TEMPLATE VALIDATION
###############################################################################

if [[ "$__LOADER_TEMPLATE_VERSION__" != "testmode" ]]; then
    # Version check
    if [[ "$__LOADER_TEMPLATE_VERSION__" != "$__LOADER_TEMPLATE_REQUIRED_VERSION__" ]]; then
        loader_print_error $__LOADER_ERROR_VERSION__
        return $__LOADER_ERROR_VERSION__
    fi
    # Must have all required properties
    for __LOADER_PROP__ in "${__LOADER_REQUIRED_PROPS__[@]}"; do
        declare -n __LOADER_VAL__=$__LOADER_PROP__
        if [[ "${__LOADER_VAL__[*]}" != "" ]]; then continue; fi  # Required property can't be empty/undefined
        printf "${__LOADER_ERROR_STRINGS__[$__LOADER_ERROR_MISSING_PROPS__]} (%s)\n" "$__LOADER_BASENAME__" "$__LOADER_PROP__"
        return $__LOADER_ERROR_MISSING_PROPS__
    done
    unset __LOADER_PROP__ __LOADER_VAL__
fi

###############################################################################



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
            source "$__MODULE_DEFINITION_PATH__"    # Source module
    __SECTION__=$__MODULE_ERROR_VERSION__
            [[ "$MODULE_TEMPLATE_VERSION" == "$__MODULE_TEMPLATE_REQUIRED_VERSION__" ]];    # Version check
    __SECTION__=$__MODULE_ERROR_MISSING_PROPS__
            local _varname
            for _varname in "${__MODULE_REQUIRED_PROPS__[@]}"; do
                local -n _val=$_varname
                [[ "$_val" != "" ]];  # Required property can't be empty/undefined
            done
    __SECTION__=$__MODULE_ERROR_INVALID_NAME__
            is_varname "$MODULE"
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
                read -r -t 10 -p "Continuing in 10 seconds. Press ENTER to continue, or CTRL+C to exit..." || true
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

    # If the module's "COMMAND" field is set, this is a menu command, not a script.
    local _command; table_get _module_table "$_module_name" "COMMAND" _command
    if [[ "$_command" != "" ]]; then
        eval "$_command; return \$?"
    fi

    # Otherwise, the module should be imported as a script (inside a subshell) and then installed.
    local _script_path=""; table_get _module_table "$_module_name" "FILEPATH" _script_path
    local _status
    (
        module_import "$_script_path" # Sources and validates the module
        module_install  # Install and set __STATUS__ variable
        exit "$__STATUS__"
    )> >(tee -a -- "$__LOGFILE__") 2>&1; _status=$?
    table_set _module_table "$_module_name" "STATUS" "$_status"
    return $_status
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
        __infovar="$__LOADER_BASENAME__"

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
    fast_argparse _fnargs "" "width" "$@"

    local _width="${_fnargs[width]}"
    if [[ "$_width" == "" ]]; then
        get_term_width _width
    fi

    local _titlebox=""
    get_title_box _titlebox "$__LOADER_TITLE__" -width "$_width"
    printf "\n%s\n" "$_titlebox"

    if [[ "$__AUTOCONFIRM__" == "$TRUE" ]]; then
        fold -sw "$_width" <<< 'WARNING: Using --install (Unattended Mode) skips all user input prompts. Modules will install immediately on loading without confirmation.'
        printf "\n"
    fi
    if [[ "$__FORCE__" == "$TRUE" ]]; then
        fold -sw "$_width" <<< "WARNING: Using '--force true' will force modules to reinstall even if they have already been installed. This may cause undesireable system modifications."
        printf "\n"
    fi
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



# loader_get_modules_unordered {module_table} {"module list string"} {module_list_array}
function loader_get_modules_unordered() {
    local -n __module_table=$1   # Table of module definitions
    local __module_list_str="$2" # Input string: a space-separated list of module names (which may not be valid names).
    local -n __module_arr=$3     # Returns an array of valid module names

    local -a __module_names=()   # Array of all module names
    table_get_rownames __module_table __module_names

    local -a __module_arr_unverified=()
    str_to_arr __module_arr_unverified __module_list_str -e " "
    if [[ "${#__module_arr_unverified[@]}" -eq 0 ]]; then return $FALSE; fi # Fail if the module list is empty.
    
    local __module_name
    for __module_name in "${__module_arr_unverified[@]}"; do
        if ! has_value __module_names "$__module_name"; then return $FALSE; fi # Fail if any modules in the list are invalid module names.
    done

    __module_arr+=( "${__module_arr_unverified[@]}" )   # The list has been verified.
}



# loader_get_modules_ordered {module_table} {"input string"} {module_list_array}
function loader_get_modules_ordered() {
    local -n _module_table=$1    # Table of module definitions
    local _module_list_str="$2"  # Input string: a space-separated list of module names (which may not be valid names).
    local -n _module_arr=$3      # Return an array of module names, with their dependencies, in installation order.
    _module_arr=()

    # Get an unordered list of modules to install.
    local -a _module_list_unordered=()
    loader_get_modules_unordered _module_table "$_module_list_str" _module_list_unordered || return $FALSE

    # Init _install_priority array with module names, initially set to priority 0 (bottom of dependency tree).
    local -A _install_priority=()
    local _module_name
    for _module_name in "${_module_list_unordered[@]}"; do
        _install_priority["$_module_name"]=0
    done

    # Get array of valid module names (for validating REQUIRES)
    local -a _module_names=()
    table_get_rownames _module_table _module_names

    # Starting with the validated module names in _install_priority, walk the dependency tree
    #   (the "REQUIRES" column of module_table), adding each child module to the array.
    # Module names are keys of _install_priority, and tree depth are the values.
    # Algorithm (non-recursive):
    #   loop while _loop_again == TRUE
    #       _loop_again = FALSE
    #       loop through _install_priority. For each _parent:
    #           loop through its _children. For each (valid) _child:
    #               If _child_priority > _parent_priority, ignore it
    #               Else, (_child is not in the list yet or _child_priority <= _parent_priority)
    #                 set _child_priority = _parent_priority+1.
    #                 set _loop_again flag
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

                # Check that a definition exists for _child.
                if ! has_value _module_names "$_child"; then
                    printf "Error: Module [%s] requires [%s], but no module with that name is available.\n" "$_parent" "$_child"
                    return $__LOADER_ERROR_INVALID_REQUIRES__
                fi

                # Get _child priority (or set to 0 if not in the list yet).
                # If _child has higher priority than _parent, skip to next _child
                _child_priority="${_install_priority[$_child]:-0}"
                if [[ "$_child_priority" -gt "$_parent_priority" ]]; then
                    continue
                
                # Otherwise, elevate _child_priority to one higher than the _parent_priority, and set _loop_again flag
                else
                    (( _child_priority="$_parent_priority"+1 ))
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
        _module_arr+=("$_highest_module")
        unset "_install_priority[$_highest_module]"
    done
    #print_var _install_list

    [[ "${#_module_arr[@]}" -gt 0 ]];   # Fail if resulting array is empty.
}

###############################################################################



###############################################################################
## LOADER START
##   This function is called at the end of the loader definition template.
##     - Finds and imports module definitions
##     - Creates temp directory and logfile
##     - Displays the user interface
##     - Installs modules and runs menu commands
###############################################################################

function loader_start() {

    ####    Script Elevation
    if [[ "$__ALLOW_ROOT__" == "$TRUE" ]]; then
        printf "Requesting elevation...  "
        sudo printf "...granted.\n\n"
    else
        require_non_root
    fi

    ####    Add module definitions from module files
    local -A module_table=()
    local module_path
    for module_path in "${__MODULE_PATHS__[@]}"; do
        loader_get_module_definition_from_path module_table "$module_path"
    done
    printf "\n"


    ####    Add module definitions for menu commands
    local keyword
    for keyword in "${!__MENU_COMMANDS__[@]}"; do
        local -A moduledef=( ["MODULE"]="$keyword" ["COMMAND"]="${__MENU_COMMANDS__[$keyword]}" ["HIDDEN"]="true" ["STATUS"]="$__MODULE_STATUS_UNKNOWN__" )
        table_set_row module_table "$keyword" moduledef
    done

    
    ####    Add module definition for [all]
    local requireslist module
    local -a module_list_array=()
    table_get_rownames module_table module_list_array
    for module in "${module_list_array[@]}"; do
        local param_hidden=""
        table_get module_table "$module" "HIDDEN" param_hidden
        if [[ "${param_hidden,,}" != "true" ]]; then    # Add all non-hidden modules to the REQUIRES list of [all]
            requireslist="$requireslist $module"
        fi
    done
    trim requireslist
    local -A moduledef=( ["MODULE"]="all"
                         ["TITLE"]="Installs all modules in this list"
                         ["COMMAND"]="printf 'Completed [all].\n'; return \$__MODULE_STATUS_UNKNOWN__"
                         ["REQUIRES"]="$requireslist"
                         ["HIDDEN"]="false"
                         ["STATUS"]="$__MODULE_STATUS_UNKNOWN__" )
    table_set_row module_table "all" moduledef


    ####    Create Temp directory and register exit traps
    __TEMP_DIR__="$(mktemp -d -t "$__LOADER_BASENAME__.XXXX")"
    if [[ ! -d "$__TEMP_DIR__" ]]; then
        __TEMP_DIR__="./$__LOADER_BASENAME__"
        mkdir "$__TEMP_DIR__"
    fi
    if [[ ! -d "$__TEMP_DIR__" ]]; then
        loader_print_error $__LOADER_ERROR_TEMP_DIR__; exit $__LOADER_ERROR_TEMP_DIR__
    fi
    push_exit_trap 'printf "Deleting temporary directory: %s\n\n" "$__TEMP_DIR__" ; rm -rf "$__TEMP_DIR__" || sudo rm -rf "$__TEMP_DIR__"'
    trap 'printf "\n"; exit' SIGINT


    ####    Reset the logfile
    loader_print_header -width 80 > "$__LOGFILE__" || return_error "Logfile \"$__LOGFILE__\" is not writeable."


    ####    Loop until user exits the script, or (in unattended mode) loop until all modules have completed.
    while true; do
        ####    Print header
        get_term_width __TERMINAL_WIDTH__ || __TERMINAL_WIDTH__=0
        if [[ "$__TERMINAL_WIDTH__" -lt 20 ]]; then
            __TERMINAL_WIDTH__=80
        fi
        loader_print_header -width "$__TERMINAL_WIDTH__"

        ####    Print module defs table and instructions
        if [[ "$__AUTOCONFIRM__" == "$FALSE" ]]; then
            local wrapped_description
            wrap_string wrapped_description "$__LOADER_DESCRIPTION__" "$__TERMINAL_WIDTH__"
            printf "%s\n\n" "$wrapped_description"
            loader_print_modules_from_table module_table -width "$__TERMINAL_WIDTH__"
        fi
        printf "\n"

        ####    In unattended mode, the module list comes from the --install argument.
        [[ "$__AUTOCONFIRM__" == "$TRUE" ]] && local module_list="${__ARGS__[install]}" || local module_list=""

        ####    Collect and validate user input (normal mode) or just validate the --install argument (unattended mode)
        local -a modules_unordered=() 
        while ! loader_get_modules_unordered module_table "$module_list" modules_unordered ; do
            __AUTOCONFIRM__="$FALSE"    # Fall back to normal mode if the -install argument was invalid
            local wrapped_prompt=""; wrap_string wrapped_prompt "$__MENU_PROMPT__" "$__TERMINAL_WIDTH__"
            printf "%s\n\n" "$wrapped_prompt"
            read -r -p "  > " module_list
        done

        ####    Walk the module dependency tree to populate an ordered list
        local -a modules_ordered_with_deps=()
        loader_get_modules_ordered module_table "$module_list" modules_ordered_with_deps

        printf "\nLoading the following modules:\n"
        print_var modules_ordered_with_deps -showname "false"
        printf "\n"
        if [[ "$__AUTOCONFIRM__" == "$TRUE" ]]; then
            read -r -t 10 -p "Continuing in 10 seconds. Press ENTER to continue, or CTRL+C to exit..." || true
            printf "\n\n"
        fi

        ####    Run each module sequentially, starting with the deepest dependencies.
        local module status
        for module in "${modules_ordered_with_deps[@]}"; do

            # Skip this module if already installed and...
            #   FORCE    AUTOCONF  USER_REQUESTED    SKIP
            #       0           0               0       1   
            #       0           0               1       0   
            #       0           1               0       1   
            #       0           1               1       1   
            #       1           0               0       0   
            #       1           0               1       0   
            #       1           1               0       0   
            #       1           1               1       0   
            #   SKIP = ~FORCE && (AUTOCONF || ~USER_REQUESTED)
            #
            table_get module_table "$module" "STATUS" status
            if [[ "$status" == "$__MODULE_STATUS_INSTALLED__" && "$__FORCE__" == "$FALSE" ]]; then
                if [[ "$__AUTOCONFIRM__" == "$TRUE" ]] || ! has_value modules_unordered "$module"; then
                    printf "Skipping module [%s] because it is already installed.\n" "$module"
                    printf "  Rerun script with '--force true' to change this behavior.\n\n"
                    continue
                fi
            fi

            # Install module (or run menu command, if module is actually a menu command)
            loader_install_module module_table "$module"; status=$?
            printf "\n"

            # If module installed successfully, continue to the next module in the list
            if [[ $status -eq $__MODULE_STATUS_INSTALLED__ || $status -eq $__MODULE_STATUS_UNKNOWN__ ]]; then
                pause "Press ENTER to continue..."  # Skips this prompt if $__AUTOCONFIRM__ == $TRUE
                printf "\n"
                continue
            fi

            # If module failed to install, print an error message
            if [[ $status -eq $__MODULE_STATUS_NOT_INSTALLED__ ]]; then
                printf "ERROR: Module [%s] was not installed successfully.\n\n" "$module" 
            else
                printf "ERROR: Module [%s] failed with exit code: %s\n\n" "$module" "$status"
            fi

            # If module failed to install, skip the rest of the modules in the list if...
            #   FORCE   AUTOCONF        BREAK
            #       0           0           0
            #       0           1           1
            #       1           0           0
            #       1           1           0
            if [[ "$__FORCE__" == "$FALSE" && "$__AUTOCONFIRM__" == "$TRUE" ]]; then
                printf "Cancelling installation because [%s] failed to install.\n" "$module"
                printf "  Rerun script with '--force true' to change this behavior.\n\n"
                break
            fi

        done    # End of module install loop


        ####    Exit script (unattended mode only)
        if [[ "$__AUTOCONFIRM__" == "$TRUE" ]]; then exit 0; fi

    done    # End of UI loop
}



#####################################################################################################

__COMMON_INSTALLER_AVAILABLE__="$TRUE"
