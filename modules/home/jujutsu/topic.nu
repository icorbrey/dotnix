# # Topics, jank edition.
#
# For an explanation of topics, see:
# https://github.com/jj-vcs/jj/blob/push-yuslknovtlto/docs/design/topics.md
#
# ```toml
# [aliases]
# topic = ["util", "exec", "nu", "path/to/topic.nu"]
# ```

# Commands for working with topics.
export def main [] {
  help main
}

# Create a new topic with an optional definition.
export def "main create" [
  name: string,
  definition?: string
] {
  if (topic-exists $name) {
    echo $"Topic `($name)` already exists."
    return;
  }

  set-topic-definition $name (
    $"\(($definition | default "none()")\)"
  )
}

# Delete a topic by name.
export def "main delete" [
  name: string
] {
  if (!(topic-exists $name)) {
    echo $"Topic `($name)` does not exist."
    return;
  }

  jj config unset --repo (topic-path $name)
}

# Add a revision to a topic.
export def "main add" [
  topic: string,
  revision: string,
] {
  if (!(topic-exists $name)) {
    echo $"Topic `($name)` does not exist. You can create it with `jj topic create ($name)`."
    return;
  }

  let definition = (get-topic-definition $name)
  set-topic-definition $name (
    if ($definition | str contains $"~ \(($revision)\)") {
      ($definition | str replace $"~ \(($revision)\)" $"| \(($revision)\)")
    } else {
      $"($definition) | \(($revision)\)"
    }
  )
}

# Remove a revision from a topic.
export def "main remove" [
  topic: string,
  revision: string,
] {
  if (!(topic-exists $name)) {
    echo $"Topic `($name)` does not exist. You can create it with `jj topic create ($name)`."
    return;
  }

  let definition = (get-topic-definition $name)
  set-topic-definition $name (
    if ($definition | str contains $"| \(($revision)\)") {
      ($definition | str replace $"| \(($revision)\)" $"~ \(($revision)\)")
    } else {
      $"($definition) ~ \(($revision)\)"
    }
  )
}

def topic-path [name: string] {
  $"revset-aliases.'topics/($name)'"
}

def set-topic-definition [name: string, definition: string] {
  jj config set --repo (topic-path $name) $definition
}

def get-topic-definition [name: string] {
  jj config get --repo (topic-path $name)
    | split row '\n'
    | get 0
    | str trim
}

def topic-exists [name: string] {
  (get-topic-definition $name) != null
}
