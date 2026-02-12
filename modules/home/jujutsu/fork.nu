def infer_repo_path [upstream_url: string] {
  let cleaned = $upstream_url
    | str trim
    | str replace --regex '/+$' ''

  let parsed = $cleaned
    | parse --regex '^(?:https?://)?[^/]+/(?P<path>.+)$'

  if ($parsed | is-empty) {
    ""
  } else {
    $parsed.0.path | str replace --regex '\.git$' ''
  }
}

let upstream_url = (
  input "Upstream repository URL (HTTPS): "
  | str trim
)

if ($upstream_url | is-empty) {
  error make { msg: "Upstream URL is required." }
}

let origin_url = (
  input "Fork repository URL (SSH): "
  | str trim
)

if ($origin_url | is-empty) {
  error make { msg: "Origin URL is required." }
}

let default_repo_path = infer_repo_path $upstream_url

let repo_path_input = (
  input $"Repository path under ~/contrib \(default: ($default_repo_path)\): "
  | str trim
)

let repo_path = if ($repo_path_input | is-empty) {
  if ($default_repo_path | is-empty) {
    error make { msg: "Repository path is required when no default can be inferred from upstream URL." }
  } else {
    $default_repo_path
  }
} else {
  $repo_path_input
}

let repo_dir = [$nu.home-path "contrib" $repo_path] | path join

jj git clone $origin_url $repo_dir

let trunk_alias = (
  jj config get --repository $repo_dir 'revset-aliases."trunk()"'
  | str trim
)

let parsed_trunk = (
  $trunk_alias
  | parse --regex '^(?P<branch>.+)@origin$'
)

if ($parsed_trunk | is-empty) {
  error make {
    msg: $"Could not infer trunk branch from trunk() value: ($trunk_alias)"
    help: "Expected trunk() to be in the form <branch>@origin immediately after clone."
  }
}

let trunk_branch = $parsed_trunk.0.branch

jj git remote add upstream $upstream_url --repository $repo_dir
jj git fetch --remote upstream --repository $repo_dir
jj bookmark track $"($trunk_branch)@upstream" --repository $repo_dir

do {
  cd $repo_dir
  jj config set --repo 'revset-aliases."trunk()"' $trunk_branch
}
