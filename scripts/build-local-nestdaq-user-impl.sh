#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="/workspace/src/nestdaq-user-impl"
BUILD_DIR="/workspace/build/nestdaq-user-impl"
INSTALL_DIR="/workspace/local"
NPROC="${NPROC:-4}"

mkdir -p /workspace/src /workspace/build "${INSTALL_DIR}"

if [[ ! -d "${SRC_DIR}/.git" ]]; then
    git clone https://github.com/spadi-alliance/nestdaq-user-impl.git "${SRC_DIR}"
else
    echo "Using existing source: ${SRC_DIR}"
fi

python3 - <<'PY'
from pathlib import Path
p = Path("/workspace/src/nestdaq-user-impl/CMakeLists.txt")
s = p.read_text()
s = s.replace("find_package(ROOT REQUIRED COMPONENTS RIO RHTTP Hist)",
              'message(STATUS "ROOT support disabled")')
s = s.replace("    TriggerView;\n", "")
p.write_text(s)
PY

cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
  -DCMAKE_PREFIX_PATH="${INSTALL_DIR};/opt/spadi;/opt/spadi/src/uhbook" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_CXX_STANDARD=17

cmake --build "${BUILD_DIR}" -j"${NPROC}"
cmake --install "${BUILD_DIR}"

echo "Source : ${SRC_DIR}"
echo "Build  : ${BUILD_DIR}"
echo "Install: ${INSTALL_DIR}"
