# Relevant beaker scripts

BEAKER_IMG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

alias ai2="ssh ai2"
alias bstop='beaker session stop'
blist() {
    beaker session list --all --author davidh | grep running
}
bport() {
    source $BEAKER_IMG_DIR/deps/update_port.sh
}
# alias bd='beaker session describe'
alias bd='python '$BEAKER_IMG_DIR'/deps/get_jobs.py --username davidh --sessions-only' # describe sessions
alias bdall='python '$BEAKER_IMG_DIR'/deps/get_jobs.py --username davidh' # describe all jobs
alias bl='python '$BEAKER_IMG_DIR'/deps/launcher.py' # launch session
alias blogs='python '$BEAKER_IMG_DIR'/deps/stream_logs.py -j' # launch session
alias bstream='python '$BEAKER_IMG_DIR'/deps/stream_logs.py -s -j' # launch session

bpriority() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: bpriority <workspace> <priority>"
        return 1
    fi

    WORKSPACE="$1"
    PRIORITY="$2"

    echo "Downloading current results for $WORKSPACE..."
    beaker workspace experiments "$WORKSPACE" --format json > /tmp/output.json
    JSON_FILE="/tmp/output.json"

    echo "Extracting BEAKER_JOB_IDs..."
    jq -r '.[] | .jobs[] | select(.status.canceledCode != 0 and .status.canceledCode != 1) | .id' "$JSON_FILE" | while read -r JOB_ID; do
        echo "Updating priority for job: $JOB_ID"
        beaker job update-priority "$JOB_ID" "$PRIORITY" --format json
    done
}
bsecrets() {
    WORKSPACE_NAME="$1"
    echo "Adding secrets to $WORKSPACE_NAME..."
    cat ~/.ssh/id_rsa | beaker secret write -w $WORKSPACE_NAME ssh-key
    cat ~/.aws/credentials | beaker secret write -w $WORKSPACE_NAME aws-creds
    echo -n $HF_TOKEN | beaker secret write -w $WORKSPACE_NAME HF_TOKEN
    echo -n $HF_TOKEN | beaker secret write -w $WORKSPACE_NAME HF_TOKEN_READ_ONLY # <- for oe-eval
    echo -n $OPENAI_API_KEY | beaker secret write -w $WORKSPACE_NAME OPENAI_API_KEY
    echo -n $ANTHROPIC_API_KEY | beaker secret write -w $WORKSPACE_NAME ANTHROPIC_API_KEY
    echo -n $BEAKER_TOKEN | beaker secret write -w $WORKSPACE_NAME BEAKER_TOKEN
    echo -n $WANDB_API_KEY | beaker secret write -w $WORKSPACE_NAME WANDB_API_KEY
    echo -n $WANDB_API_KEY | beaker secret write -w $WORKSPACE_NAME DAVIDH_WANDB_API_KEY
    echo -n $AWS_SECRET_ACCESS_KEY | beaker secret write -w $WORKSPACE_NAME AWS_SECRET_ACCESS_KEY
    echo -n $AWS_ACCESS_KEY_ID | beaker secret write -w $WORKSPACE_NAME AWS_ACCESS_KEY_ID
    echo -n $AWS_SECRET_ACCESS_KEY | beaker secret write -w $WORKSPACE_NAME DAVIDH_AWS_SECRET_ACCESS_KEY
    echo -n $AWS_ACCESS_KEY_ID | beaker secret write -w $WORKSPACE_NAME DAVIDH_AWS_ACCESS_KEY_ID
    echo -n $GOOGLE_API_KEY | beaker secret write -w $WORKSPACE_NAME GOOGLE_API_KEY
    beaker secret list -w $WORKSPACE_NAME
}
bweb() {
    if [ -z "$*" ]; then
        open -a "Google Chrome" "https://beaker.allen.ai/orgs/ai2/workspaces/davidh?rowsPerPage=100"
    else
        open -a "Google Chrome" "https://beaker.allen.ai/orgs/ai2/workspaces/$*?rowsPerPage=100?"
    fi
}

ai2code() {
    if [ -z "$1" ]; then
        code --remote ssh-remote+ai2 /root/ai2
    else
        local remote_path="${1:-}"
        code --remote ssh-remote+ai2 /root/ai2/$remote_path
    fi
}
ai2codereset() {
    ai2 'rm -rf ~/.vscode-server/cli/servers'
}
ai2cleanup() {
    isort . && black . && ruff check . && mypy .
}