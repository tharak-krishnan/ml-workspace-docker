#!/bin/bash
set -e

# Activate the Python virtual environment
. /opt/venv/bin/activate

# Check if the first argument is a directory or file path
# If so, assume the user wants to open JupyterLab in that specific context
# Otherwise, default to the /workspace directory
if [ -d "$1" ] || [ -f "$1" ]; then
    # If $1 is a directory or file, pass all arguments ($@) to jupyter lab
    # This allows users to specify a notebook or sub-directory to open directly
    jupyter lab "$@"
else
    # If $1 is not a directory/file (or no arguments are given),
    # start jupyter lab in the default /workspace directory.
    # Any additional CMD arguments (like --ip, --port) are still passed via "$@".
    jupyter lab --notebook-dir=/workspace "$@"
fi

