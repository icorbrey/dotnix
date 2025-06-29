use std null-device

# Commands for dealing with code reviews.
#
# Configuration options:
#
# - `review.wip-prefix`: The prefix used for WIP branches (default `wip/`)
# - `review.review-prefix`: The prefix used for review branches (default ``)
export def main [] {
  help main
}

# View all changes made since the last round of reviews.
#
# Configuration options:
#
# - `review.wip-prefix`: The prefix used for WIP branches (default `wip/`)
# - `review.review-prefix`: The prefix used for review branches (default ``)
export def "main diff" [] {
  let review_ref = (review_ref) + "@origin"
  let wip_ref = wip_ref

  let review_commit_id = commit_id_at $review_ref
  let wip_commit_id = commit_id_at $wip_ref

  if $wip_commit_id == $review_commit_id {
    echo "Review ref is at WIP ref."
    return
  }
  
  jj interdiff -f $review_commit_id -t $wip_commit_id
}

# Publish your changes to be reviewed.
#
# Configuration options:
#
# - `review.wip-prefix`: The prefix used for WIP branches (default `wip/`)
# - `review.review-prefix`: The prefix used for review branches (default ``)
export def "main publish" [] {
  let review_ref = review_ref
  let wip_ref = wip_ref
  
  jj bookmark track ($review_ref + "@origin")
  let old_commit_id = commit_id_at $review_ref
  
  # Move the review ref to the wip ref and push it to the remote
  jj bookmark set $review_ref -r $wip_ref --allow-backwards
  jj git push --bookmark $review_ref

  # Clean up divergent changes and the review ref
  jj abandon $old_commit_id
  jj bookmark forget $review_ref
}

def commit_id_at [revset: string] {
  jj log -r $revset -T "commit_id" --no-graph --no-pager
}

def "config-get" [key: string, default: string] {
  (jj config get $key err> (null-device)
    | str trim
    | default -e $default)
}

def "config-get review-prefix" [] {
  config-get review.review-prefix ""
}

def "config-get wip-prefix" [] {
  config-get review.wip-prefix "wip/"
}

def wip_ref [] {
  (jj log -T "bookmarks ++ '\n'" -r "heads(::@ & bookmarks())" --no-graph --no-pager
    | str trim
    | split row -r '\n'
    | get 0)
}

def review_ref [] {
  (wip_ref
    | parse $"(config-get wip-prefix){ref}"
    | (config-get review-prefix) + $in.0.ref)
}

