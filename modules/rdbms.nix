{
  flake.modules.nixos.rdbms =
    { lib, pkgs, ... }:

    {
      services = {
        mysql = {
          enable = true;
          package = pkgs.mysql84;
          settings.mysqld = lib.mkMerge [
            {
              skip_name_resolve = false; # https://serverfault.com/questions/393862/mysql-warning-ip-address-could-not-be-resolved/393874#393874
            }
            {
              performance_schema = false;
              slow_query_log = true;
              # log-error = "/var/log/mysql/error.log";
            }
            {
              innodb_buffer_pool_size = "512M";
              innodb_buffer_pool_instances = 2;
            }
            {
              # skip-log-bin = true;
              binlog_expire_logs_seconds = 15 * 86400;
              # innodb_redo_log_capacity = "512M";
              # innodb_log_buffer_size = "64M";
              # innodb_log_writer_threads = false;
            }
            {
              # innodb_read_ahead_threshold = 0;
              innodb_io_capacity = 1000;
              innodb_io_capacity_max = 3000;
              innodb_lru_scan_depth = 512;
              innodb_flush_method = "fsync";
            }
            {
              innodb_log_write_ahead_size = "16K"; # https://shatteredsilicon.net/mysql-mariadb-innodb-on-zfs/
              innodb_doublewrite = false;
              innodb_use_native_aio = false;
              innodb_use_fdatasync = true; # https://vadosware.io/post/everything-ive-seen-on-optimizing-postgres-on-zfs-on-linux/#bonus-what-discovering-silent-fdatasync-data-corruption-looks-like
            }
            {
              # innodb_read_io_threads = 8;
              # innodb_write_io_threads = 8;
            }
            {
              tmp_table_size = "128M";
              max_heap_table_size = "128M";
              temptable_max_ram = "128M";
              temptable_max_mmap = "128M";
            }
            {
              open_files_limit = 102400;
              table_open_cache = 51200;
            }
          ];
        };
        postgresql = lib.mkMerge [
          {
            enable = true;
            package = pkgs.postgresql_17;
          }
          {
            extensions = [ pkgs.postgresql17Packages.pg_bigm ];
            settings.shared_preload_libraries = [ "pg_bigm" ]; # https://github.com/pgbigm/pg_bigm
          }
          {
            settings = lib.mkMerge [
              {
                # https://www.postgresql.org/docs/current/auto-explain.html
                shared_preload_libraries = [ "auto_explain" ];
                "auto_explain.log_min_duration" = 1000;
                # "auto_explain.log_analyze" = true;
                "auto_explain.log_buffers" = true;
                "auto_explain.log_wal" = true;
                "auto_explain.log_timing" = false;
                "auto_explain.log_triggers" = true;
                "auto_explain.log_verbose" = true;
                "auto_explain.log_settings" = true;
                "auto_explain.log_nested_statements" = true;
              }
              {
                track_io_timing = true;
                track_wal_io_timing = true;
                track_functions = "all";
                # log_statement_stats = true;
                log_min_messages = "INFO";
                log_min_duration_statement = "20s";
                log_autovacuum_min_duration = "20s";
                log_temp_files = 0;
              }
              {
                temp_buffers = "32MB";
                synchronous_commit = false;
                checkpoint_timeout = "10min";
                wal_compression = "zstd";
                # default_toast_compression = lz4;
                # jit = false;
                wal_writer_delay = "1s";
                commit_delay = 10000; # 10ms
                # max_parallel_workers = 0;
              }
              {
                autovacuum_naptime = "1s";
                autovacuum_vacuum_scale_factor = 0.02;
                autovacuum_analyze_scale_factor = 0.01;
                autovacuum_vacuum_cost_delay = "1ms";
                vacuum_cost_delay = 0.01; # 10ns
                vacuum_cost_limit = 1000;
              }
              {
                # https://github.com/le0pard/pgtune
                max_connections = 100;
                work_mem = "6MB";
                shared_buffers = "1GB";
                effective_cache_size = "3GB";
                maintenance_work_mem = "512MB";
                # checkpoint_completion_target = 0.9;
                default_statistics_target = 500;
                random_page_cost = "1.1";
                # huge_pages = true;
                min_wal_size = "2GB";
                max_wal_size = "8GB";
              }
              {
                # https://vadosware.io/post/everything-ive-seen-on-optimizing-postgres-on-zfs-on-linux/
                # https://news.ycombinator.com/item?id=29647645
                full_page_writes = false;
                wal_init_zero = false;
                wal_recycle = false;
                wal_sync_method = "fdatasync"; # https://www.postgresql.org/docs/current/pgtestfsync.html
                effective_io_concurrency = 500;
              }
            ];
          }
          {
            settings.listen_addresses = "localhost, 172.17.0.1" |> lib.mkForce; # host.docker.internal
            authentication = "host all all 172.16.0.0/12 scram-sha-256";
          }
        ];
      };
    };
  flake.modules.homeManager.rdbms.home.file.".psqlrc".text = "\\timing on"; # https://dba.stackexchange.com/questions/156015/how-to-set-timing-on-permanently-in-postgresql/156016#156016
}
