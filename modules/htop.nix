{ lib, ... }:

{
  flake.modules.homeManager.htop.programs.htop.settings.show_cpu_frequency = false |> lib.mkForce;
}
