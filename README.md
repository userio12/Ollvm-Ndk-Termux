# OLLVM NDK for Termux Android

Pre-built OLLVM (Obfuscator-LLVM) toolchain for Android NDK, optimized for Termux usage.

## 📦 Quick Start

### For Termux Users

1. **Download** the latest release for your architecture (aarch64 recommended)
2. **Extract** to your desired location:
   ```bash
   tar -xzf ollvm-termux-*.tar.gz -C $HOME
   ```

3. **Setup** in Termux:
   ```bash
   # Install dependencies
   pkg install proot-distro git cmake clang
   
   # Setup proot environment
   proot-distro install ubuntu
   ```

4. **Use** with your code:
   ```bash
   export OLLVM_PLUGIN=$HOME/ollvm-termux/libLLVMObfuscator.so
   clang -fno-legacy-pass-manager \
     -fpass-plugin=$OLLVM_PLUGIN \
     -mllvm -fla \
     -mllvm -sub \
     your_code.c -o your_code
   ```

## 🛠️ Available OLLVM Passes

| Pass | Flag | Description |
|------|------|-------------|
| **Flattening** | `-mllvm -fla` | Control flow flattening - makes code logic harder to follow |
| **Bogus Control Flow** | `-mllvm -boguscf` | Insert fake control flow branches |
| **Substitution** | `-mllvm -sub` | Replace instructions with equivalent complex ones |
| **Split Basic Blocks** | `-mllvm -split` | Split basic blocks to increase complexity |
| **String Encryption** | `-mllvm -sobf` | Encrypt string literals in binary |

## 📋 Usage Examples

### Basic Compilation
```bash
clang -fpass-plugin=libLLVMObfuscator.so \
  -mllvm -fla \
  hello.c -o hello
```

### Multiple Passes
```bash
clang -fno-legacy-pass-manager \
  -fpass-plugin=libLLVMObfuscator.so \
  -mllvm -fla \
  -mllvm -sub \
  -mllvm -sobf \
  secure_app.c -o secure_app
```

### CMake Integration
```bash
cmake -DCMAKE_C_COMPILER=clang \
  -DCMAKE_C_FLAGS="-fpass-plugin=/path/to/libLLVMObfuscator.so -mllvm -fla" \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_CXX_FLAGS="-fpass-plugin=/path/to/libLLVMObfuscator.so -mllvm -fla" \
  .
```

### Android NDK Usage
```bash
# Using with NDK clang
$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/clang \
  --target=aarch64-none-linux-android33 \
  -fno-legacy-pass-manager \
  -fpass-plugin=libLLVMObfuscator.so \
  -mllvm -fla \
  native-lib.c -o native-lib.so
```

### Gradle Integration
In `app/build.gradle.kts`:
```kotlin
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                arguments += listOf(
                    "-DANDROID_CCACHE=${file("ollvm-wrapper.sh").absolutePath}"
                )
            }
        }
    }
}
```

## 🏗️ GitHub Actions

This repository includes automated workflows:

### Build OLLVM Plugin
- Triggers: Push to main, PRs, or manual dispatch
- Builds: LLVM 16, 17, 18 with OLLVM
- Output: Ready-to-use plugin binaries

### Build Patched NDK
- Triggers: Weekly schedule or manual dispatch
- Creates: Full NDK with integrated OLLVM
- Includes: Wrapper scripts for easy usage

### Termux Proot Build
- Runs in ARM64 container (simulates Termux)
- Optimized for aarch64 Termux devices

## 🔧 Building from Source

### Prerequisites
- Ubuntu/Debian Linux (or Termux with proot)
- 8GB+ RAM
- 15GB+ free disk space
- Build dependencies: `build-essential cmake ninja-build python3 git`

### Build LLVM
```bash
git clone --depth 1 --branch llvmorg-17.0.6 https://github.com/llvm/llvm-project.git
cd llvm-project
mkdir build && cd build

cmake ../llvm \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS='clang' \
  -DLLVM_TARGETS_TO_BUILD='AArch64;ARM' \
  -DCMAKE_INSTALL_PREFIX=/opt/llvm \
  -DLLVM_ENABLE_TERMINFO=OFF

ninja -j$(nproc)
ninja install
```

### Build OLLVM Plugin
```bash
git clone https://github.com/eshard/obfuscator-llvm.git
cd obfuscator-llvm
mkdir build && cd build

cmake -G Ninja \
  -DLLVM_DIR=/opt/llvm/lib/cmake/llvm \
  -DCMAKE_BUILD_TYPE=Release \
  ..

ninja
```

## 📱 Termux-Specific Setup

### Method 1: Using Pre-built Plugin
```bash
# In Termux
pkg install proot-distro
proot-distro install ubuntu
proot-distro login ubuntu

# Inside proot
apt install clang cmake make
# Use the downloaded plugin
```

### Method 2: Build Natively in Termux (Advanced)
```bash
# Install dependencies
pkg install cmake ninja clang python make

# Set swap space (needed for large builds)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Build following source instructions above
```

## ⚠️ Important Notes

1. **Memory Requirements**: Building LLVM requires 4-8GB RAM
2. **Storage**: Full build needs 15-20GB free space
3. **Time**: Expect 2-6 hours for full LLVM build on most devices
4. **Proot Recommended**: Use `proot-distro` for better compatibility
5. **NDK Version Matching**: 
   - NDK r27 → LLVM 17
   - NDK r28 → LLVM 18

## 🐛 Troubleshooting

### Build Fails with "out of memory"
- Enable zram/swap
- Reduce parallel jobs: `ninja -j2` instead of `ninja -j$(nproc)`

### Plugin Not Found at Runtime
- Use absolute path to `libLLVMObfuscator.so`
- Check file exists: `ls -lh libLLVMObfuscator.so`

### CMake Can't Find LLVM
- Set `LLVM_DIR` explicitly: `-DLLVM_DIR=/opt/llvm/lib/cmake/llvm`

### Pass Not Applied
- Ensure you use `-fno-legacy-pass-manager` for LLVM 14+
- Verify plugin loads: `clang -fpass-plugin=plugin.so -Xclang -verify-passes`

## 📚 Resources

- [OLLVM Original Project](https://github.com/obfuscator-llvm/obfuscator)
- [Modern OLLVM Fork](https://github.com/eshard/obfuscator-llvm)
- [Android NDK](https://developer.android.com/ndk)
- [Termux](https://termux.dev/)
- [LLVM Pass Documentation](https://llvm.org/docs/WritingAnLLVMPass.html)

## 📄 License

OLLVM is distributed under the Apache License 2.0 with LLVM Exceptions.
See the [LLVM License](https://llvm.org/LICENSE.txt) for details.

## 🤝 Contributing

Contributions welcome! Please open issues or submit PRs for:
- Bug fixes
- Support for newer LLVM versions
- Additional obfuscation passes
- Termux-specific optimizations
