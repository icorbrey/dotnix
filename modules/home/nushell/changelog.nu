# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ changelog.nu – produce collapsible-Markdown release notes from jj log    ║
# ║                                                                          ║
# ║ Usage: nu changelog.nu [<revset>]                                        ║
# ║        – <revset> always appends "~empty()" to drop empty commits.       ║
# ║ Needs: Nushell 0.91+ • jj 0.24+                                          ║
# ╚══════════════════════════════════════════════════════════════════════════╝

export def main [revset: string] {

  # 1 ▸ Revset that always filters out empty commits
  let rev = $"(($revset)) ~empty\()"

  # 2 ▸ jj template that prints one JSON object per line
  let jj_tpl = "'{ \"title\": ' ++ description.first_line().escape_json() ++ ', \"body\": ' ++ description.remove_prefix(description.first_line()).trim().escape_json() ++ ' },'"

  # 3 ▸ Pull commits → list of structured records
  let commits = $"[(jj log --no-graph -r $rev -T $jj_tpl)]" | from json

  # 4 ▸ Helper maps & constants
  let typemap = {
    feat     : [🌱 "Features"],
    fix      : [🐞 "Fixes"],
    chore    : [🧹 "Chores"],
    style    : [🕺 "Style"],
    docs     : [📚 "Docs"],
    refactor : [♻️ "Refactor"],
    perf     : [⚡ "Performance"],
    test     : [✅ "Tests"],
    build    : [🔧 "Other"],
  }
  let order       = [feat fix chore style docs refactor perf test build]
  let trailer_re  = '^(Co-authored-by|Signed-off-by|Change-Id|Reviewed-|BREAKING CHANGE):'

  # converts the minimal Markdown we expect in commit titles → HTML tags
  def md->html [s: string] {
    $s
    | str replace -r --all '`([^`]+)`'      '<code>$1</code>'
    | str replace -r --all '\*\*([^*]+)\*\*' '<strong>$1</strong>'
    | str replace -r --all '__([^_]+)__'     '<strong>$1</strong>'
    | str replace -r --all '\*([^*]+)\*'     '<em>$1</em>'
    | str replace -r --all '_([^_]+)_'       '<em>$1</em>'
  }

  # 5 ▸ Parse each commit header/body into a tidy record
  let parsed = (
    $commits | each {|c|
      # Conventional-commit regex
      let caps = ($c.title | parse --regex '(?P<type>[a-z]+)(\((?P<scope>[^)]+)\))?[:!]\s+(?P<summary>.+)')

      if ($caps | is-empty) {
        # non-conventional → bucket as build/general
        {
          type:    "build",
          scope:   "general",
          summary: $c.title,
          html_summary: (md->html $c.title),
          body:    ($c.body
                    | lines
                    | where $it !~ $trailer_re
                    | str join "\n")
        }
      } else {
        let cap      = ($caps | get 0)
        let raw_body = (
            $c.body
            | lines
            | where $it !~ $trailer_re          # drop trailers
            | str join "\n"                     # back to single string
        )
        
        # ► collapse layout:
        let clean_body = (
            $raw_body
            | split row "\n\n"                  # ① split into paragraphs
            | each {|p|                         # ② in each paragraph …
                $p
                | str replace -r --all '\n' ' '       #    turn inner newlines → spaces
                | str trim
              }
            | str join "\n<br />"                     # ③ re-join paragraphs with ONE \n
        )
        {
          type:    ($cap.type),
          scope:   (($cap.scope | default "general") | str trim),
          summary: ($cap.summary),
          html_summary: (md->html $cap.summary),
          body:    $clean_body
        }
      }
    }
  )

  # 6 ▸ Emit Markdown grouped by type ▸ then by scope
  for t in $order {
    let rows = ($parsed | where type == $t)
    if ($rows | length) > 0 {
      let emoji   = ($typemap | get $t | get 0)
      let section = ($typemap | get $t | get 1)

      print $"## ($emoji) ($section)\n"

      # group the commits by scope → [{ scope, commits }]
      let scopes = (
        $rows | group-by scope
              | transpose scope commits
              | sort-by scope
      )

      $scopes | each {|grp|
        let scope_name = $grp.scope            # e.g. "offers" or "general"
        let commits    = $grp.commits
        let n          = ($commits | length)

        # helper to produce one dropdown / plain bullet -----------------------
        def --env make-bullet [c prefix?: string = ""] {
          if ($c.body | str length) > 0 {
            if ($prefix | str length) > 0 {
              print "- <details>"
              print $"    <summary>($prefix)($c.html_summary)</summary>\n"
              print $"    <br />($c.body)"
              print "  </details>"
            } else {
              print "- <details>"
              print $"    <summary>($c.html_summary)</summary>\n"
              print $"    <br />($c.body)"
              print "  </details>"
            }
          } else {
            if ($prefix | str length) > 0 {
              print $"- ($prefix)($c.summary)"
            } else {
              print $"- ($c.summary)"
            }
          }
        }

        # --------------------------------------------------------------------
        if $n > 1 {
          # ▸ Multiple commits for this scope → nested list
          let header = if $scope_name == "general" { "misc" } else { $scope_name }
          print $"- **($header)**"
          $commits | each {|c|
            # nested bullet two spaces in
            if ($c.body | str length) > 0 {
              print "  - <details>"
              print $"      <summary>($c.html_summary)</summary>\n"
              print $"      <br />($c.body)"
              print "    </details>"
            } else {
              print $"  - ($c.summary)"
            }
          }
          print ""          # blank line after this scope group
        } else {
          # ▸ Just one commit → inline bullet
          let c = ($commits | get 0)
          let prefix = if $scope_name == "general" { "" } else { $"<strong>($scope_name)</strong>: " }
          make-bullet $c $prefix
        }
      }
      
      print ""              # blank line after each type section
    }
  }
}
