# Claude Code and uv tools install to ~/.local/bin.
export PATH="$HOME/.local/bin:$PATH"
# VS Code's `code` command.
VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
[ -d "$VSCODE_BIN" ] && export PATH="$PATH:$VSCODE_BIN"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git docker)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Play an ascii/*.frames file (made by ascii/make-frames.sh) with optional
# text printed below it ($2). The frames play in place above that text,
# forward then backward, until a key is pressed. The key isn't eaten: if you
# start typing a command, it lands in the prompt. Dodecahedron from ASCII Magic
# (MIT): https://www.ascii-magic.com/ascii/rotating-dodecahedron
zmodload zsh/zselect 2>/dev/null
play_frames() {
  [[ -r $1 ]] || return 0
  local -a L; L=("${(@f)$(<$1)}")
  local below=$2 h=$L[1] i=0 step=1 n b=0
  n=$(( (${#L} - 1) / h ))
  [[ -n $below ]] && b=${#${(f)below}}
  # Draw the first frame and the text below it.
  printf '%s\e[K\n' "${(@)L[2,1+h]}"
  [[ -n $below ]] && print -r -- "$below"
  # Animate only in a terminal tall enough to hold both (the cursor can't
  # move back into the scrollback); otherwise leave the first frame.
  [[ -t 0 && -t 1 ]] && (( LINES > h + b + 1 && n > 1 )) || return 0
  # Per-key input (so a keypress is seen without Enter) and no echo while drawing.
  local tty_state; tty_state=$(stty -g 2>/dev/null)
  stty -icanon -echo 2>/dev/null
  printf '\e[?25l'
  until zselect -t 7 -r 0 2>/dev/null; do   # 70ms per frame; stop on input
    (( i + step < 0 || i + step >= n )) && (( step = -step ))
    (( i += step ))
    printf '\e[%dA' $(( h + b ))
    printf '%s\e[K\n' "${(@)L[2+i*h,1+(i+1)*h]}"
    (( b )) && printf '\e[%dB' $b
  done
  printf '\e[?25h'
  [[ -n $tty_state ]] && stty $tty_state 2>/dev/null
}

# A fortune from Tux: bubble and Tux in white, the saying in rainbow. cowthink
# draws it plain (color codes would throw off the bubble width), then only the
# text inside the bubble is colored.
cow_banner() {
  local -a cow mid out; local i end
  cow=("${(@f)$(fortune | cowthink -f tux)}")
  # Bubble: line 1 is the top edge, text lines follow until the " ---" edge.
  for (( end = 2; end <= ${#cow}; end++ )); do [[ $cow[end] == ' -'* ]] && break; done
  for (( i = 2; i < end; i++ )); do mid+=("${cow[i][3,-3]}"); done
  if command -v lolcat >/dev/null; then
    out=("${(@f)$(print -rl -- "${mid[@]}" | lolcat -f)}")
  else
    out=("${mid[@]}")
  fi
  local W=$'\e[37m' R=$'\e[0m'
  print -r -- "$W$cow[1]"
  for (( i = 2; i < end; i++ )); do
    print -r -- "$W${cow[i][1,2]}$R${out[i-1]}$W${cow[i][-2,-1]}"
  done
  print -rl -- "${(@)cow[end,-2]}"
  print -r -- "${cow[-1]}$R"
}

# Startup banner; skipped if the tools are not installed yet.
if command -v figlet >/dev/null && command -v fortune >/dev/null; then
  printf '\e[36m'; date "+ %H : %M" | figlet -f univers; printf '\e[0m'
  play_frames ~/projects/dotfiles/ascii/rotating-dodecahedron.frames "$(cow_banner)"
fi

function getPrompt() {
  echo -n "%(?:🐕 :🔥 )"
  echo -n "%{$fg_bold[blue]%}%c%{$reset_color%} $(git_prompt_info) "
}
PROMPT='$(getPrompt)'
