{ ... }:

{
  users.users.n0099.openssh.authorizedKeys.keyFiles = [
    # https://github.com/oddlama/agenix-rekey/issues/88
    # https://github.com/NixOS/nixpkgs/blob/3bcc93c5f7a4b30335d31f21e2f1281cba68c318/nixos/modules/services/networking/ssh/sshd.nix#L688-L689
    ./toBeFilled/users/n0099/sshPublicKeys
  ];
}
