def parse_upstream_input [upstream_input: string] {
  let cleaned = $upstream_input
    | str trim
    | str replace --regex '/+$' ''

  let git_ssh = $cleaned | parse --regex '^git@(?P<host>[^:]+):(?P<path>.+)$'
  if ($git_ssh | is-not-empty) {
    let path = $git_ssh.0.path | str replace --regex '\.git$' ''
    let repo = $path | split row "/" | last
    return { host: $git_ssh.0.host, path: $path, repo: $repo }
  }

  if ($cleaned | str contains "://") {
    let parsed = $cleaned | parse --regex '^https?://(?P<host>[^/]+)/(?P<path>.+)$'
    if ($parsed | is-not-empty) {
      let path = $parsed.0.path | str replace --regex '\.git$' ''
      let repo = $path | split row "/" | last
      return { host: $parsed.0.host, path: $path, repo: $repo }
    }
  }

  let host_path = $cleaned | parse --regex '^(?P<host>[^/]+\\.[^/]+)/(?P<path>.+)$'
  if ($host_path | is-not-empty) {
    let path = $host_path.0.path | str replace --regex '\.git$' ''
    let repo = $path | split row "/" | last
    return { host: $host_path.0.host, path: $path, repo: $repo }
  }

  let shorthand = $cleaned | parse --regex '^(?P<owner>[^/]+)/(?P<repo>[^/]+)$'
  if ($shorthand | is-not-empty) {
    let repo = $shorthand.0.repo | str replace --regex '\.git$' ''
    return { host: "github.com", path: $"($shorthand.0.owner)/($repo)", repo: $repo }
  }

  { host: "", path: "", repo: "" }
}

def get_fork_owner [host: string] {
  try {
    jj config get $"fork-owners.\"($host)\"" | str trim
  } catch {
    ""
  }
}

def infer_repo_path [upstream_input: string] {
  let parsed = parse_upstream_input $upstream_input
  if ($parsed.path | is-empty) { "" } else { $parsed.path }
}

def normalize_upstream_url [upstream_input: string] {
  let parsed = parse_upstream_input $upstream_input
  if ($parsed.host | is-empty) {
    $upstream_input | str trim | str replace --regex '/+$' ''
  } else {
    $"https://($parsed.host)/($parsed.path)"
  }
}

def main [upstream_arg?: string] {
  let upstream_input = if ($upstream_arg | is-empty) {
    input "Upstream repository (URL, SSH, owner/repo, or host/repo): "
    | str trim
  } else {
    $upstream_arg | str trim
  }

if ($upstream_input | is-empty) {
  error make { msg: "Upstream URL is required." }
}

let upstream_url = normalize_upstream_url $upstream_input
if (not ($upstream_url | str starts-with "https://")) {
  error make { msg: "Upstream URL must be HTTPS (https://...)." }
}
let parsed_upstream = parse_upstream_input $upstream_input
let default_repo_path = infer_repo_path $upstream_input
let repo_name = $parsed_upstream.repo
let upstream_host = if ($parsed_upstream.host | is-empty) { "github.com" } else { $parsed_upstream.host }
let fork_owner = get_fork_owner $upstream_host
let default_origin_url = if ($repo_name | is-empty) or ($fork_owner | is-empty) {
  ""
} else {
  $"git@($upstream_host):($fork_owner)/($repo_name).git"
}

  let origin_prompt = if ($default_origin_url | is-empty) {
    "Fork repository URL (SSH): "
  } else {
    "Fork repository URL (SSH) (default: " + $default_origin_url + "): "
  }
  let origin_url_input = (input $origin_prompt | str trim)

let origin_url = if ($origin_url_input | is-empty) {
  if ($default_origin_url | is-empty) {
    error make { msg: "Origin URL is required." }
  } else {
    $default_origin_url
  }
} else {
  $origin_url_input
}

if ($origin_url | is-empty) {
  error make { msg: "Origin URL is required." }
}
if (not ($origin_url | str starts-with "git@")) and (not ($origin_url | str starts-with "ssh://")) {
  error make { msg: "Origin URL must be SSH (git@... or ssh://...)." }
}

  let repo_path_prompt = if ($default_repo_path | is-empty) {
    "Repository path under ~/contrib: "
  } else {
    "Repository path under ~/contrib (default: " + $default_repo_path + "): "
  }
  let repo_path_input = (input $repo_path_prompt | str trim)

let repo_path = if ($repo_path_input | is-empty) {
  if ($default_repo_path | is-empty) {
    error make { msg: "Repository path is required when no default can be inferred from upstream URL." }
  } else {
    $default_repo_path
  }
} else {
  $repo_path_input
}

let repo_dir = [$nu.home-dir "contrib" $repo_path] | path join

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
}
