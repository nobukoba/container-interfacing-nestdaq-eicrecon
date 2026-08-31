# container-interfacing-nestdaq-eicrecon

NestDAQ-side Docker / Apptainer environment for the NestDAQ–EICrecon interface.

## How to use

### Apptainer / Singularity

Download the latest SIF image:

```bash
curl -fL \
  -o container-interfacing-nestdaq-eicrecon.sif \
  https://github.com/nobukoba/container-interfacing-nestdaq-eicrecon/releases/latest/download/container-interfacing-nestdaq-eicrecon.sif
```

Create a persistent writable work directory:

```bash
mkdir -p work
```

Start with Apptainer:

```bash
apptainer shell \
  --bind "$PWD/work:/work" \
  container-interfacing-nestdaq-eicrecon.sif
```

For SingularityCE:

```bash
singularity shell \
  --bind "$PWD/work:/work" \
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
Ctrl-b d      detach
```

Reattach with:

```bash
tmux -L spadi-sif attach -t nestdaq
```

The STF/TFB windows remain open after their device exits so that the final log and exit status can be inspected.

### Docker

For normal use, pull the prebuilt x86-64-v2 image from GHCR:

```bash
docker pull --platform linux/amd64/v2 \
  ghcr.io/nobukoba/container-interfacing-nestdaq-eicrecon:latest
```

Run it with host networking:

```bash
docker run --rm -it \
  --name container-interfacing-nestdaq-eicrecon \
  --platform linux/amd64/v2 \
  --network host \
  ghcr.io/nobukoba/container-interfacing-nestdaq-eicrecon:latest
```

Open another shell in the running container with:

```bash
docker exec -it container-interfacing-nestdaq-eicrecon bash
```

For development, clone the repository and build the Docker image locally. The build script also targets `linux/amd64/v2`:

```bash
git clone https://github.com/nobukoba/container-interfacing-nestdaq-eicrecon.git
cd container-interfacing-nestdaq-eicrecon
./build-docker-image.sh
./run-docker-container.sh
```

A second shell can then be opened with:

```bash
./login-docker-container.sh
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

/work/
├── src/
├── build/
├── local/
└── scripts/
```

`/opt/spadi` contains software and helper scripts supplied by the image. `/work` is the writable user/development area.

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

## Developing nestdaq-user-impl

With `/work` bound into the container:

```bash
/opt/spadi/scripts/build-local-nestdaq-user-impl.sh
```

It uses:

```text
source  : /work/src/nestdaq-user-impl
build   : /work/build/nestdaq-user-impl
install : /work/local
```

To use the locally installed version:

```bash
export PATH=/work/local/bin:$PATH
export LD_LIBRARY_PATH=/work/local/lib:/work/local/lib64:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=/work/local:$CMAKE_PREFIX_PATH
```

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
Docker build (linux/amd64/v2)
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

The image is based on AlmaLinux 10 and is compiled with the x86-64-v2 baseline:

```text
-O2 -march=x86-64-v2 -mtune=generic
```

This keeps compatibility with DAQ machines that do not provide x86-64-v3.
