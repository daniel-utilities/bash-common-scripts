#!/usr/bin/env bash

###############################################################################
####                       [common-installer loader]                       ####
###############################################################################
####                                                                       ####
####    In each [required] section below, modify the definitions to fit    ####
####    the application. Any [optional] sections may be omitted or blank.  ####
####                                                                       ####
###############################################################################
#   Do not edit this section!
__LOADER_TEMPLATE_VERSION__="1.0"
__LOADER_BASE_NAME__="$(basename -s .sh "$0")"


###############################################################################
####                         VARIABLE DEFINITIONS                          ####
###############################################################################

#   [optional]
#       ****                    Define additional global variables in this section.
#                               These will be made readable (but not writeable) by all modules.
#       
PROJECT_ROOT="$(dirname "$(readlink -f "$0")")" # Directory containing this script
PROJECT_BIN="$PROJECT_ROOT/bin"
PROJECT_CONFIG="$PROJECT_ROOT/config"
PROJECT_MODULES="$PROJECT_ROOT/modules"
PROJECT_SCRIPTS="$PROJECT_ROOT/scripts"


#   [required]
#       COMMON_SCRIPTS_PATH     Path to directory containing common-*.sh
#
COMMON_SCRIPTS_PATH="$PROJECT_SCRIPTS/bash-common-scripts"


#   [required]
#       MODULE_PATHS            Array containing one or more paths. Each path string should be one of the following:
#                                 - Directories to search for MODULE.sh definition files
#                                 - Direct paths to MODULE.sh definition files
#
MODULE_PATHS=(
    "$PROJECT_MODULES"
)
 

#   [required]
#       MENU_TITLE              Title text to display in the menu header.
#       MENU_DESCRIPTION        Description of loader. May contain multiple lines.
#       MENU_PROMPT             User input prompt. May contain multiple lines.
#
MENU_TITLE="TODO: Add title here"
MENU_DESCRIPTION=\
"TODO: Add description here.
> Enter a module name to learn more. The system will not be modified without your permission.
> Enter 'help' to list all valid internal commands.
> Press CTRL+C to abort the script at any time."
MENU_PROMPT="Enter module names or commands, or type 'x' to exit:"
 

#   [optional]
#       CUSTOM_MENU_COMMANDS    Associative array in which:
#                                 ["keys"] are user input keywords, corresponding to
#                                 "values", which are executable commands.
#                               CUSTOM_MENU_COMMANDS overrides __DEFAULT_MENU_COMMANDS__ where both have the same keys.
#
declare -A CUSTOM_MENU_COMMANDS=(
    ["example"]='echo "When the user types \"example\" at the menu, this command runs."'
)


#   [optional]
#       CUSTOM_ARGS             Associative array in which:
#                                 ["keys"] are command-line flags (taking one positional argument after each), with
#                                 "values", which are the default values of the arguments if not specified.
#                               CUSTOM_ARGS overrides __DEFAULT_ARGS__ where both have the same keys.
#
declare -A CUSTOM_ARGS=(
    ["logfile"]="$PROJECT_ROOT/my-default-logfile-name.log"
)


#   [optional]
#       CUSTOM_ARGS_HELP_TEXT   Multiline string containing argument usage help.
#
CUSTOM_ARGS_HELP_TEXT=\
""


###############################################################################
#   Do not edit this section!
source "$COMMON_SCRIPTS_PATH/common-installer.sh"
if [[ "$?" -ne 0 ]]; then
    echo "Error loading required source: $COMMON_SCRIPTS_PATH/common-installer.sh"
    echo "Please run:"
    echo "  git submodule update --init --recursive"
    echo ""
    exit 1
fi
loader_start "$@"

###############################################################################
