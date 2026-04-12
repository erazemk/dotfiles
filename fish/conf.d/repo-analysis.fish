function repo-analysis
    echo 'What changes a lot?'
    git log --format=format: --name-only --since='1 year ago' | rg -v 'po$|json$|desktop$' | sort | uniq -c | sort -nr | head -20

    echo
    echo 'What breaks a lot?'
    git log -i -E --grep='fix|bug|broke|bad|wrong|incorrect|problem' --name-only --format='' | sort | uniq -c | sort -nr | head -20

    echo
    echo 'And what were the emergencies?'
    git log --oneline --since='1 year ago' | grep -iE 'revert|hotfix|emergency|urgent|rollback'

    echo
    echo "What's the project's momentum over the past 5 years?"
    git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c | tail -n 60

    echo
    echo "Who's been driving this project in the past year?"
    git shortlog -sn --no-merges --since='1 year ago' | rg -v 'l10n daemon script' | head -n 30

    echo
    echo 'And what about for all time?'
    git shortlog -sn --no-merges | rg -v 'l10n daemon script' | head -n 30
end
