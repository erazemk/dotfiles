---
name: tmux
description: Use tmux to launch, inspect, and coordinate detached terminal sessions, including starting other agent processes and waiting for them to finish.
---

# tmux Orchestration Skill

Use this skill when you want to run another agent or long-lived command in a separate terminal context without blocking the current one.

## Principles

- Prefer **detached** tmux sessions for agent orchestration.
- Reuse an existing session only if you know its target pane is idle.
- If multiple jobs may run at once, create a **dedicated session or window per job**.
- When sending commands into tmux, wrap them in `sh -lc '...'` so they work even if the pane's interactive shell is `fish` or another non-POSIX shell.

## Find existing tmux sessions

List sessions:

```bash
tmux list-sessions
```

A more compact machine-friendly format:

```bash
tmux list-sessions -F '#{session_name}\t#{session_windows}\t#{session_created_string}'
```

Check whether a specific session exists:

```bash
tmux has-session -t my-session 2>/dev/null
```

List windows in a session:

```bash
tmux list-windows -t my-session
```

List panes in a session:

```bash
tmux list-panes -t my-session -F '#{session_name}:#{window_index}.#{pane_index}\t#{pane_current_command}\t#{pane_title}'
```

## Start a tmux session

Create a detached session in a specific working directory:

```bash
session="agent-worker"
workdir="/path/to/repo"

if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -c "$workdir"
fi
```

If you want a fresh dedicated session for a job, use a unique name:

```bash
session="agent-$(date +%Y%m%d-%H%M%S)"
tmux new-session -d -s "$session" -c "$PWD"
```

## Trigger a command in a session

Target the first pane of the first window:

```bash
pane="my-session:0.0"
tmux send-keys -t "$pane" "sh -lc 'cd /path/to/repo && <command>'" C-m
```

If you do not want to reuse the existing pane, create a new window first:

```bash
session="my-session"
window="job-1"
workdir="/path/to/repo"

tmux new-window -d -t "$session" -n "$window" -c "$workdir"
tmux send-keys -t "$session:$window.0" "sh -lc 'cd /path/to/repo && <command>'" C-m
```

For agent-style workloads, replacing `<command>` with something like `pi ...`, `claude ...`, or another CLI is fine.

## Trigger a command and wait for it to finish

The most reliable pattern is:

1. send the command into a tmux pane,
2. have that command signal a unique `tmux wait-for` channel when done,
3. write the exit status to a temporary file,
4. wait on the channel from the current process.

Example:

```bash
session="agent-worker"
pane="$session:0.0"
workdir="/path/to/repo"
channel="tmux-job-$(date +%s)-$$"
status_file="${TMPDIR:-/tmp}/${channel}.status"

workdir_q=$(printf '%q' "$workdir")
status_file_q=$(printf '%q' "$status_file")
channel_q=$(printf '%q' "$channel")

payload="cd $workdir_q && <command>; status=\$?; printf '%s' \"\$status\" > $status_file_q; tmux wait-for -S $channel_q"

tmux send-keys -t "$pane" "sh -lc $(printf %q "$payload")" C-m
tmux wait-for "$channel"

status=$(<"$status_file")
rm -f "$status_file"

if [ "$status" -ne 0 ]; then
  echo "command failed with status $status"
fi
```

This works even when the tmux pane is running `fish`, because the actual command is executed via `sh -lc`.

## Recommended pattern for launching another agent with pi

For one-shot pi worker jobs, use non-interactive mode:

- Use `pi -p` for a single prompt and final text output.
- Use `--append-system-prompt` for extra steering while keeping pi's default coding-agent prompt.
- Use `--system-prompt` only if you intentionally want to replace the default prompt.
- Use `--no-session` for ephemeral worker jobs unless you explicitly want persisted session history.
- Add `--tools`, `--model`, `--thinking`, `--skill`, `--extension`, and `@file` arguments as needed.
- If the parent process needs structured events instead of a final text response, use `pi --mode json ...` instead of `pi -p ...`.

Example: launch a detached pi worker with custom instructions, wait for it to finish, and capture its exit code:

```bash
session="agents"
job="review-auth-flow"
workdir="/path/to/repo"
channel="${job}-done-$$"
status_file="${TMPDIR:-/tmp}/${channel}.status"
task="Review the auth flow and list risks, bugs, and suggested fixes."
instructions="Work read-only. Be concise. Quote exact file paths in findings."

if ! tmux has-session -t "$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -c "$workdir"
fi

tmux new-window -d -t "$session" -n "$job" -c "$workdir"

workdir_q=$(printf '%q' "$workdir")
instructions_q=$(printf '%q' "$instructions")
task_q=$(printf '%q' "$task")
status_file_q=$(printf '%q' "$status_file")
channel_q=$(printf '%q' "$channel")

payload="cd $workdir_q && pi -p --no-session --append-system-prompt $instructions_q $task_q; status=\$?; printf '%s' \"\$status\" > $status_file_q; tmux wait-for -S $channel_q"

tmux send-keys -t "$session:$job.0" "sh -lc $(printf %q "$payload")" C-m
tmux wait-for "$channel"
status=$(<"$status_file")
rm -f "$status_file"
```

For longer custom instructions, put them in a file and pass them via `--append-system-prompt` if your pi setup uses file-backed system-prompt arguments.

## Optional: inspect output after completion

Capture the pane contents after the job finishes:

```bash
tmux capture-pane -pt "$pane"
```

You can also target the job window directly:

```bash
tmux capture-pane -pt "$session:$job.0"
```

## Best practices

- Use unique session, window, and wait-channel names to avoid collisions.
- Prefer a new window for each concurrent job instead of sharing one pane.
- Only send a command into an existing pane if you know it is safe to interrupt or reuse.
- Use `tmux capture-pane` if you need to read logs or agent output after the command completes.
