# internal helper (no description in help): prepend a directory to PATH unless it is already there
_path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;            # already there — do nothing
    *) PATH="$1:$PATH" ;;
  esac
}

# user scripts managed by chezmoi (app-check)
_path_prepend "$HOME/.local/bin"
