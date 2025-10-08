{ lib, ... }:

{
  programs.htop.settings.show_cpu_frequency = lib.mkForce false;
}
