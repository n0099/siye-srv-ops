{ config, lib, ... }:

{
  containers.email = lib.mkMerge [
    (
      let
        commonName = "n0099.net";
        cert = rec {
          dir = "/etc/ssl/certs/${commonName}";
          cert = "${dir}/fullchain.pem";
          privateKey = "${dir}/privkey.pem";
        };
      in
      {
        bindMounts.${cert.dir}.isReadOnly = true;
        config.services = {
          postfix = {
            sslCert = cert.cert;
            sslKey = cert.privateKey;
          };
          dovecot2 = {
            sslServerCert = cert.cert;
            sslServerKey = cert.privateKey;
          };
          roundcube.extraConfig = ''
            # https://www.roundcubeforum.net/index.php?topic=22035.0
            $config['imap_conn_options']['ssl']['peer_name'] ='${commonName}';
            $config['smtp_conn_options']['ssl']['peer_name'] ='${commonName}';
          '';
        };
      }
    )
    {
      config = lib.mkMerge [
        {
          services.postfix.config = {
            # https://utcc.utoronto.ca/~cks/space/blog/spam/TLSExternalTypes-2025-05
            lmtp_tls_protocols = ">=TLSv1.3";
            smtp_tls_protocols = ">=TLSv1.3";
            smtpd_tls_protocols = ">=TLSv1.2";
          };
          services.dovecot2.extraConfig = ''
            # https://doc.dovecot.org/2.3/configuration_manual/dovecot_ssl_configuration/
            ssl = required
            ssl_min_protocol = TLSv1.3
          '';
        }
        {
          services.postfix.config = {
            tls_append_default_CA = true;
            smtp_tls_session_cache_database = "btree:\${data_directory}/smtp_scache";
            smtpd_tls_received_header = true;
            smtpd_tls_auth_only = true;
          };
        }
        {
          services.dovecot2.enableDHE = true;
          security.dhparams = config.security.dhparams;
        }
      ];
    }
  ];
}
