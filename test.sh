#!/bin/bash
source common-functions.sh
source wsl-functions.sh

declare -a months=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
declare -a arr1=($'elem1' $'elem2' $'elem3' $'elem4' $'elem5')
declare -a arr2=($'  elem1  ' $'  elem2  ' $'  elem3  ' $'  elem4  ' $'  elem5  ')
declare -a arr3=($'\telem1\t' $'\telem2\t' $'\telem3\t' $'\telem4\t' $'\telem5\t')
declare -a arr4=($'\nelem1\n' $'\nelem2\n' $'\nelem3\n' $'\nelem4\n' $'\nelem4\n')
declare -a arr5=($'' $'' $'' $'' $'')
declare -a arr6=($'  ' $'  ' $'  ' $'  ' $'  ')
declare -a arr7=($'\t' $'\t' $'\t' $'\t' $'\t')
declare -a arr8=($'\n' $'\n' $'\n' $'\n' $'\n')

declare str1=$'elem1 elem2 elem3 elem4 elem5';                  sep1=$' '
declare str2=$'  elem1    elem2    elem3    elem4    elem5  ';  sep2=$' '
declare str3=$'\telem1\t\telem2\t\telem3\t\telem4\t\telem5\t';  sep3=$'\t'
declare str4=$'\nelem1\n\nelem2\n\nelem3\n\nelem4\n\nelem4\n';  sep4=$'\n'
declare str5=$''          ; sep5=$' '
declare str6=$'          '; sep6=$' '
declare str7=$'\t\t\t\t\t'; sep7=$' '
declare str8=$'\n\n\n\n\n'; sep8=$''

clear

# arr_to_str
if false; then
    pass=0
    tests=8
    for i in {1..8}; do
        printf "\n************************************\n"
        funcname="arr_to_str"
        varname="arr$i"
        declare -n var=${varname}

        printf "\n$varname (original):\n"
        print_arr var

        printf "\n$funcname $varname ' ' str\n"
            str1=""
            $funcname var ' ' str1
        printf "str: \"$str1\"\n"

        printf "\nstr=\"\$($funcname $varname ' ')\"\n"
            str2="$($funcname var ' ')"
        printf "str: \"$str2\"\n"

        if [[ "$str1" == "$str2" ]]; then printf "\nTEST: PASS\n"; ((pass++))
        else                              printf "\nTEST: FAIL\n"
        fi
    done
    printf "\n************************************\n"
    printf "\nSUCCESS: $pass/$tests\n"
fi

# str_to_arr
if false; then
    pass=0
    tests=8
    for i in {1..8}; do
        printf "\n************************************\n"
        funcname="str_to_arr"
        varname="str$i"
        declare -n var=${varname}
        delimname="sep$i"
        declare -n delim=${delimname}

        printf "$varname: \"$var\"\n"
        printf "delim:\n"
        print_octal "$delim"

        printf "\n$funcname arr \"\$delim\" $varname\n"
            arr1=()
            $funcname arr1 "$delim" var
        printf "\narr:\n"
        print_arr arr1

        printf "\n$funcname arr \"\$delim\" < <(printf \"\$$varname\")\n"
            arr2=()
            $funcname arr2 "$delim" < <(printf "$var")
        printf "\narr:\n"
        print_arr arr2

        if arrays_are_equal arr1 arr2; then printf "\nTEST: PASS\n"; ((pass++))
        else                                printf "\nTEST: FAIL\n"
        fi
    done
    printf "\n************************************\n"
    printf "\nSUCCESS: $pass/$tests\n"
fi


# trim
if false; then
    pass=0
    tests=8
    for i in {1..8}; do
        printf "\n************************************\n"
        funcname="trim"
        varname="str$i"
        declare -n var=${varname}

        printf "$varname: \"$var\"\n"

        printf "\n$funcname $varname\n"
            trimmed1="$var"
            $funcname trimmed1
        printf "$varname: \"$trimmed1\"\n"

        printf "\n$varname=\"\$($funcname < <(printf \"\$$varname\") )\n"
            trimmed2="$var"
            trimmed2="$($funcname < <(printf "$trimmed2") )"
        printf "$varname: \"$trimmed2\"\n"

        if [[ "$trimmed1" == "$trimmed2" ]]; then printf "\nTEST: PASS\n"; ((pass++))
        else                                      printf "\nTEST: FAIL\n"
        fi
    done
    printf "\n************************************\n"
    printf "\nSUCCESS: $pass/$tests\n"
fi


# operate_on_each
if true; then
    pass=0
    tests=4
    for i in {1..4}; do
        printf "\n"
        printf "************************************\n"
        printf "Test $i\n"
        printf "************************************\n"
        arrname="arr$i"
        declare -n arr=${arrname}
        sep=$' '
        str=; arr_to_str arr ' ' str

        printf "\n"
        printf "arr (original):\n"
        print_arr arr
        printf "\n"
        printf "str (original):\n\"$str\"\n"

        printf "\n"
        printf "Operation:\n"
        printf "operate_on_each 'trim REF' \"tokenize=array\" arr\n"
            _arr1=("${arr[@]}")
            operate_on_each 'trim REF' tokenize=array _arr1
        printf "\n"
        printf "arr (modified):\n"
        print_arr _arr1

        printf "\n"
        printf "Operation:\n"
        printf "operate_on_each 'trim REF' \"tokenize=string\" str ' '  ' '\n"
        printf "str_to_arr arr ' ' str\n"
            _str="$str"
            operate_on_each 'trim REF' tokenize=string _str "$sep" "$sep"
            _arr2=()
            str_to_arr _arr2 "$sep" _str
        printf "\n"
        printf "str (modified):\n\"$_str\"\n"
        printf "\n"
        printf "arr (modified):\n"
        print_arr _arr2

        printf "\n"
        printf "Operation:\n"
        printf "str=\"\$(operate_on_each 'trim REF' tokenize=stdin ' '  ' ' < <(printf \"\$str\") )\"\n"
        printf "str_to_arr arr ' ' str\n"
            _str="$str"
            _str="$(operate_on_each 'trim REF' tokenize=stdin "$sep" "$sep" < <(printf "$_str") )"
            _arr3=()
            str_to_arr _arr3 "$sep" _str
        printf "\n"
        printf "str (modified):\n\"$_str\"\n"
        printf "\n"
        printf "arr (modified):\n"
        print_arr _arr3

        printf "\n"
        if arrays_are_equal _arr1 _arr2 && arrays_are_equal _arr1 _arr3; then
            printf "TEST: PASS\n"
            ((pass++))
        else
            printf "TEST: FAIL\n"
        fi
    done
    printf "\n************************************\n"
    printf "\nSUCCESS: $pass/$tests\n"
fi

