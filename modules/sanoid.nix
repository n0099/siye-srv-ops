{
  flake.modules.nixos.sanoid =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    let
      logsDir = "/var/log/sanoid-upload";
      zfs = "/run/booted-system/sw/bin/zfs"; # https://github.com/NixOS/nixpkgs/blob/3acb677ea67d4c6218f33de0db0955f116b7588c/nixos/modules/services/backup/sanoid.nix#L109
      script = pkgs.writeShellApplication {
        name = "sanoid-upload.sh";
        bashOptions = [
          # https://mywiki.wooledge.org/BashFAQ/105
          # https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425
          "errexit"
          "nounset"
          "xtrace"
          "pipefail"
        ];
        runtimeInputs = with pkgs; [
          pv
          jq
          time
          rclone
        ];
        runtimeEnv = {
          # https://forum.rclone.org/t/multiple-config-rclone-conf-files/38219
          # https://forum.rclone.org/t/using-backend-flags-in-remotes-configuration-in-config-file/26889
          # https://rclone.org/docs/#precedence
          RCLONE_CONFIG_S3_TYPE = "s3";
          RCLONE_CONFIG_S3_PROVIDER = "AWS";
          RCLONE_CONFIG_S3_STORAGE_CLASS = "GLACIER";
          RCLONE_CONFIG_S3_NO_CHECK_BUCKET = true; # https://forum.rclone.org/t/s3-copy-illegal-location-constraint-exception-error-when-trying-to-copy-to-a-new-path/48888

          # https://rclone.org/s3/#s3-chunk-size
          # https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html
          # https://www.wolframalpha.com/input?i=10000%20*%20x%20MiB%20%3D%201TiB
          RCLONE_CONFIG_S3_CHUNK_SIZE = "100Mi";
          # RCLONE_CONFIG_S3_UPLOAD_CONCURRENCY = 8;
        };
        text = ''
          # based on https://github.com/n0099/azcopy_sanoid_zfs_snapshot.sh/tree/4380663fab1b44c05fee3a28d9572b7887ce614d

          # https://github.com/jimsalterjrs/sanoid/blob/dbcaeef1ac55bd3dd929b86a8f6082fef16f02b1/README.md#pre_snapshot_script
          [[ $SANOID_SCRIPT == post ]] || exit
          [[ $SANOID_PRE_FAILURE -eq 0 ]] || exit
          [[ $SANOID_TARGETS ]] || exit
          [[ $SANOID_SNAPNAMES ]] || exit

          # https://unix.stackexchange.com/questions/79064/how-to-export-variables-from-a-file/79077#79077
          set -o allexport
          # shellcheck disable=SC1091
          source "${config.age.secrets."sanoid.upload.env".path}"
          set +o allexport

          # https://stackoverflow.com/questions/5564418/exporting-an-array-in-bash-script/21941473#21941473
          # https://stackoverflow.com/questions/1469849/how-to-split-one-string-into-multiple-strings-separated-by-at-least-one-space-in/30212526#30212526
          read -ra buckets <<< "''${BUCKETS:?env var \$BUCKETS is not set}"

          month_dir=$(date -u +%Y-%m)
          prefix=rpool/ENC/

          zfs_send_to_rclone() {
            local bucket=$1
            local file_system=$2
            local snapshot=$3
            local latest_snapshot=''${4-}
            local send_params=()
            # https://stackoverflow.com/questions/3953645/ternary-operator-in-bash/25119904#25119904
            [[ -n $latest_snapshot ]] \
              && send_params+=('-i' "$file_system@$latest_snapshot" "$file_system@$snapshot") \
              || send_params+=("$file_system@$snapshot")

            # https://mywiki.wooledge.org/BashPitfalls#local_var.3D.24.28cmd.29
            local send_size
            send_size=$(${zfs} send -wLcPn "''${send_params[@]}" \
              | awk '/^size/{print $2}')
            [[ $send_size -gt 0 ]] || return 0

            # https://mywiki.wooledge.org/BashFAQ/050
            command time -v ${zfs} send -wLcP "''${send_params[@]}" \
              | pv -pterabfs "$send_size" \
              | command time -v rclone rcat \
                --error-on-no-transfer --ignore-existing \
                "$bucket/$month_dir/''${file_system#"''${prefix}"}/''${snapshot#autosnap_}"
            # https://forum.rclone.org/t/copyto-fail-on-error-and-dont-overwrite-files/47736
          }

          process_snapshots() {
            file_system=$1 # share with process_snapshot()
            # shellcheck disable=SC2329
            process_snapshot() {
              local snapshot=$2
              for bucket in "''${buckets[@]}"
              do
                case $snapshot in
                  autosnap_*_daily)
                    # https://mywiki.wooledge.org/BashPitfalls#local_var.3D.24.28cmd.29
                    local latest_snapshot
                    latest_snapshot=$(rclone lsjson --files-only \
                      "$bucket/$month_dir/''${file_system#"''${prefix}"}" \
                        | jq -r 'sort_by(.ModTime) | last | .Path')
                    if [[ -n $latest_snapshot ]] && [[ $latest_snapshot != 'null' ]]
                    then
                      zfs_send_to_rclone "$bucket" "$file_system" "$snapshot" autosnap_"$latest_snapshot"
                    fi
                    ;;
                  autosnap_*_monthly)
                    zfs_send_to_rclone "$bucket" "$file_system" "$snapshot"
                esac
              done
            }
            mapfile -td, -c 1 -C process_snapshot < <(printf "%s\0" "$SANOID_SNAPNAMES")
            # order of frequency types in $SANOID_SNAPNAMES seems to be ensured by sanoid
            # https://github.com/jimsalterjrs/sanoid/blob/a5fa5e7badecc435663e40e6a0f69523c2a0fd1c/sanoid#L146
            # https://github.com/jimsalterjrs/sanoid/blob/a5fa5e7badecc435663e40e6a0f69523c2a0fd1c/sanoid#L585
          }

          process_file_system() {
            local file_system=$2
            # https://stackoverflow.com/questions/917260/can-var-parameter-expansion-expressions-be-nested-in-bash
            local file_system_without_prefix=''${file_system#"''${prefix}"}
            local file_system_slash2dot=''${file_system_without_prefix//\//.}
            local log_file=${logsDir}/$file_system_slash2dot.log
            umask 177 # https://superuser.com/questions/1030110/what-is-the-difference-between-umask-and-chmod/1449322#1449322
            # https://stackoverflow.com/questions/75474417/bash-pv-outputting-m-at-the-end-of-each-line/75481792#75481792
            # https://stackoverflow.com/questions/70398228/transform-stream-sent-to-a-file-by-tee/70398383#70398383
            process_snapshots "$file_system" 2>&1 \
              | tee >(stdbuf -oL tr "\r" "\n" >> "$log_file")
            echo >> "$log_file" # extra newline
          }

          # https://github.com/jimsalterjrs/sanoid/issues/455
          # https://github.com/jimsalterjrs/sanoid/issues/104
          # https://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash/15988793#15988793
          mapfile -td, -c 1 -C process_file_system < <(printf "%s\0" "$SANOID_TARGETS")
        '';
      };
    in
    lib.mkMerge [
      {
        systemd.services.sanoid.serviceConfig =
          lib.genAttrs [ "User" "Group" "ExecStartPre" "ExecStopPost" ] (
            # https://github.com/NixOS/nixpkgs/blob/3acb677ea67d4c6218f33de0db0955f116b7588c/nixos/modules/services/backup/sanoid.nix#L248
            _: "" |> lib.mkForce
          )
          // {
            DynamicUser = false |> lib.mkForce;
          };
      }
      {
        systemd.tmpfiles.settings."sanoid-upload".${logsDir}."d" = { };
        services.logrotate.settings."sanoid-upload".files = "${logsDir}/*.log";
      }
      {
        services.sanoid.templates.default = {
          script_timeout = 0; # https://github.com/jimsalterjrs/sanoid/blob/a5fa5e7badecc435663e40e6a0f69523c2a0fd1c/sanoid#L1658
          post_snapshot_script = "sh -c '${script}/bin/${script.name} >/dev/null 2>&1'";
        };
      }
    ];
}
