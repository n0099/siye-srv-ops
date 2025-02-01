# syntax=docker/dockerfile:1
FROM php:8.3-fpm

# https://getcomposer.org/doc/00-intro.md#docker-image
COPY --from=composer/composer:latest-bin /composer /usr/local/bin/composer
# https://github.com/composer/composer/issues/680
ENV COMPOSER_HOME /tmp/.composer
ARG DEBIAN_FRONTEND=noninteractive

ADD --chmod=0755 \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    /usr/local/bin

# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
ARG DEBIAN_FRONTEND=noninteractive \
    PHP_EXTENSIONS
RUN <<'DASH' dash -eux
    # https://stackoverflow.com/questions/38438933/how-to-make-a-build-arg-mandatory-during-docker-build
    test -n "$PHP_EXTENSIONS"
    install-php-extensions opcache $PHP_EXTENSIONS

    # https://stackoverflow.com/questions/52444600/is-there-a-problem-with-using-php-zip-composer-warns-about-it
    apt-get update
    apt-get install -y 7zip

    cp "$PHP_INI_DIR"/php.ini-production "$PHP_INI_DIR"/php.ini
DASH

# optional args
ARG PHP_INI
ARG PHP_INI_OPEN_BASEDIR
COPY <<-INI "$PHP_INI_DIR"/conf.d/Dockerfile.ini
	# using tab for <<- to remove them: https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html#tag_19_07_04
	[PHP]
	; https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/php-tricks-esp/php-useful-functions-disable_functions-open_basedir-bypass#filesystem-functions
	disable_functions = putenv,create_function,disk_free_space,disk_total_space,diskfreespace,dl,eval,exec,get_current_user,getlastmo,getmygid,getmyinode,getmypid,getmyuid,mail,mb_send_mail,highlight_file,opcache_get_configuration,opcache_get_status,passthru,pclose,pcntl_alarm,pcntl_async_signals,pcntl_exec,pcntl_fork,pcntl_get_last_error,pcntl_getpriority,pcntl_setpriority,pcntl_signal,pcntl_signal_dispatch,pcntl_signal_get_handler,pcntl_sigprocmask,pcntl_sigtimedwait,pcntl_sigwaitinfo,pcntl_strerror,pcntl_unshare,pcntl_wait,pcntl_waitpid,pcntl_wexitstatus,pcntl_wifcontinued,pcntl_wifexited,pcntl_wifsignaled,pcntl_wifstopped,pcntl_wstopsig,pcntl_wtermsig,php_ini_loaded_file,phpinfo,popen,posix_getlogin,posix_getpwuid,posix_kill,posix_mkfifo,posix_setpgid,posix_setsid,posix_setuid,posix_ttyname,posix_uname,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,show_source,system
	open_basedir = /tmp:/var/www/html:$PHP_INI_OPEN_BASEDIR
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
	open_basedir = /tmp:/var/www/html:/usr/local/bin/composer:$PHP_INI_OPEN_BASEDIR
	$PHP_INI

	[opcache]
	opcache.enable_cli = 1
	opcache.jit_buffer_size = 128M
	opcache.max_accelerated_files = 65536
	opcache.file_cache = /tmp/opcache
INI
