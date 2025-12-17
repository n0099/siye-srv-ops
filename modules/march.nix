{
  flake.modules.nixos.march = {
    nixpkgs.hostPlatform = {
      # https://wiki.nixos.org/wiki/Build_flags#Building_the_whole_system_on_NixOS
      # https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
      gcc.arch = "znver5";
      gcc.tune = "znver5";
      system = "x86_64-linux";
    };
    nix.settings.system-features = [
      # https://github.com/NixOS/nixpkgs/blob/5b5be50345d4113d04ba58c444348849f5585b4a/nixos/modules/config/nix.nix#L53-L58
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
    ]
    ++ [ "gccarch-znver5" ];
  };
}
