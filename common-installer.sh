#####################################################################################################
#
#       BASH COMMON-INSTALLER FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-scripts/common-functions.sh
#       source ./bash-common-scripts/common-io.sh
#       source ./bash-common-scripts/common-tables.sh
#       source ./bash-common-scripts/common-installer.sh
#
#####################################################################################################
#       REQUIRES COMMON-FUNCTIONS, COMMON-IO
#
if [[ "$__COMMON_FUNCS_AVAILABLE" != "$TRUE" ]]; then
    echo "ERROR: This script requires \"common-functions.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-functions.sh\" before sourcing this script."
    return 1
fi
if [[ "$__COMMON_IO_AVAILABLE" != "$TRUE" ]]; then
    echo "ERROR: This script requires \"common-io.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-io.sh\" before sourcing this script."
    return 1
fi
if [[ "$__COMMON_TABLES_AVAILABLE" != "$TRUE" ]]; then
    echo "ERROR: This script requires \"common-tables.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-tables.sh\" before sourcing this script."
    return 1
fi
#
#####################################################################################################
#       GLOBAL VARIABLES:
#
unset __COMMON_INSTALLER_AVAILABLE  # Set to TRUE at the end of this file.
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



# find_installer_modules {tablevar} {searchpath}
function find_installer_modules() {
    local -n _tab=$1
    local searchpath="$2"
    #printf "Searchpath: '%s'\n" "$searchpath"

    # Recognized keys
    local -A required_keys=( [module]=""
                             [description]="" )
    local -A optional_keys=( [requires]=""
                             [title]=""
                             [longdescription]=""
                             [author]=""
                             [platforms]=""
                             [tags]=""
                             [hidden]=""
                             [command]="" )

    # Initialize the table
    local properties="filepath verified ${!required_keys[@]} ${!optional_keys[@]}"
    if ! is_table _tab; then
        table_create _tab -colnames "$properties"
    fi

    # Find .sh files in the searchpath
    local file=""
    local -a files=()
    find_files_matching_path files "$searchpath/*.sh"

    # Check each .sh file for common-installer module identifiers
    for ((i = 0; i < ${#files[@]}; i++)); do
        file="${files[$i]}"

        # Must have module identifier
        if ! has_line "$file" '\[common-installer module\]' ; then continue; fi

        # Scan file for the required keys; skip file if it is missing any
        for key in ${!required_keys[@]}; do
            find_key_value_pair val "$file" "$key"
            required_keys["$key"]="$val"
        done
        if has_value required_keys "" ; then
            printf "WARNING: Script identifies as an installer module but is missing some required keys: %s\n" "$file"
            continue
        fi
        printf "Found installer module: %s\n" "${required_keys[module]}"

        # Scan file for the optional keys
        local val=""
        for key in ${!optional_keys[@]}; do
            find_key_value_pair val "$file" "$key"
            optional_keys["$key"]="$val"
        done

        # Add a new row to the table
        table_set     _tab "${required_keys[module]}" filepath "$file"
        table_set_row _tab "${required_keys[module]}" required_keys
        table_set_row _tab "${required_keys[module]}" optional_keys
    done
}


# verify_installer_module {tablevar} {module} [logfile]
function verify_installer_module() {
    local -n _tab=$1
    local module="$2"
    local logfile="$3"

    local script=""; table_get _tab "$module" "filepath" script

    run_and_log "/usr/bin/env bash \"$script\" -verify-only"
    if [[ $? -eq 0 ]]; then table_set _tab "$module" "verified" "$TRUE";  return 0
    else                    table_set _tab "$module" "verified" "$FALSE"; return 1
    fi
}



# load_installer_module {module_table} {module_name} [-args "..."] [-logfile "/path/to/logfile"]
function load_installer_module() {
    # Args
    local -A _fnargs=( [args]=""
                       [logfile]="" )
    fast_argparse _fnargs "module_table module_name" "args logfile" "$@"
    local -n _module_table="${_fnargs[module_table]}"
    local _module_name="${_fnargs[module_name]}"
    local _scriptargs="${_fnargs[args]}"
    local _logfile="${_fnargs[logfile]}"

    local _script_path=""; table_get _module_table "$_module_name" "filepath" _script_path

    local _command="printf 'Loading module [%s]. Logfile: \"%s\"\n\n' '$_module_name' '$_logfile'; /usr/bin/env bash \"$_script_path\" $_scriptargs"
    
    run_and_log "$_command" "$_logfile"
    return $?
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
    local -a _display_cols_reorder=("description"  "requires")
    local -A _display_cols_rename=(["description"]="Description:"  ["requires"]="Requires:" )

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
    table_print _display_table -rowname_header "$_rowname_header" -colsep "$_colsep" -max_col_width "$_max_col_width" -width "$_width" 

}





#####################################################################################################

__COMMON_INSTALLER_AVAILABLE="$TRUE"
