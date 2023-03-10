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
LOADER_TEMPLATE_VERSION="1.1"
LOADER_SCRIPT_PATH="$(readlink -f "$0")"
LOADER_DIR="$(dirname "$LOADER_SCRIPT_PATH")"


###############################################################################
####                         VARIABLE DEFINITIONS                          ####
###############################################################################

#   [required]
#       COMMON_SCRIPTS_DIR      Path to directory containing common-*.sh
#
COMMON_SCRIPTS_DIR="$__LOADER_DIR__/scripts/bash-common-scripts"


#   [required]
#       MODULE_PATHS            Array containing one or more paths. Each path string should be one of the following:
#                                 - Directories to search for MODULE.sh definition files
#                                 - Direct paths to MODULE.sh definition files
#
MODULE_PATHS=(
    "$__LOADER_DIR__/modules"
)
 

#   [required]
#       LOADER_TITLE            Title text to display in the menu header.
#       LOADER_DESCRIPTION      Description of loader. May contain multiple lines.
#
LOADER_TITLE="TODO: Add loader title here"
LOADER_DESCRIPTION=\
"TODO: Add loader description here."
 

#   [optional]
#       ****                    Define additional global variables in this section.
#                               These will be readable by all modules.
#       
# PROJECT_BIN_DIR="$LOADER_DIR/bin"
# PROJECT_CONFIG_DIR="$LOADER_DIR/config"
# PROJECT_SCRIPTS_DIR="$LOADER_DIR/scripts"


#   [optional]
#       ARGSPEC                 Associative array in which:
#                                 ["keys"] are command-line flags (taking one positional argument after each), with
#                                 "values", which are the default values of the arguments if not specified.
#                               ARGSPEC overrides default values of __ARGS__ where both have the same keys.
#
# declare -A ARGSPEC=(
#     ["install"]=""
#     ["force"]="false"
#     ["allowroot"]="false"
#     ["logfile"]="$LOADER_DIR/nxt-tools.log"
#     ["prefix"]="/usr/local"
# )


#   [optional]
#       ARGS_HELP_TEXT          Multiline string containing argument usage help.
#                               ARGS_HELP_TEXT overrides __DEFAULT_ARGS_HELP_TEXT__ if nonempty.
#
# ARGS_HELP_TEXT=\
# "TODO: Usage help text here."


#   [optional]
#       MENU_COMMANDS           Associative array in which:
#                                 ["keys"] are user input keywords, corresponding to
#                                 "values", which are executable commands.
#                               MENU_COMMANDS overrides __MENU_COMMANDS__ where both have the same keys.
#
# declare -A MENU_COMMANDS=(
#   ["userinput"]="echo 'Command to run'"
# )


###############################################################################
#   Do not edit this section!
if ! source "$COMMON_SCRIPTS_DIR/common-installer.sh"; then
    echo "Error loading required source: $COMMON_SCRIPTS_DIR/common-installer.sh"
    echo "Please run:"
    echo "  git submodule update --init --recursive"
    echo ""
    exit 1
fi
loader_start

###############################################################################
