# vim:ft=zsh ts=2 sw=2 sts=2
#
# Boban
# A Powerline-inspired theme for ZSH

CURRENT_BG='NONE'
DEFAULT_USER=${DEFAULT_USER:-default}

# Special Powerline characters
() {
	local LC_ALL="" LC_CTYPE="en_US.UTF-8"
	# NOTE: This segment separator character is correct.  In 2012, Powerline changed
	# the code points they use for their special characters. This is the new code point.
	# If this is not working for you, you probably have an old version of the
	# Powerline-patched fonts installed. Download and install the new version.
	# Do not submit PRs to change this unless you have reviewed the Powerline code point
	# history and have new information.
	# This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
	# what font the user is viewing this source code in. Do not replace the
	# escape sequence with a single literal character.
	# Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
	SEGMENT_SEPARATOR=$'\ue0b0'
	RIGHT_SEPARATOR=$'\ue0b3'
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
	local bg fg
	[[ -n $1 ]] && bg="%K{$1}" || bg="%k"
	[[ -n $2 ]] && fg="%F{$2}" || fg="%f"
	if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
		echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
	else
		echo -n "%{$bg%}%{$fg%} "
	fi
	CURRENT_BG=$1
	[[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
	if [[ -n $CURRENT_BG ]]; then
		echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
	else
		echo -n "%{%k%}"
	fi
	echo -n "%{%f%}"
	CURRENT_BG=''
}

# Begin the right prompt
prompt_endr() {
	echo -n " %{%k%F{grey}%}$RIGHT_SEPARATOR"
	echo -n "%{%f%}"
	CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
	if [[ "$USER" != "$DEFAULT_USER" || "$SSH_CLIENT" ]]; then
		prompt_segment black default "%(!.%{%F{yellow}%}.)$USER@%m"
	fi
}

# Git: branch/detached head, dirty status
prompt_git() {

	local PL_BRANCH_CHAR
	() {
		local LC_ALL="" LC_CTYPE="en_US.UTF-8"
		PL_BRANCH_CHAR=$'\ue0a0'         # 
	}
	local ref dirty mode repo_path
	repo_path=$(git rev-parse --git-dir 2>/dev/null)

	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
		dirty=$(parse_git_dirty)
		ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
		if [[ -n $dirty ]]; then
			prompt_segment yellow black
		else
			prompt_segment green black
		fi

		if [[ -e "${repo_path}/BISECT_LOG" ]]; then
			mode=" <B>"
		elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
			mode=" >M<"
		elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
			mode=" >R>"
		fi

		setopt promptsubst
		autoload -Uz vcs_info

		zstyle ':vcs_info:*' enable git
		zstyle ':vcs_info:*' get-revision true
		zstyle ':vcs_info:*' check-for-changes true
		zstyle ':vcs_info:*' stagedstr '+'
		zstyle ':vcs_info:*' unstagedstr '●'
		zstyle ':vcs_info:*' formats ' %u%c'
		zstyle ':vcs_info:*' actionformats ' %u%c'
		vcs_info
		echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
	fi
}

# Dir: current working directory
prompt_dir() {
	if [[ -w "$PWD" ]]; then
		prompt_segment blue black '%~'
	else
		prompt_segment red black '%~'
	fi
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
	local virtualenv_path="$VIRTUAL_ENV"
	if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
		prompt_segment blue black ""
	fi
}

# AWS profile
prompt_aws() {
	local aws_profile="$AWS_PROFILE"
	if [[ -n $aws_profile ]]; then
		prompt_segment black yellow "󰸏 $aws_profile"
	fi
}

# Terraform: current terraform workspace
prompt_tf() {
	# dont show 'default' workspace in home dir
	[[ "$PWD" == ~ ]] && return
	# check if in terraform dir
	if [ -d .terraform ]; then
		workspace=$(terraform workspace show 2> /dev/null) || return
		prompt_segment black magenta "󱁢 ${workspace}"
	fi
}

# Kubectl: current active kubeconfig file
prompt_kubectl() {
	if [[ -n $KUBECONFIG ]]; then
		prompt_segment magenta black "󱃾 $(basename $KUBECONFIG)"
	fi
}

# Status:
# - was there an error?
# - am I root?
# - are there background jobs?
prompt_status() {
	local symbols
	symbols=()
	[ $RETVAL -ne 0 ] && symbols+="%{%F{red}%}$RETVAL"
	[ $UID -eq 0 ] && symbols+="%{%F{yellow}%}⚡"
	[ $(jobs -l | wc -l) -gt 0 ] && symbols+="%{%F{cyan}%}⚙"

	[ -n "$symbols" ] && prompt_segment background default "$symbols"
}

prompt_time() {
	prompt_segment background default $(date "+%H:%M:%S")
}

## Main prompt
build_prompt() {
	prompt_context
	prompt_dir
	prompt_virtualenv
	prompt_aws
	prompt_kubectl
	prompt_tf
	prompt_git
	prompt_end
}

## Right prompt
build_rprompt() {
	RETVAL=$?
	prompt_status
	prompt_endr
	# prompt_time
}

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT='%{%f%b%k%}$(build_rprompt) '
