{ ... }:

{
  imports = [
    ./tls.nix
    ./mysql.nix
    ./postfix
    ./postfix/sasl-smtpd.nix
    ./dovecot
    ./roundcube.nix
  ];
  config = {
    containers.email = {
      n0099 = {
        subnetPrefix = "172.16.0.";
        outboundInterface = "ens3";
      };
      bindMounts."/var/spool/mail" = {
        hostPath = "/srv/mail";
        isReadOnly = false;
      };
      config.services = {
        # https://brokkr.net/2018/06/04/setting-up-postfix-and-dovecot-slowly-and-properly/
        postfix.enable = true;
        dovecot2.enable = true;
        roundcube.enable = true;
      };
    };
  };
}
