let types = [
  (type 🌱 Features      feat    )
  (type 🐞 Fixes         fix     )
  (type 🧹 Chores        chore   )
  (type 🕺 Style         style   )
  (type 📖 Documentation docs    )
  (type ♻️ Refactoring   refactor)
  (type ⚡ Performance   perf    )
  (type 🧪 Tests         test    )
  (type 🔧 Build         build   )
  (type 🐸 Other                 )
]

def type [emoji: string, label: string, identifier?: string] {
  {
    identifier: $identifier,
    label: $"($emoji) ($label)",
  }
}

export def main [revset: string] {
  let changes = $revset
    | without_empty
    | read_log
    | update title { parse_title }
    | update body { format_body }
    | into_groups
    | render
}

# Empty commits by definition have no changes to log.
def without_empty [] {
  each {|revset| $"(($revset)) ~ empty\() ~ description\(exact:\"\")" }
}

# Get the changes for the given revset.
def read_log [] {
  let revset = $in
  let template = '
    "{
      \"title\": " ++ description.first_line().escape_json() ++ ",
      \"body\": " ++ description.remove_prefix(description.first_line()).trim().escape_json() ++ "
    }"
  '
  
  $"[(jj log --no-graph -r $revset -T $template)]"
    | from json
}

# Parse the commit title into its component parts.
def parse_title [] {
  let title = $in
  let match_title = '(?:(?P<type>[a-z]+)(\((?P<scope>[^)]+)\))?[:!]\s+)?(?P<summary>.+)'

  let caps = $title
    | parse --regex $match_title
    | get 0

  {
    type: $caps.type,
    scope: $caps.scope,
    summary: (
      $caps.summary
        | str replace -r --all '`([^`]+)`'       '<code>$1</code>'
        | str replace -r --all '\*\*([^*]+)\*\*' '<strong>$1</strong>'
        | str replace -r --all '__([^_]+)__'     '<strong>$1</strong>'
        | str replace -r --all '\*([^*]+)\*'     '<em>$1</em>'
        | str replace -r --all '_([^_]+)_'       '<em>$1</em>'
    ),
  }
}

# Format the commit body for nice rendering in DevOps.
def format_body [] {
  let body = $in
  let bad_trailers = '(^(Co-authored-by|Signed-off-by|Change-Id|Reviewed-|BREAKING CHANGE):|\[((no|skip) ci| ci (no|skip))\])'
  
  $body
    | lines
    | where $it !~ $bad_trailers
    | str join "\n"
    | split row "\n\n"
    | each {|paragraph|
      $paragraph
        | str replace -r --all '\n' ' '
        | str trim
    }
    | str join "\n<br />"
}

def get_type [] {
  let type = $in
  $types
    | enumerate
    | where $it.item.identifier == $type
    | each {|type|
      {
        label: $type.item.label,
        order: $type.index,
      }
    }
    | get 0
}

def into_groups [] {
  group-by type
    | transpose type changes
    | update type { get_type }
    | sort-by type.order
    | update changes {|group|
      $group.changes
        | group-by title.scope
        | transpose scope changes
        | sort-by scope
    }
    | rename --column { changes: scopes }
}

def render [] {
  let categories = $in
  for category in $categories {
    if ($category.scopes | is-empty) {
      continue
    }

    print $'## ($category.type.label)'
    print ''
    print ''

    for group in $category.scopes {
      if ($group.scope | is-empty) or (($group.changes | length) == 1) {
        print ($group.changes | draw_change true | str join "\n")
      } else {
        print 'TK'
      }
    }
  }
}


def draw_change [show_scope: bool] {
  let change = $in | get 0

  let scope = if ($change.title.scope | is-empty) or (not $show_scope) {
    ''
  } else {
    $'<strong>($change.title.scope)</strong>: '
  }

  if ($change.body | is-empty) {
    return $'- ($scope)($change.title.summary)'
  } else {
    return $'- <details>
      <summary>($scope)($change.title.summary)</summary>
      <br />($change.body)
    </details>'
  }
}
