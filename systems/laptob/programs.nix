let enabled = { enable = true; };
in {
  programs = {
    xfconf = enabled;
    dconf = enabled;
  };
}
