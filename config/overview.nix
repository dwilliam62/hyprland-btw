{
  config,
  lib,
  ...
}: let
  overviewSource = ./overview;
in {
  # Quickshell-overview is a Qt6 QML app for Hyprland workspace overview
  # It shows all workspaces with live window previews, drag-and-drop support
  # Toggled via: SUPER + TAB (bound in config/hypr/binds.conf)
  # Started via exec-once in config/hypr/startup.conf

  # Seed the Quickshell overview code into ~/.config/quickshell/overview
  # Copy (not symlink) so QML module resolution works and users can edit files.
  #
  # Quickshell watches this directory and reloads the whole shell whenever it
  # changes, so the previous unconditional `rm -rf` + `cp -R` made it reload
  # against a missing or half-written tree on every rebuild. That is what
  # surfaced as "Overview is not a type" / "File not found" and left the
  # overview broken until the instance was restarted. Instead:
  #   * if the deployed tree already matches the source, leave it (and the
  #     running quickshell) completely untouched;
  #   * otherwise stage the new tree next to the target and swap it in with
  #     renames, so the window where the directory is missing stays tiny.
  home.activation.seedOverviewCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu
    DEST="$HOME/.config/quickshell/overview"
    SRC="${overviewSource}"

    mkdir -p "$HOME/.config/quickshell"

    if [ -d "$DEST" ] && diff -rq "$SRC" "$DEST" >/dev/null 2>&1; then
      : # already up to date
    else
      STAGE="$(mktemp -d "$HOME/.config/quickshell/.overview.XXXXXX")"
      cp -R "$SRC"/. "$STAGE"/
      chmod -R u+rwX "$STAGE"

      rm -rf "$DEST.old"
      if [ -e "$DEST" ]; then
        mv "$DEST" "$DEST.old"
      fi
      mv "$STAGE" "$DEST"
      rm -rf "$DEST.old"
    fi
  '';
}
