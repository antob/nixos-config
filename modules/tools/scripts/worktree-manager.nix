{ pkgs, ... }:

pkgs.writeShellScriptBin "wt" ''
  #!/bin/bash

  # Git Worktree Manager
  # Handles creating, listing, switching, and cleaning up Git worktrees

  set -e

  # Colors for output
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color

  # Get repo root
  GIT_ROOT=$(git rev-parse --show-toplevel)
  WORKTREE_DIR="$GIT_ROOT/.worktrees"

  # Add a new worktree
  add_worktree() {
    local wt_name="''$1"
    local from_branch="''${2:-$1}"

    if [[ -z "$wt_name" ]]; then
      echo -e "''${RED}Error: Worktree name required''${NC}"
      exit 1
    fi

    local worktree_path="$WORKTREE_DIR/$wt_name"

    # Check if worktree already exists
    if [[ -d "$worktree_path" ]]; then
      echo -e "''${YELLOW}Worktree already exists at: $worktree_path''${NC}"
      echo -e "Switch to it instead? (y/n)"
      read -r response
      if [[ "$response" == "y" ]]; then
        switch_worktree "$wt_name"
      fi
      return
    fi

    echo -e "''${BLUE}Creating worktree: $wt_name''${NC}"
    echo "  From: $from_branch"
    echo "  Path: $worktree_path"

    # Add worktree
    mkdir -p "$WORKTREE_DIR"

    echo -e "''${BLUE}Creating worktree...''${NC}"
    if git show-ref --verify --quiet "refs/heads/$wt_name"; then
      echo -e "''${YELLOW}Branch '$wt_name' already exists, using it directly''${NC}"
      git worktree add "$worktree_path" "$wt_name"
    else
      git worktree add -b "$wt_name" "$worktree_path" "$from_branch"
    fi

    echo -e "''${GREEN}✓ Worktree added successfully!''${NC}"
    echo ""
    echo "To switch to this worktree:"
    echo -e "''${BLUE}cd $worktree_path''${NC}"
    echo ""
  }

  # List all worktrees
  list_worktrees() {
    echo -e "''${BLUE}Available worktrees:''${NC}"
    echo ""

    if [[ ! -d "$WORKTREE_DIR" ]]; then
      echo -e "''${YELLOW}No worktrees found''${NC}"
      return
    fi

    local count=0
    for worktree_path in "$WORKTREE_DIR"/*; do
      if [[ -d "$worktree_path" && -e "$worktree_path/.git" ]]; then
        count=$((count + 1))
        local worktree_name=$(basename "$worktree_path")
        local branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

        if [[ "$PWD" == "$worktree_path" ]]; then
          echo -e "''${GREEN}✓ $worktree_name''${NC} (current) → branch: $branch"
        else
          echo -e "  $worktree_name → branch: $branch"
        fi
      fi
    done

    if [[ $count -eq 0 ]]; then
      echo -e "''${YELLOW}No worktrees found''${NC}"
    else
      echo ""
      echo -e "''${BLUE}Total: $count worktree(s)''${NC}"
    fi

    echo ""
    echo -e "''${BLUE}Main repository:''${NC}"
    local main_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    echo "  Branch: $main_branch"
    echo "  Path: $GIT_ROOT"
  }

  # Switch to a worktree
  switch_worktree() {
    local worktree_name="$1"

    if [[ -z "$worktree_name" ]]; then
      list_worktrees
      echo -e "''${BLUE}Switch to which worktree? (enter name)''${NC}"
      read -r worktree_name
    fi

    local worktree_path="$WORKTREE_DIR/$worktree_name"

    if [[ ! -d "$worktree_path" ]]; then
      echo -e "''${RED}Error: Worktree not found: $worktree_name''${NC}"
      echo ""
      list_worktrees
      exit 1
    fi

    echo -e "''${GREEN}Switching to worktree: $worktree_name''${NC}"
    cd "$worktree_path"
    echo -e "''${BLUE}Now in: $(pwd)''${NC}"
  }

  # Remove a single worktree
  remove_worktree() {
    local wt_name="$1"

    if [[ -z "$wt_name" ]]; then
      list_worktrees
      echo -e "''${BLUE}Remove which worktree? (enter name)''${NC}"
      read -r wt_name
    fi

    local worktree_path="$WORKTREE_DIR/$wt_name"

    if [[ ! -d "$worktree_path" ]]; then
      echo -e "''${RED}Error: Worktree not found: $wt_name''${NC}"
      exit 1
    fi

    if [[ "$PWD" == "$worktree_path" ]]; then
      echo -e "''${RED}Error: Cannot remove the currently active worktree''${NC}"
      exit 1
    fi

    echo -e "''${YELLOW}Remove worktree '$wt_name'? (y/n)''${NC}"
    read -r response
    if [[ "$response" != "y" ]]; then
      echo -e "''${YELLOW}Cancelled''${NC}"
      return
    fi

    git worktree remove "$worktree_path" --force

    # Clean up empty directory if nothing left
    if [[ -z "$(ls -A "$WORKTREE_DIR" 2>/dev/null)" ]]; then
      rmdir "$WORKTREE_DIR" 2>/dev/null || true
    fi

    echo -e "''${GREEN}✓ Removed: $wt_name''${NC}"
  }

  # Clean up completed worktrees
  cleanup_worktrees() {
    if [[ ! -d "$WORKTREE_DIR" ]]; then
      echo -e "''${YELLOW}No worktrees to clean up''${NC}"
      return
    fi

    echo -e "''${BLUE}Checking for completed worktrees...''${NC}"
    echo ""

    local found=0
    local to_remove=()

    for worktree_path in "$WORKTREE_DIR"/*; do
      if [[ -d "$worktree_path" && -e "$worktree_path/.git" ]]; then
        local worktree_name=$(basename "$worktree_path")

        # Skip if current worktree
        if [[ "$PWD" == "$worktree_path" ]]; then
          echo -e "''${YELLOW}(skip) $worktree_name - currently active''${NC}"
          continue
        fi

        found=$((found + 1))
        to_remove+=("$worktree_path")
        echo -e "''${YELLOW}• $worktree_name''${NC}"
      fi
    done

    if [[ $found -eq 0 ]]; then
      echo -e "''${GREEN}No inactive worktrees to clean up''${NC}"
      return
    fi

    echo ""
    echo -e "Remove $found worktree(s)? (y/n)"
    read -r response

    if [[ "$response" != "y" ]]; then
      echo -e "''${YELLOW}Cleanup cancelled''${NC}"
      return
    fi

    echo -e "''${BLUE}Cleaning up worktrees...''${NC}"
    for worktree_path in "''${to_remove[@]}"; do
      local worktree_name=$(basename "$worktree_path")
      git worktree remove "$worktree_path" --force 2>/dev/null || true
      echo -e "''${GREEN}✓ Removed: $worktree_name''${NC}"
    done

    # Clean up empty directory if nothing left
    if [[ -z "$(ls -A "$WORKTREE_DIR" 2>/dev/null)" ]]; then
      rmdir "$WORKTREE_DIR" 2>/dev/null || true
    fi

    echo -e "''${GREEN}Cleanup complete!''${NC}"
  }

  # Main command handler
  main() {
    local command="''${1:-list}"

    case "$command" in
      add)
        add_worktree "$2" "$3"
        ;;
      list|ls)
        list_worktrees
        ;;
      switch|go)
        switch_worktree "$2"
        ;;
      remove|rm)
        remove_worktree "$2"
        ;;
      cleanup|clean)
        cleanup_worktrees
        ;;
      help)
        show_help
        ;;
      *)
        echo -e "''${RED}Unknown command: $command''${NC}"
        echo ""
        show_help
        exit 1
        ;;
    esac
  }

  show_help() {
    cat << EOF
  Git Worktree Manager

  Usage: wt <command> [options]

  Commands:
    add <worktree-name> [from-branch] Add new worktree
                                      (from-branch defaults to worktree-name)
    list | ls                         List all worktrees
    switch | go [name]                Switch to worktree
    remove | rm <name>                Remove a worktree
    cleanup | clean                   Clean up inactive worktrees
    help                              Show this help message

  Examples:
    wt add feature-login
    wt add feature-auth develop
    wt switch feature-login
    wt remove feature-login
    wt cleanup
    wt list

  EOF
  }

  # Run
  main "$@"
''
