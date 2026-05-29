{...}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    shellWrapperName = "yy";
  };

  xdg.configFile = {
    "yazi/yazi.toml".source = ./yazi.toml;
    "yazi/keymap.toml".source = ./keymap.toml;
    "yazi/theme.toml".source = ./theme.toml;
    "yazi/init.lua".source = ./init.lua;
    "yazi/package.toml".source = ./package.toml;

    "yazi/flavors".source = ./flavors;
    "yazi/plugins".source = ./plugins;
  };
}
