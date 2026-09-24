# ~/.zshrc — Oh My Zsh + Powerlevel10k (lean, satu baris) + modern CLI tools
# Backup config lama: ~/.zshrc.bak.*

# ---- Powerlevel10k instant prompt (harus tetap di paling atas) ----
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---- Oh My Zsh ----
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

zstyle ':omz:update' mode reminder     # cuma ingatkan kalau ada update
zstyle ':omz:update' frequency 14
HYPHEN_INSENSITIVE="true"              # - dan _ dianggap sama saat completion
DISABLE_UNTRACKED_FILES_DIRTY="true"   # git status di prompt lebih cepat untuk repo besar

# zsh-autosuggestions: saran dari history dulu, lalu dari completion
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'

# Urutan penting: fzf-tab sebelum autosuggestions, syntax-highlighting paling akhir
plugins=(
  git                      # alias git: gst, gco, gp, glog, ...
  sudo                     # tekan Esc dua kali -> tambah sudo di depan perintah
  extract                  # extract <arsip apa saja>
  fzf-tab                  # Tab completion pakai fzf
  zsh-autosuggestions      # saran abu-abu dari history (terima: -> atau Ctrl+Space)
  zsh-syntax-highlighting  # warna perintah saat mengetik
)

source "$ZSH/oh-my-zsh.sh"

# ---- Environment ----
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PATH="$HOME/.local/bin:$PATH"

# ---- History ----
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_SAVE_NO_DUPS

# ---- Completion + fzf-tab ----
zstyle ':completion:*' menu no                 # wajib untuk fzf-tab
zstyle ':completion:*:*:*:*:*' menu no         # override default Oh My Zsh (menu select)
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always --icons $realpath'

# ---- fzf: Ctrl+R cari history, Ctrl+T cari file, Alt+C cd ke folder ----
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline --color=16'
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons {}'"
fi

# ---- mise: versi runtime (node, ruby, go, python, ...) untuk dev env dari menu Install > Development ----
# Dipasang saat pertama dipakai (hypr-dev-env). activate = versi per proyek (.mise.toml) mengikuti cd;
# shims di PATH supaya program non-interaktif (editor, skrip) juga menemukan tool mise.
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
  [[ :$PATH: == *:$HOME/.local/share/mise/shims:* ]] || export PATH="$PATH:$HOME/.local/share/mise/shims"
fi

# ---- Podman rootless sebagai pengganti Docker (menu Install > Development > Docker DB) ----
# podman-docker menyediakan CLI `docker`; DOCKER_HOST mengarahkan docker-compose/lazydocker ke socket Podman user.
if (( $+commands[podman] )) && ! (( $+commands[dockerd] )); then
  export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$UID}/podman/podman.sock"
fi

# ---- rustup/cargo (dari menu Install > Development > Rust): binari di ~/.cargo/bin ----
[[ -d $HOME/.cargo/bin ]] && export PATH="$PATH:$HOME/.cargo/bin"

# ---- zoxide: cd pintar. `cd proj` lompat ke folder yang sering dipakai, `cdi` = pilih interaktif ----
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"

# ---- bat: pengganti cat + man page berwarna ----
if (( $+commands[bat] )); then
  alias cat='bat -pp'                          # plain + tanpa pager, persis cat tapi berwarna
  export BAT_THEME=ansi                        # bat pakai 16 warna terminal, ikut tema Noctalia
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT="-c"
fi

# ---- eza: pengganti ls ----
if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --group-directories-first --git'
  alias la='eza -lah --icons --group-directories-first --git'
  alias l='la'
  alias lt='eza --tree --level=2 --icons --group-directories-first'
fi

# ---- alias lain ----
(( $+commands[lazygit] )) && alias lg='lazygit'
alias zshrc='${EDITOR} ~/.zshrc'
alias reload='exec zsh'
alias t='tmux new-session -A -s main'   # masuk/buat sesi tmux "main"

# Tool lain (tanpa alias, panggil langsung): fd (find), rg (grep), dust (du), duf (df),
# btop (top), tldr <cmd> (cheatsheet), delta (git diff), jq (json)

# ---- Keybinding ----
bindkey '^ ' autosuggest-accept   # Ctrl+Space terima saran autosuggest

# ---- Powerlevel10k ----
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
