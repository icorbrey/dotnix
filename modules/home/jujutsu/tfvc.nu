use std/log

# Commands for working with TFVC remotes.
export def main [] {
  help main
}

const tfs_url_key = "tfvc.url";

def coalesce_tfs_url [url?: string] {
  $url
    | default (jj config get $tfs_url_key)
    | default (error make {
      msg: "No TFS server URL was provided.",
      help: "Either add e.g. `--url https://example.com` or run `jj config set --user tfvc.url https://example.com`.",
    })
}

# Clone a repository from TFS as a colocated Jujutsu repository.
#
# You may want to consider using `jj tfvc clone quick`. This command will
# likely take a very long time to execute, as it fetches every changeset in the
# given repository individually and converts it into a commit. Use this if
# you're planning on fetching the full history for reference purposes, or if
# you're converting the repository to Git.
export def "main clone" [
  path: string,        # The path in TFS to clone from
  destination: string, # The directory to place the repository in
  --url: string,       # The URL to use for the TFS server
] {
  let tfs_url = coalesce_tfs_url $url

  git tfs clone $tfs_url $path $destination
  cd $destination
  jj git init --colocate
}

export def "main clone list" [
  --url: string,  # The URL to use for the TFS server
] {
  let tfs_url = coalesce_tfs_url $url

  git tfs list-remote-branches $tfs_url
}

# Quick-clone a repository from TFS as a colocated Jujutsu repository.
#
# This only converts the latest changeset in the path into a commit, which is
# not great for historical purposes but does take _significantly_ less time
# than a full clone.
export def "main clone quick" [
  path: string,        # The path in TFS to clone from
  destination: string, # The directory to place the repository in
  --url: string,       # The URL to use for the TFS server
  --changeset (-c): number, # Specify a changeset to clone from
  --no-branches
] {
  let tfs_url = coalesce_tfs_url $url

  git tfs quick-clone $tfs_url $path $destination
  cd $destination
  jj git init --colocate
}

# [WIP] Fetch the latest changes from TFS.
export def "main fetch" [
  --no-branches
] {
  jj git export
  git tfs fetch
  jj git import
}

# [WIP] Check in your changes as a series of changesets.
export def "main push" [
  --message (-m): string, # The message to check in changes with
  --squash,               # Squash all changes into a single changeset
] {
  jj git export
  git tfs ...([
    (if $squash { "checkin" } else { "rcheckin" })
    (if $message != null { [ -m $message ] } else { null })

  ] | compact | flatten)
  jj git import
}

# Commands for working with TFVC shelvesets.
export def "main shelveset" [] {
  help main shelveset
}

# [WIP] Delete a shelveset.
export def "main shelveset delete" [
  descriptor: string, # The unique descriptor for your shelveset
] {
  jj git export
  git tfs shelve-delete $descriptor
  jj git import
}

# 
export def "main shelveset import" [
  descriptor: string,  # The unique descriptor for the shelveset
  bookmark: string,    # The bookmark to point at this shelveset
  --user (-u): string, # The user who owns this shelveset
] {
  jj git export
  git tfs unshelve $descriptor $bookmark ([
    (if $user != null { [ $"-u=($user)" ] } else { null })
  ])
  jj git import
}

export def "main shelveset list" [
  --all-users (-a), # List shelvesets from all users
] {
  jj git export
  git tfs shelve-list ...([
    (if $all_users { [ -u=all ] } else { null })
  ] | compact | flatten)
  jj git import
}

# Creates a TFVC shelveset from a Jujutsu bookmark.
export def "main shelveset push" [
  descriptor: string,      # The unique descriptor for your shelveset.
  --bookmark (-b): string, # Push only this bookmark.
  --change (-c): string,   # Push this shelveset by creating a bookmark based on its change ID.
] {
  if $bookmark != null and $change != null {
    return (error make {
      msg: "--bookmark (-b) and --change (-c) cannot be used at the same time.",
    })
  }

  jj git export
  git tfs shelve $descriptor ([
    ($bookmark | default (if $change {
      let prefix = (jj config get git.push-bookmark-prefix)
      let change_id = (jj log --no-graph --color never -r $change -T "change_id.shortest(12)")
      [ $prefix + $change_id ]
    } else {
      null
    })
  )  ] | compact | flatten)
  jj git import
}

