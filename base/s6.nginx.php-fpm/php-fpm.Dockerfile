# syntax=docker/dockerfile:1
RUN <<'ASH' ash -eux
    apk add --no-cache php83 php83-fpm php83-opcache php83-zip composer
ASH

ENV COMPOSER_HOME=/tmp/.composer

ARG PHP_EXTENSIONS
COPY ./base/s6.nginx.php-fpm/install-php-extensions.sh /install-php-extensions.sh
RUN <<ASH ash -eux
    /install-php-extensions.sh $PHP_EXTENSIONS
    rm -v /install-php-extensions.sh
ASH

ARG PHP_INI
COPY <<-INI /etc/php83/conf.d/Dockerfile.ini
	[PHP]
	memory_limit = 256M
	$PHP_INI

	[opcache]
	opcache.jit_buffer_size = 128M
	opcache.max_accelerated_files = 65536
	opcache.file_cache = /tmp/opcache
INI

# https://github.com/docker-library/php/issues/182#issuecomment-622441391
# https://stackoverflow.com/questions/10844641/how-to-change-the-path-to-php-ini-in-php-cli-version/10844817#10844817
COPY <<-INI /etc/php83/php-fpm-fcgi.ini
	# using tab for <<- to remove them: https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html#tag_19_07_04
	[PHP]
	error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
	display_errors = Off
	allow_url_fopen = Off
	expose_php = Off
	open_basedir = /tmp:/var/www
	; https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/php-tricks-esp/php-useful-functions-disable_functions-open_basedir-bypass#filesystem-functions
	disable_functions = putenv,create_function,disk_free_space,disk_total_space,diskfreespace,dl,eval,exec,get_current_user,getlastmo,getmygid,getmyinode,getmypid,getmyuid,mail,mb_send_mail,opcache_get_configuration,opcache_get_status,passthru,pclose,pcntl_alarm,pcntl_async_signals,pcntl_exec,pcntl_fork,pcntl_get_last_error,pcntl_getpriority,pcntl_setpriority,pcntl_signal,pcntl_signal_dispatch,pcntl_signal_get_handler,pcntl_sigprocmask,pcntl_sigtimedwait,pcntl_sigwaitinfo,pcntl_strerror,pcntl_unshare,pcntl_wait,pcntl_waitpid,pcntl_wexitstatus,pcntl_wifcontinued,pcntl_wifexited,pcntl_wifsignaled,pcntl_wifstopped,pcntl_wstopsig,pcntl_wtermsig,php_ini_loaded_file,phpinfo,popen,posix_getlogin,posix_getpwuid,posix_kill,posix_mkfifo,posix_setpgid,posix_setsid,posix_setuid,posix_ttyname,posix_uname,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,show_source,system
output_buffering = 4096
	max_execution_time = 60
	post_max_size = 16M
	upload_max_filesize = 16M
	; https://stackoverflow.com/questions/77426003/symfony-nginx-upstream-sent-too-big-header-while-reading-response-header-fro/79031358#79031358
	fastcgi.logging = Off
INI

COPY <<-INI /etc/php83/php-cli.ini
	[opcache]
	opcache.enable_cli = 1
INI

COPY <<-'INI' /etc/php83/php-fpm.d/www.extra.conf
	[www]
	user = www-data
	group = www-data
	listen = /run/php-fpm.sock
	listen.owner = www-data
	listen.group = www-data
INI
