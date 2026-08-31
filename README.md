# spadi-interfacing-nestdaq-eicrecon

NestDAQ-side Docker / Apptainer environment for the NestDAQ–EICrecon interface.

The GitHub Actions workflow creates:

```text
Docker:
  ghcr.io/<owner>/spadi-interfacing-nestdaq-eicrecon:latest
  ghcr.io/<owner>/spadi-interfacing-nestdaq-eicrecon:YYYYMMDD-HHMMutc

SIF:
  spadi-interfacing-nestdaq-eicrecon.sif
  spadi-interfacing-nestdaq-eicrecon-YYYYMMDD-HHMMutc.sif
```

The non-timestamped SIF name is intended for normal use. The timestamped file identifies the exact build.

## Repository layout

```text
.
├── Dockerfile
├── .github/
│   └── workflows/
│       └── docker.yml
├── scripts/
│   ├── build-local-nestdaq-user-impl.sh
│   └── example-interfacing-nestdaq-eicrecon/
│       └── start-valkey.sh
└── example_rawdata/
    └── raris_ac_lgad_202603/
        ├── 00/
        │   └── ...
        ├── 01/
        │   └── ...
        └── 02/
            └── ...
```

The small example raw data is tracked directly in GitHub and copied into the image.

## Container layout

```text
/opt/spadi/
├── bin/
├── include/
├── lib/
├── lib64/
├── src/
├── scripts/
│   ├── build-local-nestdaq-user-impl.sh
│   ├── exp-config/
│   └── example-interfacing-nestdaq-eicrecon/
│       └── start-valkey.sh
└── example_rawdata/
    └── raris_ac_lgad_202603/
        ├── 00/
        │   └── ...
        ├── 01/
        │   └── ...
        └── 02/
            └── ...

/work/
├── src/
├── build/
├── local/
└── scripts/
```

`/opt/spadi` belongs to the image.

`/work` is the writable user/development area. It is intentionally safe to bind the whole `/work` directory because the image-provided helper scripts are under `/opt/spadi/scripts`.

## GitHub Actions

### Automatic build trigger

The Docker/SIF workflow is automatically triggered by a push to `main` only when these paths change:

```text
Dockerfile
scripts/**
example_rawdata/**
.github/workflows/docker.yml
```

A change only to `README.md` or the local Docker helper scripts does not start a container rebuild.

The workflow can always be run manually from:

```text
GitHub
  → Actions
  → Build Docker and SIF
  → Run workflow
```

Manual execution uses `workflow_dispatch` and is useful when a rebuild is desired even though none of the automatic trigger paths changed.


The workflow runs automatically when a push to `main` changes files that affect the Docker/SIF build, or manually with **Run workflow**.

```text
checkout
   ↓
Docker build for linux/amd64
   ↓
push Docker image to GHCR
   ↓
build SIF from the GHCR image
   ↓
smoke-test the SIF
   ↓
upload both SIF filenames as GitHub Actions artifacts
```

The smoke test checks the main helper scripts, example raw-data directory, Valkey, wget, tmux, xterm and emacs.

## Example raw data

Put the small example files in:

```text
example_rawdata/raris_ac_lgad_202603/
```

Commit them normally:

```bash
git add example_rawdata
git commit -m "Add example raw data"
git push
```

Inside Docker and SIF they appear at:

```text
/opt/spadi/example_rawdata/raris_ac_lgad_202603/00/partial_run000021.dat
/opt/spadi/example_rawdata/raris_ac_lgad_202603/01/partial_run000021.dat
/opt/spadi/example_rawdata/raris_ac_lgad_202603/02/partial_run000021.dat
```

## Local Docker build

```bash
./build-docker-image.sh
```

Run:

```bash
./run-docker-container.sh
```

## Opening additional terminals in a running Docker container

`run-docker-container.sh` starts the container with the fixed name:

```text
spadi-interfacing-nestdaq-eicrecon
```

Start it in Terminal 1:

```bash
./run-docker-container.sh
```

Check the running container:

```bash
docker ps
```

Enter the same container from another terminal with:

```bash
./login-docker-container.sh
```

The script checks that `spadi-interfacing-nestdaq-eicrecon` is running and then executes:

```bash
docker exec -it spadi-interfacing-nestdaq-eicrecon bash
```

Multiple shells can be opened at the same time:

```text
Terminal 1:
  ./run-docker-container.sh

Terminal 2:
  ./login-docker-container.sh

Terminal 3:
  ./login-docker-container.sh
```

This is useful for running multiple NestDAQ / FairMQ processes in separate terminals while sharing the same container environment.

The names are intentionally consistent:

```text
GitHub repository : spadi-interfacing-nestdaq-eicrecon
Docker image      : spadi-interfacing-nestdaq-eicrecon
Docker container  : spadi-interfacing-nestdaq-eicrecon
SIF               : spadi-interfacing-nestdaq-eicrecon.sif
```

## SIF: simplest execution

Create one persistent writable work directory next to the SIF:

```bash
mkdir -p work
```

Start the container:

```bash
apptainer shell \
  --bind "$PWD/work:/work" \
  spadi-interfacing-nestdaq-eicrecon.sif
```

The entire host `work/` directory is available as `/work` and remains after the container exits.

For SingularityCE:

```bash
singularity shell \
  --bind "$PWD/work:/work" \
  spadi-interfacing-nestdaq-eicrecon.sif
```

A separate SIF run script is not necessary at this stage because the standard command is short and is documented here.

## SIF without persistent work

For a temporary writable container session:

```bash
apptainer shell \
  --writable-tmpfs \
  spadi-interfacing-nestdaq-eicrecon.sif
```

Changes disappear when the session ends.

## Valkey

This image also builds RedisTimeSeries v1.10.24 and loads `redistimeseries.so` into Valkey. This is required by the NestDAQ `metrics` plugin, which writes time-series metrics with commands such as `TS.ADD`.

The default module path is:

```text
/opt/spadi/lib/redistimeseries.so
```

`start-valkey.sh` verifies that `TS.ADD` is available immediately after startup.


Inside Docker or SIF:

```bash
/opt/spadi/scripts/example-interfacing-nestdaq-eicrecon/start-valkey.sh
```

Expected result:

```text
PONG
```

Check again with:

```bash
valkey-cli ping
```

## Developing nestdaq-user-impl

With `/work` bound as shown above, run inside the container:

```bash
/opt/spadi/scripts/build-local-nestdaq-user-impl.sh
```

It uses:

```text
source  : /work/src/nestdaq-user-impl
build   : /work/build/nestdaq-user-impl
install : /work/local
```

Because `/work` is bound from the host, the source tree and build products persist after leaving the SIF.

`/work/local` is intentionally not added globally to the image environment. To use the locally installed version in the current shell:

```bash
export PATH=/work/local/bin:$PATH
export LD_LIBRARY_PATH=/work/local/lib:/work/local/lib64:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=/work/local:$CMAKE_PREFIX_PATH
```

## Run a single command from SIF

```bash
apptainer exec \
  --bind "$PWD/work:/work" \
  spadi-interfacing-nestdaq-eicrecon.sif \
  bash -lc 'ls -lh /opt/spadi/example_rawdata/raris_ac_lgad_202603/'
```

## Networking

Apptainer normally shares the host network namespace, so Docker-style `--network host` is normally unnecessary.

For example, processes on the same host can use a ZeroMQ endpoint such as:

```text
tcp://127.0.0.1:5501
```

## Manual SIF build

On a Linux system with Apptainer:

```bash
apptainer build \
  spadi-interfacing-nestdaq-eicrecon.sif \
  docker://ghcr.io/nobukoba/spadi-interfacing-nestdaq-eicrecon:latest
```

## Basic SIF check

```bash
apptainer exec \
  spadi-interfacing-nestdaq-eicrecon.sif \
  bash -lc '
    set -e
    command -v wget
    command -v valkey-server
    test -x /opt/spadi/scripts/build-local-nestdaq-user-impl.sh
    test -x /opt/spadi/scripts/example-interfacing-nestdaq-eicrecon/start-valkey.sh
    test -d /opt/spadi/scripts/exp-config
    test -d /opt/spadi/example_rawdata/raris_ac_lgad_202603
  '
```

Exit status 0 means the basic layout and required commands are present.

## Developer / Maintainer notes

This section records both the development procedure and the design decisions behind the image layout.

### Repository directory structure

```text
spadi-interfacing-nestdaq-eicrecon/
├── Dockerfile
├── README.md
├── build-docker-image.sh
├── run-docker-container.sh
├── login-docker-container.sh
├── push-docker-image-to-ghcr.sh
├── .github/
│   └── workflows/
│       └── docker.yml
├── scripts/
│   ├── build-local-nestdaq-user-impl.sh
│   └── example-interfacing-nestdaq-eicrecon/
│       └── start-valkey.sh
└── example_rawdata/
    └── raris_ac_lgad_202603/
        ├── 00/
        │   └── ...
        ├── 01/
        │   └── ...
        └── 02/
            └── ...
```

### Docker / SIF directory structure

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
│       └── start-valkey.sh
└── example_rawdata/
    └── raris_ac_lgad_202603/
        ├── 00/
        │   └── ...
        ├── 01/
        │   └── ...
        └── 02/
            └── ...
```

### Writable development area

```text
/work/
├── src/
│   └── nestdaq-user-impl/
├── build/
│   └── nestdaq-user-impl/
├── local/
│   ├── bin/
│   ├── include/
│   └── lib/
└── scripts/
```

Directory policy:

- `/opt/spadi` contains software installed as part of the Docker/SIF image. Users normally do not modify it.
- `/opt/spadi/scripts` contains helper and example scripts supplied by the image.
- `/opt/spadi/scripts/example-interfacing-nestdaq-eicrecon` contains scripts specifically for the NestDAQ–EICrecon interfacing example.
- `/work` is the writable user/developer workspace and can be bind-mounted as one directory.
- `/work/src` contains source trees under development.
- `/work/build` contains out-of-source build trees.
- `/work/local` is the install prefix for locally rebuilt/development versions.
- `/work/scripts` is reserved for user-created test and development scripts.

Keeping image-provided scripts under `/opt/spadi/scripts` is intentional: binding a host directory over `/work` must not hide the helper scripts supplied by the image.

### Example raw-data mapping

The example data are stored in the repository as:

```text
example_rawdata/raris_ac_lgad_202603/
├── 00/
├── 01/
└── 02/
```

During the Docker build they are copied without changing this structure to:

```text
/opt/spadi/example_rawdata/raris_ac_lgad_202603/
├── 00/
├── 01/
└── 02/
```

### Clone and build locally

```bash
git clone https://github.com/nobukoba/spadi-interfacing-nestdaq-eicrecon.git
cd spadi-interfacing-nestdaq-eicrecon
./build-docker-image.sh
```

Run the local Docker image with:

```bash
./run-docker-container.sh
```

### Manual push to GHCR

```bash
./push-docker-image-to-ghcr.sh
```

The repository can therefore be used both for local Docker development and for automated builds on GitHub Actions.

### GitHub Actions build flow

The workflow runs automatically on `main` only when one of the following build-related paths changes:

```text
Dockerfile
scripts/**
example_rawdata/**
.github/workflows/docker.yml
```

It can also be started manually at any time with GitHub Actions **Run workflow** (`workflow_dispatch`).

Changes only to documentation or local convenience scripts, such as:

```text
README.md
build-docker-image.sh
run-docker-container.sh
login-docker-container.sh
push-docker-image-to-ghcr.sh
```

do not automatically rebuild the Docker image or SIF. This avoids unnecessary builds when the container contents have not changed.

When triggered, the workflow performs:

```text
GitHub repository
       |
       v
Docker build
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
       v
GitHub Actions artifact
```

Docker image names:

```text
ghcr.io/nobukoba/spadi-interfacing-nestdaq-eicrecon:latest
ghcr.io/nobukoba/spadi-interfacing-nestdaq-eicrecon:YYYYMMDD-HHMMutc
```

SIF names:

```text
spadi-interfacing-nestdaq-eicrecon.sif
spadi-interfacing-nestdaq-eicrecon-YYYYMMDD-HHMMutc.sif
```

### CPU compatibility policy

The container is based on AlmaLinux 10 and the software is compiled using the x86-64-v2 ISA baseline:

```text
-O2 -march=x86-64-v2 -mtune=generic
```

This choice is intentional for compatibility with DAQ machines that do not provide x86-64-v3. Do not change the baseline to x86-64-v3 unless support for those systems is no longer required.

### Updating the development nestdaq-user-impl

Run:

```bash
/opt/spadi/scripts/build-local-nestdaq-user-impl.sh
```

The helper uses:

```text
source  : /work/src/nestdaq-user-impl
build   : /work/build/nestdaq-user-impl
install : /work/local
```

The image-provided installation under `/opt/spadi` remains unchanged. The locally built installation under `/work/local` can be selected explicitly in a development shell.

### Build size reporting

The local Docker build script prints the resulting Docker image size at the end of the build:

```text
=== Docker image size ===
REPOSITORY                              TAG                  IMAGE ID       CREATED          SIZE
spadi-interfacing-nestdaq-eicrecon     YYYYMMDD-HHMMutc     ...            ...              ...
```

GitHub Actions also prints:

- the Docker image size after pulling the just-pushed GHCR image;
- the size of both generated SIF files.

This makes it easy to notice unexpected image growth between builds.

## Maintenance with ChatGPT

For routine maintenance of this repository, using ChatGPT is recommended. Typical tasks include updating the Dockerfile, helper scripts, GitHub Actions workflows, package versions, documentation, and troubleshooting build errors.

Connecting ChatGPT to GitHub is particularly useful because ChatGPT can inspect the current repository instead of relying on copied-and-pasted fragments or an old local snapshot.

### Connect GitHub to ChatGPT

In ChatGPT, open the available **Apps** or **Plugins** settings, select **GitHub**, authorize the GitHub account, and allow access to:

```text
nobukoba/spadi-interfacing-nestdaq-eicrecon
```

OpenAI documentation:

- English: https://help.openai.com/en/articles/11145903-connecting-github-to-chatgpt-deep-research
- Japanese: https://help.openai.com/ja-jp/articles/11145903

GitHub availability can depend on the ChatGPT plan and product experience. The GitHub app can inspect, search, and analyze repository content. According to the OpenAI documentation, the GitHub app itself provides read access for analysis; workflows that directly generate, edit, and push code to GitHub are available through Codex.

### Recommended maintenance workflow

```text
GitHub repository
       |
       v
ChatGPT reads the current repository
       |
       v
Discuss the requested change
       |
       v
Inspect affected files and dependencies
       |
       v
Make or generate the changes
       |
       v
Review the diff
       |
       v
Build and test
       |
       v
Commit / push to GitHub
       |
       v
GitHub Actions builds Docker and SIF images
```

When asking ChatGPT for maintenance, identify this repository explicitly. For example:

```text
Please inspect the current
nobukoba/spadi-interfacing-nestdaq-eicrecon
repository on GitHub and update the Docker environment.

Before changing anything, check the current Dockerfile,
scripts, README, and GitHub Actions workflow so that existing
design choices are preserved.
```

For a build problem:

```text
Please inspect the current GitHub repository and diagnose
the following build error.

[Paste the error output here]

Please preserve the existing directory layout and explain
which files need to be changed.
```

For a small feature or maintenance change:

```text
Please inspect the current GitHub repository first.

Add the requested feature while preserving the existing
container layout, script naming conventions, and GitHub
Actions behavior. Update README.md when the user-facing
procedure changes.
```

### Important maintenance practice

Do not ask ChatGPT to reconstruct the project only from conversation history when the GitHub repository is available. Ask it to inspect the current repository first. GitHub should be treated as the authoritative source for the current version of the project.

After a change, review:

```bash
git diff
git status
```

For shell-script changes:

```bash
bash -n build-docker-image.sh
bash -n run-docker-container.sh
bash -n login-docker-container.sh
bash -n push-docker-image-to-ghcr.sh
```

For Docker-related changes, run:

```bash
./build-docker-image.sh
```

before committing when a local Docker environment is available. GitHub Actions then provides the reproducible Docker/GHCR and SIF build path for the committed version.

## Running the NestDAQ → EICrecon example

The NestDAQ-side example scripts are installed in:

```text
/opt/spadi/scripts/example-interfacing-nestdaq-eicrecon/
```

They are based on the scripts used in the original NestDAQ setup, with paths adjusted for this container, Valkey support, and the example RAW-data layout in this repository.

Main scripts:

```text
start-valkey.sh        Start Valkey
mq-param.sh            Load NestDAQ parameters
topology-stf-tf.sh     Configure STFBFilePlayer → TimeFrameBuilder topology
start_device.sh        Start a NestDAQ/FairMQ device
run-stf-tf.sh          Start STFBFilePlayer and TimeFrameBuilder in tmux (no xterm)
kill_fairmq_devices.sh Stop the example tmux/device processes
```

The example uses these explicit RAW-data inputs:

```text
/opt/spadi/example_rawdata/raris_ac_lgad_202603/
```

Start the NestDAQ side with a single command:

```bash
cd /opt/spadi/scripts/example-interfacing-nestdaq-eicrecon
./run-stf-tf.sh
```

`run-stf-tf.sh` starts Valkey, loads the NestDAQ parameters, configures the topology, starts all processes in one `nestdaq` tmux session, and attaches to that session.

The `TimeFrameBuilder` input is fixed to TCP port `5500` for the STFBFilePlayer connections.

The `TimeFrameBuilder` output is configured as a ZeroMQ/FairMQ `push` socket bound to TCP port `5501`, for connection to the EICrecon side.

Check the tmux sessions with:

```bash
tmux ls
```

Attach to them with:

```bash
tmux attach -t stfb
tmux attach -t tfb
```

Stop the example with:

```bash
./kill_fairmq_devices.sh
```

The original uploaded scripts used to prepare this container example are retained under `reference/original-run_interfacing_nestdaq_eicrecon/` for comparison.



### Terminal handling

This example does **not** use `xterm`. `run-stf-tf.sh` starts the NestDAQ processes in `tmux`, so it also works when the container is entered from a normal terminal or through `docker exec`.

The intended sequence is:

```text
./init.sh
   ↓
./tf.sh
   ├── ./mq-param.sh
   ├── ./topology-stf-tf.sh
   └── ./run-stf-tf.sh
          └── tmux sessions
```


### One-command startup

For normal operation, the complete NestDAQ side can be started with:

```bash
cd /opt/spadi/scripts/example-interfacing-nestdaq-eicrecon
./run-stf-tf.sh
```

This starts Valkey, loads the parameters and topology, creates a single `nestdaq` tmux session, and attaches to it. The windows are:

```text
webctl  daq-webctl --http-uri http://0.0.0.0:8080
STF0    STFBFilePlayer
STF1    STFBFilePlayer
STF2    STFBFilePlayer
TFB     TimeFrameBuilder
```

`daq-webctl` runs in the foreground in the `webctl` tmux window, so its output is directly visible.


### tmux layout

`run-stf-tf.sh` creates one tmux session named `nestdaq`:

```text
webctl   daq-webctl --http-uri http://0.0.0.0:8080
STF0     STFBFilePlayer
STF1     STFBFilePlayer
STF2     STFBFilePlayer
TFB      TimeFrameBuilder
```

No `xterm` is used. The script automatically attaches to the `nestdaq` session after starting the processes.

A tmux window is configured with `remain-on-exit on`. Therefore, if `STF0`, `STF1`, `STF2`, or `TFB` terminates because of an error, its tab remains visible instead of disappearing. Select that tab to inspect the error output.

Useful tmux keys:

```text
Ctrl-b n        next window
Ctrl-b p        previous window
Ctrl-b 0..4     select a window by number
Ctrl-b d        detach from tmux
```

To re-enter later:

```bash
tmux attach -t nestdaq
```

To stop the example:

```bash
./kill_fairmq_devices.sh
```

### Docker host-network note

`daq_service` normally tries to discover the IP address from the default network route. With Docker host networking, particularly on Docker Desktop, a usable default route may not be visible inside the container. In that case NestDAQ can terminate with:

```text
Could not detect default route network interface name from /proc/net/route nor 'ip route'
```

The example therefore passes an explicit host IP to every NestDAQ/FairMQ device:

```text
--host-ip 127.0.0.1
```

This is appropriate for this example because the NestDAQ devices communicate with each other inside the same container. The TimeFrameBuilder output for the EICrecon interface is still exposed separately on TCP port 5501.

The value can be overridden when necessary:

```bash
export NESTDAQ_HOST_IP=192.168.x.x
./run-stf-tf.sh
```

### tmux device windows after a run

`STF0`, `STF1`, `STF2`, and `TFB` remain open after the corresponding device exits, including error exits. The pane prints the process exit status and then leaves an interactive shell open so the final log remains visible for debugging.

### RedisTimeSeries on AlmaLinux 10 / Valkey

The image builds RedisTimeSeries `v1.10.24` directly with `make build DEPS=1` rather than running `./sbin/setup`. The upstream setup helper uses EPEL/virtualenv distro-detection logic that does not recognize AlmaLinux 10 reliably. The resulting `redistimeseries.so` is loaded by `start-valkey.sh`, which verifies that `TS.ADD` is available before starting NestDAQ.
