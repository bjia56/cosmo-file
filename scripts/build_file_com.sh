#!/bin/bash
# Build script for creating file.com with Cosmopolitan libc
#
# This script clones the file repository, builds it separately for x86_64 and
# aarch64 architectures using arch-specific Cosmopolitan compilers, then uses
# apelink to combine them into a single fat binary that runs on multiple platforms.
#
# Requirements:
#   - cosmocc compiler toolchain (https://cosmo.zip/pub/cosmocc/)
#   - git
#   - Standard build tools (make, etc.)
#
# Usage:
#   ./scripts/build_file_com.sh

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build"
OUTPUT_DIR="${PROJECT_ROOT}/src/cosmo_file/data"
OUTPUT_BINARY="${OUTPUT_DIR}/file.com"
OUTPUT_LICENSE="${OUTPUT_DIR}/COPYING"

# Read file version from Python module
# This ensures the build always uses the version defined in _version.py
FILE_VERSION=$(python3 -c "import sys; sys.path.insert(0, '${PROJECT_ROOT}/src'); from cosmo_file._version import FILE_GIT_TAG; print(FILE_GIT_TAG)")

# file repository details
FILE_REPO="https://github.com/file/file.git"

echo "================================================"
echo "Building file.com with Cosmopolitan libc"
echo "Creating fat binary with x86_64 and aarch64"
echo "================================================"
echo "Build directory: ${BUILD_DIR}"
echo "Output: ${OUTPUT_BINARY}"
echo "file version: ${FILE_VERSION}"
echo ""

# Check for required tools
for tool in cosmocc x86_64-unknown-cosmo-cc aarch64-unknown-cosmo-cc apelink; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool not found in PATH"
        echo "Please install cosmocc toolchain from: https://cosmo.zip/pub/cosmocc/"
        echo ""
        echo "Quick install:"
        echo "  mkdir -p ~/.cosmo"
        echo "  cd ~/.cosmo"
        echo "  wget https://cosmo.zip/pub/cosmocc/cosmocc.zip"
        echo "  unzip cosmocc.zip"
        echo "  export PATH=\"\$HOME/.cosmo/bin:\$PATH\""
        exit 1
    fi
done

# Check for autoreconf, zip, git, make, patch
if ! command -v autoreconf &> /dev/null; then
    echo "Error: autoreconf not found in PATH"
    echo "Please install autoconf package."
    exit 1
fi
if ! command -v zip &> /dev/null; then
    echo "Error: zip not found in PATH"
    echo "Please install zip."
    exit 1
fi
if ! command -v git &> /dev/null; then
    echo "Error: git not found in PATH"
    echo "Please install git."
    exit 1
fi
if ! command -v make &> /dev/null; then
    echo "Error: make not found in PATH"
    echo "Please install make."
    exit 1
fi
if ! command -v patch &> /dev/null; then
    echo "Error: patch not found in PATH"
    echo "Please install patch."
    exit 1
fi

echo "Found toolchain:"
echo "  cosmocc: $(which cosmocc)"
echo "  x86_64-unknown-cosmo-cc: $(which x86_64-unknown-cosmo-cc)"
echo "  aarch64-unknown-cosmo-cc: $(which aarch64-unknown-cosmo-cc)"
echo "  apelink: $(which apelink)"
echo ""

# Clean and create build directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"/{x86_64,aarch64,source}

# Clone file repository once
echo "Cloning file repository..."
git clone --depth 1 --branch "${FILE_VERSION}" "${FILE_REPO}" "${BUILD_DIR}/source/file"

# Apply patches if they exist for this version
cd "${BUILD_DIR}/source/file"
PATCH_DIR="${PROJECT_ROOT}/patches/${FILE_VERSION}"
if [ -d "${PATCH_DIR}" ]; then
    echo ""
    echo "Applying patches for ${FILE_VERSION}..."
    for patch in "${PATCH_DIR}"/*.patch; do
        if [ -f "$patch" ]; then
            echo "  Applying $(basename "$patch")..."
            patch -p1 < "$patch"
        fi
    done
    echo "Patches applied successfully"
fi

# Run autoreconf once if needed
if [ ! -f configure ]; then
    echo ""
    echo "Running autoreconf..."
    autoreconf -f -i
fi

# Function to build for a specific architecture
build_for_arch() {
    local arch=$1
    local cc_name=$2
    local build_dir="${BUILD_DIR}/${arch}"

    echo ""
    echo "================================================"
    echo "Building for ${arch}"
    echo "================================================"

    # Copy source to arch-specific directory
    cp -r "${BUILD_DIR}/source/file" "${build_dir}/file"
    cd "${build_dir}/file"

    # Configure with arch-specific compiler
    echo "Configuring for ${arch}..."
    CC="${cc_name}" \
    CXX="${cc_name%cc}++" \
    ./configure \
        --prefix="/zip" \
        --disable-shared

    # Build
    echo "Compiling for ${arch}..."
    make -j$(nproc)

    # Verify binary was created
    if [ ! -f src/file ]; then
        echo "Error: src/file not found after ${arch} build"
        ls -la src/
        exit 1
    fi

    # Copy to arch-specific location
    cp src/file "${build_dir}/file.elf"
    echo "Built ${arch} binary: ${build_dir}/file.elf"
    ls -lh "${build_dir}/file.elf"
}

# Build for both architectures
build_for_arch "x86_64" "x86_64-unknown-cosmo-cc"
build_for_arch "aarch64" "aarch64-unknown-cosmo-cc"

# Link the two binaries into a fat binary using apelink
echo ""
echo "================================================"
echo "Creating fat binary with apelink"
echo "================================================"

mkdir -p "${OUTPUT_DIR}"

cosmo_bin=$(dirname $(which cosmocc))
apelink \
    -l ${cosmo_bin}/ape-x86_64.elf \
    -l ${cosmo_bin}/ape-aarch64.elf \
    -M ${cosmo_bin}/ape-m1.c \
    -o "${OUTPUT_BINARY}" \
    "${BUILD_DIR}/x86_64/file.elf" \
    "${BUILD_DIR}/aarch64/file.elf"

chmod +x "${OUTPUT_BINARY}"

# Embed magic.mgc file
cd "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/share/misc"
cp "${BUILD_DIR}/x86_64/file/magic/magic.mgc" "${BUILD_DIR}/share/misc"
zip -qr "${OUTPUT_BINARY}" share/misc

# Verify the fat binary
echo ""
echo "Verifying fat binary..."
file "${OUTPUT_BINARY}" || true
ls -lh "${OUTPUT_BINARY}"

echo ""
echo "Testing binary..."
"${OUTPUT_BINARY}" --version || true

# Copy LICENSE file
cp "${BUILD_DIR}/source/file/COPYING" "${OUTPUT_LICENSE}"
echo "Copied LICENSE to ${OUTPUT_LICENSE}"

echo ""
echo "================================================"
echo "Build complete!"
echo "================================================"
echo "Fat binary: ${OUTPUT_BINARY}"
echo "================================================"
