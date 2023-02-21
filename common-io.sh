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
if [[ "$__COMMON_FUNCS_AVAILABLE__" != "$TRUE" ]]; then
    echo "ERROR: This script requires \"common-functions.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-functions.sh\" before sourcing this script."
    return 1
fi
#
#####################################################################################################
#       GLOBAL VARIABLES:
#
unset __COMMON_IO_AVAILABLE__   # Set to TRUE at the end of this file.
# __EXIT_TRAPS__                # Array containing a stack of commands to run on script exit. Set by push_exit_trap.
# __EXIT_CODE__                 # Contains the exit code after a call to 'exit', if push_exit_trap was used.
#
#####################################################################################################
#       FUNCTION REFERENCE:
#
# is_systemd
#   Checks if system has been initialized with systemd.
# require_systemd
#   Returns from the calling function with an error message if systemd is not available.
# run_and_log {commmand} [-logfile "path/to/logfile"] [-append true|false] [-set "abefhkmnptuvxBCHP] [-o option-name]"]
#   Run a shell command in the current environment and log the output to a file.
# push_exit_trap {"command"} ["exit message"]
#   Registers a command to run on script exit (EXIT or SIGINT).
# pop_exit_trap
#   Runs the last command added to the exit traps array and removes it from the stack.
# pop_all_exit_traps
#   Runs all commands in the exit traps array in LIFO order and clears the stack.
# find_files_matching_path {arrayname} {"path"} [-type "b,c,d,p,f,l" ] [-su false|true|auto] [-ret_searchpath varname] [-ret_searchdepth varname]
#   Returns an array of files matching the "path" string, which may have one or more wildcards (*).
# single_copy {"source"} {"destination"} [-mkdir true|false] [-overwrite true|false] [-preserve false|true] [-chmod "..."] [-chown "..."] [-su false|true|auto]
#   Copies a single file or directory from "source" to "destination".
# multi_copy {arrayname} [-type "b,c,d,p,f,l" ] [-mkdir true|false] [-overwrite true|false] [-preserve false|true] [-chmod "..."] [-chown "..."] [-su false|true|auto] [-testmode false|true]
#  Copies files from multiple sources to multiple destinations, resolving wildcards (*) in the source paths.
# extract {SOURCE} {DESTINATION}
#   Extracts an archive file to a destination directory. Supports tar, gz, bz2, xz, zip.
# git_latest {"url"} {"branch"}
#   Clones or pulls a git repository in the current directory (with recursive submodules).
# has_line {"file"} {"regexp"} [varname]
#  Searches a file for a line which matches the regular expression.
# find_key_value_pair {varname} {"file"} {"key"} ["sep"]
#  Searches a file for a line containing the specified key, then returns the associated value.
# ensure_line {file} {str} [match=whole/partial [sudo=true/false]]
#   Appends a line to the file, if line does not exist. Choose whole or partial line match.
# ensure_line_visudo {file} {str} [match=whole/partial]
#   Appends a line to the file using the "visudo" utility, if line does not exist.
# delete_lines_matching {file} {str} [match=whole/partial [sudo=true/false]]
#   Removes a lines from the file matching str.
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
    if [[ -z "$__SYSTEMD" ]]; then
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


# run_and_log {commmand} [-logfile "path/to/logfile"] [-append true|false] [-set "abefhkmnptuvxBCHP] [-o option-name]"]
#   Run a shell command in the current environment and log the output to a file.
# Inputs:
#   command     - Command to run. Runs in the current environment.
#   logfile     - Writes output to this file.
#   append      - If true (default), appends output to this file instead of overwriting it
#   set         - Applies these shell options before running the command, and restores the originals after.
# Outputs:
#   logfile     - File is created if it does not exist, and text is appended to the end.
#   $?          - Numeric exit value of the command.
#
function run_and_log() {
    local -A _fnargs=( ["append"]="true" ["set"]="$-"  )
    fast_argparse _fnargs "command" "logfile append set" "$@"
    if [[ "${_fnargs[append]}" == "true" ]]; then   local append_flag="-a"
    else                                            local append_flag="";       fi
    local _exitcode=0

    push_exit_trap "set -$-"
    if [[ "${_fnargs[logfile]}" == "" ]]; then 
        [[ "${_fnargs[set]}" != "" ]] && set -${_fnargs[set]}
        eval "${_fnargs[command]} ; _exitcode=\$?"
    else
        [[ "${_fnargs[set]}" != "" ]] && set -${_fnargs[set]}
        eval "${_fnargs[command]} ; _exitcode=\$?" > >(tee $append_flag -- "${_fnargs[logfile]}") 2>&1
    fi
    pop_exit_trap

    if [[ $? -ne 0 ]]; then # Return exit code of 'eval'
        return $?
    else                    # Return exit code of the command
        return $_exitcode
    fi
}


# push_exit_trap {"command"} ["exit message"]
#   Registers a command to run on script exit (EXIT or SIGINT).
# Inputs:
#   command     - Command to run on script exit. Commands will execute in LIFO order.
#   message     - Message to print on script exit. Only applies if no message has been set yet.
# Outputs:
#   __EXIT_TRAPS__  - Global variable (array) containing the stack of commands.
#   
function push_exit_trap() {
    local command="$1"
    local message="$2"

    # Init __EXIT_TRAPS__ if necessary
    if [[ ! -v __EXIT_TRAPS__ ]]; then
        declare -ag __EXIT_TRAPS__=()
        if [[ "$message" == "" ]]; then
            trap "declare -g __EXIT_CODE__=\$? ; pop_all_exit_traps" EXIT
        else
            trap "declare -g __EXIT_CODE__=\$? ; printf '\n%s\n' '$message' ; pop_all_exit_traps" EXIT
        fi
        trap "exit 2" SIGINT
    fi

    __EXIT_TRAPS__+=( "$command" )   # Top of stack is last item in array
}


# pop_exit_trap
#   Runs the last command added to the exit traps array and removes it from the stack.
# Outputs:
#   $?          - Numeric exit value of the command.
#   
function pop_exit_trap() {
    if [[ ! -v __EXIT_TRAPS__ ]]; then return 0; fi

    local indices=("${!__EXIT_TRAPS__[@]}");
    local top_idx="${indices[@]: -1}"     # Top of stack is last item in array
    local command="${__EXIT_TRAPS__[$top_idx]}"
    local exitcode=0

    # Run the command
    if [[ "$command" != "" ]]; then
        eval "$command ; exitcode=$?"
    fi

    unset "__EXIT_TRAPS__[$top_idx]"    # Remove command from top of stack
    return $exitcode
}


# pop_all_exit_traps
#   Runs all commands in the exit traps array in LIFO order and clears the stack.
# Outputs:
#   $?          - Returns the last nonzero exit value of the commands, or 0 if all ran successfully.
#   
function pop_all_exit_traps() {
    if [[ ! -v __EXIT_TRAPS__ ]]; then return 0; fi

    local exitcode=0
    while [[ "${#__EXIT_TRAPS__[@]}" -gt 0 ]]; do
        pop_exit_trap || exitcode=$?
    done
    return $exitcode
}


# find_files_matching_path {arrayname} {"path"} [-type "b,c,d,p,f,l" ] [-su false|true|auto] [-ret_searchpath varname] [-ret_searchdepth varname]
#   Returns an array of files matching the "path" string, which may have one or more wildcards (*).
#
function find_files_matching_path() {
    local -A _fnargs=( [type]="f,l" [su]="false" )
    fast_argparse _fnargs "arrayname path" "type su ret_searchpath ret_searchdepth" "$@"

    local -n __arrref=${_fnargs[arrayname]}
    local __pattern="${_fnargs[path]}"
    [[ "${_fnargs[type]}" != "" ]]     && local __types="${_fnargs[type]}"  || return 0
    [[ "${_fnargs[su],,}" == "true" ]] && local __cmd_prefix="sudo"         || local __cmd_prefix=""
    [[ "${_fnargs[ret_searchpath]}" != "" ]]  && local -n __searchpath=${_fnargs[ret_searchpath]}   || local __searchpath
    [[ "${_fnargs[ret_searchdepth]}" != "" ]] && local -n __searchdepth=${_fnargs[ret_searchdepth]} || local __searchdepth

    trim __pattern
    if [[ "$__pattern" == "" ]]; then return_error "No path provided."; fi
    if [[ "$__pattern" == */ ]]; then __types="d"; fi
    clean_path __pattern "$__pattern"
    trim __types

    # Figure out where to start looking for matching files
    if [[ "$__pattern" == *"*"* ]]; then
        local __searchpath_relative_pattern
        get_dirname __searchpath "${__pattern%"${__pattern#*\*}"}" # __searchpath is the parent directory of the first glob (*)         
        if [[ "$__searchpath" == "/" ]]; then
            __searchpath_relative_pattern="${__pattern#"${__searchpath}"}"
        else
            __searchpath_relative_pattern="${__pattern#"${__searchpath}/"}"
        fi

        # Set the search depth
        __searchdepth="${__searchpath_relative_pattern//[^\/]/}/" # count the number of slashes, plus 1
        __searchdepth="${#__searchdepth}"
    else
        # __pattern does not contain globs; just check if it exists and is one of the provided __types
        get_dirname __searchpath "$__pattern"
        __searchdepth=1
    fi

    #   printvar __pattern
    #   printvar __searchpath
    #   printvar __searchpath_relative_pattern
    #   printvar __searchdepth

    # Search for matching files
    local -a __matches
    local __errorcode=0 __errorfile="$(mktemp /tmp/find_files_matching_path.XXXXXX)"
    local __attempts=0 __max_attempts=1
    [[ "${_fnargs[su],,}" == "auto" ]] && __max_attempts=2
    while [[ "$__attempts" -lt "$__max_attempts" ]]; do (( __attempts=__attempts+1 ))

        # Run command. Store stdout into array, store stderr into temp file, store __errorcode in variable.
        local __cmd="$__cmd_prefix find \"$__searchpath\" -maxdepth $__searchdepth -path \"$__pattern\" -type $__types -print0"
        local __match
        __matches=()
        while IFS= read -d $'\0' -r __match || ! __errorcode="$__match"; do
            __matches+=( "$__match" )
        done < <( eval "$__cmd 2>\"$__errorfile\"" && [[ ! -s "$__errorfile" ]]; printf "$?" ) # returns an error if command fails or if errors are logged
        if [[ "$__errorcode" -eq 0 ]]; then break; fi # quit attempts if command completed without errors.

        __cmd_prefix="sudo"   # If errors occurred, next attempt will use sudo (next attempt only happens if -su auto)
    done

    if [[ "$__errorcode" -ne 0 ]]; then
        printf "Command '%s' logged errors:\n" "${__cmd%%"${__cmd#*find}"}" >&2
        cat "$__errorfile" >&2
    fi

    __arrref+=( "${__matches[@]}" ) # return results from last attempt
    rm "$__errorfile"
    return $__errorcode
}


# single_copy {"source"} {"destination"} [-mkdir true|false] [-overwrite true|false] [-preserve false|true] [-chmod "..."] [-chown "..."] [-su false|true|auto]
#   Copies a single file or directory from "source" to "destination".
#   Does NOT support globbing (*). See multi_copy() for generic file matching.
# Inputs:
#   source       - File or directory to copy.
#                    If source ends with /, function will require that source points to a directory.
#                    Otherwise, any file or folder with the given path will be copied.
#   destination  - File or directory to copy to.
#                  If source is a file:
#                    - If destination is an existing directory, source file will be copied to that directory, keeping the same basename.
#                    - If destination ends with /, source file will be copied to that directory, keeping the same basename
#                    - Otherwise, destination is treated as a file path, and source is copied to destination.
#                  If source is a directory:
#                    - If destination is an existing directory, the contents of source are recursively copied to destination, keeping the same basenames.
#                    - If destination ends with a /, the contents of source are recursively copied to destination, keeping the same basenames.
#                    - Otherwise, destination is treated as a directory path. Directory is created and the contents of source are recursively copied to destination.
#   mkdir        - Default: true. If true, creates all parent directories (mkdir -p) in the destination path before copying.
#   overwrite    - Default: true. If false, will not overwrite files in the destination if they already exist.
#   preserve     - Default: false. If true, uses --preserve=all flag for cp (preserves timestamps, owner, and all other file attributes from the source)
#   chmod        - Default: "". If provided, pass these arguments to chmod and apply to the destination.
#                    Recursion flags are automatically applied if necessary.
#   chown        - Default: "". If provided, pass these arguments to chown and apply to the destination.
#                    Recursion flags are automatically applied if necessary.
#   su           - Default: false. If true, run all file operations with sudo.
#                    If auto, reruns the function with -su "true" if any file operations fail.
# Outputs:
#   &1 (stdout)  - Function prints to standard output channel.
#   &2 (stderr)  - Function prints to standard error channel.
#   $?           - Numeric exit value; 0 indicates success.
#   
function single_copy() {
    local -A _fnargs=( [mkdir]="true" [overwrite]="true" [preserve]="false" [chmod]="" [chown]="" [su]="false" [testmode]="false" )
    fast_argparse _fnargs "src dst" "mkdir overwrite preserve chmod chown su testmode" "$@"

    local srcfile="${_fnargs[src]}"
    local dstfile="${_fnargs[dst]}"
    [[ "${_fnargs[mkdir],,}" == "true" ]]     && local mkdir_args="-p -v" || local mkdir_args="-v"
    [[ "${_fnargs[overwrite],,}" == "true" ]] && local cp_args="-v -f"    || local cp_args="-v -n"
    [[ "${_fnargs[preserve],,}" == "true" ]]  && cp_args="$cp_args --preserve=all"
    [[ "${_fnargs[chmod]}" != "" ]]           && local chmod_args="-f -c --preserve-root ${_fnargs[chmod]}" || local chmod_args=""
    [[ "${_fnargs[chown]}" != "" ]]           && local chown_args="-f -c --preserve-root ${_fnargs[chown]}" || local chown_args=""
    [[ "${_fnargs[su],,}" == "true" ]]        && local cmd_prefix="sudo"  || local cmd_prefix=""
    [[ "${_fnargs[testmode],,}" == "true" ]]  && local testmode=$TRUE     || local testmode=$FALSE

    # Input validation; also determine if source and destination point to files or directories
    local src_is_dir="" dst_is_dir=""
    trim srcfile
    trim dstfile
    if [[ "$srcfile" == "" ]]; then return_error "No source provided."; fi
    if [[ "$dstfile" == "" ]]; then return_error "No destination provided."; fi
    if [[ "$srcfile" == */ ]]; then src_is_dir="demand"; fi
    if [[ "$dstfile" == */ ]]; then dst_is_dir="demand"; fi
    clean_path srcfile "$srcfile"   # removes trailing slashes
    clean_path dstfile "$dstfile"
    if   [[ "$src_is_dir" == "demand" ]]; then

        if [[ -d "$srcfile" ]]; then src_is_dir=$TRUE
        else    return_error "Source directory '$srcfile' does not exist."
        fi

    else # [[ "$src_is_dir" == "" ]]
    
        if [[ -d "$srcfile" ]]; then src_is_dir=$TRUE
        elif [[ -e "$srcfile" ]]; then src_is_dir=$FALSE
        else return_error "Source '$srcfile' does not exist."
        fi
    
    fi

    if   [[ "$dst_is_dir" == "demand" ]]; then

        if [[ -d "$dstfile" ]]; then dst_is_dir=$TRUE
        elif [[ -e "$dstfile" ]]; then return_error "Destination '$dstfile' exists but is a file, not a directory."
        else dst_is_dir=$TRUE
        fi

    else # [[ "$dst_is_dir" == "" ]]
    
        if [[ -d "$dstfile" ]]; then dst_is_dir=$TRUE
        elif [[ -e "$dstfile" ]]; then dst_is_dir=$FALSE
        else dst_is_dir="$src_is_dir"
        fi
    
    fi

    # File can be copied to File or Dir
    # Dir can be copied to Dir but not File
    if [[ "$src_is_dir" == "$TRUE" && "$dst_is_dir" == "$FALSE" ]]; then
        return_error "Cannot copy directory to file '$dstfile'."
    fi

    # Where the files will be copied to
    local dst_dir=""
    if [[ "$dst_is_dir" == "$TRUE" ]]; then
        dst_dir="$dstfile"
    else                                          
        get_dirname dst_dir "$dstfile"
    fi

    (   
        set -e
        if [[ "${_fnargs[su],,}" == "auto" ]]; then exec 2>/dev/null; fi

        # mkdir
        if [[ ! -d "$dst_dir" ]]; then
            $cmd_prefix mkdir $mkdir_args -- "$dst_dir"
        fi

        # copy
        if [[ $src_is_dir == $TRUE ]]; then
            cp_args="$cp_args -r"
            local cp_src="$srcfile/."
        else
            local cp_src="$srcfile"
        fi
        if [[ $dst_is_dir == $TRUE ]]; then
            local cp_dst="$dstfile/"
        else
            local cp_dst="$dstfile"
        fi
        $cmd_prefix cp $cp_args -- "$cp_src" "$cp_dst"

        # chmod
        if [[ "$chmod_args" != "" ]]; then
            if [[ $dst_is_dir == $TRUE ]]; then
                chmod_args="-R $chmod_args"
            fi
            $cmd_prefix chmod $chmod_args -- "$dstfile"
        fi

        # chown
        if [[ "$chown_args" != "" ]]; then
            if [[ $dst_is_dir == $TRUE ]]; then
                chown_args="-R $chown_args"
            fi
            $cmd_prefix chown $chown_args -- "$dstfile"
        fi

        # printvar mkdir_args
        # printvar cp_src
        # printvar cp_dst
        # printvar cp_args
        # printvar chmod_args
        # printvar chown_args
        exit 0
    )
    local errorcode=$?

    if [[ $errorcode -ne 0 && "${_fnargs[su]}" == "auto" ]]; then   # If errors occurred and su == auto, rerun with -su true
        single_copy "${_fnargs[src]}" "${_fnargs[dst]}" \
            -mkdir "${_fnargs[mkdir]}"  \
            -overwrite "${_fnargs[overwrite]}"  \
            -preserve "${_fnargs[preserve]}"  \
            -chmod "${_fnargs[chmod]}"  \
            -chown "${_fnargs[chown]}"  \
            -su "true"
        errorcode=$?
    fi

    if [[ $errorcode -ne 0 ]]; then
        printf "single_copy failed with sudo." >&2
    fi

    return $errorcode
}


# multi_copy {arrayname} [-type "b,c,d,p,f,l" ] [-mkdir true|false] [-overwrite true|false] [-preserve false|true] [-chmod "..."] [-chown "..."] [-su false|true|auto] [-testmode false|true]
#  Copies files from multiple sources to multiple destinations, resolving wildcards (*) in the source paths.
# Inputs:
#   arrayname  - Name of array containing strings formatted as:
#                declare -a ( "SOURCE_1 : DEST_1"
#                             "SOURCE_2 : DEST_2" )        
#   source       - File or directory to copy.
#                    If source ends with /, function will require that source points to a directory.
#                    Otherwise, any file or folder with the given path will be copied.
#   destination  - File or directory to copy to.
#                  If source is a file:
#                    - If destination is an existing directory, source file will be copied to that directory, keeping the same basename.
#                    - If destination ends with /, source file will be copied to that directory, keeping the same basename
#                    - Otherwise, destination is treated as a file path, and source is copied to destination.
#                  If source is a directory:
#                    - If destination is an existing directory, the contents of source are recursively copied to destination, keeping the same basenames.
#                    - If destination ends with a /, the contents of source are recursively copied to destination, keeping the same basenames.
#                    - Otherwise, destination is treated as a directory path. Directory is created and the contents of source are recursively copied to destination.
#   mkdir        - Default: true. If true, creates all parent directories (mkdir -p) in the destination path before copying.
#   overwrite    - Default: true. If false, will not overwrite files in the destination if they already exist.
#   preserve     - Default: false. If true, uses --preserve=all flag for cp (preserves timestamps, owner, and all other file attributes from the source)
#   chmod        - Default: "". If provided, pass these arguments to chmod and apply to the destination.
#                    Recursion flags are automatically applied if necessary.
#   chown        - Default: "". If provided, pass these arguments to chown and apply to the destination.
#                    Recursion flags are automatically applied if necessary.
#   su           - Default: false. If true, run all file operations with sudo.
#                    If auto, reruns the function with -su "true" if any file operations fail.
# Outputs:
#   &1 (stdout)  - Function prints to standard output channel.
#   &2 (stderr)  - Function prints to standard error channel.
#   $?           - Numeric exit value; 0 indicates success.
#   
function multi_copy() {
    local -A _fnargs=( [type]="f,l" [mkdir]="true" [overwrite]="true" [preserve]="false" [chmod]="" [chown]="" [su]="false" [testmode]="false" )
    fast_argparse _fnargs "arrayname" "type mkdir overwrite preserve chmod chown su testmode" "$@"

    local -n _arrref=${_fnargs[arrayname]}
    [[ "${_fnargs[su],,}" == "true" ]]        && local cmd_prefix="sudo"  || local cmd_prefix=""
    [[ "${_fnargs[testmode],,}" == "true" ]]  && local testmode=$TRUE     || local testmode=$FALSE

    local -a srcfiles=() dstfiles=()
    for item in "${_arrref[@]}"; do
        # Parse a line of input
        if [[ "$item" != *:* ]]; then continue; fi
        local src_pattern="${item%%:*}"; trim src_pattern
        local dst_pattern="${item#*:}";  trim dst_pattern
        if [[ "$src_pattern" == "" || "$dst_pattern" == "" ]]; then continue; fi
        [[ "$src_pattern" == */ ]]           && local src_is_dir=$TRUE  || local src_is_dir=$FALSE
        [[ "$dst_pattern" == */ ]]           && local dst_is_dir=$TRUE  || local dst_is_dir=$FALSE

        # Locate all the files matching the input string
        local searchpath
        local -a matches=()
        find_files_matching_path matches "$src_pattern" -type "${_fnargs[type]}" -su "${_fnargs[su]}" -ret_searchpath searchpath

        clean_path src_pattern "$src_pattern"
        clean_path dst_pattern "$dst_pattern"

        # Decide what the destination filenames should be
        local srcfile dstfile searchpath_relative_pattern
        for srcfile in "${matches[@]}"; do
            if [[ "$searchpath" == "/" ]]; then
                searchpath_relative_pattern="${srcfile#"${searchpath}"}"
            else
                searchpath_relative_pattern="${srcfile#"${searchpath}/"}"
            fi

            if [[ "$dst_is_dir" == "$TRUE" ]]; then
                dstfile="${dst_pattern}/${searchpath_relative_pattern}"
            else
                dstfile="$dst_pattern"
            fi

            # Add paths to lists       
            srcfiles+=( "$srcfile" ) 
            dstfiles+=( "$dstfile" )
        done
    done

    if [[ "$testmode" == "$TRUE" ]]; then
        printvar srcfiles
        printvar dstfiles
        return 0
    fi

    # Create destination directories, copy files, and apply attributes as specified
    for idx in "${!srcfiles[@]}"; do
        single_copy "${srcfiles[$idx]}" "${dstfiles[$idx]}" \
            -mkdir "${_fnargs[mkdir]}"  \
            -overwrite "${_fnargs[overwrite]}"  \
            -preserve "${_fnargs[preserve]}"  \
            -chmod "${_fnargs[chmod]}"  \
            -chown "${_fnargs[chown]}"  \
            -su "${_fnargs[su]}"
    done

}


# extract {SOURCE} [-d DESTINATION] [-su true|false|auto]
#   Extracts an archive file to a destination directory.
# Inputs:
#   SOURCE               - Archive filename to extract
#   -d DESTINATION       - Destination directory. Defaults to "./"
#   -su true|false|auto  - If true, uses 'sudo' to run the extractor.
#                          If auto, reruns the function with '-su true' if extraction fails.
# Outputs:
#   $?                   - Numeric exit code; 0 if successfully extracted SOURCE file, 1 otherwise.
#
function extract() {
    local -A _fnargs=( [d]="./" [su]="false" )
    fast_argparse _fnargs "src" "d su" "$@"

    local src="${_fnargs[src]}"
    if [[ ! -f "$src" ]]; then return_error "File does not exist: $src"; fi
    local dst_dir="${_fnargs[d]}"
    if [[ ! -d "$dst_dir" ]]; then return_error "Directory does not exist: $dst_dir"; fi
    local cmd_prefix=""
    if [[ "${_fnargs[su]}" == "true" ]]; then local cmd_prefix="sudo"; fi

    (
        set -e                      # Exit subshell on error
        get_realpath src "$src"     # Convert to absolute path
        local ext=""; get_fileext ext "$src"
        local name=""; get_basename name "$src" "$ext"

        if [[ "${_fnargs[su]}" == "auto" ]]; then exec 2>/dev/null; fi

        cd "$dst_dir"
        case "${src,,}" in
            *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
                            $cmd_prefix tar xvf "$src"      ;;
            *.cbz|*.epub|*.zip)
                            $cmd_prefix unzip "$src"        ;;
            *.7z|*.apk|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
                            $cmd_prefix 7z x "$src"         ;;
            *.cbr|*.rar)    $cmd_prefix unrar x -ad "$src"  ;;
            *.lzma)         $cmd_prefix unlzma "$src"       ;;
            *.bz2)          $cmd_prefix bunzip2 "$src"      ;;
            *.gz)           $cmd_prefix gunzip "$src"       ;;
            *.z)            $cmd_prefix uncompress "$src"   ;;
            *.xz)           $cmd_prefix unxz "$src"         ;;
            *.exe)          $cmd_prefix cabextract "$src"   ;;
            *.cpio)         $cmd_prefix cpio -id < "$src"   ;;
            *.cba|*.ace)    $cmd_prefix unace x "$src"      ;;
            *.zpaq)         $cmd_prefix zpaq x "$src"       ;;
            *.arc)          $cmd_prefix arc e "$src"        ;;
            *.a)            $cmd_prefix ar x "$src"         ;;
            *.zlib)         $cmd_prefix zlib-flate -uncompress < "$src" > "$name"  ;;
            *.cso)          local tempfile="$dst_dir/$name.iso"
                            $cmd_prefix ciso 0 "$src" "$tempfile"
                            $cmd_prefix extract "$tempfile"
                            $cmd_prefix rm -f "$tempfile"   ;;
            *)              return_error "Cannot extract file (unrecognized file extension): $src" ;;
        esac
        exit 0
    )
    local errorcode=$?

    if [[ $errorcode -ne 0 && "${_fnargs[su]}" == "auto" ]]; then   # If errors occurred and su == auto, rerun with -su true
        extract "$src" -d "$dst_dir" -su "true"
    fi

    return $errorcode
}


# git_latest {"url"} {"branch"}
#   Clones or pulls a git repository in the current directory (with recursive submodules).
#   If repo already exists, resets local changes and pulls the latest version.
# Inputs:
#   url         - URL to Git repository
#   branch      - Branch to clone/pull
#
function git_latest()
{
    local url="$1"
    local branch="$2"
    
    local repo_name; get_basename repo_name "$url"
    local repo_name="${repo_name%.*}"

    if [[ -d "./$repo_name" ]]; then
        cd "$repo_name"
        git fetch --all
        git reset --hard origin/$branch
        git pull
        git submodule update --init --recursive
        cd "$wd"
    else
        git clone --branch "$branch" --recurse-submodules "$url"
    fi
}


# has_line {"file"} {"regexp"} [varname]
#  Searches a file for a line which matches the regular expression.
# Inputs:
#   file                - Path to a file.
#   regexp              - Regular expression to match.
# Outputs:
#   $?                  - Numeric exit code. 0 (success) if a matching line was found, 1 (failure) otherwise.
#   varname             - If supplied, stores the whole line into this variable.
#   ${BATCH_REMATCH[N]} - Automatic assignment by regex parser. If any capturing groups are specified in the regex,
#                         the captured strings are stored in this array (1-indexed).
#
function has_line() {
    local _file="$1"
    local _pat="$2"
    if [[ "$3" != "" ]]; then local -n _ret=$3
    else                      local _ret=""
    fi

    local _line
    while IFS= read -r _line || [[ -n "$_line" ]] ; do
        if [[ "$_line" =~ $_pat ]]; then 
            _ret="${BASH_REMATCH[0]}"
            return 0
        fi
    done < "$_file"
    _ret=""
    return 1
}


# find_key_value_pair {varname} {"file"} {"key"} ["sep"]
#  Searches a file for a line containing the specified key, then returns the associated value.
# Inputs:
#   file        - Path to a file.
#   key         - Key to search for. Key/value pair must be in the format:
#                   key sep "value"
#                   key sep 'value'
#   sep         - Pair separator. Defaults to '='.
# Outputs:
#   varname     - Name of variable to store the value.
#   $?          - Numeric exit code. 0 (success) if the pair was found, 1 (failure) otherwise.
#
function find_key_value_pair() {
    local -n _ret=$1
    local _file="$2"
    local _key="$3"
    local _sep="$4"
    if [[ "$_sep" == "" ]]; then _sep="="; fi

    local _pat="^\\s*${_key}\\s*${_sep}\\s*[\"'](.*?)[\"']\\s*\$"
    local _line
    while IFS= read -r _line || [[ -n "$_line" ]] ; do
        if [[ "$_line" =~ $_pat ]]; then 
            _ret="${BASH_REMATCH[1]}"
            return 0
        fi
    done < "$_file"
    _ret=""
    return 1
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
    [[ ! -e "$SERVICE_FILE" ]] && return_error "Required file $SERVICE_FILE does not exist."

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

__COMMON_IO_AVAILABLE__="$TRUE"
