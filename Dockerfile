# syntax=docker/dockerfile:1
FROM quay.io/almalinuxorg/9-base:9

ARG NPROC=4
ARG LIBZMQ_VERSION=v4.3.5
ARG FMT_VERSION=10.2.1
ARG FAIRMQ_VERSION=v1.4.55
ARG HIREDIS_VERSION=v1.1.0
ARG REDIS_PLUS_PLUS_VERSION=1.3.6
ARG REDISTIMESERIES_VERSION=v1.10.24

ENV SPADI_ROOT=/opt/spadi
ENV EXP_CONFIG_ROOT=/opt/spadi/scripts/exp-config
ENV SPADI_EXAMPLE_RAWDATA=/opt/spadi/example_rawdata
ENV PATH=/opt/spadi/bin:${PATH}
ENV LD_LIBRARY_PATH=/opt/spadi/lib:/opt/spadi/lib64
ENV CMAKE_PREFIX_PATH=/opt/spadi
ENV PKG_CONFIG_PATH=/opt/spadi/lib/pkgconfig:/opt/spadi/lib64/pkgconfig
ENV CFLAGS="-O2 -march=x86-64-v2 -mtune=generic"
ENV CXXFLAGS="-O2 -march=x86-64-v2 -mtune=generic"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN dnf -y update && \
    dnf -y install \
      git gcc gcc-c++ make cmake pkgconf-pkg-config \
      boost-devel openssl-devel libuuid-devel sqlite-devel \
      bzip2-devel xz-devel zlib-devel libzstd-devel \
      libtool autoconf automake \
      which findutils diffutils patch tar gzip bzip2 xz \
      wget ca-certificates python3 python3-pip python3-setuptools rsync jq \
      valkey tmux xterm emacs binutils file procps-ng \
      net-tools nmap-ncat iproute iputils && \
    ln -sf "$(command -v python3)" /usr/local/bin/python3.9 && \
    ln -sf "$(command -v gcc)" /usr/local/bin/cc && \
    python3.9 --version && \
    cc --version && \
    dnf clean all && rm -rf /var/cache/dnf

RUN mkdir -p \
      ${SPADI_ROOT}/src \
      ${SPADI_ROOT}/bin \
      ${SPADI_ROOT}/include \
      ${SPADI_ROOT}/lib \
      ${SPADI_ROOT}/lib64 \
      ${SPADI_ROOT}/scripts \
      ${SPADI_EXAMPLE_RAWDATA}/raris_ac_lgad_202603 \
      /workspace/src \
      /workspace/build \
      /workspace/local \
      /workspace/scripts && \
    chmod 1777 /workspace

RUN cd ${SPADI_ROOT}/src && \
    git clone --depth 1 --branch ${LIBZMQ_VERSION} https://github.com/zeromq/libzmq.git && \
    cmake -S libzmq -B libzmq/build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${SPADI_ROOT} -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DBUILD_TESTS=OFF -DENABLE_DRAFTS=OFF && \
    cmake --build libzmq/build -j${NPROC} && cmake --install libzmq/build

RUN cd ${SPADI_ROOT}/src && \
    git clone --depth 1 --branch ${FMT_VERSION} https://github.com/fmtlib/fmt.git && \
    cmake -S fmt -B fmt/build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${SPADI_ROOT} -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DBUILD_SHARED_LIBS=ON -DFMT_TEST=OFF -DFMT_DOC=OFF && \
    cmake --build fmt/build -j${NPROC} && cmake --install fmt/build

RUN cd ${SPADI_ROOT}/src && \
    git clone --depth 1 https://github.com/FairRootGroup/FairLogger.git && \
    cmake -S FairLogger -B FairLogger/build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${SPADI_ROOT} -DCMAKE_PREFIX_PATH=${SPADI_ROOT} \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_STANDARD=17 -DUSE_EXTERNAL_FMT=ON && \
    cmake --build FairLogger/build -j${NPROC} && cmake --install FairLogger/build

RUN cd ${SPADI_ROOT}/src && \
    git clone --depth 1 --branch ${FAIRMQ_VERSION} https://github.com/FairRootGroup/FairMQ.git && \
    cmake -S FairMQ -B FairMQ/build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${SPADI_ROOT} -DCMAKE_PREFIX_PATH=${SPADI_ROOT} \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_STANDARD=17 -DBUILD_TESTING=OFF && \
    cmake --build FairMQ/build -j${NPROC} && cmake --install FairMQ/build

RUN cd ${SPADI_ROOT}/src && \
    git clone --depth 1 --branch ${HIREDIS_VERSION} https://github.com/redis/hiredis.git && \
    make -C hiredis -j${NPROC} PREFIX=${SPADI_ROOT} && \
    make -C hiredis PREFIX=${SPADI_ROOT} install

RUN cd ${SPADI_ROOT}/src && \
    git clone --depth 1 --branch ${REDIS_PLUS_PLUS_VERSION} https://github.com/sewenew/redis-plus-plus.git && \
    sed -i '/#include "cxx_utils.h"/i #include <cstdint>' redis-plus-plus/src/sw/redis++/utils.h && \
    cmake -S redis-plus-plus -B redis-plus-plus/build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${SPADI_ROOT} -DCMAKE_PREFIX_PATH=${SPADI_ROOT} \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DREDIS_PLUS_PLUS_CXX_STANDARD=17 \
      -DREDIS_PLUS_PLUS_BUILD_TEST=OFF -DREDIS_PLUS_PLUS_BUILD_STATIC=OFF && \
    cmake --build redis-plus-plus/build -j${NPROC} && cmake --install redis-plus-plus/build

# NestDAQ's metrics plugin uses RedisTimeSeries commands such as TS.ADD.
# Build the module directly because the image already contains the required
# build prerequisites and this avoids distribution-detection setup differences.
# v1.10.x is used because it targets Redis/Valkey 7.2-era module APIs; v1.12.x
# requires Redis 7.4 or newer.
RUN cd ${SPADI_ROOT}/src && \
    git clone --recursive --depth 1 --branch ${REDISTIMESERIES_VERSION} \
      https://github.com/RedisTimeSeries/RedisTimeSeries.git && \
    cd RedisTimeSeries && \
    make -j${NPROC} build DEPS=1 && \
    RTS_SO="$(find bin -type f -name redistimeseries.so -print -quit)" && \
    test -n "${RTS_SO}" && \
    install -m 0755 "${RTS_SO}" ${SPADI_ROOT}/lib/redistimeseries.so

# NestDAQ's common.cmake uses -march=native for Release builds.  On native
# GitHub x86 runners this enables AVX, while Apple Silicon Docker's x86_64
# emulation does not expose AVX.  Force an x86-64-v2 / non-AVX Release build.
# AlmaLinux 9's Boost.System error_code provides message(), not exception-style
# what(); patch the current NestDAQ controller sources without dropping daq-webctl.
RUN cd ${SPADI_ROOT}/src && \
    git clone --depth 1 https://github.com/spadi-alliance/nestdaq.git && \
    sed -i \
      's/-Ofast -DNDEBUG -march=native/-Ofast -DNDEBUG -march=x86-64-v2 -mtune=generic -mno-avx -mno-avx2/' \
      nestdaq/cmake/common.cmake && \
    sed -i 's/ec\.what()/ec.message()/g' \
      nestdaq/controller/websocket_session.cxx \
      nestdaq/controller/http_session.cxx \
      nestdaq/controller/HttpWebSocketServer.cxx && \
    cmake -S nestdaq -B nestdaq/build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${SPADI_ROOT} -DCMAKE_PREFIX_PATH=${SPADI_ROOT} \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_STANDARD=17 && \
    cmake --build nestdaq/build -j${NPROC} --verbose && \
    cmake --install nestdaq/build && \
    echo '=== Checking NestDAQ executables for AVX instructions ===' && \
    objdump -d ${SPADI_ROOT}/bin/TimeFrameBuilder > /tmp/TimeFrameBuilder.dis && \
    if grep -Eq 'vzeroupper|ymm[0-9]+|zmm[0-9]+|vmovdqu' /tmp/TimeFrameBuilder.dis; then \
      echo 'ERROR: AVX instructions found in TimeFrameBuilder' >&2; \
      exit 1; \
    fi && \
    objdump -d ${SPADI_ROOT}/bin/daq-webctl > /tmp/daq-webctl.dis && \
    if grep -Eq 'vzeroupper|ymm[0-9]+|zmm[0-9]+|vmovdqu' /tmp/daq-webctl.dis; then \
      echo 'ERROR: AVX instructions found in daq-webctl' >&2; \
      exit 1; \
    fi && \
    rm -f /tmp/TimeFrameBuilder.dis /tmp/daq-webctl.dis

RUN cd ${SPADI_ROOT}/src && \
    git clone --depth 1 https://github.com/spadi-alliance/uhbook.git && \
    ln -sf ${SPADI_ROOT}/src/uhbook/uhbook.cxx ${SPADI_ROOT}/include/uhbook.cxx

# nestdaq-user-impl also sets -march=native unconditionally for Release builds.
# Patch that project setting itself so GitHub-hosted native x86 builders cannot
# re-enable AVX after command-line/environment flags have been supplied.
# Its internal Utility and AmQTdcModule targets are declared after executables
# that link to them, so CMake treats those names as external -l libraries.
# Move the subdirectories before the executable definitions so they are proper
# CMake targets and can be linked from the same build tree.
RUN cd ${SPADI_ROOT}/src && \
    git clone --depth 1 https://github.com/spadi-alliance/nestdaq-user-impl.git && \
    python3 - <<'PY'
from pathlib import Path
p = Path("/opt/spadi/src/nestdaq-user-impl/CMakeLists.txt")
s = p.read_text()
s = s.replace("find_package(ROOT REQUIRED COMPONENTS RIO RHTTP Hist)",
              'message(STATUS "ROOT support disabled")')
s = s.replace("    TriggerView;\n", "")
s = s.replace('set(CMAKE_CXX_FLAGS_RELEASE "-Ofast -DNDEBUG -march=native")',
              'set(CMAKE_CXX_FLAGS_RELEASE "-Ofast -DNDEBUG -march=x86-64-v2 -mtune=generic -mno-avx -mno-avx2")')
s = s.replace("  target_include_directories(${EXEC} PUBLIC \n",
              "  target_include_directories(${EXEC} PUBLIC \n    ${CMAKE_INSTALL_PREFIX}/include;\n",
              1)
s = s.replace("#==============================================================================\n# Sampler(for Emulator), Sink, FileSink, STFBuilder, TimeFrameBuilder\n",
              "#==============================================================================\n# Internal libraries must exist before executables link to them.\nadd_subdirectory(utility)\nadd_subdirectory(emulator)\nadd_subdirectory(sqlite)\n\n#==============================================================================\n# Sampler(for Emulator), Sink, FileSink, STFBuilder, TimeFrameBuilder\n",
              1)
s = s.replace("#================================================================================\nadd_subdirectory(utility)\nadd_subdirectory(emulator)\nadd_subdirectory(sqlite)\n", "", 1)
p.write_text(s)
PY

RUN cmake -S ${SPADI_ROOT}/src/nestdaq-user-impl \
      -B ${SPADI_ROOT}/src/nestdaq-user-impl/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${SPADI_ROOT} \
      -DCMAKE_PREFIX_PATH="${SPADI_ROOT};${SPADI_ROOT}/src/uhbook" \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DCMAKE_CXX_STANDARD=17 && \
    cmake --build ${SPADI_ROOT}/src/nestdaq-user-impl/build -j${NPROC} --verbose && \
    cmake --install ${SPADI_ROOT}/src/nestdaq-user-impl/build && \
    echo '=== Checking nestdaq-user-impl executables for AVX instructions ===' && \
    objdump -d ${SPADI_ROOT}/bin/STFBFilePlayer > /tmp/STFBFilePlayer.dis && \
    if grep -Eq 'vzeroupper|ymm[0-9]+|zmm[0-9]+|vmovdqu' /tmp/STFBFilePlayer.dis; then \
      echo 'ERROR: AVX instructions found in STFBFilePlayer' >&2; \
      exit 1; \
    fi && \
    rm -f /tmp/STFBFilePlayer.dis

RUN git clone --depth 1 https://github.com/spadi-alliance/exp-config.git ${EXP_CONFIG_ROOT}

COPY scripts/ ${SPADI_ROOT}/scripts/

COPY example_rawdata/raris_ac_lgad_202603/ \
     ${SPADI_EXAMPLE_RAWDATA}/raris_ac_lgad_202603/

RUN chmod +x \
      ${SPADI_ROOT}/scripts/build-local-nestdaq-user-impl.sh \
      ${SPADI_ROOT}/scripts/example-interfacing-nestdaq-eicrecon/start-valkey.sh && \
    chmod -R a+rX ${SPADI_ROOT}/scripts ${SPADI_EXAMPLE_RAWDATA}

RUN printf '%s\n' '/opt/spadi/lib' '/opt/spadi/lib64' > /etc/ld.so.conf.d/spadi.conf && ldconfig

WORKDIR /workspace
CMD ["/bin/bash"]
