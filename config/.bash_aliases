# =============================================================================
#                           BASH ALIASES - herwingx
# =============================================================================

# -----------------------------------------------------------------------------
# Dotfiles
# -----------------------------------------------------------------------------
alias sync-dotfiles='(cd ~/dotfiles && git pull && ./install.sh) && source ~/.bashrc && echo "✅ Dotfiles Sincronizados"'
alias reload='exec bash'

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
    # Fallback a ls normal con colores
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
# Git shortcuts
# -----------------------------------------------------------------------------
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias glog='git log --oneline --graph --decorate -10'

# -----------------------------------------------------------------------------
# Docker shortcuts
# -----------------------------------------------------------------------------
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dlog='docker logs -f'

# -----------------------------------------------------------------------------
# Sistema
# -----------------------------------------------------------------------------
alias off='sudo shutdown now'
alias rb='sudo reboot now'
alias size='du -h --max-depth=1 ~/'
alias storage='df -h'
alias ports='netstat -tulanp'
alias myip='curl -s ifconfig.me'
alias weather='curl wttr.in'
alias f='find . -type f -name'

# Herramientas modernas como default
if command -v btop &> /dev/null; then
    alias top='btop'
    alias htop='btop'
fi

# bat en lugar de cat si está disponible
if command -v bat &> /dev/null; then
    alias cat='bat'
elif command -v batcat &> /dev/null; then
    alias cat='batcat'
fi

# -----------------------------------------------------------------------------
# Actualización (detecta distro)
# -----------------------------------------------------------------------------
if [ -f /etc/debian_version ]; then
    alias update='sudo apt update && sudo apt upgrade -y'
    alias up='sudo apt update && sudo apt upgrade -y'
    alias install='sudo apt install'
elif [ -f /etc/redhat-release ]; then
    alias update='sudo dnf upgrade --refresh -y'
    alias up='sudo dnf upgrade --refresh -y'
    alias install='sudo dnf install'
elif [ -f /etc/arch-release ]; then
    alias update='sudo pacman -Syu'
    alias up='sudo pacman -Syu'
    alias install='sudo pacman -S'
fi

# -----------------------------------------------------------------------------
# Utilidades
# -----------------------------------------------------------------------------
alias c='clear'
alias h='history'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Safety nets
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -pv'

# Copiar al portapapeles
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

# -----------------------------------------------------------------------------
# Bitwarden CLI
# -----------------------------------------------------------------------------
alias bwu='export BW_SESSION=$(bw unlock --raw)'
alias bws='bw sync'

# -----------------------------------------------------------------------------
# FZF configuration
# -----------------------------------------------------------------------------
if command -v fzf &> /dev/null; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# -----------------------------------------------------------------------------
# Waydroid (si aplica)
# -----------------------------------------------------------------------------
alias waydroid='waydroid show-full-ui'

echo "✓ Aliases cargados"