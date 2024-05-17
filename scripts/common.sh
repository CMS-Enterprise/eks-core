# Souce this in other scripts to get common utility function

# Set logging functions for colored output
red() { echo -e "\033[0;31m${*}\033[0m"; } >&2
green() { echo -e "\033[0;32m${*}\033[0m"; } >&2
yellow() { echo -e "\033[0;33m${*}\033[0m"; } >&2
