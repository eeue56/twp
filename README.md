# twp
A simpler interface to git

## Principles
- `git` has many features but a broad UX
- `git` shouldn't be replaced, but the UX should be
- Interactively using `git` leads to better usage
- Common commands should be short, ideally 4 characters.
- Less common commands should have memorable names.
- Naming things differently from git helps separate the usage between `git` and `twp`.
- Developer-first: scripts should use `git` instead.

## Start a repo

Purpose: Clone a repo locally.
Replaces: `git clone`, `git init`
Principle: Most repos will be started remotely, then cloned to each developer machine.

```
twp init git@github.com:eeue56/twp.git
```

## Save your work

Purpose: Add your work to the repo.
Replaces: `git add`, `git commit`
Principle: Interactively selecting content to save, and the message, leads to cleaner history.

```
twp save
```

## Edit what your last save included

Purpose: Add or remove work from your last saved work.
Replaces: `git add -p --amend`, `git commit -p --amend`
Principle: Easier editing of commits leads to cleaner commits.

```
twp edit
```

## Send your work

Purpose: Send your saved work to the repo.
Replaces: `git push`
Principle: Sending saved work should only apply to your current branch. The branch should have the same name on the server.

```
twp send
```

## Recieve (recv) work

Purpose: Get work from the repo.
Replaces: `git pull`
Principle: Receiving work should only apply to your current branch.

```
twp recv
```

## See info about a repo

Purpose: See relevant info about a repo.
Replaces: `git status`, `git remote`
Principle: Knowing the remote is important to separate public work from private. Knowing what the differences locally vs remotely is useful for workflow.

```
twp info
```

## Swap which active branch you are working on

Purpose: Swap active branch.
Replaces: `git checkout`, `git switch`
Principle: Interactively swapping is easier than remembering the branch name.

```
twp swap
```

## Store a copy of your work, but undo the changes made

Purpose: Keeping some changes for later without currently saving them.
Replaces: `git stash push`
Principle: Interactively selecting changes to store, with a message, makes storing more useful.

```
twp quick-save
```

## Load a copy of your work

Purpose: Keeping some changes for later without currently saving them.
Replaces: `git stash pop`
Principle: Interactively selecting changes to store, with a message, makes storing more useful.

```
twp quick-load
```


## Drop

Purpose: Set everything back to the last saved version
Replace: `git reset`, `git checkout`
Principle: Interactively resetting changes simplifies reset.

```
twp drop
```