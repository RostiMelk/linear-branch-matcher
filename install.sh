#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check the operating system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  OS="mac"
else
  echo "Unsupported operating system. Please install manually."
  exit 1
fi

# Check the shell type
if command_exists bash; then
  SHELL_TYPE="bash"
elif command_exists fish; then
  SHELL_TYPE="fish"
elif command_exists zsh; then
  SHELL_TYPE="zsh"
else
  echo "Unsupported shell. Please install manually."
  exit 1
fi

# Install required dependencies based on the operating system
echo "Installing dependencies..."
if [[ "$OS" == "linux" ]]; then
  sudo apt-get update
  sudo apt-get install -y curl jq
elif [[ "$OS" == "mac" ]]; then
  brew update > /dev/null
  brew install curl jq --quiet > /dev/null
fi

# Set up the Linear Branch Matcher script
echo "Setting up the Linear Branch Matcher script..."

# Download the script and source it in the shell
url="https://raw.githubusercontent.com/RostiMelk/linear-branch-matcher/master/linear-branch-matcher.sh"
mkdir -p ~/.linear-branch-matcher
curl -s "$url" > ~/.linear-branch-matcher/linear-branch-matcher.sh
echo "Checking for old version"

# Add the script to the shell
if [[ "$SHELL" == *"bash"* ]]; then
  if  grep -q "linear-branch-matcher.sh" ~/.bashrc; then
    echo "Script already in bashrc"
  else
    echo "Adding the script to the bash shell..."
    echo "source ~/.linear-branch-matcher/linear-branch-matcher.sh" >> ~/.bashrc
  fi
elif [[ "$SHELL" == *"fish"* ]]; then
  if grep -q "linear-branch-matcher.sh" ~/.config/fish/config.fish; then
    echo "Script already in fish config"
  else
    echo "Adding the script to the fish shell..."
    echo "source ~/.linear-branch-matcher/linear-branch-matcher.sh" >> ~/.config/fish/config.fish
  fi
elif [[ "$SHELL" == *"zsh"* ]]; then
  if grep -q "linear-branch-matcher.sh" ~/.zshrc; then
    echo "Script already in zshrc"
  else
    echo "Adding the script to the zsh shell..."
    echo "source ~/.linear-branch-matcher/linear-branch-matcher.sh" >> ~/.zshrc
  fi
fi

# Export the Linear API key
echo ""
echo "Installation complete. Linear Branch Matcher script is now set up!"
echo "Restart your shell to start using the script."
echo ""
echo "To add a Linear API key, add the following line to your shell configuration file (.zprofile, .bash_profile, etc.):"
echo "export LINEAR_API_KEY=\"your_api_key_here\""
echo "Find your API key here: https://linear.app/settings/api"