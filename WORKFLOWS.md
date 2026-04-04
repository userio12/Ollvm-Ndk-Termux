# Build OLLVM NDK for Termux

This repository contains GitHub Actions workflows to automatically build OLLVM (Obfuscator-LLVM) for Android NDK, optimized for use on Termux devices.

## 🚀 Getting Started

### Option 1: Use Pre-built Releases (Easiest)
1. Go to the **Releases** page
2. Download the latest OLLVM plugin for your architecture
3. Extract and use with your NDK clang

### Option 2: Build via GitHub Actions
1. Go to **Actions** tab
2. Select a workflow:
   - **Build OLLVM NDK for Termux** - Builds OLLVM plugin for multiple LLVM versions
   - **Build OLLVM on Termux (Proot)** - Builds in ARM64 container (simulates Termux)
   - **Build Latest NDK with OLLVM** - Creates full patched NDK toolchain
3. Click **Run workflow**
4. Choose versions and click **Run workflow**
5. Download artifacts from the workflow run

### Option 3: Build Locally on Termux
```bash
# Clone this repository
git clone <your-repo-url>
cd Ollvm-Ndk-Termux

# Run the build script in Termux
chmod +x scripts/build-ollvm-termux.sh
./scripts/build-ollvm-termux.sh 17.0.6
```

## 📦 Workflows

### 1. build-ollvm.yml
**Purpose**: Build OLLVM plugin for multiple LLVM versions  
**Triggers**: Push, PR, manual dispatch  
**Outputs**: `libLLVMObfuscator.so` for LLVM 16, 17, 18  
**Runtime**: ~2-3 hours

**Manual Trigger**:
```yaml
workflow_dispatch:
  inputs:
    llvm_version: '17.0.6'
    ndk_version: 'r27'
    build_type: 'Release'
```

### 2. build-termux-proot.yml
**Purpose**: Build OLLVM in ARM64 container (Termux-like environment)  
**Triggers**: Manual dispatch  
**Outputs**: aarch64-optimized plugin  
**Runtime**: ~3-5 hours

### 3. build-ndk-patched.yml
**Purpose**: Create full NDK with integrated OLLVM  
**Triggers**: Weekly schedule, manual dispatch  
**Outputs**: Complete patched NDK toolchain  
**Runtime**: ~6-8 hours

## 📱 Usage on Termux

### After downloading the plugin:

```bash
# Extract plugin
tar -xzf ollvm-*.tar.gz
cd ollvm-*

# Set plugin path
export OLLVM_PLUGIN=$(pwd)/libLLVMObfuscator.so

# Compile your code with obfuscation
clang -fno-legacy-pass-manager \
  -fpass-plugin=$OLLVM_PLUGIN \
  -mllvm -fla \
  -mllvm -sub \
  your_code.c -o your_code
```

### Using the wrapper script:

```bash
# Make wrapper executable
chmod +x scripts/ollvm-wrapper.sh

# Set as wrapper
export OLLVM_PLUGIN=/path/to/libLLVMObfuscator.so

# Use wrapper for automatic obfuscation
./scripts/ollvm-wrapper.sh -c your_code.c -o your_code.o
```

### CMake integration:

```bash
cmake -DCMAKE_C_COMPILER=clang \
  -DCMAKE_C_FLAGS="-fpass-plugin=/path/to/libLLVMObfuscator.so -mllvm -fla" \
  .
```

## 🛠️ OLLVM Passes

| Pass | Flag | Effect | Performance Impact |
|------|------|--------|-------------------|
| Flattening | `-mllvm -fla` | Control flow flattening | Medium |
| Bogus CF | `-mllvm -boguscf` | Fake branches | Low-Medium |
| Substitution | `-mllvm -sub` | Complex instruction replacement | Low |
| Split Blocks | `-mllvm -split` | More basic blocks | Very Low |
| String Encrypt | `-mllvm -sobf` | Encrypt strings | Low |

**Recommended combination for strong protection**:
```bash
-mllvm -fla -mllvm -sub -mllvm -sobf
```

**Recommended for performance-critical code**:
```bash
-mllvm -boguscf -mllvm -split
```

## ⚙️ Advanced Configuration

### Using environment variables for automatic pass injection:

```bash
# These passes will auto-inject at specific optimization stages
export LLVM_OBF_SCALAROPTIMIZERLATE_PASSES="flattening,bogus,substitution"
export LLVM_OBF_OPTIMIZERLASTEP_PASSES="string-encryption"

# Compile normally - passes inject automatically
clang your_code.c -o your_code
```

### Custom pass configuration:

```bash
# Create a passes.json file
cat > passes.json << 'EOF'
{
  "passes": [
    "flattening",
    "substitution",
    "split-basic-blocks"
  ],
  "string_encryption": true,
  "seed": "random"
}
EOF

# Use custom configuration
export LLVM_OBF_CONFIG=$(pwd)/passes.json
```

## 🔧 Troubleshooting

### Workflow fails with timeout
- LLVM builds take 2-8 hours depending on runner
- Try reducing LLVM version (16.x faster than 18.x)
- Use self-hosted runner for faster builds

### Plugin not loading
```bash
# Check if plugin is compatible
file libLLVMObfuscator.so

# Verify LLVM version matches
clang --version
```

### Out of memory in Termux
```bash
# Add swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### CMake can't find LLVM
```bash
# Set LLVM_DIR explicitly
cmake -DLLVM_DIR=/opt/llvm/lib/cmake/llvm ..
```

## 📊 Build Matrix

The workflows build the following combinations:

| LLVM Version | NDK Version | Architecture | Status |
|--------------|-------------|--------------|--------|
| 16.0.6 | r26 | x86_64, aarch64 | ✅ |
| 17.0.6 | r27 | x86_64, aarch64 | ✅ |
| 18.1.0 | r28 | x86_64, aarch64 | ✅ |

## 📝 Repository Structure

```
Ollvm-Ndk-Termux/
├── .github/workflows/
│   ├── build-ollvm.yml          # Main OLLVM plugin build
│   ├── build-termux-proot.yml   # Termux proot build
│   └── build-ndk-patched.yml    # Full NDK build
├── scripts/
│   ├── build-ollvm-termux.sh    # Local Termux build script
│   └── ollvm-wrapper.sh         # NDK wrapper script
├── README.md                    # This file
└── WORKFLOWS.md                 # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally or via workflow
5. Submit a pull request

## 📄 License

- OLLVM: Apache License 2.0 with LLVM Exceptions
- Scripts and Workflows: MIT License

## 🔗 Links

- [OLLVM Original](https://github.com/obfuscator-llvm/obfuscator)
- [Modern OLLVM Fork](https://github.com/eshard/obfuscator-llvm)
- [O-MVLL (Alternative)](https://github.com/open-obfuscator/o-mvll)
- [Android NDK](https://developer.android.com/ndk)
- [Termux](https://termux.dev/)
