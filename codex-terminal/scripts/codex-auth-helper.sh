#!/bin/bash

show_auth_menu() {
    clear
    echo "=============================================="
    echo "          Codex Authentication Helper         "
    echo "=============================================="
    echo ""
    echo "Options:"
    echo "  1) Start OAuth sign-in (codex --login)"
    echo "  2) Device code login (codex login --device-auth)"
    echo "  3) Manual API key input"
    echo "  4) Read API key from file (/config/openai-api-key.txt)"
    echo "  5) Retry standard session"
    echo "  6) Exit"
    echo ""
}

start_oauth_login() {
    echo ""
    echo "Starting OAuth sign-in..."
    echo "Follow the login link in the terminal to complete OAuth sign-in."
    sleep 1
    exec ${CODEX_COMMAND:-codex} --login
}

start_device_code_login() {
    echo ""
    echo "Starting device code login..."
    echo "Follow the login link and enter the code to complete sign-in."
    sleep 1
    exec ${CODEX_COMMAND:-codex} login --device-auth
}

manual_auth_input() {
    echo ""
    echo "Please enter your OpenAI API key:"
    echo -n "Key: "
    read -r api_key

    if [ -z "$api_key" ]; then
        echo "No key provided"
        return 1
    fi

    echo -n "$api_key" > /data/openai-api-key
    chmod 600 /data/openai-api-key
    export OPENAI_API_KEY="$api_key"

    echo "Key saved. Starting Codex..."
    sleep 1
    exec ${CODEX_COMMAND:-codex}
}

read_key_from_file() {
    local key_file="/config/openai-api-key.txt"

    echo ""
    echo "Looking for API key in: $key_file"

    if [ -f "$key_file" ]; then
        api_key=$(cat "$key_file")
        if [ -z "$api_key" ]; then
            echo "File exists but is empty"
            return 1
        fi

        echo -n "$api_key" > /data/openai-api-key
        chmod 600 /data/openai-api-key
        export OPENAI_API_KEY="$api_key"

        echo "Key loaded. Starting Codex..."
        sleep 1
        exec ${CODEX_COMMAND:-codex}
    else
        echo "File not found: $key_file"
        echo "Create the file in your Home Assistant config directory and retry."
        return 1
    fi
}

retry_standard_auth() {
    echo ""
    echo "Starting Codex..."
    sleep 1
    exec ${CODEX_COMMAND:-codex}
}

main() {
    while true; do
        show_auth_menu
        echo -n "Enter your choice [1-6]: "
        read -r choice

        case "$choice" in
            1)
                start_oauth_login
                ;;
            2)
                start_device_code_login
                ;;
            3)
                manual_auth_input
                if [ $? -eq 0 ]; then
                    exit 0
                fi
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            4)
                read_key_from_file
                if [ $? -eq 0 ]; then
                    exit 0
                fi
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            5)
                retry_standard_auth
                ;;
            6)
                echo "Exiting"
                exit 0
                ;;
            *)
                echo "Invalid choice"
                sleep 1
                ;;
        esac
    done
}

main "$@"
