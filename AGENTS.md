# Repository instructions for AI agents

This file contains the instructions and design constraints that AI assistants and coding agents should read before rebuilding or modifying this repository.

The repository itself is the authoritative source for the current package versions, scripts, build options, and runtime configuration. Before making changes, inspect the current repository, especially:

- `Dockerfile`
- `README.md`
- `.github/workflows/docker.yml`
- `run-docker-container.sh`
- `build-docker-image.sh`
- `login-docker-container.sh`
- `scripts/`
- `example_rawdata/`

Do not recreate the environment only from this document. Preserve the current repository behavior unless a change is necessary.

## Current AlmaLinux 9 branch status

The active compatibility branch is `almalinux9`. Keep its work separate from
`main` until the Docker build, SIF build, and smoke test all pass.

As of 2026-09-02, GitHub Actions has progressed through the dependency builds
and into the NestDAQ controller build. AlmaLinux 9's Boost.System
`error_code` exposes `message()` rather than exception-style `what()`. The
Dockerfile therefore patches the three current controller sources that call
`ec.what()`:

```text
controller/websocket_session.cxx
controller/http_session.cxx
controller/HttpWebSocketServer.cxx
```

The preceding run also established that `nestdaq-user-impl` needs its internal
`utility`, `emulator`, and `sqlite` CMake targets declared before executables
that link to them. Preserve that target-ordering patch while continuing the
AlmaLinux 9 build.

After each targeted fix, push to `almalinux9`, inspect the resulting `Build
Docker and SIF` run, and record any new reproducible constraint here. Do not
merge the branch into `main` merely because the Docker compilation succeeds;
the SIF build and smoke test must also finish successfully.

## Purpose

This repository provides the NestDAQ-side Docker / Apptainer environment for the NestDAQ–EICrecon interface.

EICrecon itself runs in a separate container/environment and communicates with NestDAQ over the network.

## Important build requirements

1. Build the container from AlmaLinux 9. Keep AlmaLinux 9 as the base unless a version change is explicitly requested and tested.

2. Publish and run the container as `linux/amd64`, not `linux/amd64/v2`. CPU compatibility of compiled NestDAQ software is controlled separately by compiler flags.

3. Do not allow AVX/AVX2 instructions into NestDAQ or nestdaq-user-impl executables. The Apple Silicon Docker x86_64 environment used for testing does not expose AVX.

4. NestDAQ and nestdaq-user-impl currently contain Release compiler settings using `-march=native`. Patch those settings during the container build so Release builds use an x86-64-v2-compatible non-AVX configuration, for example:

   ```text
   -march=x86-64-v2 -mtune=generic -mno-avx -mno-avx2
   ```

   Do not modify the upstream GitHub repositories themselves merely to build this image.

5. Verify important generated executables with `objdump` so AVX instructions such as `vzeroupper`, YMM/ZMM register use, or VEX-encoded AVX instructions do not accidentally enter the distributed image.

6. Do not assume that the Docker platform setting prevents `-march=native` from generating AVX on a native x86 GitHub Actions runner. Docker image platform and compiler CPU optimization are separate issues.

## Container layout

Install image-provided NestDAQ-related software under:

```text
/opt/spadi
```

Important directories include:

```text
/opt/spadi/bin
/opt/spadi/include
/opt/spadi/lib
/opt/spadi/lib64
/opt/spadi/src
/opt/spadi/scripts
/opt/spadi/example_rawdata
```

Keep `/opt/spadi` as the image-provided software area.

Use `/workspace` as the persistent writable user/development area.

For Docker, bind the current host directory directly to `/workspace`:

```text
host:      $PWD
container: /workspace
```

The standard Docker mapping is therefore:

```bash
-v "$PWD:/workspace"
```

`run-docker-container.sh` should use the current directory by default and allow another host directory to be selected with the `WORKSPACE_DIR` environment variable.

Docker and Apptainer/Singularity should both support mapping a host directory to `/workspace`.

## Software stack

Include the software currently required by the Dockerfile, including the current versions/configurations of:

- ZeroMQ
- fmt
- FairLogger
- FairMQ
- hiredis
- redis-plus-plus
- Valkey
- RedisTimeSeries
- NestDAQ
- UHBOOK
- nestdaq-user-impl
- exp-config

Read the current Dockerfile for exact versions and build options instead of assuming versions documented here remain current.

RedisTimeSeries support is required because the NestDAQ `metrics` plugin uses commands such as `TS.ADD`. Valkey must load the RedisTimeSeries module used by the image.

Preserve the example NestDAQ setup and example raw data included in the repository.

## NestDAQ–EICrecon topology

The example topology is conceptually:

```text
STFBFilePlayer 0/1/2
        |
        v
TimeFrameBuilder input  tcp://127.0.0.1:5500
        |
        v
TimeFrameBuilder output tcp://127.0.0.1:5501
        |
        v
EICrecon
```

EICrecon is external to this image.

The example startup scripts use `tmux` so that STFBFilePlayer instances, TimeFrameBuilder, and control processes can be inspected separately and their final output remains visible after a process exits. The session binds `Ctrl-b x` to close the current pane without a confirmation prompt.

## GitHub Actions and images

GitHub Actions should build and publish the Docker image to:

```text
ghcr.io/nobukoba/container-interfacing-nestdaq-eicrecon
```

The Docker image platform is `linux/amd64`.

It should provide both `latest` and timestamped tags as currently defined by the workflow.

GitHub Actions should also create an Apptainer/Singularity SIF image from the Docker image and publish it according to the current workflow/release configuration.

Keep the README synchronized with actual commands, paths, image names, networking, CPU compatibility, and helper scripts.

## How AI agents should work on this repository

When working on this repository:

- inspect the current GitHub/repository state before editing;
- explain the specific cause of a build/runtime problem before making broad changes when possible;
- prefer targeted fixes over global compiler or dependency changes;
- preserve working behavior unrelated to the requested change;
- show concrete shell commands for testing;
- after changing the repository, report exactly which files changed and what should be tested;
- never claim to have inspected, built, tested, or modified something that was not actually accessible or executed.

When asked to rebuild or reproduce the image, first inspect the repository and summarize the current image architecture, build flow, runtime flow, and any differences between the repository and these requirements. Then make or propose only the changes actually needed.

## ChatGPT and other AI assistants

These instructions are not specific to one AI product. They are intended for ChatGPT, Codex, and other coding agents that understand repository instruction files.

A normal ChatGPT session can still be useful for understanding the repository, reviewing public GitHub files, generating Dockerfiles/scripts, debugging logs, and suggesting changes. Direct repository access and repository-writing capabilities depend on the ChatGPT plan, mode, and available integrations.

If GitHub repository access is unavailable, read the public repository through web access if available. If that is also unavailable, ask the user to provide the relevant files. Do not pretend that inaccessible files were inspected.
