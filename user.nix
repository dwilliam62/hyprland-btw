# Single source of truth for the primary username.
#
# install.sh rewrites this file with the username chosen at install time.
# flake.nix reads it and threads `userName` into configuration.nix (the
# NixOS user account) and home.nix (the Home Manager profile), so nothing
# else needs to hardcode the username.
{
  userName = "dwilliams";
}
