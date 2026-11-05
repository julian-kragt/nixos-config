# Appreo project: Homebrew formulae/casks and PHP memcached reminder on workhorse.
{
  pkgs,
  config,
  lib,
  ...
}:
let
  valetHome = "${config.hostSpec.home}/.config/valet";
  phpVersion = "8.3";
  valetSock = "valet${builtins.replaceStrings [ "." ] [ "" ] phpVersion}.sock";

  # nixpkgs' libmemcached.pc has doubled store paths and `Requires: libsasl2`,
  # and pecl's configure resets PKG_CONFIG_PATH to <dir>/lib/pkgconfig only, so
  # pkg-config can't resolve it. Provide a prefix with a self-contained .pc.
  libmemcachedForPecl = pkgs.runCommand "libmemcached-for-pecl" { } ''
    mkdir -p $out/lib/pkgconfig
    ln -s ${pkgs.libmemcached}/include $out/include
    for f in ${pkgs.libmemcached}/lib/*; do
      [ "$(basename $f)" = pkgconfig ] || ln -s $f $out/lib/
    done
    cat > $out/lib/pkgconfig/libmemcached.pc <<EOF
    prefix=$out
    Name: libmemcached
    Description: libmemcached C/C++ library
    Version: ${pkgs.libmemcached.version}
    Libs: -L${pkgs.libmemcached}/lib -L${pkgs.cyrus_sasl.out}/lib -lmemcached -lmemcachedutil -lsasl2
    Cflags: -I${pkgs.libmemcached}/include -I${pkgs.cyrus_sasl.dev}/include
    EOF
  '';

  valetFpmConf = pkgs.writeText "valet-fpm.conf" ''
    ; FPM pool configuration for Valet (managed by appreo.nix)

    [valet]
    user = ${config.hostSpec.primaryUser}
    group = staff
    listen = ${valetHome}/${valetSock}
    listen.owner = ${config.hostSpec.primaryUser}
    listen.group = staff
    listen.mode = 0777

    pm = dynamic
    pm.max_children = 5
    pm.start_servers = 2
    pm.min_spare_servers = 1
    pm.max_spare_servers = 3

    env[LC_ALL] = C
    env[PGGSSENCMODE] = disable
  '';

  valetFpmErrorLogIni = pkgs.writeText "error_log.ini" ''
    ; php-fpm error logging directives (managed by appreo.nix)

    error_log="${valetHome}/Log/php-fpm.log"
    log_errors=on
    log_level=debug
  '';

  appreoSocket = "/tmp/appreo-pc.sock";
  appreoConfig = pkgs.writeText "appreo-process-compose.yaml" ''
    version: "0.5"
    processes:
      desktop:
        command: "sencha app watch"
        working_dir: "${config.hostSpec.home}/projects/appreo/desktop"
      app:
        command: "sencha app watch --port=1843"
        working_dir: "${config.hostSpec.home}/projects/appreo/app"
      backoffice:
        command: "pnpm run dev"
        working_dir: "${config.hostSpec.home}/projects/appreo/backoffice"
      horizon:
        command: "php artisan horizon"
        working_dir: "${config.hostSpec.home}/projects/appreo/api"
  '';
in
{
  homebrew.enable = true;

  homebrew.brews = [
    {
       name = "php@8.3";
       link = true;
     }
    {
      name = "composer";
      link = true;
    }
    "percona-server"
    "memcached"
    "pkg-config"
    "rabbitmq"
    "redis"
  ];

  homebrew.casks = [
    "sencha"
    "mysql-shell"
  ];

  # Sencha Cmd's installer is x86_64-only; Rosetta must exist before brew bundle runs.
  system.activationScripts.preActivation.text = lib.mkBefore ''
    if ! /usr/bin/pgrep -q oahd; then
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi
  '';

  environment.systemPackages = [
    pkgs.libmemcached
    pkgs.autoconf
    pkgs.automake
    pkgs.libtool
    pkgs.code-cursor
    pkgs.zlib
    pkgs.nodejs
    pkgs.pnpm
    pkgs.process-compose
    (pkgs.writeShellScriptBin "watch-appreo" ''
      exec ${pkgs.process-compose}/bin/process-compose \
        --config ${appreoConfig} \
        --use-uds \
        --unix-socket ${appreoSocket} \
        up "$@"
    '')
    (pkgs.writeShellScriptBin "stop-appreo" ''
      exec ${pkgs.process-compose}/bin/process-compose \
        --use-uds \
        --unix-socket ${appreoSocket} \
        down
    '')
  ];

  environment.systemPath = [
    "${config.homebrew.prefix}/bin"
    "${config.hostSpec.home}/.config/composer/vendor/bin"
    "/opt/Sencha/Cmd"
    "/opt/homebrew/opt/python@3.14/libexec/bin"
  ];

  environment.shellAliases = {
    a = "php artisan";
  };

  # Install the PHP memcached extension automatically when it's missing, broken,
  # or linked against anything but the current libmemcached. The .so hardcodes
  # /nix/store paths that brew and pecl know nothing about, so it would otherwise
  # break once a flake update's old libmemcached gets garbage-collected.
  # pecl is interactive, so we feed the prompt answers via printf:
  #   libmemcached dir, zlib dir, fastlz=no, igbinary=no, json=no, msgpack=no,
  #   sasl=no, sessions=yes, memcached protocol=yes
  # Homebrew is owned by the primary user, so drop privileges from the root
  # activation context with sudo -u.
  system.activationScripts.postActivation.text = ''
    # Ensure Valet PHP-FPM pool config exists (valet use can lose this after brew php upgrades).
    FPM_DIR="${config.homebrew.prefix}/etc/php/${phpVersion}/php-fpm.d"
    PHP_CONF_D="${config.homebrew.prefix}/etc/php/${phpVersion}/conf.d"
    VALET_FPM_CONF="$FPM_DIR/valet-fpm.conf"
    if [ -d "$FPM_DIR" ]; then
      cp ${valetFpmConf} "$VALET_FPM_CONF"
      chown ${config.hostSpec.primaryUser}:staff "$VALET_FPM_CONF"
      if [ -f "$FPM_DIR/www.conf" ] && [ ! -f "$FPM_DIR/www.conf-backup" ]; then
        mv "$FPM_DIR/www.conf" "$FPM_DIR/www.conf-backup"
      fi
    fi
    if [ -d "$PHP_CONF_D" ]; then
      cp ${valetFpmErrorLogIni} "$PHP_CONF_D/error_log.ini"
      chown ${config.hostSpec.primaryUser}:staff "$PHP_CONF_D/error_log.ini"
    fi
    if [ -d "${valetHome}" ]; then
      ln -sfn "${valetHome}/${valetSock}" "${valetHome}/valet.sock"
    fi

    PHP="${config.homebrew.prefix}/opt/php@8.3/bin/php"
    PECL="${config.homebrew.prefix}/opt/php@8.3/bin/pecl"
    PHP_CONFIG="${config.homebrew.prefix}/opt/php@8.3/bin/php-config"
    PHP_INI="${config.homebrew.prefix}/etc/php/${phpVersion}/php.ini"

    # Don't grep `php -m` here: a failed load prints a warning naming memcached to stdout.
    if [ -x "$PHP" ] && [ -x "$PECL" ] && {
      ! "$PHP" -r 'exit(extension_loaded("memcached") ? 0 : 1);' >/dev/null 2>&1 ||
        ! /usr/bin/otool -L "$("$PHP_CONFIG" --extension-dir)/memcached.so" | grep -qF "${pkgs.libmemcached}/lib/"
    }; then
      printf -- "Installing PHP memcached extension via pecl...\n"
      PECL_PATH="${pkgs.autoconf}/bin:${pkgs.automake}/bin:${pkgs.libtool}/bin:${pkgs.pkg-config}/bin:$PATH"
      PECL_AUTOCONF="${pkgs.autoconf}/bin/autoconf"
      # pecl appends to php.ini on every install, even if the line already exists.
      [ ! -f "$PHP_INI" ] || sudo -u ${config.hostSpec.primaryUser} /usr/bin/sed -i "" '/^extension="memcached\.so"$/d' "$PHP_INI"
      if printf -- "${libmemcachedForPecl}\n${pkgs.zlib.dev}\nno\nno\nno\nno\nno\nyes\nyes\n" \
        | sudo -u ${config.hostSpec.primaryUser} \
          env PATH="$PECL_PATH" PHP_AUTOCONF="$PECL_AUTOCONF" "$PECL" install -f memcached; then
        : # pecl adds extension="memcached.so" to php.ini itself
      else
        printf -- "Warning: pecl install memcached failed; inspect output above.\n"
      fi
    fi
  '';
}
