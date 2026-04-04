#!/data/data/com.termux/files/usr/bin/bash

# OLLVM Build Script for Termux
# This script builds LLVM + OLLVM plugin natively in Termux (with proot)

set -e

# Configuration
LLVM_VERSION="${1:-17.0.6}"
BUILD_DIR="${HOME}/ollvm-build"
INSTALL_DIR="${PREFIX}/opt/llvm-ollvm"
JOBS=$(nproc)

echo "========================================="
echo "OLLVM Builder for Termux"
echo "LLVM Version: $LLVM_VERSION"
echo "Build Directory: $BUILD_DIR"
echo "Install Directory: $INSTALL_DIR"
echo "Parallel Jobs: $JOBS"
echo "========================================="

# Check if proot-distro is installed
if ! command -v proot-distro &> /dev/null; then
    echo "❌ proot-distro not found. Installing..."
    pkg install -y proot-distro
    proot-distro install ubuntu
fi

# Check available space
AVAILABLE_SPACE=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 15 ]; then
    echo "⚠️  Warning: Only ${AVAILABLE_SPACE}GB available. You need at least 15GB."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo ""
echo "📦 Step 1: Entering proot environment..."
proot-distro login ubuntu -- \
    bash -c "
        set -e
        
        echo 'Updating package lists...'
        apt update && apt upgrade -y
        
        echo 'Installing build dependencies...'
        apt install -y build-essential cmake ninja-build python3 git wget xz-utils
        
        echo 'Cloning LLVM project...'
        cd /root
        if [ ! -d 'llvm-project' ]; then
            git clone --depth 1 --branch llvmorg-$LLVM_VERSION https://github.com/llvm/llvm-project.git
        fi
        
        cd llvm-project
        mkdir -p build && cd build
        
        echo 'Configuring LLVM build...'
        cmake ../llvm \
            -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DLLVM_ENABLE_PROJECTS='clang' \
            -DLLVM_TARGETS_TO_BUILD='AArch64;ARM' \
            -DCMAKE_INSTALL_PREFIX=/opt/llvm-$LLVM_VERSION \
            -DLLVM_ENABLE_TERMINFO=OFF \
            -DLLVM_ENABLE_ZLIB=OFF
        
        echo 'Building LLVM... This will take 2-6 hours depending on your device.'
        echo 'Starting build at: ' \$(date)
        ninja -j$JOBS || ninja -j2
        
        echo 'Installing LLVM...'
        ninja install
        
        echo 'Cloning OLLVM...'
        cd /root
        if [ ! -d 'obfuscator-llvm' ]; then
            git clone https://github.com/eshard/obfuscator-llvm.git
        fi
        
        cd obfuscator-llvm
        mkdir -p build && cd build
        
        echo 'Configuring OLLVM plugin...'
        cmake -G Ninja \
            -DLLVM_DIR=/opt/llvm-$LLVM_VERSION/lib/cmake/llvm \
            -DCMAKE_BUILD_TYPE=Release \
            ..
        
        echo 'Building OLLVM plugin...'
        ninja -j$JOBS || ninja -j2
        
        echo 'Verifying plugin...'
        if [ -f 'libLLVMObfuscator.so' ]; then
            echo '✅ OLLVM plugin built successfully!'
            ls -lh libLLVMObfuscator.so
            file libLLVMObfuscator.so
        else
            echo '❌ Build failed: libLLVMObfuscator.so not found'
            exit 1
        fi
        
        echo 'Creating package...'
        cd /root
        mkdir -p ollvm-termux-$LLVM_VERSION
        cp obfuscator-llvm/build/libLLVMObfuscator.so ollvm-termux-$LLVM_VERSION/
        
        cat > ollvm-termux-$LLVM_VERSION/README.md << 'README_EOF'
# OLLVM Plugin for Termux

## Usage
\`\`\`bash
export OLLVM_PLUGIN=\$HOME/ollvm-termux/libLLVMObfuscator.so
clang -fno-legacy-pass-manager \\
  -fpass-plugin=\$OLLVM_PLUGIN \\
  -mllvm -fla \\
  your_code.c -o your_code
\`\`\`

## Available Passes
- flattening (-fla): Control flow flattening
- bogus (-boguscf): Bogus control flow
- substitution (-sub): Instruction substitution
- split-basic-blocks (-split): Basic block splitting
- string-encryption (-sobf): String encryption
README_EOF
        
        tar -czf ollvm-termux-$LLVM_VERSION-aarch64.tar.gz \
            ollvm-termux-$LLVM_VERSION
        
        echo ''
        echo '========================================='
        echo '✅ Build Complete!'
        echo 'Package: /root/ollvm-termux-$LLVM_VERSION-aarch64.tar.gz'
        echo '========================================='
        
        cp /root/ollvm-termux-$LLVM_VERSION-aarch64.tar.gz /sdcard/Download/ 2>/dev/null || true
    "

echo ""
echo "📦 Package saved to: $BUILD_DIR"
ls -lh "$BUILD_DIR"/*.tar.gz 2>/dev/null || echo "No packages found (check proot output above)"
echo ""
echo "To use the plugin:"
echo "  tar -xzf ollvm-termux-$LLVM_VERSION-aarch64.tar.gz"
echo "  cd ollvm-termux-$LLVM_VERSION"
echo "  clang -fpass-plugin=\$(pwd)/libLLVMObfuscator.so -mllvm -fla test.c -o test"
