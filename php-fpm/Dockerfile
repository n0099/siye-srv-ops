# syntax=docker/dockerfile:1
FROM php:8.3-fpm AS php-fpm

ADD --chmod=0755 \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    /usr/local/bin
ARG PHP_EXTENSIONS
RUN <<-'DASH' dash
    test -n "$PHP_EXTENSIONS"
    # https://stackoverflow.com/questions/74253281/git-was-not-found-in-your-path-skipping-source-download
    install-php-extensions opcache zip $PHP_EXTENSIONS
    cp "$PHP_INI_DIR"/php.ini-production "$PHP_INI_DIR"/php.ini
DASH

ARG PHP_INI
COPY <<INI "$PHP_INI_DIR"/conf.d/Dockerfile.ini
# DO NOT INDENT php.ini
[PHP]
; https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/php-tricks-esp/php-useful-functions-disable_functions-open_basedir-bypass#filesystem-functions
disable_functions = putenv,create_function,disk_free_space,disk_total_space,diskfreespace,dl,eval,exec,get_current_user,getlastmo,getmygid,getmyinode,getmypid,getmyuid,mail,mb_send_mail,highlight_file,opcache_get_configuration,opcache_get_status,passthru,pclose,pcntl_alarm,pcntl_async_signals,pcntl_exec,pcntl_fork,pcntl_get_last_error,pcntl_getpriority,pcntl_setpriority,pcntl_signal,pcntl_signal_dispatch,pcntl_signal_get_handler,pcntl_sigprocmask,pcntl_sigtimedwait,pcntl_sigwaitinfo,pcntl_strerror,pcntl_unshare,pcntl_wait,pcntl_waitpid,pcntl_wexitstatus,pcntl_wifcontinued,pcntl_wifexited,pcntl_wifsignaled,pcntl_wifstopped,pcntl_wstopsig,pcntl_wtermsig,php_ini_loaded_file,phpinfo,popen,posix_getlogin,posix_getpwuid,posix_kill,posix_mkfifo,posix_setpgid,posix_setsid,posix_setuid,posix_ttyname,posix_uname,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,show_source,system
open_basedir =
post_max_size = 16M
upload_max_filesize = 16M
allow_url_fopen = Off
$PHP_INI

[opcache]
opcache.jit_buffer_size = 128M
opcache.max_accelerated_files = 65536
opcache.file_cache = /tmp/opcache
INI

# https://github.com/docker-library/php/issues/182#issuecomment-622441391
# https://stackoverflow.com/questions/10844641/how-to-change-the-path-to-php-ini-in-php-cli-version/10844817#10844817
COPY <<INI "$PHP_INI_DIR"/conf.d/php-cli.ini
[PHP]
disable_functions =
open_basedir =
$PHP_INI

[opcache]
opcache.enable_cli = 1
opcache.jit_buffer_size = 128M
opcache.max_accelerated_files = 65536
opcache.file_cache = /tmp/opcache
INI

# https://getcomposer.org/doc/00-intro.md#docker-image
COPY --from=composer/composer:latest-bin /composer /usr/local/bin/composer

# https://docs.docker.com/reference/dockerfile/#using-arg-variables
ARG PHP_INI_OPEN_BASEDIR
# https://docs.docker.com/reference/compose-file/build/#args
ENV PHP_INI_OPEN_BASEDIR=$PHP_INI_OPEN_BASEDIR
ARG WEB_ROOT
RUN <<-'BASH' bash
    # https://stackoverflow.com/questions/38438933/how-to-make-a-build-arg-mandatory-during-docker-build
    test -n "$PHP_INI_OPEN_BASEDIR"
    test -n "$WEB_ROOT"
BASH
WORKDIR $WEB_ROOT

COPY <<-'BASH' /etc/rc.local
    test -n "$PHP_INI_OPEN_BASEDIR" # check env var existence in derived containers
    # https://unix.stackexchange.com/questions/296705/using-sed-with-ampersand
    # https://unix.stackexchange.com/questions/32907/what-characters-do-i-need-to-escape-when-using-sed-in-a-sh-script
    sed -e 's#^open_basedir =#& '"$(printenv PHP_INI_OPEN_BASEDIR | sed -e 's/[#\&]/\\\\&/g')"# \
        -i "$PHP_INI_DIR"/conf.d/Dockerfile.ini
BASH
RUN chmod +x /etc/rc.local
# https://stackoverflow.com/questions/47615751/docker-compose-run-a-script-after-container-has-started/47629959#47629959
# https://unix.stackexchange.com/questions/144514/add-arguments-to-bash-c/144519#144519
ENTRYPOINT ["sh", "-xc", "/etc/rc.local && exec \"$@\"", " "]
