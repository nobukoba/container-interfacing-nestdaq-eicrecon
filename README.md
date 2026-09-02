# container-interfacing-nestdaq-eicrecon

NestDAQ-side Docker / Apptainer environment for the NestDAQ–EICrecon interface.

> **AlmaLinux 9 development branch:** this branch is currently being validated.
> Until its Docker build, SIF build, and smoke test pass, use the
> `almalinux9` image tag for testing rather than treating `latest` as the
> AlmaLinux 9 image.

## How to use

### Apptainer / Singularity

Download the latest SIF image:

```bash
curl -fL \
  -o container-interfacing-nestdaq-eicrecon.sif \
  https://github.com/nobukoba/container-interfacing-nestdaq-eicrecon/releases/latest/download/container-interfacing-nestdaq-eicrecon.sif
```

Start with Apptainer and bind the current directory to `/workspace`:

```bash
apptainer shell \
  --bind "$PWD:/workspace" \
  container-interfacing-nestdaq-eicrecon.sif
```

For SingularityCE:

```bash
singularity shell \
  --bind "$PWD:/workspace" \
  container-interfacing-nestdaq-eicrecon.sif
```

Inside the container, start the NestDAQ example:

```bash
cd /opt/spadi/scripts/example-interfacing-nestdaq-eicrecon
./run-stf-tf.sh
```

This starts the NestDAQ processes in a `tmux` session.

The example topology is:

```text
STFBFilePlayer 0/1/2 -> TimeFrameBuilder input : tcp://127.0.0.1:5500
TimeFrameBuilder     -> EICrecon                : tcp://127.0.0.1:5501
```

Useful tmux keys:

```text
Ctrl-b n      next window
Ctrl-b p      previous window
Ctrl-b 0..4   select window
Ctrl-b x      close the current pane without confirmation
Ctrl-b d      detach
```

Reattach with:

```bash
tmux -L spadi-sif attach -t nestdaq
```

The STF/TFB windows remain open after their device exits so that the final log and exit status can be inspected. A dead pane can be closed immediately with `Ctrl-b x`; this session is configured not to ask for `y/n` confirmation.

### Docker

For normal use, pull the prebuilt x86_64 image from GHCR:

```bash
docker pull --platform linux/amd64 \
  ghcr.io/nobukoba/container-interfacing-nestdaq-eicrecon:latest
```

To test the image produced from this `almalinux9` branch, replace `latest` in
the pull and run commands with `almalinux9`.

Run the image with host networking and bind the current host directory to `/workspace` inside the container:

```bash
docker run --rm -it \
  --name container-interfacing-nestdaq-eicrecon \
  --platform linux/amd64 \
  --network host \
  -v "$PWD:/workspace" \
  ghcr.io/nobukoba/container-interfacing-nestdaq-eicrecon:latest
```

Files written under `/workspace` inside the container are therefore stored directly in the current host directory and remain available after the container exits.

Open another shell in the running container with:

```bash
docker exec -it container-interfacing-nestdaq-eicrecon bash
```

## For developers

For development and maintenance of this container, please use **ChatGPT, Codex, or another AI assistant/coding agent** together with the instructions in [`AGENTS.md`](./AGENTS.md).

Before modifying the container, ask the AI agent to read `AGENTS.md` and inspect the current repository files. `AGENTS.md` contains the repository-specific build requirements, directory layout, container image conventions, and maintenance guidelines.

`CHATGPT_REBUILD_PROMPT.md` is not used in this repository. The repository itself and `AGENTS.md` are the authoritative sources for development and maintenance.

### Building the Docker image locally

Clone the repository and build the Docker image locally. The build script targets `linux/amd64`:

```bash
git clone https://github.com/nobukoba/container-interfacing-nestdaq-eicrecon.git
cd container-interfacing-nestdaq-eicrecon
git switch almalinux9
./build-docker-image.sh
./run-docker-container.sh
```

`run-docker-container.sh` binds the current directory to `/workspace` in the container.

A second shell can then be opened with:

```bash
./login-docker-container.sh
```

### Developing nestdaq-user-impl

With the current directory bound to `/workspace` in the container:

```bash
/opt/spadi/scripts/build-local-nestdaq-user-impl.sh
```

It uses:

```text
source  : /workspace/src/nestdaq-user-impl
build   : /workspace/build/nestdaq-user-impl
install : /workspace/local
```

To use the locally installed version:

```bash
export PATH=/workspace/local/bin:$PATH
export LD_LIBRARY_PATH=/workspace/local/lib:/workspace/local/lib64:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=/workspace/local:$CMAKE_PREFIX_PATH
```

## Images

GitHub Actions builds both Docker and Apptainer/Singularity images.

```text
Docker:
  ghcr.io/nobukoba/container-interfacing-nestdaq-eicrecon:latest
  ghcr.io/nobukoba/container-interfacing-nestdaq-eicrecon:YYYYMMDD-HHMMutc

SIF:
  container-interfacing-nestdaq-eicrecon.sif
  container-interfacing-nestdaq-eicrecon-YYYYMMDD-HHMMutc.sif
```

The non-timestamped SIF is published in the `latest` GitHub Release and is intended for normal use. The timestamped SIF identifies the exact build.

## Example raw data

Repository:

```text
example_rawdata/raris_ac_lgad_202603/
├── 00/
├── 01/
└── 02/
```

Inside Docker/SIF:

```text
/opt/spadi/example_rawdata/raris_ac_lgad_202603/
```

The example configuration uses `run000020.dat` from each of the three directories.

## Container layout

```text
/opt/spadi/
├── bin/
├── include/
├── lib/
├── lib64/
├── src/
│   ├── nestdaq/
│   ├── nestdaq-user-impl/
│   └── uhbook/
├── scripts/
│   ├── build-local-nestdaq-user-impl.sh
│   ├── exp-config/
│   └── example-interfacing-nestdaq-eicrecon/
└── example_rawdata/
    └── raris_ac_lgad_202603/

/workspace/
├── src/
├── build/
├── local/
└── scripts/
```

`/opt/spadi` contains software and helper scripts supplied by the image. `/workspace` is the writable user/development area. When using the provided Docker or Apptainer commands, the current host directory is mounted directly at `/workspace`.

## Valkey and RedisTimeSeries

The image builds RedisTimeSeries v1.10.24 and loads `redistimeseries.so` into Valkey. This is required by the NestDAQ `metrics` plugin for commands such as `TS.ADD`.

```text
/opt/spadi/lib/redistimeseries.so
```

`run-stf-tf.sh` starts Valkey through `start-valkey.sh`. To start it separately:

```bash
/opt/spadi/scripts/example-interfacing-nestdaq-eicrecon/start-valkey.sh
```

The startup script verifies `PING` and availability of `TS.ADD`.

## Networking

Apptainer normally shares the host network namespace, so Docker-style `--network host` is normally unnecessary.

The EICrecon-facing endpoint is:

```text
tcp://127.0.0.1:5501
```

## Manual SIF build

```bash
apptainer build \
  container-interfacing-nestdaq-eicrecon.sif \
  docker://ghcr.io/nobukoba/container-interfacing-nestdaq-eicrecon:latest
```

## GitHub Actions

The workflow can be run manually from:

```text
GitHub -> Actions -> Build Docker and SIF -> Run workflow
```

It is also triggered by changes to build-related files on `main`.

```text
GitHub repository
       |
       v
Docker build (linux/amd64)
       |
       v
GHCR
       |
       v
Apptainer SIF build
       |
       v
SIF smoke test
       |
       +--> GitHub Actions artifact
       |
       +--> latest GitHub Release
```

The `latest` release provides the stable URL used by the `curl` command at the top of this README.

## CPU compatibility

The image is based on AlmaLinux 9. NestDAQ-related executables are compiled with an x86-64-v2-compatible non-AVX configuration:

```text
-O2 -march=x86-64-v2 -mtune=generic
```

The Docker image platform itself is published as `linux/amd64`.
