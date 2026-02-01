# Codex Terminal

A web-based terminal interface for running a Codex CLI inside Home Assistant.

## Features

- Web terminal access through your Home Assistant UI
- Optional auto-launch of Codex on login
- Direct access to your Home Assistant config directory
- Optional persistent packages (apk and pip)
- OAuth sign-in flow on first run (with device code fallback)
- Optional OpenAI API key configuration

## Configuration

Example configuration:

```
auto_launch_codex: true
codex_command: codex
codex_install_command: npm i -g @openai/codex
openai_api_key: ""
openai_base_url: ""
openai_organization: ""
persistent_apk_packages: []
persistent_pip_packages: []
```

### Options

- `auto_launch_codex` (bool): Automatically run Codex when the terminal opens.
- `codex_command` (string): Command used to start Codex. Default: `codex`.
- `codex_install_command` (string): Command used to install Codex if missing.
- `openai_api_key` (string): Optional OpenAI API key for key-based auth.
- `openai_base_url` (string): Optional base URL for the OpenAI API.
- `openai_organization` (string): Optional OpenAI organization ID.
- `persistent_apk_packages` (list): APK packages to install on every start.
- `persistent_pip_packages` (list): Python packages to install on every start.

## Authentication

By default, Codex will prompt you to sign in with your ChatGPT account and provide a login link on first run. The authentication helper can also start OAuth sign-in explicitly (`codex --login`). If you are in a headless environment, the helper includes a device-code flow (`codex login --device-auth`) which must be enabled in your ChatGPT security settings. If you prefer key-based auth, you can set the OpenAI API key in one of three ways:

1. Add-on config: set `openai_api_key` in the add-on options.
2. File: create `/config/openai-api-key.txt` and restart the add-on.
3. Session helper: select the authentication helper in the session picker.

## Notes

- This add-on does not include Home Assistant integrations. It provides a web terminal with a Codex CLI.
- If your Codex CLI uses a different install method, set `codex_install_command` accordingly.
- For ingress access, use the add-on panel in Home Assistant.
