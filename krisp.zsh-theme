
# time
function real_time() {
    local color="%{$fg_no_bold[cyan]%}";                    
    local time="[$(date +%r" "%Z)]/[$(TZ=America/New_York date +%r" "%Z)]";
    local color_reset="%{$reset_color%}";
    echo "${color}${time}${color_reset}";
}


# directory
function directory() {
    local color="%{$fg_no_bold[yellow]%}";
    local directory="${PWD/#$HOME}";
    local color_reset="%{$reset_color%}";
    echo "${color}[${directory:1}]${color_reset}";
}


# git
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_no_bold[green][%}";
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}";
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_no_bold[green]%}]";
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_no_bold[green]%}]";

function update_git_status() {
    GIT_STATUS=$(git_prompt_info);
}

function git_status() {
    echo "${GIT_STATUS}"
}


# command
function update_command_status() {
    local arrow="";
    local color_reset="%{$reset_color%}";
    local reset_font="%{$fg_no_bold[white]%}";
    COMMAND_RESULT=$1;
    export COMMAND_RESULT=$COMMAND_RESULT
    if $COMMAND_RESULT;
    then
        arrow="%{$fg_bold[red]%}❱%{$fg_bold[yellow]%}❱%{$fg_bold[green]%}❱";
    else
        arrow="%{$fg_bold[red]%}❱❱❱";
    fi
    COMMAND_STATUS="${arrow}${reset_font}${color_reset}";
}
update_command_status true;

function command_status() {
    echo "${COMMAND_STATUS}"
}

preexec() {
    echo
}


precmd() {
    # last_cmd
    local last_cmd_return_code=$?;
    local last_cmd_result=true;
    if [ "$last_cmd_return_code" = "0" ];
    then
        last_cmd_result=true;
    else
        last_cmd_result=false;
    fi

    # update_git_status
    update_git_status;

    # update_command_status
    update_command_status $last_cmd_result;

}

setopt PROMPT_SUBST;

HEADLINE_GIT_STAGED="%{$fg_bold[yellow]%}+";
HEADLINE_GIT_CHANGED="%{$fg_bold[red]%}*";
HEADLINE_GIT_UNTRACKED="%{$fg_bold[yellow]%}U";
HEADLINE_GIT_BEHIND="%{$fg_bold[yellow]%}↓";
HEADLINE_GIT_AHEAD="%{$fg_bold[yellow]%}↑";
HEADLINE_GIT_DIVERGED="%{$fg_bold[yellow]%}↕";
HEADLINE_GIT_STASHED="%{$fg_bold[blue]%}S";
HEADLINE_GIT_CONFLICTS="%{$fg_bold[red]%}✘✘";
HEADLINE_GIT_CLEAN="%{$fg_bold[green]%}✔"; 
# Git status

headline_git() {
  GIT_OPTIONAL_LOCKS=0 command git "$@"
}

headline_git_status() {
  # Data structures
  local order; order=('STAGED' 'CHANGED' 'UNTRACKED' 'BEHIND' 'AHEAD' 'DIVERGED' 'STASHED' 'CONFLICTS')
  local -A totals
  for key in $order; do
    totals+=($key 0)
  done


  local raw lines
  raw="$(headline_git status --porcelain -b 2> /dev/null)"
  if [[ $? == 128 ]]; then
    return 1 # failure
  fi
  lines=(${(@f)raw})

  if [[ ${lines[1]} =~ '^## [^ ]+ \[(.*)\]' ]]; then
    local items=("${(@s/,/)match}")
    for item in $items; do
      if [[ $item =~ '(behind|ahead|diverged) ([0-9]+)?' ]]; then
        case $match[1] in
          'behind') totals[BEHIND]=$match[2];;
          'ahead') totals[AHEAD]=$match[2];;
          'diverged') totals[DIVERGED]=$match[2];;
        esac
      fi
    done
  fi

  # Process status lines
  for line in $lines; do
    if [[ $line =~ '^##|^!!' ]]; then
      continue
    elif [[ $line =~ '^U[ADU]|^[AD]U|^AA|^DD' ]]; then
      totals[CONFLICTS]=$(( ${totals[CONFLICTS]} + 1 ))
    elif [[ $line =~ '^\?\?' ]]; then
      totals[UNTRACKED]=$(( ${totals[UNTRACKED]} + 1 ))
    elif [[ $line =~ '^[MTADRC] ' ]]; then
      totals[STAGED]=$(( ${totals[STAGED]} + 1 ))
    elif [[ $line =~ '^[MTARC][MTD]' ]]; then
      totals[STAGED]=$(( ${totals[STAGED]} + 1 ))
      totals[CHANGED]=$(( ${totals[CHANGED]} + 1 ))
    elif [[ $line =~ '^ [MTADRC]' ]]; then
      totals[CHANGED]=$(( ${totals[CHANGED]} + 1 ))
    fi
  done

  # Check for stashes
  if $(headline_git rev-parse --verify refs/stash &> /dev/null); then
    totals[STASHED]=$(headline_git rev-list --walk-reflogs --count refs/stash 2> /dev/null)
  fi

  # Build string
  local prefix status_str
  status_str=''
  for key in $order; do
    if (( ${totals[$key]} > 0 )); then
      if (( ${#HEADLINE_STATUS_TO_STATUS} && ${#status_str} )); then # not first iteration
        local style_joint="$reset$HEADLINE_STYLE_DEFAULT$HEADLINE_STYLE_JOINT"
        local style_status="$resetHEADLINE_STYLE_DEFAULT$HEADLINE_STYLE_STATUS"
        status_str="$status_str%{$style_joint%}$HEADLINE_STATUS_TO_STATUS%{$style_status%}"
      fi
      eval prefix="\$HEADLINE_GIT_${key}"
      if [[ $HEADLINE_DO_GIT_STATUS_COUNTS == 'true' ]]; then
        if [[ $HEADLINE_DO_GIT_STATUS_OMIT_ONE == 'true' && (( ${totals[$key]} == 1 )) ]]; then
          status_str="$status_str$prefix"
        else
          status_str="$status_str${totals[$key]}$prefix"
        fi
      else
        status_str="$status_str$prefix"
      fi
    fi
  done

  # Return
  if (( ${#status_str} )); then
    echo $status_str
  else
    echo $HEADLINE_GIT_CLEAN
  fi
}

# timer
TMOUT=1;
TRAPALRM() {
    if [ "$WIDGET" = "" ] || [ "$WIDGET" = "accept-line" ] ; then
        zle reset-prompt;
    fi
}

# prompt
PROMPT='%{$fg_bold[yellow]%}⚡ $(directory)$(git_status)$(headline_git_status) $(command_status)  ';
RPROMPT='$(real_time)';