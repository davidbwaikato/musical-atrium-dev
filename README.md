# Schwarzman parametric atrium development tools

This repository is intended to be checked out as the `dev/` Git submodule of the Schwarzman parametric atrium project. It provides a pinned, project-local Node.js and pnpm toolchain without requiring an administrator account or changing a system installation.

## Supported hosts

- Windows x64 or ARM64 through Git Bash
- Linux x64 or ARM64
- macOS x64 or ARM64

The installer downloads official Node.js archives, verifies them against the corresponding `SHASUMS256.txt`, caches the downloads, and unpacks the toolchain beneath `prog-langs/installed/`. Re-running it is safe and normally reuses both the cached archive and existing installation.

## Add as a submodule

After creating and pushing this repository to its own Git remote, add it to the application repository:

```bash
git submodule add <DEV-REPOSITORY-URL> dev
git commit -m "Add development toolchain submodule"
```

For an existing checkout containing the submodule:

```bash
git submodule update --init --recursive
```

## Install and activate

Run the single installer from the application repository:

```bash
./dev/INSTALL-DEV-TOOLS-ALL.sh
```

The installer downloads anything that is absent, installs Node.js locally, and provisions the pinned pnpm version through a project-local Corepack cache.

Activate the toolchain in the current Git Bash, Bash or Zsh session:

```bash
source ./dev/SETUP.bash
```

Activation must be repeated for each new terminal. It prepends only this submodule's Node.js directory to `PATH`.

You can then work with the parent project normally:

```bash
node --version
pnpm --version
pnpm install
pnpm dev
```

## Pinned versions

Versions are centralised in `versions.env`:

- Node.js 24.18.0
- pnpm 11.25.0

Change the pins there and rerun `INSTALL-DEV-TOOLS-ALL.sh` to install another version. Versioned Node.js installations can coexist beneath `prog-langs/installed/`.

## Repository layout

```text
.
├── INSTALL-DEV-TOOLS-ALL.sh
├── README.md
├── SETUP.bash
├── versions.env
└── prog-langs
    ├── _common.bash
    ├── ACTIVATE-NODEJS.bash
    ├── INSTALL-NODEJS.sh
    ├── downloads
    └── installed
```

The `downloads/` and `installed/` contents are deliberately ignored by Git. Only their placeholder files are committed.

## Initial Git commit on Windows

The shell scripts must be stored with LF line endings and executable modes. When creating the repository in Git Bash, use:

```bash
git init -b main
git add .
git update-index --chmod=+x INSTALL-DEV-TOOLS-ALL.sh
git update-index --chmod=+x prog-langs/INSTALL-NODEJS.sh
git commit -m "Initial Node.js development toolchain"
```
