#!/bin/bash

show_banner() {
    clear
    echo "=============================================="
    echo "                Codex Terminal               "
    echo "=============================================="
    echo ""
}

show_menu() {
    echo "Choose your session type:"
    echo ""
    echo "  1) Start Codex (default)"
    echo "  2) Custom Codex command"
    echo "  3) Authentication helper"
    echo "  4) Drop to bash shell"
    echo "  5) Exit"
    echo ""
}

get_user_choice() {
    local choice
    printf "Enter your choice [1-5] (default: 1): " >&2
    read -r choice

    if [ -z "$choice" ]; then
        choice=1
    fi

    choice=$(echo "$choice" | tr -d '[:space:]')
    echo "$choice"
}

launch_codex_default() {
    echo "Starting Codex..."
    sleep 1
    exec ${CODEX_COMMAND:-codex}
}

launch_codex_custom() {
    echo ""
    echo "Enter your Codex command arguments (example: --help):"
    echo -n "> ${CODEX_COMMAND:-codex} "
    read -r custom_args

    if [ -z "$custom_args" ]; then
        launch_codex_default
    else
        echo "Running: ${CODEX_COMMAND:-codex} $custom_args"
        sleep 1
        eval "exec ${CODEX_COMMAND:-codex} $custom_args"
    fi
}

launch_auth_helper() {
    echo "Starting authentication helper..."
    sleep 1
    exec /opt/scripts/codex-auth-helper.sh
}

launch_bash_shell() {
    echo "Dropping to bash shell..."
    echo "Tip: Run Codex manually when ready"
    sleep 1
    exec bash
}

exit_session_picker() {
    echo "Goodbye"
    exit 0
}

main() {
    while true; do
        show_banner
        show_menu
        choice=$(get_user_choice)

        case "$choice" in
            1)
                launch_codex_default
                ;;
            2)
                launch_codex_custom
                ;;
            3)
                launch_auth_helper
                ;;
            4)
                launch_bash_shell
                ;;
            5)
                exit_session_picker
                ;;
            *)
                echo ""
                echo "Invalid choice: '$choice'"
                echo "Please select a number between 1-5"
                echo ""
                printf "Press Enter to continue..." >&2
                read -r
                ;;
        esac
    done
}

trap 'exit_session_picker' EXIT INT TERM

main "$@"
