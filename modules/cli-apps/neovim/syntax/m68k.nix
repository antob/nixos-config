{ ... }:
{
  home.file.".config/nvim/ftdetect/m68k.vim".text = /* vim */ ''
    au BufRead,BufNewFile *.s set filetype=asm68k
    set commentstring=;\ %s
  '';
}
