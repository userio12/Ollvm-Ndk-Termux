# OLLVM NDK for Termux Android

Complete toolkit for building Obfuscator-LLVM (OLLVM) integrated Android NDK, optimized for Termux devices.

![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Termux-green.svg)
![LLVM](https://img.shields.io/badge/LLVM-17%2F18-orange.svg)

---

## 📦 What is This?

This repository provides **automated GitHub Actions workflows** to build Android NDK with **OLLVM (Obfuscator-LLVM)** integration. You get pre-built toolchains that can obfuscate your native C/C++ code, making reverse engineering much harder.

**Key Features:**
- ✅ **4 Different Build Workflows** for various use cases
- ✅ **Supports NDK r27 & r28** (Latest versions)
- ✅ **Works on Termux** (ARM64 native builds available)
- ✅ **Zero Manual Setup** - Download and use immediately
- ✅ **Multiple OLLVM Passes** - Flattening, Substitution, Bogus CF, String Encryption

---

## 🚀 Quick Start

### Option 1: Use Pre-built Releases (Easiest)
1. Go to **[Releases](https://github.com/userio12/Ollvm-Ndk-Termux/releases)** page
2. Download the package for your platform
3. Extract and start using

### Option 2: Build Your Own (Custom Versions)
1. Go to **Actions** tab
2. Select a workflow (see table below)
3. Click **Run workflow** → Choose versions → Run
4. Wait for build to finish (2-6 hours)
5. Download artifact

---

## 📊 Workflow Comparison

| Workflow | What it Builds | Platform | Build Time | Difficulty | Best For |
|----------|---------------|----------|------------|------------|----------|
| **Build OLLVM NDK** | OLLVM Plugin Only | Linux x86_64 | ~2 hours | Easy | PC Development |
| **Build Latest NDK with OLLVM** | Full NDK + Plugin | Linux x86_64 | ~2-3 hours | Easy | **Recommended for most users** |
| **Build OLLVM on Termux (Proot)** | Plugin Only | ARM64 (Emulated) | ~4 hours | Medium | Termux Plugin Usage |
| **Build OLLVM NDK (aarch64 Native)** | Full NDK + Plugin | ARM64 (Emulated) | ~5-6 hours | Medium | **Native Termux Compilation** |

---

## 📋 Workflow Details

### 1️⃣ Build OLLVM NDK (Plugin Only)

**What you get:** Just the `libLLVMObfuscator.so` plugin file.

**Requirements:** You must download Android NDK separately and integrate manually.

**Available Versions:**
- LLVM 16.0.6
- LLVM 17.0.6 (Default)
- LLVM 18.1.0

**Usage:**
```bash
# Download plugin from workflow artifacts
tar -xzf ollvm-plugin-*.tar.gz

# Use with any clang
clang -fno-legacy-pass-manager \
  -fpass-plugin=/path/to/libLLVMObfuscator.so \
  -mllvm -fla \
  your_code.c -o your_code
```

**When to use:**
- ✅ You already have NDK installed
- ✅ You want to use OLLVM with custom LLVM versions
- ❌ You don't want to configure anything manually

---

### 2️⃣ Build Latest NDK with OLLVM (Recommended)

**What you get:** Complete Android NDK (r27 or r28) with OLLVM plugin pre-installed and wrapper script included.

**Available Versions:**
- **NDK r28** + LLVM 18.1.8 (Latest, Recommended)
- **NDK r27** + LLVM 17.0.6

**Package Contents:**
```
ollvm-ndk-28.0.12433566-linux-x86_64/
├── toolchains/llvm/prebuilt/linux-x86_64/
│   ├── bin/clang              # Standard clang
│   ├── bin/clang++            # Standard clang++
│   └── lib/libLLVMObfuscator.so  # OLLVM plugin
├── ollvm-clang.sh             # Wrapper script (auto-enables OLLVM)
└── README-OLLVM.md            # Usage guide
```

**Usage:**
```bash
# Extract the package
tar -xzf ollvm-ndk-*.tar.gz
cd ollvm-ndk-*/

# Method 1: Use wrapper (OLLVM enabled by default)
export PATH=$(pwd):$PATH
./ollvm-clang.sh -mllvm -fla -mllvm -sub your_code.c -o your_code

# Method 2: Use clang directly
clang -fpass-plugin=lib/libLLVMObuscator.so \
  -mllvm -fla \
  your_code.c -o your_code

# Method 3: Disable OLLVM temporarily
OLLVM_DISABLED=1 clang your_code.c -o your_code
```

**CMake Integration:**
In your `app/build.gradle.kts`:
```kotlin
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                arguments += listOf(
                    "-DANDROID_CCACHE=/path/to/ollvm-clang.sh"
                )
            }
        }
    }
}
```

**When to use:**
- ✅ You want everything pre-configured
- ✅ Building Android apps with native code
- ✅ You need latest Android features (16KB pages, etc.)
- ✅ **This is what most people want**

---

### 3️⃣ Build OLLVM on Termux (Proot)

**What you get:** OLLVM plugin compiled for ARM64 processors.

**Important:** This workflow runs in an ARM64 container (emulated), which is slow but produces a native ARM64 binary.

**Usage on Termux:**
```bash
# Download and extract on your Termux device
tar -xzf ollvm-termux-*.tar.gz
cd ollvm-termux-*

export OLLVM_PLUGIN=$(pwd)/libLLVMObfuscator.so

# Use with Termux clang
clang -fno-legacy-pass-manager \
  -fpass-plugin=$OLLVM_PLUGIN \
  -mllvm -fla \
  your_code.c -o your_code
```

**Requirements on Termux:**
```bash
# Install proot-distro
pkg install proot-distro
proot-distro install ubuntu

# Or install dependencies natively
pkg install clang cmake make
```

**When to use:**
- ✅ You want to compile directly on your phone
- ✅ You don't have access to a PC
- ✅ You need ARM64-optimized binaries

---

### 4️⃣ Build OLLVM NDK (aarch64 Native)

**What you get:** Complete NDK toolchain that runs **natively on ARM64 devices** (like the popular r25c releases).

**This is similar to:** [codehasan/dex2c OLLVM NDK](https://github.com/codehasan/dex2c/releases)

**Package Structure:**
```
android-ndk-ollvm-aarch64/
├── toolchains/llvm/prebuilt/linux-aarch64/
│   ├── bin/clang
│   ├── bin/clang++
│   └── lib/libLLVMObfuscator.so
├── sysroot/                      # Android sysroots (API 21-35)
├── build/                        # CMake build scripts
└── ollvm-clang                   # Convenience wrapper
```

**Usage on Termux:**
```bash
# Extract to home directory
tar -xJf android-ndk-ollvm-aarch64.tar.xz -C $HOME

# Add to PATH
export PATH=$HOME/android-ndk-ollvm-aarch64:$PATH

# Compile (OLLVM enabled automatically via wrapper)
ollvm-clang -mllvm -fla -mllvm -sub test.c -o test

# Or use clang directly
clang -fpass-plugin=$HOME/android-ndk-ollvm-aarch64/toolchains/llvm/prebuilt/linux-aarch64/lib/libLLVMObfuscator.so \
  -mllvm -fla \
  test.c -o test
```

**When to use:**
- ✅ You want the **fastest compilation on device** (native ARM64)
- ✅ You work primarily in Termux
- ✅ You want a standalone NDK that doesn't need proot
- ✅ **Best for heavy development on phone**

---

## 🛡️ Available OLLVM Passes

| Pass | Flag | Effect | Performance Cost |
|------|------|--------|------------------|
| **Control Flow Flattening** | `-mllvm -fla` | Makes control flow graphs flat and complex | Medium (15-30%) |
| **Bogus Control Flow** | `-mllvm -bcf` | Adds fake branches and dead code | Low (5-15%) |
| **Instruction Substitution** | `-mllvm -sub` | Replaces simple instructions with complex equivalents | Low (5-10%) |
| **Basic Block Split** | `-mllvm -split` | Splits basic blocks to increase CFG complexity | Very Low (1-5%) |
| **String Encryption** | `-mllvm -sobf` | Encrypts string literals in binary | Low (3-8%) |

### 🎯 Recommended Combinations

**Maximum Protection:**
```bash
-mllvm -fla -mllvm -bcf -mllvm -sub -mllvm -sobf
```

**Balanced (Recommended):**
```bash
-mllvm -fla -mllvm -sub
```

**Performance-Focused:**
```bash
-mllvm -bcf -mllvm -split
```

---

## 📖 Complete Usage Examples

### Example 1: Protect a Password Check Function

```c
// password.c
#include <stdio.h>
#include <string.h>

int verify_password(const char* input) {
    const char* secret = "MySecretPass123";
    return strcmp(input, secret) == 0;
}

int main() {
    char input[100];
    printf("Enter password: ");
    scanf("%s", input);
    
    if (verify_password(input)) {
        printf("Access granted!\n");
    } else {
        printf("Access denied!\n");
    }
    return 0;
}
```

**Compile with OLLVM:**
```bash
# Using the aarch64 NDK
ollvm-clang -mllvm -fla -mllvm -sobf password.c -o password_protected

# The resulting binary will have:
# - Flattened control flow in verify_password()
# - Encrypted string "MySecretPass123"
# - Much harder to reverse engineer!
```

### Example 2: CMake Project Integration

**CMakeLists.txt:**
```cmake
cmake_minimum_required(VERSION 3.22)
project(MyApp)

add_library(my_lib SHARED src/native-lib.cpp)

# OLLVM flags (optional - can also use wrapper)
if(OLLVM_ENABLED)
    target_compile_options(my_lib PRIVATE
        -fno-legacy-pass-manager
        -fpass-plugin=${OLLVM_PLUGIN_PATH}
        -mllvm -fla
        -mllvm -sub
    )
endif()
```

**Build:**
```bash
cmake -B build \
  -DCMAKE_TOOLCHAIN_FILE=/path/to/ndk/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-33 \
  -DOLLVM_ENABLED=ON \
  -DOLLVM_PLUGIN_PATH=/path/to/libLLVMObfuscator.so

cmake --build build
```

### Example 3: Android Studio Integration

**app/build.gradle.kts:**
```kotlin
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                // Point to our OLLVM wrapper
                arguments += listOf(
                    "-DANDROID_CCACHE=${file("../../ollvm-ndk/ollvm-clang.sh")}",
                    "-DOLLVM_ENABLED=true"
                )
            }
        }
    }
    
    buildTypes {
        release {
            // Only obfuscate release builds
            externalNativeBuild {
                cmake {
                    arguments += "-DOLLVM_PASSES=-fla;-sub;-sobf"
                }
            }
        }
    }
}
```

---

## 📱 Termux-Specific Guide

### Prerequisites
```bash
# Update packages
pkg update && pkg upgrade

# Install required tools
pkg install clang cmake make git wget tar

# (Optional) Install proot-distro for Ubuntu environment
pkg install proot-distro
proot-distro install ubuntu
```

### Using Pre-built NDK on Termux

**For aarch64 Native builds:**
```bash
# 1. Download from Releases or workflow artifacts
wget https://github.com/userio12/Ollvm-Ndk-Termux/releases/download/v1.0/android-ndk-ollvm-aarch64.tar.xz

# 2. Extract
tar -xJf android-ndk-ollvm-aarch64.tar.xz -C $HOME

# 3. Setup environment
cat >> ~/.bashrc << 'EOF'
export ANDROID_NDK_HOME=$HOME/android-ndk-ollvm-aarch64
export PATH=$ANDROID_NDK_HOME:$PATH
EOF
source ~/.bashrc

# 4. Test it
ollvm-clang --version
```

### Building Natively in Termux (Advanced)

If you want to build OLLVM directly on your device (no workflow needed):

```bash
# Install dependencies
pkg install cmake ninja clang python make

# Clone LLVM
git clone --depth 1 --branch llvmorg-17.0.6 https://github.com/llvm/llvm-project.git
cd llvm-project

# Build LLVM (takes 3-6 hours on phone)
mkdir build && cd build
cmake ../llvm \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS='clang' \
  -DLLVM_TARGETS_TO_BUILD='AArch64' \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DLLVM_ENABLE_TERMINFO=OFF

ninja -j$(nproc)  # or -j4 if low on RAM
ninja install

# Build OLLVM plugin
cd ~
git clone https://github.com/eshard/obfuscator-llvm.git
cd obfuscator-llvm
mkdir build && cd build

cmake -G Ninja \
  -DLLVM_DIR=$PREFIX/lib/cmake/llvm \
  -DCMAKE_BUILD_TYPE=Release \
  ..

ninja

# Plugin is ready!
ls -lh libLLVMObfuscator.so
```

---

## 🛠️ Troubleshooting

### Build Fails with "Out of Memory"
**Solution:** Reduce parallel jobs
```bash
# In workflow: Edit timeout or add to cmake
ninja -j2  # Instead of -j$(nproc)
```

### "Plugin Not Found" Error
**Solution:** Use absolute path
```bash
# Wrong
clang -fpass-plugin=libLLVMObfuscator.so ...

# Correct
clang -fpass-plugin=/full/path/to/libLLVMObfuscator.so ...
```

### Workflow Takes Too Long
**Cause:** ARM64 emulation on GitHub runners is slow.

**Solution:** Use **Build Latest NDK with OLLVM** instead (runs on fast x86_64 servers, works with `proot` on Termux).

### CMake Can't Find LLVM
**Solution:** Set LLVM_DIR explicitly
```bash
cmake -DLLVM_DIR=/opt/llvm-17/lib/cmake/llvm ...
```

### Pass Not Applied
**Checklist:**
1. ✅ Use `-fno-legacy-pass-manager` (required for LLVM 14+)
2. ✅ Use `-fpass-plugin=` with full path to `.so` file
3. ✅ Verify plugin loads: `clang -fpass-plugin=plugin.so -Xclang -verify-passes`
4. ✅ Don't mix `-mllvm` flags with `-fpass-plugin` (use one or the other)

### Binary Crashes at Runtime
**Possible causes:**
- String encryption pass applied incorrectly
- Architecture mismatch
- Missing dependencies

**Debug:**
```bash
# Check binary architecture
file your_binary

# Run with debug info
export LLVM_OBF_DEBUG_SEED=y
your_binary
```

---

## 📁 Repository Structure

```
Ollvm-Ndk-Termux/
├── .github/workflows/
│   ├── build-ollvm.yml                 # Plugin-only build (x86_64)
│   ├── build-ndk-patched.yml           # Full NDK + OLLVM (x86_64)
│   ├── build-termux-proot.yml          # Plugin for Termux (ARM64)
│   └── build-ollvm-ndk-aarch64.yml     # Full NDK for Termux (ARM64 Native)
├── scripts/
│   ├── build-ollvm-termux.sh           # Local Termux build script
│   └── ollvm-wrapper.sh                # Wrapper for auto-obfuscation
├── README.md                           # This file
└── WORKFLOWS.md                        # Detailed workflow guide
```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

**Areas we need help with:**
- [ ] Support for newer LLVM versions (19+)
- [ ] Additional OLLVM passes
- [ ] Better error messages in wrapper scripts
- [ ] iOS toolchain support
- [ ] Documentation improvements

---

## 📄 License

- **OLLVM Original:** Apache License 2.0 with LLVM Exceptions
- **Workflows & Scripts:** MIT License
- **Android NDK:** Apache License 2.0 (Google)

See [LLVM License](https://llvm.org/LICENSE.txt) for details.

---

## 🔗 Useful Links

- **[OLLVM Original Project](https://github.com/obfuscator-llvm/obfuscator)**
- **[Modern OLLVM Fork](https://github.com/eshard/obfuscator-llvm)**
- **[O-MVLL (Alternative)](https://github.com/open-obfuscator/o-mvll)**
- **[Android NDK Official](https://developer.android.com/ndk)**
- **[Termux Official](https://termux.dev/)**
- **[LLVM Pass Documentation](https://llvm.org/docs/WritingAnLLVMPass.html)**

---

## ⚠️ Disclaimer

This toolkit is intended for:
- ✅ Protecting your own code from reverse engineering
- ✅ Educational and research purposes
- ✅ Securing proprietary algorithms

**NOT for:**
- ❌ Malicious purposes
- ❌ Circumventing security measures
- ❌ Violating any software licenses or laws

**Use responsibly and ethically.**

---

## 📧 Support

- **Issues:** Open a [GitHub Issue](https://github.com/userio12/Ollvm-Ndk-Termux/issues)
- **Discussions:** Use [GitHub Discussions](https://github.com/userio12/Ollvm-Ndk-Termux/discussions)

---

**Made with ❤️ for the Android security community**
