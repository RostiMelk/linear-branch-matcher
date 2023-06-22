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
            --data '{ "query": "{ issue(id: \"'$formattedBranch'\") { id title } }" }' \
            https://api.linear.app/graphql)

        local linearTitle=$(echo "$response" | jq -r '.data.issue.title')
        echo "$linearTitle"
    }


    function getLinearIdFromBranchName() {
        local branch=$1
        local pattern="\b[A-Za-z]{3}-[0-9]+\b"
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
        return
    fi

    local branch=$(getCurrentBranch)
    if [ -z "$branch" ]; then
        return
    fi

    local linearTitle=$(matchBranchtoLinear "$branch")
    if [ -z "$linearTitle" ]; then
        return
    fi

    purple=$(tput setaf 171)
    reset=$(tput sgr0)
    export PS1="$PS1${purple}\"$linearTitle\"${reset} "
}

# Function to update prompt when directory changes
function updatePrompt() {
    setLinearTitleAsPS1
}

# Set the initial prompt
setLinearTitleAsPS1

# Set the updatePrompt function as the chpwd hook
chpwd_functions+=(updatePrompt)