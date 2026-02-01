# Codex Terminal

A web-based terminal interface for running a Codex CLI inside Home Assistant.

## Features

- Web terminal access through your Home Assistant UI
- Optional auto-launch of Codex on login
- Direct access to your Home Assistant config directory
- Optional persistent packages (apk and pip)
- Optional OpenAI API key configuration

## Configuration

Example configuration:

```
auto_launch_codex: true
codex_command: codex
codex_install_command: npm install -g @openai/codex
openai_api_key: YOUR_API_KEY
openai_base_url: ""
openai_organization: ""
persistent_apk_packages: []
persistent_pip_packages: []
```

### Options

- `auto_launch_codex` (bool): Automatically run Codex when the terminal opens.
- `codex_command` (string): Command used to start Codex. Default: `codex`.
- `codex_install_command` (string): Command used to install Codex if missing.
- `openai_api_key` (string): OpenAI API key (optional but required for most CLIs).
- `openai_base_url` (string): Optional base URL for the OpenAI API.
- `openai_organization` (string): Optional OpenAI organization ID.
- `persistent_apk_packages` (list): APK packages to install on every start.
- `persistent_pip_packages` (list): Python packages to install on every start.

## Authentication

You can set the OpenAI API key in one of three ways:

1. Add-on config: set `openai_api_key` in the add-on options.
2. File: create `/config/openai-api-key.txt` and restart the add-on.
3. Session helper: select the authentication helper in the session picker.

## Notes

- This add-on does not include Home Assistant integrations. It provides a web terminal with a Codex CLI.
- If your Codex CLI uses a different install method, set `codex_install_command` accordingly.
- For ingress access, use the add-on panel in Home Assistant.
