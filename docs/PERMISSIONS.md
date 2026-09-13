# Permission Autopilot

YogeeshCode auto-approves safe actions, denies risky ones, and asks for everything else. No annoying prompts for read/edit, but dangerous operations always ask.

## Default Rules

### Auto-approved (no prompt)

**File operations:** read, write, edit, replace, glob, grep, list, lsp, task, note, webfetch, websearch

**Safe terminal commands:**
- Navigation: `cd`, `pwd`, `ls`, `tree`
- Read: `cat`, `head`, `tail`, `less`, `more`, `wc`, `file`, `stat`, `which`, `type`
- Search: `find`, `grep`, `rg`, `ag`, `ack`, `locate`, `whereis`
- Git (read-only): `git status`, `git log`, `git diff`, `git show`, `git branch`, `git remote`, `git stash list`, `git tag`
- Build/test: `npm run`, `npm test`, `bun run`, `bun test`, `node`, `npx`, `tsc`, `eslint`, `prettier`, `jest`, `vitest`, `mocha`, `pytest`, `cargo build`, `cargo test`, `go build`, `go test`, `make`, `cmake`, `maven`, `gradle`
- Package managers (local): `npm install`, `npm ci`, `bun add`, `yarn`, `pip install --user`, `cargo add`, `go get`
- File ops: `cp`, `mv`, `mkdir`, `touch`, `chmod` (not 777), `ln`, `tar`, `zip`, `unzip`, `gzip`, `gunzip`
- Text processing: `sed`, `awk`, `sort`, `uniq`, `cut`, `tr`, `jq`, `yq`, `diff`, `patch`
- System info: `date`, `whoami`, `hostname`, `uname`, `env`, `printenv`, `ps`, `top`, `df`, `du`, `free`, `uptime`
- Docker (read): `docker ps`, `docker images`, `docker logs`, `docker inspect`, `docker stats`
- Misc: `echo`, `printf`, `tee`, `xargs`, `watch`, `time`, `timeout`

### Denied (auto-reject, cannot override with --auto)

- `rm -rf`, `rm -r -f`, `rm -fr`, `rm -f -r`
- `sudo` (any command)
- `chmod 777`, `chmod -R 777`
- `ssh` (any)
- `git reset --hard`, `git reset --hard HEAD`
- `git clean -fd`, `git clean -fxd`
- `git push --force`, `git push --hard`, `git push -f`
- `format`, `mkfs`, `mkfs.*`
- `dd` (any)
- `kill -9`, `killall`, `pkill`
| `shutdown`, `reboot`, `halt`, `poweroff`
- `curl | sh`, `curl | bash`, `wget | sh`, `wget | bash` (pipe to shell)
- `:(){ :|:& };:` (fork bomb)

### Ask (prompt user)

- `git push` (without --force)
- `git rebase`, `git rebase -i`, `git cherry-pick`, `git merge`
- `kill` (without -9)
- `docker run`, `docker exec`, `docker build`, `docker compose`, `docker rm`, `docker rmi`
- `curl` (POST/PUT/DELETE/OPTIONS), `ftp`, `sftp`, `rsync`, `scp`
- `wget` (write operations)
- `brew install`, `brew upgrade`, `brew uninstall`
- `apt`, `apt-get`, `yum`, `dnf`, `pacman`
- `npm install -g`, `npm publish`, `npm unpublish`
- `pip install --system`, `pip install -g`, `pip uninstall`
- `cargo install`, `cargo publish`, `cargo uninstall`
- `go install`, `go mod tidy`, `go mod vendor`
- `yarn global`, `pnpm add -g`
- `gem install`, `gem uninstall`
- `composer install`, `composer update`
- `npx create-*` (project scaffolding)
- Any command not in allow or deny lists

## CLI Override

```bash
# Approve everything except explicit denies (rm -rf, sudo, etc.)
yogeeshcode --auto

# Ask for everything (paranoid mode)
yogeeshcode --no-auto

# Default (smart autopilot)
yogeeshcode
```

## TUI Toggle

Press `Ctrl+P` in the TUI to toggle between auto and ask mode. Status indicator shows current mode.

## Configuration

Permission rules are configured in `~/.yogeeshcode/yogeeshcode.json`:

```json
{
  "permission": {
    "edit": "allow",
    "bash": "ask",
    "bash_allowlist": ["ls", "cat", "git status", "..."],
    "bash_denylist": ["rm -rf", "sudo", "..."]
  }
}
```

## Deny List Rationale

| Pattern | Why denied |
|---------|-----------|
| `rm -rf` | Irreversible file deletion, root of all oops |
| `sudo` | Root access, can destroy system |
| `chmod 777` | World-writable = security hole |
| `git reset --hard` | Discards all uncommitted work |
| `git push --force` | Rewrites remote history, breaks teammates |
| `dd` | Disk destroyer, one wrong `of=` and gone |
| `curl \| sh` | Remote code execution as root |
| Fork bomb | System DoS |

## Ask List Rationale

| Pattern | Why ask |
|---------|---------|
| `git push` | Publishing, affects others |
| `git rebase` | Rewrites history |
| `docker run` | Executes arbitrary images |
| `brew install` | Modifies system |
| `npm install -g` | Global install, affects all projects |
| `pip install` | Can override system packages |
| `curl POST` | Sends data to remote |
