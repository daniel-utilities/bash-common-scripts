#####################################################################################################
#
#       BASH COMMON-TABLES FUNCTIONS
#       By danielk-98, 2022
#
#       git clone https://github.com/daniel-utilities/bash-common-scripts.git
#       source ./bash-common-scripts/common-functions.sh
#       source ./bash-common-scripts/common-tables.sh
#
#####################################################################################################
#       REQUIRES COMMON-FUNCTIONS
#
if [[ "$__COMMON_FUNCS_AVAILABLE" != "$TRUE" ]]; then
    echo "ERROR: This script requires \"common-functions.sh\" to be sourced in the current environment."
    echo "Please run \"source path/to/common-functions.sh\" before sourcing this script."
    return 1
fi
#
#####################################################################################################
#       GLOBAL VARIABLES:
#
unset __COMMON_TABLES_AVAILABLE  # Set to TRUE at the end of this file.
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
# LEVEL 0 FUNCTIONS
#   Functions take no namerefs as arguments, so name conflicts are not possible
###############################################################################

###############################################################################
# LEVEL 1 FUNCTIONS
#   Functions take namerefs as arguments, but do not pass the namerefs to
#   another function.
#   All local variables are prefixed with '_', therefore passing a nameref of
#   the format '_NAME' may cause errors.
###############################################################################

function is_table() {
    local -n _table=$1
    [[ "${_table@a}" == *A* && "${_table[__vartype]}" == "table" ]];
}

function require_table() {
    local -n _table=$1
    [[ "${_table@a}" == *A* && "${_table[__vartype]}" == "table" ]] && return 0 || return_error "variable $1 is not a table."
}

function table_get_colnames() {
    local -n _table=$1;    require_table $1
    local -n _ret=$2;      require_type_a $2
    local IFS=$'\t' _name
    _ret=(); for _name in ${_table[__colnames]}; do _ret+=("$_name"); done
}

function table_get_rownames() {
    local -n _table=$1;    require_table $1
    local -n _ret=$2;      require_type_a $2
    local IFS=$'\t' _name
    _ret=(); for _name in ${_table[__rownames]}; do _ret+=("$_name"); done
}

function table_get_numcols() {
    local -n _table=$1;    require_table $1
    local -n _numcols=$2
    _numcols="${_table[__numcols]}"
}

function table_get_numrows() {
    local -n _table=$1;    require_table $1
    local -n _numrows=$2
    _numrows="${_table[__numrows]}"
}

function table_get_metadata() {
    local -n _table=$1;    require_table $1
    local _key="$2"
    local -n _ret=$3
    _ret="${_table[__$_key]}"
}

function table_set_metadata() {
    local -n _table=$1;    require_table $1
    local _key="$2"
    local _val="$3"
    _table["__$_key"]="$_val"
}


# Row and column names cannot begin with '__' or contain tabs '\t' or newlines '\n'.
#
function table_create() {
    local -A _fnargs=( [sep]=$' \t' )
    fast_argparse _fnargs "tablename" "rownames colnames sep" "$@"

    local -n _table=${_fnargs[tablename]};  require_type_A ${_fnargs[tablename]}
    _table=( ["__vartype"]="table" ) # set the table identifier metadata

    local IFS="${_fnargs[sep]}" _name
    local -a _colnames=(); for _name in ${_fnargs[colnames]}; do _colnames+=("$_name"); done
    local -a _rownames=(); for _name in ${_fnargs[rownames]}; do _rownames+=("$_name"); done
    local _numcols="${#_colnames[@]}"
    local _numrows="${#_rownames[@]}"
    IFS=' '

    printf -v _table["__colnames"] "%s\t" "${_colnames[@]}"
    printf -v _table["__rownames"] "%s\t" "${_rownames[@]}"
    _table["__numcols"]="$_numcols"
    _table["__numrows"]="$_numrows"
}


function table_get() {
    local -n _table=$1;    require_table $1
    local _rowname="$2";   [[ "$2" == "" ]] && return 1
    local _colname="$3";   [[ "$3" == "" ]] && return 1
    local -n _ret=$4

    local _key="$_rowname"$'\t'"$_colname"
    _ret="${_table[$_key]}"
}


function table_remove() {
    local -n _table=$1;    require_table $1
    local _rowname="$2";   [[ "$2" == "" ]] && return 1
    local _colname="$3";   [[ "$3" == "" ]] && return 1
    [[ "$4" != "" ]] && local -n _ret=$4 || local _ret

    local _key="$_rowname"$'\t'"$_colname"
    _ret="${_table[$_key]}"
    [[ -v "_table[$_key]" ]] && unset -v "_table[$_key]" || return 1
}


function table_get_col() {
    local -n _table=$1;    require_table $1
    local _colname="$2";   [[ "$2" == "" ]] && return 1
    local -n _ret=$3;      local _vartype; get_type _ret _vartype

    local IFS=$'\t' _name
#   local -a _colnames=(); for _name in ${_table[__colnames]}; do _colnames+=("$_name"); done
    local -a _rownames=(); for _name in ${_table[__rownames]}; do _rownames+=("$_name"); done
#   local _numcols="${_table[__numcols]}"
#   local _numrows="${_table[__numrows]}"
    IFS=$' '

    # Find all the values belonging to this column
    local -A _found=()
    local _key _val _row _col
    for _key in "${!_table[@]}"; do
        [[ "$_key" == __* ]] && continue # ignore metadata
        _val="${_table[$_key]}"
        _row="${_key%$'\t'*}"
        _col="${_key#*$'\t'}"
        [[ "$_col" == "$_colname" ]] && _found["$_row"]="$_val" || continue # ignore values that are not in this column
#       [[ "$_row" == "$_rowname" ]] && _found["$_col"]="$_val" || continue # ignore values that are not in this row
    done

    # Return the column values in the order specified by __rownames
    _ret=()
    for _row in "${_rownames[@]}"; do
#   for _col in "${_colnames[@]}"; do
        _val="${_found[$_row]}"
#       _val="${_found[$_col]}"
        [[ "$_vartype" == A ]] && _ret["$_row"]="$_val" || _ret+=("$_val")
#       [[ "$_vartype" == A ]] && _ret["$_col"]="$_val" || _ret+=("$_val")
    done
}


function table_get_row() {
    local -n _table=$1;    require_table $1
    local _rowname="$2";   [[ "$2" == "" ]] && return 1
    local -n _ret=$3;      local _vartype; get_type _ret _vartype

    local IFS=$'\t' _name
    local -a _colnames=(); for _name in ${_table[__colnames]}; do _colnames+=("$_name"); done
#   local -a _rownames=(); for _name in ${_table[__rownames]}; do _rownames+=("$_name"); done
#   local _numcols="${_table[__numcols]}"
#   local _numrows="${_table[__numrows]}"
    IFS=$' '

    # Find all the values belonging to this row
    local -A _found=()
    local _key _val _row _col
    for _key in "${!_table[@]}"; do
        [[ "$_key" == __* ]] && continue # ignore metadata
        _val="${_table[$_key]}"
        _row="${_key%$'\t'*}"
        _col="${_key#*$'\t'}"
#       [[ "$_col" == "$_colname" ]] && _found["$_row"]="$_val" || continue # ignore values that are not in this column
        [[ "$_row" == "$_rowname" ]] && _found["$_col"]="$_val" || continue # ignore values that are not in this row
    done

    # Return the row values in the order specified by __colnames
    _ret=()
#   for _row in "${_rownames[@]}"; do
    for _col in "${_colnames[@]}"; do
#       _val="${_found[$_row]}"
        _val="${_found[$_col]}"
#       [[ "$_vartype" == A ]] && _ret["$_row"]="$_val" || _ret+=("$_val")
        [[ "$_vartype" == A ]] && _ret["$_col"]="$_val" || _ret+=("$_val")
    done
}


function table_append_col() {
    local -n _table=$1;    require_table $1
    local _newcolname="$2";   [[ "$2" == "" ]] && return 1

    local IFS=$'\t' _name
    local -a _colnames=(); for _name in ${_table[__colnames]}; do _colnames+=("$_name"); done
#   local -a _rownames=(); for _name in ${_table[__rownames]}; do _rownames+=("$_name"); done
    local _numcols="${_table[__numcols]}"
#   local _numrows="${_table[__numrows]}"
    IFS=$' '
    
    has_value _colnames "$_newcolname" && return 1      # Skip if column already exists
#   has_value _rownames "$_newrowname" && return 1      # Skip if row already exists
    ((_numcols+=1))
#   ((_numrows+=1))
    _colnames=( "${_colnames[@]}" "$_newcolname" )
#   _rownames=( "${_rownames[@]}" "$_newrowname" )

    printf -v _table["__colnames"] "%s\t" "${_colnames[@]}"
#   printf -v _table["__rownames"] "%s\t" "${_rownames[@]}"
    _table["__numcols"]=$_numcols
#   _table["__numrows"]=$_numrows
}


function table_append_row() {
    local -n _table=$1;    require_table $1
    local _newrowname="$2"; [[ "$2" == "" ]] && return 1

    local IFS=$'\t' _name
#   local -a _colnames=(); for _name in ${_table[__colnames]}; do _colnames+=("$_name"); done
    local -a _rownames=(); for _name in ${_table[__rownames]}; do _rownames+=("$_name"); done
#   local _numcols="${_table[__numcols]}"
    local _numrows="${_table[__numrows]}"
    IFS=$' '
    
#   has_value _colnames "$_newcolname" && return 1      # Skip if column already exists
    has_value _rownames "$_newrowname" && return 1      # Skip if row already exists
#   ((_numcols+=1))
    ((_numrows+=1))
#   _colnames=( "${_colnames[@]}" "$_newcolname" )
    _rownames=( "${_rownames[@]}" "$_newrowname" )

#   printf -v _table["__colnames"] "%s\t" "${_colnames[@]}"
    printf -v _table["__rownames"] "%s\t" "${_rownames[@]}"
#   _table["__numcols"]=$_numcols
    _table["__numrows"]=$_numrows
}


function table_insert_col() {
    local -n _table=$1;    require_table $1
    local _newcolname="$2"; [[ "$2" == "" ]] && return 1
    local _insertbefore="$3";   [[ "$3" == "" ]] && return 1

    local IFS=$'\t' _name
    local -a _colnames=(); for _name in ${_table[__colnames]}; do _colnames+=("$_name"); done
#   local -a _rownames=(); for _name in ${_table[__rownames]}; do _rownames+=("$_name"); done
    local _numcols="${_table[__numcols]}"
#   local _numrows="${_table[__numrows]}"
    IFS=$' '
    
    has_value _colnames "$_newcolname" && return 1      # Skip if column already exists
#   has_value _rownames "$_newrowname" && return 1      # Skip if row already exists
    local _idx; find_value _colnames "$_insertbefore" _idx
#   local _idx; find_value _rownames "$_insertbefore" _idx
    find_value _colnames "$_insertbefore" _idx
    [[ "$_idx" == "" ]] && _idx=0 
    ((_numcols+=1))
#   ((_numrows+=1))
    insert_value _colnames $_idx "$_newcolname"
#   insert_value _rownames $_idx "$_newrowname"

    printf -v _table["__colnames"] "%s\t" "${_colnames[@]}"
#   printf -v _table["__rownames"] "%s\t" "${_rownames[@]}"
    _table["__numcols"]=$_numcols
#   _table["__numrows"]=$_numrows
}


function table_insert_row() {
    local -n _table=$1;    require_table $1
    local _newrowname="$2";   [[ "$2" == "" ]] && return 1
    local _insertbefore="$3";   [[ "$3" == "" ]] && return 1

    local IFS=$'\t' _name
#   local -a _colnames=(); for _name in ${_table[__colnames]}; do _colnames+=("$_name"); done
    local -a _rownames=(); for _name in ${_table[__rownames]}; do _rownames+=("$_name"); done
#   local _numcols="${_table[__numcols]}"
    local _numrows="${_table[__numrows]}"
    IFS=$' '
    
#   has_value _colnames "$_newcolname" && return 1      # Skip if column already exists
    has_value _rownames "$_newrowname" && return 1      # Skip if row already exists
#   local _idx; find_value _colnames "$_insertbefore" _idx
    local _idx; find_value _rownames "$_insertbefore" _idx
    [[ "$_idx" == "" ]] && _idx=0 
#   ((_numcols+=1))
    ((_numrows+=1))
#   insert_value _colnames $_idx "$_newcolname"
    insert_value _rownames $_idx "$_newrowname"

#   printf -v _table["__colnames"] "%s\t" "${_colnames[@]}"
    printf -v _table["__rownames"] "%s\t" "${_rownames[@]}"
#   _table["__numcols"]=$_numcols
    _table["__numrows"]=$_numrows
}


function table_rename_col() {
    local -n _table=$1;    require_table $1
    local _oldcolname="$2";   [[ "$2" == "" ]] && return 1
    local _newcolname="$3";   [[ "$3" == "" ]] && return 1

    local IFS=$'\t' _name
    local -a _colnames=(); for _name in ${_table[__colnames]}; do _colnames+=("$_name"); done
#   local -a _rownames=(); for _name in ${_table[__rownames]}; do _rownames+=("$_name"); done
#   local _numcols="${_table[__numcols]}"
#   local _numrows="${_table[__numrows]}"
    IFS=$' '
    
    # Set new column name in metadata
    local _idx
    find_value _colnames "$_oldcolname" _idx
#   find_value _rownames "$_oldrowname" _idx
    [[ "$_idx" == "" ]] && return 1
    _colnames[$_idx]="$_newcolname"
#   _rownames[$_idx]="$_newrowname"
    
    # Rename all keys referring to the old column name
    local _key _val _row _col _newkey
    for _key in "${!_table[@]}"; do
        [[ "$_key" == __* ]] && continue # ignore metadata
        _row="${_key%$'\t'*}"
        _col="${_key#*$'\t'}"
        [[ "$_col" != "$_oldcolname" ]] && continue # ignore values that are not in this column
#       [[ "$_row" != "$_oldrowname" ]] && continue # ignore values that are not in this row
        _val="${_table[$_key]}"
        unset -v "_table[$_key]"
        _newkey="$_row"$'\t'"$_newcolname"
#       _newkey="$_newrowname"$'\t'"$_col"
        _table["$_newkey"]="$_val"
    done


    printf -v _table["__colnames"] "%s\t" "${_colnames[@]}"
#   printf -v _table["__rownames"] "%s\t" "${_rownames[@]}"
#   _table["__numcols"]=$_numcols
#   _table["__numrows"]=$_numrows
}


function table_rename_row() {
    local -n _table=$1;    require_table $1
    local _oldrowname="$2";   [[ "$2" == "" ]] && return 1
    local _newrowname="$3";   [[ "$3" == "" ]] && return 1

    local IFS=$'\t' _name
#   local -a _colnames=(); for _name in ${_table[__colnames]}; do _colnames+=("$_name"); done
    local -a _rownames=(); for _name in ${_table[__rownames]}; do _rownames+=("$_name"); done
#   local _numcols="${_table[__numcols]}"
#   local _numrows="${_table[__numrows]}"
    IFS=$' '
    
    # Set new column name in metadata
    local _idx
#   find_value _colnames "$_oldcolname" _idx
    find_value _rownames "$_oldrowname" _idx
    [[ "$_idx" == "" ]] && return 1
#   _colnames[$_idx]="$_newcolname"
    _rownames[$_idx]="$_newrowname"
    
    # Rename all keys referring to the old row name
    local _key _val _row _col _newkey
    for _key in "${!_table[@]}"; do
        [[ "$_key" == __* ]] && continue # ignore metadata
        _row="${_key%$'\t'*}"
        _col="${_key#*$'\t'}"
#       [[ "$_col" != "$_oldcolname" ]] && continue # ignore values that are not in this column
        [[ "$_row" != "$_oldrowname" ]] && continue # ignore values that are not in this row
        _val="${_table[$_key]}"
        unset -v "_table[$_key]"
#       _newkey="$_row"$'\t'"$_newcolname"
        _newkey="$_newrowname"$'\t'"$_col"
        _table["$_newkey"]="$_val"
    done

#   printf -v _table["__colnames"] "%s\t" "${_colnames[@]}"
    printf -v _table["__rownames"] "%s\t" "${_rownames[@]}"
#   _table["__numcols"]=$_numcols
#   _table["__numrows"]=$_numrows
}


function table_remove_col() {
    local -n _table=$1;    require_table $1
    local _colname="$2";   [[ "$2" == "" ]] && return 1
    [[ "$3" != "" ]] && local -n _ret=$3 || local -A _ret; local _vartype; get_type _ret _vartype

    local IFS=$'\t' _name
    local -a _colnames=(); for _name in ${_table[__colnames]}; do _colnames+=("$_name"); done
    local -a _rownames=(); for _name in ${_table[__rownames]}; do _rownames+=("$_name"); done
    local _numcols="${_table[__numcols]}"
#   local _numrows="${_table[__numrows]}"
    IFS=$' '
    
    # Remove column name from metadata
    remove_value _colnames "$_colname" || return 1
#   remove_value _rownames "$_rowname" || return 1
    ((_numcols-=1))
#   ((_numrows-=1))

    # Remove all keys referring to the old column name
    local -A _found=()
    local _key _val _row _col
    for _key in "${!_table[@]}"; do
        [[ "$_key" == __* ]] && continue # ignore metadata
        _val="${_table[$_key]}"
        _row="${_key%$'\t'*}"
        _col="${_key#*$'\t'}"
        [[ "$_col" == "$_colname" ]] && _found["$_row"]="$_val" || continue # ignore values that are not in this column
#       [[ "$_row" == "$_rowname" ]] && _found["$_col"]="$_val" || continue # ignore values that are not in this row
        unset -v "_table[$_key]"
    done

    # Return the column values in the order specified by __rownames
    _ret=()
    for _row in "${_rownames[@]}"; do
#   for _col in "${_colnames[@]}"; do
        _val="${_found[$_row]}"
#       _val="${_found[$_col]}"
        [[ "$_vartype" == A ]] && _ret["$_row"]="$_val" || _ret+=("$_val")
#       [[ "$_vartype" == A ]] && _ret["$_col"]="$_val" || _ret+=("$_val")
    done

    printf -v _table["__colnames"] "%s\t" "${_colnames[@]}"
#   printf -v _table["__rownames"] "%s\t" "${_rownames[@]}"
    _table["__numcols"]=$_numcols
#   _table["__numrows"]=$_numrows
}


function table_remove_row() {
    local -n _table=$1;    require_table $1
    local _rowname="$2";   [[ "$2" == "" ]] && return 1
    [[ "$3" != "" ]] && local -n _ret=$3 || local -A _ret; local _vartype; get_type _ret _vartype

    local IFS=$'\t' _name
    local -a _colnames=(); for _name in ${_table[__colnames]}; do _colnames+=("$_name"); done
    local -a _rownames=(); for _name in ${_table[__rownames]}; do _rownames+=("$_name"); done
#   local _numcols="${_table[__numcols]}"
    local _numrows="${_table[__numrows]}"
    IFS=$' '
    
    # Remove row name from metadata
#   remove_value _colnames "$_colname" || return 1
    remove_value _rownames "$_rowname" || return 1
#   ((_numcols-=1))
    ((_numrows-=1))
    
    # Remove all keys referring to the old row name
    local -A _found=()
    local _key _val _row _col
    for _key in "${!_table[@]}"; do
        [[ "$_key" == __* ]] && continue # ignore metadata
        _val="${_table[$_key]}"
        _row="${_key%$'\t'*}"
        _col="${_key#*$'\t'}"
#       [[ "$_col" == "$_colname" ]] && _found["$_row"]="$_val" || continue # ignore values that are not in this column
        [[ "$_row" == "$_rowname" ]] && _found["$_col"]="$_val" || continue # ignore values that are not in this row
        unset -v "_table[$_key]"
    done

    # Return the row values in the order specified by __colnames
    _ret=()
#   for _row in "${_rownames[@]}"; do
    for _col in "${_colnames[@]}"; do
#       _val="${_found[$_row]}"
        _val="${_found[$_col]}"
#       [[ "$_vartype" == A ]] && _ret["$_row"]="$_val" || _ret+=("$_val")
        [[ "$_vartype" == A ]] && _ret["$_col"]="$_val" || _ret+=("$_val")
    done

#   printf -v _table["__colnames"] "%s\t" "${_colnames[@]}"
    printf -v _table["__rownames"] "%s\t" "${_rownames[@]}"
#   _table["__numcols"]=$_numcols
    _table["__numrows"]=$_numrows
}




###############################################################################
# LEVEL 2 FUNCTIONS
#   Functions take namerefs as arguments and pass the nameref to a level 1 fcn.
#   All local variables are prefixed with '__', therefore passing a nameref arg
#   of the format '__NAME' may cause errors.
###############################################################################


function table_set() {
    local -n __table=$1;    require_table $1
    local __rowname="$2";   [[ "$2" == "" ]] && return 1
    local __colname="$3";   [[ "$3" == "" ]] && return 1
    local __val="$4"

    # Append a new row and column if needed
    table_append_col __table "$__colname"
    table_append_row __table "$__rowname"

    # Add value to table
    local __key="$__rowname"$'\t'"$__colname"
    __table["$__key"]="$__val"
}


function table_set_col() {
    local -n __table=$1;    require_table $1
    local __colname="$2";   [[ "$2" == "" ]] && return 1
    local __rowname
    local -n __vals=$3;     local __vartype; get_type __vals __vartype

    local IFS=$'\t' __name
#   local -a __colnames=(); for __name in ${__table[__colnames]}; do __colnames+=("$__name"); done
    local -a __rownames=(); for __name in ${__table[__rownames]}; do __rownames+=("$__name"); done
#   local __numcols="${__table[__numcols]}"
#   local __numrows="${__table[__numrows]}"
    IFS=$' '

    table_append_col __table "$__colname"   # append a new column if needed
#   table_append_row __table "$__rowname"   # append a new row if needed

    # Add all values to table
    local __key __row __col __val 
    for __row in "${!__vals[@]}"; do
#   for __col in "${!__vals[@]}"; do
        __val="${__vals[$__row]}"
#       __val="${__vals[$__col]}"

        if [[ $__vartype == a ]]; then
            __rowname="${__rownames[$__row]}"
#           __colname="${__colnames[$__col]}"
            [[ "$__rowname" == "" ]] && continue   # skip if invalid numeric index _row
#           [[ "$__colname" == "" ]] && continue   # skip if invalid numeric index _col
        else
            __rowname="$__row"
#           __colname="$__col"
            table_append_row __table "$__rowname"  # append a new row if necessary
#           table_append_col __table "$__colname"  # append a new column if necessary
        fi

        __key="$__rowname"$'\t'"$__colname"
        __table["$__key"]="$__val"
    done

#   printf -v __table["__colnames"] "%s\t" "${__colnames[@]}"
#   printf -v __table["__rownames"] "%s\t" "${__rownames[@]}"
#   __table["__numcols"]=$__numcols
#   __table["__numrows"]=$__numrows
}


function table_set_row() {
    local -n __table=$1;    require_table $1
    local __rowname="$2";   [[ "$2" == "" ]] && return 1
    local __colname
    local -n __vals=$3;     local __vartype; get_type __vals __vartype

    local IFS=$'\t' __name
    local -a __colnames=(); for __name in ${__table[__colnames]}; do __colnames+=("$__name"); done
#   local -a __rownames=(); for __name in ${__table[__rownames]}; do __rownames+=("$__name"); done
#   local __numcols="${__table[__numcols]}"
#   local __numrows="${__table[__numrows]}"
    IFS=$' '

#   table_append_col __table "$__colname"   # append a new column if needed
    table_append_row __table "$__rowname"   # append a new row if needed

    # Add all values to table
    local __key __row __col __val 
#   for __row in "${!__vals[@]}"; do
    for __col in "${!__vals[@]}"; do
#       __val="${__vals[$__row]}"
        __val="${__vals[$__col]}"

        if [[ $__vartype == a ]]; then
#           __rowname="${__rownames[$__row]}"
            __colname="${__colnames[$__col]}"
#           [[ "$__rowname" == "" ]] && continue   # skip if invalid numeric index _row
            [[ "$__colname" == "" ]] && continue   # skip if invalid numeric index _col
        else
#           __rowname="$__row"
            __colname="$__col"
#           table_append_row __table "$__rowname"  # append a new row if necessary
            table_append_col __table "$__colname"  # append a new column if necessary
        fi

        __key="$__rowname"$'\t'"$__colname"
        __table["$__key"]="$__val"
    done

#   printf -v __table["__colnames"] "%s\t" "${__colnames[@]}"
#   printf -v __table["__rownames"] "%s\t" "${__rownames[@]}"
#   __table["__numcols"]=$__numcols
#   __table["__numrows"]=$__numrows
}


#   newnames    - Name of an array containing names to replace the old column names.
#                 If newnames is an indexable array, the first N columns are renamed to newnames.
#                 If newnames is an associative array, the format should be:
#                   newnames=( ["oldname"]="newname" ... )
#                 and only the columns specified by the keys are renamed.
#
function table_rename_cols() {
    local -n __table=$1;        require_table $1
    local -n __newnames=$2;     local __vartype; get_type $2 __vartype

    local IFS=$'\t' __name
    local -a __colnames=(); for __name in ${__table[__colnames]}; do __colnames+=("$__name"); done
#   local -a __rownames=(); for __name in ${__table[__rownames]}; do __rownames+=("$__name"); done
#   local __numcols="${__table[__numcols]}"
#   local __numrows="${__table[__numrows]}"
    IFS=$' '

    local __key __oldname __newname
    for __key in "${!__newnames[@]}"; do
        __newname="${__newnames[$__key]}"
        [[ $__vartype == A ]] && __oldname="$__key" || __oldname="${__colnames[$__key]}"
#       [[ $__vartype == A ]] && __oldname="$__key" || __oldname="${__rownames[$__key]}"
        table_rename_col __table "$__oldname" "$__newname"
#       table_rename_row __table "$__oldname" "$__newname"
    done

#   printf -v __table["__colnames"] "%s\t" "${__colnames[@]}"
#   printf -v __table["__rownames"] "%s\t" "${__rownames[@]}"
#   __table["__numcols"]=$__numcols
#   __table["__numrows"]=$__numrows
}


#   newnames    - Name of an array containing names to replace the old row names.
#                 If newnames is an indexable array, the first N rows are renamed to newnames.
#                 If newnames is an associative array, the format should be:
#                   newnames=( ["oldname"]="newname" ... )
#                 and only the rows specified by the keys are renamed.
#
function table_rename_rows() {
    local -n __table=$1;        require_table $1
    local -n __newnames=$2;     local __vartype; get_type $2 __vartype

    local IFS=$'\t' __name
#   local -a __colnames=(); for __name in ${__table[__colnames]}; do __colnames+=("$__name"); done
    local -a __rownames=(); for __name in ${__table[__rownames]}; do __rownames+=("$__name"); done
#   local __numcols="${__table[__numcols]}"
#   local __numrows="${__table[__numrows]}"
    IFS=$' '

    local __key __oldname __newname
    for __key in "${!__newnames[@]}"; do
        __newname="${__newnames[$__key]}"
#       [[ $__vartype == A ]] && __oldname="$__key" || __oldname="${__colnames[$__key]}"
        [[ $__vartype == A ]] && __oldname="$__key" || __oldname="${__rownames[$__key]}"
#       table_rename_col __table "$__oldname" "$__newname"
        table_rename_row __table "$__oldname" "$__newname"
    done

#   printf -v __table["__colnames"] "%s\t" "${__colnames[@]}"
#   printf -v __table["__rownames"] "%s\t" "${__rownames[@]}"
#   __table["__numcols"]=$__numcols
#   __table["__numrows"]=$__numrows
}


function table_remove_cols() {
    local -n __table=$1;     require_table $1
    local -n __remnames=$2

    local __remname
    for __remname in "${__remnames[@]}"; do
        table_remove_col __table "$__remname"
    done
}


function table_remove_rows() {
    local -n __table=$1;     require_table $1
    local -n __remnames=$2

    local __remname
    for __remname in "${__remnames[@]}"; do
        table_remove_row __table "$__remname"
    done
}



###############################################################################
# LEVEL 3 FUNCTIONS
#   Functions take namerefs as arguments and pass the nameref to a level 2 fcn.
#   All local variables are prefixed with '___', therefore passing a nameref
#   arg of the format '___NAME' may cause errors.
###############################################################################


function table_get_cols() {
    local -n ___table=$1;     require_table $1
    local -n ___colnames=$2
    local -n ___newtable=$3;  table_create ___newtable


    local ___colname
    local -A ___col
    for ___colname in "${___colnames[@]}"; do
        ___col=()
        table_get_col ___table "$___colname" ___col
        table_set_col ___newtable "$___colname" ___col   
    done
}


function table_get_rows() {
    local -n ___table=$1;     require_table $1
    local -n ___rownames=$2
    local -n ___newtable=$3;  table_create ___newtable


    local ___rowname
    local -A ___row
    for ___rowname in "${___rownames[@]}"; do
        ___row=()
        table_get_row ___table "$___rowname" ___row
        table_set_row ___newtable "$___rowname" ___row   
    done
}



#   neworder    - Name of an array containing a new ordering of column names.
#                 If neworder is an indexable array, columns are placed left-to-right in the specified new ordering.
#                 The format should be:
#                   neworder=( firstcolname secondcolname ... )
#                 If neworder is an associative array, keys and values are both column names, and Values are inserted before Keys.
#                 The format should be:
#                   neworder=( ["insertbeforethiscolname"]="colname" ... )
#
function table_reorder_cols() {
    local -n ___table=$1;        require_table $1
    local -n ___neworder=$2;     local ___vartype; get_type $2 ___vartype

    local IFS=$'\t' ___name
    local -a ___colnames=(); for ___name in ${___table[__colnames]}; do ___colnames+=("$___name"); done
#   local -a ___rownames=(); for ___name in ${___table[__rownames]}; do ___rownames+=("$___name"); done
#   local ___numcols="${___table[__numcols]}"
#   local ___numrows="${___table[__numrows]}"
    IFS=$' '

    local ___key ___name ___oldidx ___newidx
    local -a ___newnames=()
    if [[ $___vartype == a ]]; then
        for ___key in "${!___neworder[@]}"; do
            ___name="${___neworder[$___key]}"
            find_value ___colnames "$___name" ___oldidx && unset -v "___colnames[$___oldidx]" || continue    # skip if invalid name
#           find_value ___rownames "$___name" ___oldidx && unset -v "___rownames[$___oldidx]" || continue    # skip if invalid name
            ___newnames+=( "$___name" )
        done
        ___colnames=( "${___newnames[@]}" "${___colnames[@]}" )
#       ___rownames=( "${___newnames[@]}" "${___rownames[@]}" )

    else
        for ___key in "${!___neworder[@]}"; do
            ___name="${___neworder[$___key]}"
            find_value ___colnames "$___name" ___oldidx && unset -v "___colnames[$___oldidx]" || continue    # skip if invalid name
#           find_value ___rownames "$___name" ___oldidx && unset -v "___rownames[$___oldidx]" || continue    # skip if invalid name
            find_value ___colnames "$___key" ___newidx || ___newidx="$___oldidx"  # if key is invalid name, put the name back where you found it
#           find_value ___rownames "$___key" ___newidx || ___newidx="$___oldidx"  # if key is invalid name, put the name back where you found it
            insert_value ___colnames "$___newidx" "$___name"
#           insert_value ___rownames "$___newidx" "$___name"
        done
    fi

    printf -v ___table["__colnames"] "%s\t" "${___colnames[@]}"
#   printf -v ___table["__rownames"] "%s\t" "${___rownames[@]}"
#   ___table["__numcols"]=$___numcols
#   ___table["__numrows"]=$___numrows
}


#   neworder    - Name of an array containing a new ordering of row names.
#                 If neworder is an indexable array, rows are placed left-to-right in the specified new ordering.
#                 The format should be:
#                   neworder=( firstrowname secondrowname ... )
#                 If neworder is an associative array, keys and values are both row names, and Values are inserted before Keys.
#                 The format should be:
#                   neworder=( ["insertbeforethisrowname"]="rowname" ... )
#
function table_reorder_rows() {
    local -n ___table=$1;        require_table $1
    local -n ___neworder=$2;     local ___vartype; get_type $2 ___vartype

    local IFS=$'\t' ___name
#   local -a ___colnames=(); for ___name in ${___table[__colnames]}; do ___colnames+=("$___name"); done
    local -a ___rownames=(); for ___name in ${___table[__rownames]}; do ___rownames+=("$___name"); done
#   local ___numcols="${___table[__numcols]}"
#   local ___numrows="${___table[__numrows]}"
    IFS=$' '

    local ___key ___name ___oldidx ___newidx
    local -a ___newnames=()
    if [[ $___vartype == a ]]; then
        for ___key in "${!___neworder[@]}"; do
            ___name="${___neworder[$___key]}"
#           find_value ___colnames "$___name" ___oldidx && unset -v "___colnames[$___oldidx]" || continue    # skip if invalid name
            find_value ___rownames "$___name" ___oldidx && unset -v "___rownames[$___oldidx]" || continue    # skip if invalid name
            ___newnames+=( "$___name" )
        done
#       ___colnames=( "${___newnames[@]}" "${___colnames[@]}" )
        ___rownames=( "${___newnames[@]}" "${___rownames[@]}" )

    else
        for ___key in "${!___neworder[@]}"; do
            ___name="${___neworder[$___key]}"
#           find_value ___colnames "$___name" ___oldidx && unset -v "___colnames[$___oldidx]" || continue    # skip if invalid name
            find_value ___rownames "$___name" ___oldidx && unset -v "___rownames[$___oldidx]" || continue    # skip if invalid name
#           find_value ___colnames "$___key" ___newidx || ___newidx="$___oldidx"  # if key is invalid name, put the name back where you found it
            find_value ___rownames "$___key" ___newidx || ___newidx="$___oldidx"  # if key is invalid name, put the name back where you found it
#           insert_value ___colnames "$___newidx" "$___name"
            insert_value ___rownames "$___newidx" "$___name"
        done
    fi

#   printf -v ___table["__colnames"] "%s\t" "${___colnames[@]}"
    printf -v ___table["__rownames"] "%s\t" "${___rownames[@]}"
#   ___table["__numcols"]=$___numcols
#   ___table["__numrows"]=$___numrows
}





#####################################################################################################

__COMMON_TABLES_AVAILABLE="$TRUE"
