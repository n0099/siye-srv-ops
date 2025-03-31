# syntax=devthefuture/dockerfile-x

# https://github.com/devthefuture-org/dockerfile-x/issues/13#issuecomment-2268378348
# fix path for `INCLUDE` instructions in `./Dockerfile` with following compose service definition:
# s6:
#   build:
#     context: <parent of base>
#     dockerfile: base/s6.nginx.php-fpm/Dockerfile
# that haven't a custom Dockerfile which is based on `./Dockerfile`
FROM ./base/s6.nginx.php-fpm/Dockerfile
