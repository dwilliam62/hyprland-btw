{pkgs, ...}: {
  programs.btop = {
    enable = true;
    package = pkgs.btop.override {
      rocmSupport = true;
      cudaSupport = true;
    };
    settings = {
      color_theme = "/usr/share/btop/themes/HotPurpleTrafficLight.theme";
      theme_background = false;
      truecolor = true;
      vim_keys = true;
      rounded_corners = true;
      proc_tree = true;
      show_gpu_info = "on";
      show_uptime = true;
      show_coretemp = true;
      cpu_sensor = "auto";
      show_disks = true;
      only_physical = true;
      io_mode = true;
      io_graph_combined = false;
      shown_boxes = "cpu mem net proc gpu0 gpu1";
    };
  };
}
