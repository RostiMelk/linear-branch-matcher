function setLinearTitleAsPS1() {
    # Function to check if a directory is a Git repository
    function isGitRepo() {
        git rev-parse --is-inside-work-tree &>/dev/null
        return $?
    }

    # Function to retrieve the current branch name
    function getCurrentBranch() {
        git symbolic-ref --short HEAD 2>/dev/null
    }

    # Function to match branch name with Linear issue
    function matchBranchtoLinear() {
        local branch=$1
        local formattedBranch=$(getLinearIdFromBranchName "$branch")
        if [ -z "$formattedBranch" ]; then
            return
        fi

        local linearApiKey="$LINEAR_API_KEY"
        local response=$(curl \
            -s \
            -X POST \
            -H "Content-Type: application/json" \
            -H "Authorization: $linearApiKey" \
            --data '{ "query": "{ issue(id: \"'$formattedBranch'\") { title url } }" }' \
            https://api.linear.app/graphql)

        local linearTitle=$(echo "$response" | jq -r '.data.issue.title' | sed 's/`//g')
        local linearUrl=$(echo "$response" | jq -r '.data.issue.url')

        if [ -z "$linearTitle" ] || [ -z "$linearUrl" ]; then
            return
        fi

        if [ "$linearTitle" = "null" ] || [ "$linearUrl" = "null" ]; then
            return
        fi

        # Create hyperlink
        # local hyperlink='\e]8;;'"$linearUrl"'\e\\'"$linearTitle"'\e]8;;\e\\'
        # For some reason invisible characters are added to the prompt when using the above, using plain text for now
        local hyperlink="$linearTitle"
        echo "$hyperlink"
    }

    function getLinearIdFromBranchName() {
        local branch=$1
        local pattern="\b[A-Za-z]{3,4}-[0-9]+\b"
        local matches=$(echo "$branch" | grep -oE "$pattern")
        echo "$matches"
    }

    # Read the API key from environment variable
    if [ -z "$LINEAR_API_KEY" ]; then
        echo "Please set the LINEAR_API_KEY environment variable with your Linear API key."
        echo "Example: export LINEAR_API_KEY=\"your_api_key_here\""
        return
    fi

    if ! isGitRepo; then
        # Unset linearTitle and restore original PS1
        unset linearTitle
        export PS1="$originalPS1"
        return
    fi

    local branch=$(getCurrentBranch)
    if [ -z "$branch" ]; then
        # Unset linearTitle and restore original PS1
        unset linearTitle
        export PS1="$originalPS1"
        return
    fi

    # Check if the branch has changed
    if [ "$branch" != "$lastBranch" ]; then
        local linearHyperlink=$(matchBranchtoLinear "$branch")
        if [ -z "$linearHyperlink" ]; then
            # Unset linearTitle and restore original PS1
            unset linearTitle
            export PS1="$originalPS1"
            return
        fi
        # Cache the result
        cachedLinearHyperlink="$linearHyperlink"
        lastBranch="$branch"
    else
        # Use cached result
        linearHyperlink="$cachedLinearHyperlink"
    fi

    purple=$(tput setaf 171)
    reset=$(tput sgr0)

    export PS1="$originalPS1${purple}$linearHyperlink${reset} "
}

originalPS1=$PS1
lastBranch=""
cachedLinearHyperlink=""

# Function to update prompt when branch changes
function updatePrompt() {
    setLinearTitleAsPS1
}

# For zsh, we should use precmd hook properly
precmd() {
    setLinearTitleAsPS1
}

# Set the initial prompt
setLinearTitleAsPS1

# Set the updatePrompt function as the precmd hook
precmd_functions+=(updatePrompt)
