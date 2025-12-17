{
  flake.modules.nixos.ipv6 = {
    networking.useNetworkd = true;
    systemd.network = {
      enable = true;
      networks."10-ens3" = {
        name = "ens3";
        DHCP = "ipv4";
        address = [ "2a0a:4cc0:c0:b2b::/64" ];
        routes = [ { Gateway = "fe80::1"; } ];
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
