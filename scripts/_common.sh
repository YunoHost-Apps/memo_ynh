#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# What `yunohost service` shows next to memo in the webadmin.
service_description="Collaborative sticky-note boards"

# The bun runtime, unpacked into $install_dir/bin/bun.
#
# YunoHost has an ynh_nodejs_install but nothing for bun, so the release zip is
# just another source. It carries one top-level directory, which ynh_setup_source
# strips by default, leaving the binary alone in bin/.
memo_setup_bun() {
    mkdir --parents "$install_dir/bin"
    ynh_setup_source --dest_dir="$install_dir/bin" --source_id="bun"
    chmod 755 "$install_dir/bin/bun"
    chown "$app:$app" "$install_dir/bin/bun"
}

# node_modules, fetched by the bun we just unpacked.
#
# There are four packages and no compilation step, so this is quick and needs
# no toolchain. The app user has no home directory; both bun's home and its
# download cache are pointed inside the install dir and the cache is thrown
# away once the packages are unpacked.
memo_bun_install() {
    ynh_exec_as_app \
        HOME="$install_dir" \
        BUN_INSTALL_CACHE_DIR="$install_dir/.bun-cache" \
        "$install_dir/bin/bun" install --cwd "$install_dir" --production --frozen-lockfile

    ynh_safe_rm "$install_dir/.bun-cache"
    ynh_safe_rm "$install_dir/.bun"
}

# The one value nginx.conf needs that YunoHost does not hand us: where the
# portal should send someone back to after they sign in, base64 encoded, which
# is the form the portal reads it in. Call it before any of the nginx helpers
# or the template will not have a $portal_return to substitute and the script
# will stop there.
memo_set_portal_return() {
    portal_return=$(printf 'https://%s%s/' "$domain" "${path%/}" | base64 --wrap=0)
}

# The whole configuration, in one file, read by systemd before it drops
# privileges. Called from install, upgrade and change_url, because the domain
# and the path are baked into ORIGIN and BASEURL.
memo_add_config() {
    ynh_config_add --template="env" --destination="$install_dir/.env"
    chmod 600 "$install_dir/.env"
    chown "$app:$app" "$install_dir/.env"
}

# systemd appends to a file in here, so the directory has to exist before the
# service starts. ynh_config_add_logrotate makes it too, but only once we get
# that far, and on a restore there is no logrotate step before the start.
memo_prepare_logs() {
    mkdir --parents "/var/log/$app"
    chmod 750 "/var/log/$app"
    chown "$app:$app" "/var/log/$app"
}
