{ lib, ... }:

{
  programs.htop.settings.show_cpu_frequency = false |> lib.mkForce;
}
