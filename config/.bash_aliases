# =============================================================================
#                   BASH ALIASES & WEB DEV SHORTCUTS - herwingx
#      Compatible con Ubuntu & Fedora (Server, Desktop, Wayland/X11 & WSL)
# =============================================================================

# Detectar directorio real del repositorio de dotfiles mediante el propio symlink
DOTFILES_HOME="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"

# -----------------------------------------------------------------------------
# Dotfiles & Gestión Rápida
# -----------------------------------------------------------------------------
alias dotfiles="cd \"$DOTFILES_HOME\" && ./install.sh"
alias sync-dotfiles="(cd \"$DOTFILES_HOME\" && git pull && ./install.sh --all) && source ~/.bashrc && echo '✅ Dotfiles Sincronizados'"
alias reload='exec bash'

# -----------------------------------------------------------------------------
# Proton Pass CLI (Reemplazo moderno de Bitwarden/Vaultwarden + age)
# -----------------------------------------------------------------------------
alias secrets="\"$DOTFILES_HOME/scripts/manage_secrets.sh\""
alias pass-login='pass-cli login'
alias pass-info='pass-cli info'
alias pass-vaults='pass-cli vault list'
alias pass-ssh='pass-cli ssh-agent load'
alias pass-run="pass-cli run --env-file \"$DOTFILES_HOME/.env.example\" --"

# -----------------------------------------------------------------------------
# Theme & Colors (Harmonization)
# -----------------------------------------------------------------------------
if command -v dircolors &> /dev/null; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi
export LS_COLORS="${LS_COLORS}:di=01;36"

# -----------------------------------------------------------------------------
# LSD (LSDeluxe) - Reemplazo moderno de ls
# -----------------------------------------------------------------------------
if command -v lsd &> /dev/null; then
    alias ls='lsd'
    alias ll='lsd -la'
    alias la='lsd -a'
    alias l='lsd -l'
    alias lt='lsd --tree'
    alias ltr='lsd --tree --depth 2'
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -a'
    alias l='ls -l'
fi

# -----------------------------------------------------------------------------
# Navegación rápida
# -----------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# -----------------------------------------------------------------------------
# Git & Lazygit shortcuts
# -----------------------------------------------------------------------------
alias g='git'
if command -v lazygit &> /dev/null; then
    alias lg='lazygit'
fi

# -----------------------------------------------------------------------------
# Web Development (Node, pnpm, Bun, Python uv)
# -----------------------------------------------------------------------------
alias pn='pnpm'
alias px='pnpm dlx'
alias bx='bunx'
alias ni='npm install'
alias nr='npm run'
alias dev='pnpm run dev'
alias build='pnpm run build'
alias serve='python3 -m http.server 8000'

# -----------------------------------------------------------------------------
# Docker & Containers shortcuts
# -----------------------------------------------------------------------------
alias d='docker'
alias dc='docker compose'
if command -v lazydocker &> /dev/null; then
    alias ld='lazydocker'
fi
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dlog='docker logs -f'

# -----------------------------------------------------------------------------
# Sistema & Red (Ubuntu / Fedora)
# -----------------------------------------------------------------------------
alias off='sudo shutdown now'
alias rb='sudo reboot now'
alias size='du -h --max-depth=1 ~/'
alias storage='df -h'
if command -v ss &> /dev/null; then
    alias ports='ss -tulanp'
else
    alias ports='netstat -tulanp'
fi
alias myip='curl -s ifconfig.me; echo'
alias weather='curl -s wttr.in/?format=3'
if command -v fd &> /dev/null; then
    alias f='fd'
else
    alias f='find . -type f -name'
fi

if command -v btop &> /dev/null; then
    alias top='btop'
    alias htop='btop'
fi

if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
elif command -v batcat &> /dev/null; then
    alias cat='batcat --paging=never'
fi

# -----------------------------------------------------------------------------
# Actualización rápida según Distro (Ubuntu/Debian & Fedora/RHEL)
# -----------------------------------------------------------------------------
if [ -f /etc/debian_version ]; then
    alias update='sudo apt-get update && sudo apt-get upgrade -y && mise upgrade'
    alias up='sudo apt-get update && sudo apt-get upgrade -y'
    alias install='sudo apt-get install'
elif [ -f /etc/redhat-release ]; then
    alias update='sudo dnf upgrade --refresh -y && mise upgrade'
    alias up='sudo dnf upgrade --refresh -y'
    alias install='sudo dnf install'
fi

# -----------------------------------------------------------------------------
# Utilidades & Portapapeles Multi-Entorno (Wayland, X11, WSL)
# -----------------------------------------------------------------------------
alias c='clear'
alias h='history'
if command -v rg &> /dev/null; then
    alias grep='rg'
else
    alias grep='grep --color=auto'
fi
alias df='df -h'
alias du='du -h'
alias free='free -h'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -pv'

if command -v wl-copy &> /dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
elif command -v xclip &> /dev/null && [ -n "${DISPLAY:-}" ]; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
elif command -v clip.exe &> /dev/null; then
    alias pbcopy='clip.exe'
    alias pbpaste='powershell.exe -NoProfile -Command Get-Clipboard | tr -d "\r"'
fi

# -----------------------------------------------------------------------------
# FZF configuration (Usa fd si está instalado para máxima velocidad)
# -----------------------------------------------------------------------------
if command -v fzf &> /dev/null; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --color=hl:#00ff87,fg+:#ffffff,bg+:#1e1e2e,hl+:#00ffff,pointer:#00ff87,prompt:#00ffff'
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# -----------------------------------------------------------------------------
# Waydroid (si aplica en Desktop)
# -----------------------------------------------------------------------------
alias waydroid='waydroid show-full-ui'
