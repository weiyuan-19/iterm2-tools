#!/bin/sh
set -eu

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
usage() { printf '%s\n' 'Usage: ./install.sh [--test|--uninstall]'; }

[ "$#" -le 1 ] || { usage >&2; exit 2; }
mode=install
include_tests=false
case ${1-} in
    '') ;;
    --test) include_tests=true ;;
    --uninstall) mode=uninstall ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

# 1. Locate the source and destination directories.
[ ! -L "$0" ] || fail 'Run install.sh directly from the checkout, not through a symlink.'
repo=$(CDPATH= cd -P "$(dirname "$0")" && pwd -P)
source_dir=$repo/Scripts
target_dir=${ITERM2_SCRIPTS_DIR:-"$HOME/Library/Application Support/iTerm2/Scripts"}
while [ "$target_dir" != / ] && [ "${target_dir%/}" != "$target_dir" ]; do
    target_dir=${target_dir%/}
done
case $target_dir in
    /|*/./*|*/../*|*/.|*/..) fail 'Use an absolute Scripts path without . or .. components.' ;;
    /*) ;;
    *) fail 'ITERM2_SCRIPTS_DIR must be an absolute path.' ;;
esac
[ ! -L "$target_dir" ] || fail "Scripts must be a real directory: $target_dir"

# Resolve existing ancestors without creating anything during conflict checks.
parent=$target_dir
suffix=
while [ ! -d "$parent" ]; do
    [ ! -e "$parent" ] && [ ! -L "$parent" ] || fail "Not a directory: $parent"
    suffix=/$(basename "$parent")$suffix
    parent=$(dirname "$parent")
done
parent=$(CDPATH= cd -P "$parent" && pwd -P)
target_dir=${parent%/}$suffix
case $target_dir/ in
    /|"$source_dir/"*) fail 'The destination must be outside Scripts and cannot be /.' ;;
esac

is_our_link() (
    [ -L "$1" ] || exit 1
    relative=${1#"$target_dir/"}
    destination=$(readlink "$1")
    [ "$destination" = "$source_dir/$relative" ] && exit 0
    # Accept links created by the earlier repository-root layout.
    [ "${relative%/*}" = AutoLaunch ] && [ "$destination" = "$repo/${relative##*/}" ]
)

# 2. Visit .py files and links, skipping hidden entries and cache directories.
# Test scripts are opt-in for installation, but always eligible for uninstall.
# Subshells give each recursive call its own variables; directory links are skipped.
visit_scripts() (
    for path in "$1"/*; do
        [ "${path##*/}" != __pycache__ ] || continue
        if [ "$mode" = install ] && [ "$include_tests" = false ]; then
            case ${path#"$source_dir/"} in
                hello.py|AutoLaunch/logmenu_demo.py) continue ;;
            esac
        fi
        if [ -L "$path" ]; then
            :
        elif [ -d "$path" ]; then
            visit_scripts "$path" "$2"
            continue
        elif [ ! -f "$path" ]; then
            continue
        fi
        case $path in *.py) "$2" "$path" ;; esac
    done
)

# 3. Check every destination before installing any links.
check_script() (
    [ ! -L "$1" ] || exit 0
    target=$target_dir/${1#"$source_dir/"}
    parent=$(dirname "$target")
    while [ "$parent" != "$target_dir" ]; do
        [ ! -L "$parent" ] || fail "Refusing to write through a directory symlink: $parent"
        if [ -e "$parent" ] && [ ! -d "$parent" ]; then
            fail "Not a directory: $parent"
        fi
        parent=$(dirname "$parent")
    done
    if [ -e "$target" ] || [ -L "$target" ]; then
        is_our_link "$target" || fail "Refusing to overwrite: $target"
    fi
)

install_script() (
    [ ! -L "$1" ] || exit 0
    target=$target_dir/${1#"$source_dir/"}
    if [ -L "$target" ]; then
        if [ "$(readlink "$target")" = "$1" ]; then
            printf 'Already installed: %s\n' "$target"
            exit 0
        fi
        is_our_link "$target" || fail "Refusing to overwrite: $target"
        rm "$target"
    fi
    mkdir -p "$(dirname "$target")"
    ln -s "$1" "$target"
    printf 'Installed: %s -> %s\n' "$target" "$1"
)

uninstall_script() {
    if is_our_link "$1"; then
        rm "$1"
        printf 'Removed symlink: %s\n' "$1"
    fi
}

# 4. Install, or remove only this checkout's links (including dangling links).
if [ "$mode" = uninstall ]; then
    visit_scripts "$target_dir" uninstall_script
else
    [ -d "$source_dir" ] && [ ! -L "$source_dir" ] || fail "Missing Scripts directory: $source_dir"
    visit_scripts "$source_dir" check_script
    visit_scripts "$source_dir" install_script
fi
