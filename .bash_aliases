# --- Auto-Actualización Dotfiles ---
# Este comando descarga cambios del repo, reinstala configs y recarga la terminal
alias sync-dotfiles='(cd ~/dotfiles && git pull && ./install.sh) && source ~/.bashrc && echo "✅ Dotfiles Sincronizados"'

# --- Mantenimiento ---
alias up='sudo apt update && sudo apt upgrade -y'
alias off='sudo shutdown now'
alias rb='sudo reboot now'
alias reload='exec bash'
alias waydroid='waydroid show-full-ui'

# --- Info y Navegación ---
alias size='du -h --max-depth=1 ~/'
alias storage='df -h'
alias ..='cd ..'
alias ...='cd ../../'
alias ll='ls -alF'
alias f='find . -type f -name'

# --- Git Shortcuts ---
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate --all'