#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# What `yunohost service` shows next to memo in the webadmin.
service_description="Collaborative sticky-note boards"

# Downloads the memo binary and picks the build this processor can run.
#
# Upstream publishes three: arm64, amd64, and an amd64 one compiled without
# AVX2. The plain amd64 build dies with SIGILL on a processor older than
# Haswell, so it is only installed when /proc/cpuinfo claims the flag, and the
# binary is run once before the service does to catch a machine that claims it
# and means it differently. Whatever fails that test falls back to baseline.
memo_setup_binary() {
    local source_id="main"

    if [[ "$YNH_ARCH" == "amd64" ]] && grep --quiet --word-regexp avx2 /proc/cpuinfo; then
        source_id="amd64_avx2"
    fi

    memo_install_binary "$source_id"

    if [[ "$source_id" != "main" ]] && ! ynh_exec_as_app "$install_dir/memo" --help > /dev/null 2>&1; then
        ynh_print_warn "The AVX2 build will not run on this processor, falling back to the baseline one"
        memo_install_binary "main"
    fi
}

# Unpacks one of the binary sources over the install dir, executable and owned.
memo_install_binary() {
    ynh_setup_source --dest_dir="$install_dir" --source_id="$1" --full_replace

    chmod 750 "$install_dir/memo"
    chown "$app:$app" "$install_dir/memo"
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
