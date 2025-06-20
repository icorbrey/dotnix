use std/log
use std null-device

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

def "jj snapshot" [] {
  jj status o+e> (null-device) 
}

# Clone a repository from TFS as a colocated Jujutsu repository.
export def "main clone" [
  path: string,         # The path in TFS to clone from
  destination?: string, # The directory to place the repository in
  --url: string,        # The URL of the TFS server to talk to
  --full-history,       # Clone the full change history rather than just the latest changeset. This will take a LONG time.
] {
  let tfs_url = coalesce_tfs_url $url
  let dest = $destination | default ($path | path basename)

  if $full_history {
    git tfs clone $tfs_url $path $dest
  } else {
    git tfs quick-clone $tfs_url $path $dest
  }

  cd $dest
  jj git init --colocate
}

export def "main clone list" [
  --url: string,  # The URL to use for the TFS server
] {
  let tfs_url = coalesce_tfs_url $url

  git tfs list-remote-branches $tfs_url
}

# Fetch the latest changes from TFS.
export def "main fetch" [
  --no-branches
] {
  git tfs fetch
  jj snapshot
}
 
# Check in this branch as an approved changeset.
export def "main approve" [
  --revision (-r): string, # The revision to identify the branch with. Defaults to @.
] {
  let change_id = $revision | default '@'
  jj squash -f $"reachable\(($change_id), trunk\()+..)" -t $"reachable\(($change_id), trunk\()+::) & trunk\()+"
  git tfs rcheckin
  jj snapshot
}

# Commands for working with TFVC shelvesets.
export def "main shelveset" [] {
  help main shelveset
}

# Delete a shelveset.
export def "main shelveset delete" [
  descriptor: string, # The unique descriptor for your shelveset
] {
  git tfs shelve-delete $descriptor
  jj snapshot
}

# 
export def "main shelveset import" [
  descriptor: string,  # The unique descriptor for the shelveset
  bookmark: string,    # The bookmark to point at this shelveset
  --user (-u): string, # The user who owns this shelveset
] {
  git tfs unshelve $descriptor $bookmark ...([
    (if $user != null { [ $"-u=($user)" ] } else { null })
  ])
  jj snapshot
}

export def "main shelveset list" [
  --all-users (-a), # List shelvesets from all users
] {
  git tfs shelve-list ...([
    (if $all_users { [ -u=all ] } else { null })
  ] | compact | flatten)
  jj snapshot
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

  git tfs shelve $descriptor ...([
    ($bookmark | default (if $change != null {
      let prefix = (jj config get git.push-bookmark-prefix)
      let change_id = (jj log --no-graph --color never -r $change -T "change_id.shortest(12)")
      [ $prefix + $change_id ]
    } else {
      null
    })
  )  ] | compact | flatten)
  jj snapshot
}

