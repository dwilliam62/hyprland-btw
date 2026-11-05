# freebuff-cli -- the freebuff coding agent, always run through npx.
#
# freebuff ships to npm as a thin launcher package: index.js and launcher.js
# download the platform native binary (sha256-verified against binaryChecksums
# in its package.json) into ~/.config/manicode on first run, so there is no
# self-contained derivation to build here and no flake input to wire up.
#
# That download is a generic dynamically linked ELF (interpreter
# /lib64/ld-linux-x86-64.so.2, DT_NEEDED only glibc), so it needs
# programs.nix-ld, enabled in configuration.nix. Without nix-ld, NixOS'
# stub-ld refuses to start it with "Could not start dynamically linked
# executable".
#
# The wrapper is named freebuff-cli and resolves the package through npx on
# purpose: a globally installed or desktop build called `freebuff` can shadow
# the CLI, while `npx freebuff` always resolves the npm CLI package.
#
# Updates -- nothing here pins a version, and freebuff itself has no --update
# flag. Two layers keep themselves current:
#   * npx re-resolves the bare `freebuff` spec against the npm `latest` tag on
#     each run and reinstalls its cached copy under ~/.npm/_npx when a newer
#     release is published.
#   * freebuff's launcher checks the registry shortly after startup, verifies
#     the platform binary's sha256 against the release's binaryChecksums, and
#     installs it when the session exits (or on the next launch).
# `freebuff-cli --update` forces both now: it drops the npx cache entry and the
# downloaded binary, then reruns the launcher, whose ensureBinaryReady()
# re-downloads the current release synchronously. --version is the one flag
# that completes that download and exits instead of starting the TUI.
#
# A normal launch also compares the downloaded binary's recorded version with
# the npm `latest` tag and warns when it is behind, because the launcher stages
# its own update silently and only installs it on exit.
{pkgs, ...}: let
  binPath = pkgs.lib.makeBinPath [
    pkgs.coreutils # rm/dirname for the update path
    pkgs.nodejs # provides npm/npx, and the registry check below
  ];
in {
  home.packages = [
    (pkgs.writeShellScriptBin "freebuff-cli" ''
            # Fail fast when the system cannot start foreign ELF binaries.
            #
            # NixOS points /lib64/ld-linux-x86-64.so.2 at stub-ld, which refuses to
            # start them, so the binary this package downloads would otherwise die
            # with "Could not start dynamically linked executable". programs.nix-ld
            # (configuration.nix) points that path at nix-ld instead and links the
            # real loader into the system profile.
            #
            # Test the loader file rather than `command -v nix-ld`: the nix-ld
            # module puts only a buildEnv of libraries in systemPackages, so there is
            # no nix-ld binary on PATH to find.
            if [ ! -x /run/current-system/sw/share/nix-ld/lib/ld.so ]; then
              printf '%s\n' \
                "freebuff-cli: nix-ld is not enabled on this system." \
                "The freebuff binary is a generic dynamically linked executable," \
                "and NixOS' stub-ld refuses to start those." \
                "" \
                "Enable it in configuration.nix and rebuild:" \
                "  programs.nix-ld.enable = true;" \
                "  sudo nixos-rebuild switch --flake ." >&2
              exit 1
            fi

            # Ensure npm/npx are available regardless of the caller's PATH
            export PATH=${binPath}:$PATH

            # Compare the downloaded binary's recorded version with the npm `latest`
            # tag and warn when it is behind. Every failure (no metadata yet,
            # offline, bad registry response) is silent and bounded by the request
            # timeout: the launcher does the authoritative update check itself.
            #
            # The heredoc terminator must stay at column 0, hence the unindented
            # `NODE`.
            warn_if_stale() {
              node <<'NODE'
              const fs = require('fs')
              const os = require('os')
              const https = require('https')
              const path = require('path')

              const meta = path.join(
                os.homedir(),
                '.config',
                'manicode',
                'freebuff-metadata.json'
              )
              let current = null
              try {
                current = JSON.parse(fs.readFileSync(meta, 'utf8')).version
              } catch (error) {
                process.exit(0)
              }
              if (typeof current !== 'string' || current.length === 0) process.exit(0)

              function newer(candidate, installed) {
                const core = (version) => version.split('-')[0].split('.').map(Number)
                const a = core(candidate)
                const b = core(installed)
                for (let i = 0; i < 3; i++) {
                  const left = a[i] || 0
                  const right = b[i] || 0
                  if (left !== right) return left > right
                }
                const aPre = candidate.includes('-')
                const bPre = installed.includes('-')
                if (aPre === bPre) return false
                return !aPre
              }

              const req = https.get(
                'https://registry.npmjs.org/freebuff/latest',
                { headers: { accept: 'application/json' } },
                (res) => {
                  if (res.statusCode !== 200) {
                    res.resume()
                    return
                  }
                  let body = ""
                  res.setEncoding('utf8')
                  res.on('data', (chunk) => {
                    body += chunk
                  })
                  res.on('end', () => {
                    let latest = null
                    try {
                      latest = JSON.parse(body).version
                    } catch (error) {
                      return
                    }
                    if (typeof latest !== 'string' || latest.length === 0) return
                    if (!newer(latest, current)) return
                    process.stderr.write(
                      'freebuff-cli: freebuff ' +
                        current +
                        ' is behind npm latest ' +
                        latest +
                        '.\n' +
                        'It updates when a session exits, or refresh now with: ' +
                        'freebuff-cli --update\n'
                    )
                  })
                }
              )
              req.setTimeout(1000, () => req.destroy())
              req.on('error', () => {})
      NODE
            }

            # Force both update layers immediately instead of waiting for npx's
            # registry check and the launcher's deferred install.
            if [ "$1" = "--update" ]; then
              printf '%s\n' \
                "freebuff-cli: refreshing the npx wrapper and the downloaded binary..." >&2

              # npx keys its cache by the spec string, so a stale copy would
              # otherwise be reused. Drop every cached copy of this package (other
              # npx packages in the same cache are untouched).
              for cached in "$HOME"/.npm/_npx/*/node_modules/freebuff; do
                [ -d "$cached" ] || continue
                rm -rf "$cached"
                rm -f "$(dirname "$cached")/.bin/freebuff"
              done

              # Without metadata the launcher cannot consider the binary current, so
              # ensureBinaryReady() downloads the latest release before the first
              # spawn. Credentials and history in the same directory are preserved.
              rm -f "$HOME/.config/manicode/freebuff" \
                "$HOME/.config/manicode/freebuff-metadata.json"

              # Reinstalls the wrapper (resolving `latest` again) and lets the
              # launcher download the matching binary; --version prints it and exits.
              exec npx --yes --prefer-online freebuff --version
            fi

            # --version/--help are answered by the installed binary and must stay
            # quiet, so only a normal launch pays for the staleness check.
            case "$1" in
              -v | --version | -h | --help) ;;
              *) warn_if_stale ;;
            esac

            # `--yes` skips npx's interactive "Ok to proceed?" install prompt so the
            # first run also works from scripts and non-interactive shells.
            exec npx --yes freebuff "$@"
    '')
  ];
}
