# System
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias alv='sudo poweroff'

mkcd() {
    mkdir -p "$1" && cd "$1"
}

alias gpsr='ros2 run planning_tools qwen_to_plan.py'

# ROS
alias cb='colcon build --symlink-install'
alias sisb='source install/setup.sh'
alias justina_on='export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp; export CYCLONEDDS_URI=file:///etc/cyclonedds/cyclonedds.xml; export ROS_DOMAIN_ID=0; export ROS_LOCALHOST_ONLY=0 && ros2 daemon stop && ros2 daemon start'
alias justina_off='unset CYCLONEDDS_URI; unset RMW_IMPLEMENTATION; unset ROS_DOMAIN_ID; unset ROS_LOCALHOST_ONLY && pkill -9 -f _node && pkill -9 -f ros2 && ros2 daemon start'

cbs() {
    colcon build --packages-select "$@"
}

cbi() {
    colcon build --packages-ignore "$@"
}

# Git
alias gs='git status'
alias gc='git commit -m'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gdc='git diff --cached'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch --all --prune'
alias gr='git restore'
alias grs='git restore --staged'
alias gsw='git switch'

alias gsmi='git submodule update --init --recursive'
alias gsmu='git submodule update --remote'

gclone() {
    local repo_name

    repo_name=$(basename -s .git "$1") || return

    git clone --recurse-submodules "$1" || return
    cd "$repo_name" || return
}

gsma() {
    if [ $# -ne 2 ]; then
        echo "Usage: gsma <repo-url> <path>"
        return 1
    fi

    git submodule add "$1" "$2"
}

gsmd() {
    git submodule deinit -f "$1"
    git rm -f "$1"
    rm -rf ".git/modules/$1"
}

gbc() {
    git switch -c "$1"
    git push --set-upstream origin "$1"
}

gac() {
    git add -A
    git commit -m "$*"
}

gai() {
    local pathspecs=()

    for dir in "$@"; do
        pathspecs+=(":!$dir/")
    done

    git add -A -- . "${pathspecs[@]}"
}

gundo() {
    git reset --soft HEAD~1
}