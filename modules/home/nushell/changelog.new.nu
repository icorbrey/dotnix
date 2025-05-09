export def main [revset: string] {
  $revset
    | without_empty
    | get_changes
}

# Empty commits by definition have no changes to log.
def without_empty [revset: string] {
  $"(($revset)) ~ empty\()"
}

def get_changes [revset: string] {
  # Format the commit message as JSON.
  let template = '
    "{
      \"title\": " ++ description.first_line().escape_json ++ ",
      \"body\": " ++ description.remove_prefix(description.first_line()).trim().escape_json() ++ "
    }"
  '
  
  $"[(jj log --no-graph -r $revset -T $template)]"
    | from json
}
