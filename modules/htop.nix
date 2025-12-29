{ lib, ... }:

{
  flake.modules.homeManager.n0099.programs.htop.settings.show_cpu_frequency = false |> lib.mkForce;
}
