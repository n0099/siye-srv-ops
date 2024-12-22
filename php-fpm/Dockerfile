# syntax=docker/dockerfile:1
FROM php:8.3-fpm AS php-fpm

ADD --chmod=0755 \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    /usr/local/bin
# https://github.com/docker/docs/issues/18566#issuecomment-1796418110
RUN install-php-extensions opcache \
 && cp "$PHP_INI_DIR"/php.ini-production "$PHP_INI_DIR"/php.ini
COPY <<INI "$PHP_INI_DIR"/conf.d/Dockerfile.ini
[PHP]
; https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/php-tricks-esp/php-useful-functions-disable_functions-open_basedir-bypass#filesystem-functions
disable_functions = putenv,create_function,disk_free_space,disk_total_space,diskfreespace,dl,eval,exec,get_current_user,getlastmo,getmygid,getmyinode,getmypid,getmyuid,mail,mb_send_mail,highlight_file,opcache_get_configuration,opcache_get_status,passthru,pclose,pcntl_alarm,pcntl_async_signals,pcntl_exec,pcntl_fork,pcntl_get_last_error,pcntl_getpriority,pcntl_setpriority,pcntl_signal,pcntl_signal_dispatch,pcntl_signal_get_handler,pcntl_sigprocmask,pcntl_sigtimedwait,pcntl_sigwaitinfo,pcntl_strerror,pcntl_unshare,pcntl_wait,pcntl_waitpid,pcntl_wexitstatus,pcntl_wifcontinued,pcntl_wifexited,pcntl_wifsignaled,pcntl_wifstopped,pcntl_wstopsig,pcntl_wtermsig,php_ini_loaded_file,phpinfo,popen,posix_getlogin,posix_getpwuid,posix_kill,posix_mkfifo,posix_setpgid,posix_setsid,posix_setuid,posix_ttyname,posix_uname,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,show_source,system
open_basedir =
post_max_size = 16M
upload_max_filesize = 16M
allow_url_fopen = Off

[opcache]
opcache.enable_cli = 1
opcache.jit_buffer_size = 128M
opcache.max_accelerated_files = 65536
opcache.file_cache = /tmp/opcache
INI

ARG PHP_INI_OPEN_BASEDIR
# https://docs.docker.com/reference/dockerfile/#using-arg-variables
# https://docs.docker.com/reference/compose-file/build/#args
ENV PHP_INI_OPEN_BASEDIR=$PHP_INI_OPEN_BASEDIR
# https://stackoverflow.com/questions/38438933/how-to-make-a-build-arg-mandatory-during-docker-build
RUN test -n "$PHP_INI_OPEN_BASEDIR"

COPY <<BASH /etc/rc.local
# https://unix.stackexchange.com/questions/296705/using-sed-with-ampersand
# https://unix.stackexchange.com/questions/32907/what-characters-do-i-need-to-escape-when-using-sed-in-a-sh-script
sed -e 's#^open_basedir =#& '"$(printenv PHP_INI_OPEN_BASEDIR | sed -e 's/[#\&]/\\\\&/g')"# \\
    -i "$PHP_INI_DIR"/conf.d/Dockerfile.ini
BASH
RUN chmod +x /etc/rc.local
# https://stackoverflow.com/questions/47615751/docker-compose-run-a-script-after-container-has-started/47629959#47629959
# https://unix.stackexchange.com/questions/144514/add-arguments-to-bash-c/144519#144519
ENTRYPOINT ["sh", "-xc", "/etc/rc.local && exec \"$@\"", " "]

ARG WEB_ROOT
RUN test -n "$WEB_ROOT"
WORKDIR $WEB_ROOT

ARG PHP_EXTENSIONS
RUN install-php-extensions $PHP_EXTENSIONS
