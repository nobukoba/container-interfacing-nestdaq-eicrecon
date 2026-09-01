# ChatGPT prompt for rebuilding this container image

This page contains a reusable prompt for asking ChatGPT to recreate or maintain the `container-interfacing-nestdaq-eicrecon` container environment.

The prompt is intentionally written so that ChatGPT should inspect the current repository before making changes instead of relying on an old copy of the Dockerfile.

## Prompt

Copy the following prompt into ChatGPT:

```text
I want to recreate and maintain the container environment in this GitHub repository:

https://github.com/nobukoba/container-interfacing-nestdaq-eicrecon

Please inspect the current repository first, especially:

- Dockerfile
- README.md
- .github/workflows/docker.yml
- run-docker-container.sh
- build-docker-image.sh
- login-docker-container.sh
- scripts/
- example_rawdata/

Do not recreate the environment only from this prompt. Treat the current files in the GitHub repository as the authoritative source and preserve their current behavior unless a change is necessary.

The purpose of this repository is to provide the NestDAQ side of a NestDAQ–EICrecon interface environment. EICrecon itself runs in a separate container/environment and communicates with NestDAQ over the network.

Important requirements and design choices:

1. Build a Docker image based on AlmaLinux 10.

2. Target x86-64-v2 / linux/amd64/v2 so that the resulting image can also run under x86_64 emulation on Apple Silicon Macs.

3. Do not allow AVX/AVX2 instructions into NestDAQ or nestdaq-user-impl executables. The Apple Silicon Docker x86_64 environment used for testing does not expose AVX.

4. NestDAQ and nestdaq-user-impl currently contain Release compiler settings using `-march=native`. Patch those settings during the container build so Release builds use an x86-64-v2-compatible non-AVX configuration instead, for example:

   -march=x86-64-v2 -mtune=generic -mno-avx -mno-avx2

   Do not modify the upstream GitHub repositories themselves just to build this image.

5. Verify important generated executables with objdump so AVX instructions such as `vzeroupper`, YMM/ZMM register use, or VEX-encoded AVX instructions do not accidentally enter the distributed image.

6. Install the NestDAQ-related software under:

   /opt/spadi

   Important directories include:

   /opt/spadi/bin
   /opt/spadi/include
   /opt/spadi/lib
   /opt/spadi/lib64
   /opt/spadi/src
   /opt/spadi/scripts
   /opt/spadi/example_rawdata

7. Keep `/opt/spadi` as the image-provided software area. Use `/work` as the persistent writable user/development area.

8. The Docker run helper must bind a host work directory to `/work`. By default:

   host:      $PWD/work
   container: /work

   `run-docker-container.sh` should create the host work directory automatically if it does not exist. It should also allow another host directory to be selected with the `WORK_DIR` environment variable.

9. Include the software currently required by the Dockerfile, including the current versions/configurations of ZeroMQ, fmt, FairLogger, FairMQ, hiredis, redis-plus-plus, Valkey, RedisTimeSeries, NestDAQ, UHBOOK, nestdaq-user-impl, and exp-config. Read the Dockerfile for the exact current versions and build options instead of assuming the versions in this prompt are current.

10. RedisTimeSeries support is required because the NestDAQ metrics plugin uses commands such as `TS.ADD`. Valkey must load the RedisTimeSeries module used by the image.

11. Preserve the example NestDAQ setup and example raw data included in the repository.

12. The example topology is conceptually:

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

   EICrecon is external to this image.

13. The example startup scripts use tmux so that STFBFilePlayer instances, TimeFrameBuilder, and control processes can be inspected separately and their final output remains visible after a process exits.

14. GitHub Actions should build and publish the Docker image to:

   ghcr.io/nobukoba/container-interfacing-nestdaq-eicrecon

   It should provide both `latest` and timestamped tags as currently defined by the workflow.

15. GitHub Actions should also create an Apptainer/Singularity SIF image from the Docker image and publish it according to the current workflow/release configuration.

16. Docker and Apptainer/Singularity should both support a persistent host work directory mapped to `/work`.

17. Keep the README synchronized with actual commands, paths, image names, networking, CPU compatibility, and helper scripts.

When working on this repository:

- inspect the current GitHub state before editing;
- explain the specific cause of a build/runtime problem before making broad changes when possible;
- prefer targeted fixes over global compiler or dependency changes;
- preserve working behavior unrelated to the requested change;
- show concrete shell commands for testing;
- after changing the repository, report exactly which files changed and what should be tested;
- do not assume that `linux/amd64/v2` alone prevents `-march=native` from generating AVX on a native x86 GitHub Actions runner.

First inspect the repository and summarize the current image architecture, build flow, runtime flow, and any differences between the current repository and the requirements above. Then make or propose only the changes actually needed.
```

## Why the prompt points back to GitHub

The repository is expected to evolve. Package versions, scripts, compiler workarounds, ports, and GitHub Actions details may change over time. Keeping those details only in a static AI prompt would eventually make the prompt stale.

For that reason, the prompt describes the important design constraints but explicitly tells ChatGPT to read the current repository before recreating or modifying the image.
