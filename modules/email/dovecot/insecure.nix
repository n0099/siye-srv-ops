{
  flake.modules.nixos."containers/email/dovecot" = {
    # https://github.com/NixOS/nixpkgs/pull/590955
    nixpkgs.config.permittedInsecurePackages = [
      "dovecot-2.3.21.1"
      "dovecot-pigeonhole-0.5.21.1"
    ];
  };
}
