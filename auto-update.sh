#!/bin/bash

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a package is outdated
is_outdated() {
    local package="$1"
    local latest_version="$(npm show "$package" version 2>/dev/null)"
    local current_version="$(npm list --depth=0 "$package" 2>/dev/null | grep "$package@" | awk -F@ '{print $NF}')"

    if [[ "$latest_version" != "$current_version" ]]; then
        return 0 # Package is outdated
    else
        return 1 # Package is up-to-date
    fi
}

# Check if the current directory is a Git repository
if [ ! -d .git ]; then
    echo -e "${RED}Error: This script must be run within a Git repository.${NC}" >&2
    exit 1
fi

# Function to update a dependency and create a new commit
update_dependency() {
    local dependency="$1"

    # Check if the specified dependency is outdated
    if is_outdated "$dependency"; then
        # Get the current and latest versions of the package
        local current_version=$(npm list --depth=0 "$dependency" 2>/dev/null | grep "$dependency@" | awk -F@ '{print $NF}')
        local latest_version=$(npm show "$dependency" version 2>/dev/null)

        # Update the specified dependency
        echo -e "Updating $dependency to the latest version..."
        npm install "$dependency"

        # Create a new commit
        git add "package.json"
        git commit -m "Update $dependency to latest version" -m "from $current_version to $latest_version"

        # Display a message indicating the update and commit are complete
        echo -e "${GREEN}$dependency${NC} updated to the latest version, and a new commit has been created!"
    else
        echo -e "${GREEN}$dependency${NC} is already up-to-date."
    fi
}

# Display the current outdated dependencies
echo -e "${YELLOW}Checking for outdated dependencies...${NC}"
npm outdated

# If a dependency name is provided as a command-line argument, use it; otherwise, prompt the user
if [ $# -eq 0 ]; then
    echo -e "\nEnter the name of the dependency to update: \c"
    read dependency_name

    # Verify that the input is not empty
    if [ -z "$dependency_name" ]; then
        echo -e "${RED}Invalid input. Please provide a dependency name.${NC}" >&2
        exit 1
    fi
else
    dependency_name="$1"
fi

# Update the specified dependency
update_dependency "$dependency_name"
