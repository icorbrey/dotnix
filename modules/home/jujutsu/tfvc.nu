use std/log

# Commands for working with TFVC remotes.
export def main [] {
  help main
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

# Check in the given ref.
export def "main changeset push" [
  --bookmark (-b): string, # The bookmark to push as a changeset
  --change (-c): string, # The change ID to push as a changeset
] {
  if $bookmark != null and $change != null {
    return (error make {
      msg: "--bookmark (-b) and --change (-c) cannot be used at the same time.",
    })
  }

  if $bookmark == null and $change == null {
    return (error make {
      msg: "Must specify a bookmark (via --bookmark or -b) or a revision (via --change or -c) to shelve.",
    })
  }

  let ref = if $bookmark != null {
    if not (jj revision exists $bookmark) {
      return (error make {
        msg: $"Bookmark ($bookmark) does not exist."
      })
    }

    $bookmark
  } else {
    if not (jj revision exists $change) {
      return (error make {
        msg: $"Change ID ($change) does not exist or is ambiguous.",
      })
    }

    $change
  }

  let current = (jj log -r @ -T 'change_id' --no-graph --color=never) | complete | get stdout
  jj bookmark set -r $current $current
  jj new -r $ref --ignore-working-copy
  git tfs checkin
  jj edit $current
  jj bookmark forget $current
}

# Commands for working with TFVC shelvesets.
export def "main shelveset" [] {
  help main shelveset
}

# Delete a shelveset.
export def "main shelveset delete" [
  bookmark: string, # The unique descriptor for your shelveset
] {
  git tfs shelve-delete $bookmark
  jj snapshot
}

# 
export def "main shelveset import" [
  bookmark: string,    # The bookmark to point at this shelveset
  --user (-u): string, # The user who owns this shelveset
] {
  git tfs unshelve $bookmark $bookmark ...([
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
  --bookmark (-b): string, # Push only this bookmark.
  --change (-c): string,   # Push this shelveset by creating a bookmark based on its change ID.
] {
  if $bookmark != null and $change != null {
    return (error make {
      msg: "--bookmark (-b) and --change (-c) cannot be used at the same time.",
    })
  }

  if $bookmark != null {
    if not (jj revision exists $bookmark) {
      return (error make {
        msg: $"Bookmark ($bookmark) does not exist."
      })
    }

    git tfs shelve $bookmark $bookmark -f
    jj snapshot
  } else if $change != null {
    if not (jj revision exists $change) {
      return (error make {
        msg: $"Change ID ($change) does not exist or is ambiguous.",
      })
    }

    let bookmark = (jj log --no-graph --color never -r $change -T tfvc_push_bookmark)

    jj bookmark set $bookmark -r $change
    git tfs shelve $bookmark $bookmark -f
    jj snapshot
  } else {
    return (error make {
      msg: "Must specify a bookmark (via --bookmark or -b) or a revision (via --change or -c) to shelve.",
    })
  }
}

const tfs_url_key = "tfvc.url";

def coalesce_tfs_url [url?: string] {
  let result = $url | default (
    jj config get $tfs_url_key
      | split row '\n'
      | get 0
      | str trim
  )

  if $result != null {
    return $result
  }

  error make {
    msg: "No TFS server URL was provided.",
    help: "Either add e.g. `--url https://example.com` or run `jj config set --user tfvc.url https://example.com`.",
  }
}

def "jj revision exists" [
  revision: string # The revision to test for existence
] {
  (jj log -r $revision | complete | get exit_code) == 0
}

def "jj snapshot" [] {
  jj status | complete 
  return null
}
