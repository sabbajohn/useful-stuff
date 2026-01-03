# devops-toolkit

Collection of handy server/macOS administration scripts with an interactive launcher.

Install
-------

Recommended (git clone):

1. git clone this repo to ~/.devops-toolkit
2. Run `~/.devops-toolkit/install.sh` (may require sudo to create /usr/local/bin/devops)

Quick (curl):

curl -fsSL https://example.com/install.sh | bash

Usage
-----

Run the launcher:

bin/devops.sh

Or once installed:

devops [--silent] [--env /path/to/.env]

Features
--------

- Detects OS and architecture
- Lists available helper scripts from `bin/scripts/`
- Logs execution to `logs/`
- Supports `fzf` or `gum` for selection if installed

Demo
----

![demo-placeholder](assets/demo.gif)

Environment
-----------

You can create a `.env` file in the toolkit root to override defaults. See `.env.example`.

Contributing
------------

Add new script wrappers under `bin/scripts/` or propose features.

