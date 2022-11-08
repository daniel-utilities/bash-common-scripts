# bash-common-scripts
This repo is intended to be used as a submodule in another project.
Provides a set of Bash functions which are generally useful, especially for system configuration and software installation tasks.

## Usage
After cloning the repo, run:
```
source bash-common-scripts/common-functions.sh
```
to pull the main function definitions into your script.

Function arguments are documented in `common-functions.sh` .
Call any function like:
```
func_name "arg1" "arg2" ...
```

If a function argument is listed as REF, this argument is pass-by-reference.
Use it by providing an unquoted variable name. The variable may be modified once the function returns.
```
func_name MY_VAR
```

If a function returns data on stdout, capture the output using a Subshell or pipe its output to another process:
```
MY_VAR="$(func_name "arg1" "arg2" ... )"
func_name "arg1" > file.txt
```

In addition to stdout, a function might return data through its exit code:
```
func_name ...
EXIT_CODE=$?
```

The exit code can be used directly in an `if` statement. This is especially useful for boolean functions:
```
if is_root; then
  ...
fi
```

## WSL Functions
An additional file, `wsl-functions.sh` is available with specialized utilities for use on a WSL-2 installation.
You must source both `common-functions.sh` and `wsl-functions.sh`, in that order.
