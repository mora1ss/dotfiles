# Personal additions on top of the CachyOS fish config.
# config.fish (CachyOS) is left untouched; conf.d files load before it, and
# it already provides: ~/.local/bin in PATH, eza `ls` aliases, `..` aliases,
# and a fastfetch greeting.

if status is-interactive
    # Abbreviations expand inline, so history keeps the full command.
    abbr -a g   git
    abbr -a gs  git status -sb
    abbr -a ga  git add
    abbr -a gc  git commit
    abbr -a gp  git push
    abbr -a gd  git diff
    abbr -a gl  git log --oneline --graph -20

    abbr -a hc  hyprctl
    abbr -a hr  hyprctl reload
    abbr -a ff  fastfetch
    abbr -a cfg cd ~/.config

    abbr -a pS  sudo pacman -S --needed
    abbr -a pSs pacman -Ss
    abbr -a pQ  pacman -Qi

    # yazi: `y` opens yazi and cd's into the directory you quit from.
    function y
        set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if read -z cwd <"$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    # Prompt (config: ~/.config/starship.toml, ANSI colours only).
    if command -q starship
        starship init fish | source
    end
end
