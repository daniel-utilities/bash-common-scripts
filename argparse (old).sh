#!/usr/bin/env bash

# parse_args {argspec} {outargs} {"$@"}
#   Parses input arguments according to the specification
# Inputs:
#   argspec - Name of associative array containing argument specification, in the format:
#               declare -A argspec=(
#                   ["pos1|positional1"]=""       # corresponds to {required_value}
#                   ["pos2|positional2"]=""       # corresponds to {second_required_value}
#                   ["opt|optional1"]="default"   # corresponds to [--optional1 'userstring']
#                   ["flg|flag1"]="false"         # corresponds to [--flag1]
#                   ["sel|selection1"]="default alt1 alt2"
#                   ...                           # corresponds to [--selection1=default|alt1|alt2]
#               )
#   "$@"    - Quoted string of all program arguments.
# Outputs:
#   outargs - Name of associative array in which to store the parsed arguments.
#               declare -A outargs
#             The outargs array resulting from the previous argspec will be:
#                   ["positional1"] == "required_value"
#                   ["positional2"] == "second_required_value"
#                   ["optional1"]   == "default" or "userstring" if supplied
#                   ["flag1"]       == "false" or "true" if flag was supplied
#                   ["selection1"]  == "default" or "alt1" or "alt2"
#                   ...
#
function parse_args() {
    local -n _argspec=$1    # Input argspec associative array (not modified)
    local -n _outargs=$2    # Output associative array for parsed args
    shift 2         # All the remaining program arguments should be passed in as well

    local argfield argname argval

    # Check that argspec has a valid format
    for argfield in "${!_argspec[@]}"; do
        case "$argfield" in
            pos*) ;;
            opt*) ;;
            sel*) ;;
            flg*) ;;
            *)    echo "BUG: invalid arg type: $argfield"; exit 1
        esac
    done

    # Check for --help
    if [[ "$1" == "--help" ]]; then
        print_usage _argspec; exit 0
    fi

    # Initialize the output array to default values for all non-positional arguments
    for argfield in "${!_argspec[@]}"; do
        argval=
        case "$argfield" in
            opt*) argval="${_argspec[$argfield]}" ;;
            sel*) IFS=' ' read -r argval __trash <<< "${_argspec[$argfield]}" ;;
            flg*) argval="false" ;;
            *)    argval="" ;;
        esac
        format_output_args _outargs "$argfield" "$argval"
    done

    # Create a separate (sorted) list of all required positional arguments
    local -a pos_args
    for argfield in "${!_argspec[@]}"; do
        if [[ "$argfield" == "pos"* ]]; then
            pos_args+=( "$argfield" )
        fi
    done
    pos_args=( $( echo ${pos_args[@]} | tr ' ' $'\n' | sort ) )
    local total_pos=${#pos_args[@]}
    local found_pos=0

    # Parse arguments one by one and add them to the output array
    while [ "$#" -gt 0 ]; do
        # Parse one arg
        argfield=""
        argval=""
        parse_arg _argspec pos_args "$1" "$2" argfield argval found_pos
        local consumed=$? # parse_arg exit code is the number of consumed arguments
        [ "$#" -ge $consumed ] && shift $consumed || echo "BUG: Not enough arguments (Tried to parse: $argfield)"

        # Detect parsing errors
        if   [[ $consumed == 0 && "$argval" == "" ]]; then
            print_usage _argspec "Unknown or incomplete argument: $argfield"; exit 1
        elif [[ $consumed == 0 && "$argval" != "" ]]; then
            print_usage _argspec "Invalid value '$argval' in argument '$argfield'"; exit 1
        fi

        # Add to output args array, overwriting default value
        format_output_args _outargs "$argfield" "$argval"
    done

    # Ensure all positional arguments have been filled
    if [ $found_pos -lt $total_pos ]; then 
        print_usage _argspec "Not enough positional arguments; Found $found_pos, needed $total_pos."; exit 1
    fi

    ######################################################
    ## LOCAL FUNCTIONS
    ######################################################

    function print_usage() {
        local script="$(basename "$(readlink -f "$0")")"
        local -n __argspec=$1
        local err="$2"


        local argfield argname argval
        local -a argfields=( $( echo ${!__argspec[@]} | tr ' ' $'\n' | sort ) ) #sort alphabetically
        local -a posargs optargs selargs flgargs    # sort into categories
        for argfield in "${argfields[@]}"; do
            case "$argfield" in
                pos*) posargs+=( "$argfield" );;
                opt*) optargs+=( "$argfield" );;
                sel*) selargs+=( "$argfield" );;
                flg*) flgargs+=( "$argfield" );;
                *)    echo "BUG: invalid arg type: $argfield"; exit 1
            esac
        done

        if [[ "$err" != "" ]]; then
        echo "Error: $err";
        fi
        echo "Usage:"
        printf "  $script "
        for argfield in "${posargs[@]}"; do
        printf             "{${argfield#*|}} "
        done
        printf                               "[optional_args]\n"
        echo   "  $script --help"
        echo ""
        echo "  Positional arguments (Required, in order):"
        for argfield in "${posargs[@]}"; do
        echo "    {${argfield#*|}}"
        done
        echo ""
        echo "  Optional arguments:"
        for argfield in "${optargs[@]}"; do
        echo "    [--${argfield#*|} \"val\"]"
        echo "        Default: ${__argspec[$argfield]}"
        done
        for argfield in "${selargs[@]}"; do
        echo "    [--${argfield#*|}=$( echo ${__argspec[$argfield]} | tr ' ' '|' )]"
        done
        for argfield in "${flgargs[@]}"; do
        echo "    [--${argfield#*|}]"
        done
        echo ""

    }


    function parse_arg() {  # Exit code = Number of consumed arguments. 0 indicates error.
        local -n __argspec=$1  # argspec associative array
        local -n _pos_args=$2  # non-associative list of (sorted) positional argument names
        local _1="$3"          # arg to parse
        local _2="$4"          # next arg (sometimes arg1 arg2 are a key+value pair)
        local -n _argfield=$5  # return argument name as type|name
        local -n _argval=$6    # return argument value, or "" if no match was found.
        local -n _found_pos=$7 # return total number of parsed positional parguments
        local _total_pos=${#_pos_args[@]} # total pos args in the argspec

        _argname="${_1##*-}"      # trim leading -
        _argname="${_argname%=*}" # trim trailing =*
        _argfield="$_argname"   # Now we need to guess the type to complete the field
        _argval=""

        case "$_1" in
            --*=*|-*=*) # argtype is sel; search for matching name and val in argspec
                if   [[ "${__argspec[sel|$_argname]}" != "" ]]; then _argfield="sel|$_argname";  _argval="${_1#*=}"
                    if is_member_of_list "${__argspec[$_argfield]}" "$_argval"; then return 1
                    else _argfield="$_argname"; return 0 # error: invalid selection value
                    fi
                fi;;
            --*|-*)     # argtype is opt or flg; search for match in argspec
                if   [[ "${__argspec[opt|$_argname]}" != "" && "$_2" != "-"* ]]; then _argfield="opt|$_argname";  _argval="$_2"
                    if [[ "$_argval" != "" ]]; then return 2
                    else _argfield="$_argname"; return 0 # error: empty opt value is not allowed
                    fi
                elif [[ "${__argspec[flg|$_argname]}" != "" ]]; then _argfield="flg|$_argname";  _argval="true"
                    return 1
                fi;;
            *)          # argname is posN|name if it fits in the argspec, or just 'overflow' if it should go to overflow
                ((_found_pos=_found_pos+1));
                if [ $_found_pos -le $_total_pos ]; then _argfield="${_pos_args[$_found_pos-1]}"; _argval="$_1"
                    return 1
                else                                     _argfield="overflow";                    _argval="$_1"
                    return 1
                fi;;
        esac
        return 0
    }

    function is_member_of_list() {
        local list_str="$1"
        local elem="$2"
        for list_elem in $list_str; do
            if [[ "$elem" == "$list_elem" ]]; then return 0; fi
        done
        return 1
    }

    function format_output_args() {
        local -n __outargs=$1
        local argfield="$2"
        local argval="$3"
        local argname="${argfield#*|}"
        if [[ "$argfield" == "overflow"* ]]; then
            if [[ "${__outargs[overflow]}" == "" ]]; then
                __outargs["overflow"]="$argval"
            else
                __outargs["overflow"]="${__outargs[overflow]} $argval"
            fi
        else
            __outargs["$argname"]="$argval"
        fi
    }

}   # parse_args



#   declare -A argspec=(
#       ["pos1|positional1"]=""
#       ["opt|optional1"]="default_value"
#       ["opt|optional2"]="default_value"
#       ["flg|flag1"]="false"
#       ["flg|flag2"]="false"
#       ["sel|selection1"]="default_sel alt_sel_1 alt_sel_2"
#       ["pos2|positional2"]=""
#   )
#   declare -A outargs

#   parse_args argspec outargs "$@"

#   echo ""
#   echo "PARSED ARGS:"
#   for argfield in "${!outargs[@]}"; do
#       argval="${outargs[$argfield]}"
#       echo "  $argfield = $argval"
#   done
#   echo ""

