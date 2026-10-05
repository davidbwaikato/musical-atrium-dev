# Schwarzman parametric atrium development tools

This repository is intended to be checked out as the `dev/` Git submodule of the Musical Atrium project. It provides project-local Node.js, pnpm and Python without requiring an administrator account or changing a system installation.

## Supported hosts

- Windows x64 or ARM64 through Git Bash
- Linux x64 or ARM64
- macOS x64 or ARM64

The installer downloads official Node.js archives, verifies them against the corresponding `SHASUMS256.txt`, and unpacks them beneath `prog-langs/installed/`. It also installs a pinned portable CPython build from python-build-standalone, verifies its published `SHA256SUMS`, and creates `prog-langs/python3-for-tma/`. Python packages are installed into that virtual environment. Re-running the installer reuses the Python archive and installation; pip checks the pinned requirements again.

The baseline Python packages include librosa 0.11, Sync Toolbox, Demucs inference, Partitura, Parangonar, pyloudnorm and SoundFile. Model weights (including Demucs weights) are obtained separately when those algorithms are used.

For the main project's YouTube-ID audio download script, the environment installs `yt-dlp[default]` (including its EJS challenge scripts) and `imageio-ffmpeg`, whose wheels bundle an FFmpeg executable on the main supported platforms. The project-local Node.js runs the EJS scripts; this workflow does not need Playwright or Chromium. The `imageio-ffmpeg` 0.6.0 distribution has no bundled Windows ARM64 executable, so WAV conversion on that host needs a separate `ffmpeg` executable.

Essentia is installed on Linux x64 with glibc and supported macOS hosts. Native Windows Git Bash prints a warning and skips Essentia. The pinned Essentia wheel supports CPython 3.12 on Linux x64 (glibc), macOS x64 13+, and macOS ARM64 15+; other hosts receive a warning. The installer does not include the separate `essentia-tensorflow` package or its trained models.

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

The installer downloads anything that is absent, installs Node.js and Python locally, provisions pnpm through a project-local Corepack cache, and installs the Python requirements. To install or refresh only Python, run `./dev/prog-langs/INSTALL-PYTHON.sh`.

Activate the toolchain in the current Git Bash, Bash or Zsh session:

```bash
source ./dev/SETUP.bash
```

Activation must be repeated for each new terminal. It activates the `python3-for-tma` venv and prepends the project-local Node.js directory to `PATH`.

You can then work with the parent project normally:

```bash
node --version
pnpm --version
pnpm install
pnpm dev
python -m tma_services list --format json
```

## Pinned versions

Versions are centralised in `versions.env`:

- Node.js 24.18.0
- pnpm 11.25.0
- Python 3.12.14 (portable build 20260901)
- Python venv `python3-for-tma`

Change the language pins there and rerun `INSTALL-DEV-TOOLS-ALL.sh` to install another version. Python package pins are in `prog-langs/python-requirements.txt`. Versioned language installations can coexist beneath `prog-langs/installed/`.

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
    ├── ACTIVATE-PYTHON.bash
    ├── INSTALL-NODEJS.sh
    ├── INSTALL-PYTHON.sh
    ├── python-requirements.txt
    ├── downloads
    └── installed
```

The `downloads/`, `installed/` and `python3-for-tma/` contents are ignored by Git. Only download and installation directory placeholders are committed.

## Initial Git commit on Windows

The shell scripts must be stored with LF line endings and executable modes. When creating the repository in Git Bash, use:

```bash
git init -b main
git add .
git update-index --chmod=+x INSTALL-DEV-TOOLS-ALL.sh
git update-index --chmod=+x prog-langs/INSTALL-NODEJS.sh
git commit -m "Initial Node.js development toolchain"
```
