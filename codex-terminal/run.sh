#!/usr/bin/with-contenv bashio

set -e
set -o pipefail

init_environment() {
    local data_home="/data/home"
    local config_dir="/data/.config"
    local cache_dir="/data/.cache"
    local state_dir="/data/.local/state"

    bashio::log.info "Initializing Codex environment in /data..."

    if ! mkdir -p "$data_home" "$config_dir" "$cache_dir" "$state_dir" "/data/.local"; then
        bashio::log.error "Failed to create directories in /data"
        exit 1
    fi

    chmod 755 "$data_home" "$config_dir" "$cache_dir" "$state_dir"

    export HOME="$data_home"
    export XDG_CONFIG_HOME="$config_dir"
    export XDG_CACHE_HOME="$cache_dir"
    export XDG_STATE_HOME="$state_dir"
    export XDG_DATA_HOME="/data/.local/share"

    bashio::log.info "Environment initialized:"
    bashio::log.info "  - Home: $HOME"
    bashio::log.info "  - Config: $XDG_CONFIG_HOME"
    bashio::log.info "  - Cache: $XDG_CACHE_HOME"
}

load_openai_credentials() {
    local api_key_file="/data/openai-api-key"

    if bashio::config.has_value 'openai_api_key'; then
        local api_key
        api_key=$(bashio::config 'openai_api_key')
        if [ -n "$api_key" ] && [ "$api_key" != "null" ]; then
            export OPENAI_API_KEY="$api_key"
            echo -n "$api_key" > "$api_key_file"
            chmod 600 "$api_key_file"
            bashio::log.info "OpenAI API key loaded from add-on config"
        fi
    fi

    if [ -z "${OPENAI_API_KEY:-}" ] && [ -f "$api_key_file" ]; then
        export OPENAI_API_KEY="$(cat "$api_key_file")"
        bashio::log.info "OpenAI API key loaded from /data"
    fi

    if bashio::config.has_value 'openai_base_url'; then
        local base_url
        base_url=$(bashio::config 'openai_base_url')
        if [ -n "$base_url" ] && [ "$base_url" != "null" ]; then
            export OPENAI_BASE_URL="$base_url"
            bashio::log.info "OPENAI_BASE_URL set from add-on config"
        fi
    fi

    if bashio::config.has_value 'openai_organization'; then
        local org
        org=$(bashio::config 'openai_organization')
        if [ -n "$org" ] && [ "$org" != "null" ]; then
            export OPENAI_ORG_ID="$org"
            bashio::log.info "OPENAI_ORG_ID set from add-on config"
        fi
    fi
}

install_tools() {
    bashio::log.info "Installing additional tools..."
    if ! apk add --no-cache ttyd jq curl; then
        bashio::log.error "Failed to install required tools"
        exit 1
    fi
    bashio::log.info "Tools installed successfully"
}

install_persistent_packages() {
    bashio::log.info "Checking for persistent packages..."

    local persist_config="/data/persistent-packages.json"
    local apk_packages=""
    local pip_packages=""

    if bashio::config.has_value 'persistent_apk_packages'; then
        local config_apk
        config_apk=$(bashio::config 'persistent_apk_packages')
        if [ -n "$config_apk" ] && [ "$config_apk" != "null" ]; then
            apk_packages="$config_apk"
            bashio::log.info "Found APK packages in config: $apk_packages"
        fi
    fi

    if bashio::config.has_value 'persistent_pip_packages'; then
        local config_pip
        config_pip=$(bashio::config 'persistent_pip_packages')
        if [ -n "$config_pip" ] && [ "$config_pip" != "null" ]; then
            pip_packages="$config_pip"
            bashio::log.info "Found pip packages in config: $pip_packages"
        fi
    fi

    if [ -f "$persist_config" ]; then
        bashio::log.info "Found local persistent packages config"

        local local_apk
        local_apk=$(jq -r '.apk_packages | join(" ")' "$persist_config" 2>/dev/null || echo "")
        if [ -n "$local_apk" ]; then
            apk_packages="$apk_packages $local_apk"
        fi

        local local_pip
        local_pip=$(jq -r '.pip_packages | join(" ")' "$persist_config" 2>/dev/null || echo "")
        if [ -n "$local_pip" ]; then
            pip_packages="$pip_packages $local_pip"
        fi
    fi

    apk_packages=$(echo "$apk_packages" | tr ' ' '
' | sort -u | tr '
' ' ' | xargs)
    pip_packages=$(echo "$pip_packages" | tr ' ' '
' | sort -u | tr '
' ' ' | xargs)

    if [ -n "$apk_packages" ]; then
        bashio::log.info "Installing persistent APK packages: $apk_packages"
        if apk add --no-cache $apk_packages; then
            bashio::log.info "APK packages installed successfully"
        else
            bashio::log.warning "Some APK packages failed to install"
        fi
    fi

    if [ -n "$pip_packages" ]; then
        bashio::log.info "Installing persistent pip packages: $pip_packages"
        if pip3 install --break-system-packages --no-cache-dir $pip_packages; then
            bashio::log.info "pip packages installed successfully"
        else
            bashio::log.warning "Some pip packages failed to install"
        fi
    fi

    if [ -z "$apk_packages" ] && [ -z "$pip_packages" ]; then
        bashio::log.info "No persistent packages configured"
    fi
}

setup_session_picker() {
    if [ -f "/opt/scripts/codex-session-picker.sh" ]; then
        if ! cp /opt/scripts/codex-session-picker.sh /usr/local/bin/codex-session-picker; then
            bashio::log.error "Failed to copy codex-session-picker script"
            exit 1
        fi
        chmod +x /usr/local/bin/codex-session-picker
        bashio::log.info "Session picker script installed successfully"
    else
        bashio::log.warning "Session picker script not found, using auto-launch mode only"
    fi

    if [ -f "/opt/scripts/codex-auth-helper.sh" ]; then
        chmod +x /opt/scripts/codex-auth-helper.sh
        bashio::log.info "Authentication helper script ready"
    fi

    if [ -f "/opt/scripts/persist-install.sh" ]; then
        if ! cp /opt/scripts/persist-install.sh /usr/local/bin/persist-install; then
            bashio::log.warning "Failed to copy persist-install script"
        else
            chmod +x /usr/local/bin/persist-install
            bashio::log.info "Persist-install script installed successfully"
        fi
    fi
}

ensure_codex_installed() {
    local codex_command
    codex_command=$(bashio::config 'codex_command' 'codex')
    local codex_bin="${codex_command%% *}"

    if command -v "$codex_bin" >/dev/null 2>&1; then
        bashio::log.info "Codex command found: $codex_bin"
        return 0
    fi

    local install_command
    install_command=$(bashio::config 'codex_install_command' '')

    if [ -z "$install_command" ] || [ "$install_command" = "null" ]; then
        bashio::log.warning "Codex command not found and no install command configured"
        return 0
    fi

    bashio::log.info "Codex command not found. Attempting install: $install_command"
    if sh -c "$install_command"; then
        bashio::log.info "Codex install command completed"
    else
        bashio::log.warning "Codex install command failed"
    fi
}

get_codex_launch_command() {
    local auto_launch_codex
    auto_launch_codex=$(bashio::config 'auto_launch_codex' 'true')

    local codex_command
    codex_command=$(bashio::config 'codex_command' 'codex')

    export CODEX_COMMAND="$codex_command"

    if [ "$auto_launch_codex" = "true" ]; then
        echo "clear && echo 'Welcome to Codex Terminal' && echo '' && echo 'Starting Codex...' && sleep 1 && ${codex_command}"
    else
        if [ -f /usr/local/bin/codex-session-picker ]; then
            echo "clear && /usr/local/bin/codex-session-picker"
        else
            bashio::log.warning "Session picker not found, falling back to auto-launch"
            echo "clear && echo 'Welcome to Codex Terminal' && echo '' && echo 'Starting Codex...' && sleep 1 && ${codex_command}"
        fi
    fi
}

start_web_terminal() {
    local port=7681
    bashio::log.info "Starting web terminal on port ${port}..."

    bashio::log.info "Environment variables:"
    bashio::log.info "OPENAI_BASE_URL=${OPENAI_BASE_URL:-}"
    bashio::log.info "OPENAI_ORG_ID=${OPENAI_ORG_ID:-}"
    bashio::log.info "HOME=${HOME}"

    local launch_command
    launch_command=$(get_codex_launch_command)

    local auto_launch_codex
    auto_launch_codex=$(bashio::config 'auto_launch_codex' 'true')
    bashio::log.info "Auto-launch Codex: ${auto_launch_codex}"

    exec ttyd         --port "${port}"         --interface 0.0.0.0         --writable         --ping-interval 30         --client-option enableReconnect=true         --client-option reconnect=10         --client-option reconnectInterval=5         bash -c "$launch_command"
}

run_health_check() {
    if [ -f "/opt/scripts/health-check.sh" ]; then
        bashio::log.info "Running system health check..."
        chmod +x /opt/scripts/health-check.sh
        /opt/scripts/health-check.sh || bashio::log.warning "Some health checks failed but continuing..."
    fi
}

main() {
    bashio::log.info "Initializing Codex Terminal add-on..."

    run_health_check
    init_environment
    load_openai_credentials
    install_tools
    setup_session_picker
    install_persistent_packages
    ensure_codex_installed
    start_web_terminal
}

main "$@"
