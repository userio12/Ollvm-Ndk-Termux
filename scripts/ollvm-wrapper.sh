#!/bin/bash

# OLLVM Wrapper for Android NDK
# Use this script with ANDROID_CCACHE to automatically apply OLLVM passes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLLVM_PLUGIN="${OLLVM_PLUGIN:-$SCRIPT_DIR/libLLVMObfuscator.so}"

# Check if OLLVM is disabled
if [ "$OLLVM_DISABLED" = "1" ]; then
    exec clang "$@"
fi

# Parse arguments
ARGS=()
IS_COMPILE=false
OUTPUT_FILE=""
SOURCE_FILES=()
TARGET=""
SYSROOT=""

for arg in "$@"; do
    case "$arg" in
        -c)
            IS_COMPILE=true
            ARGS+=("$arg")
            ;;
        -o)
            ARGS+=("$arg")
            # Next arg is output file
            read -r next_arg
            OUTPUT_FILE="$next_arg"
            ARGS+=("$next_arg")
            ;;
        --target=*)
            TARGET="$arg"
            ARGS+=("$arg")
            ;;
        --sysroot=*)
            SYSROOT="$arg"
            ARGS+=("$arg")
            ;;
        *.c|*.cc|*.cpp|*.cxx|*.C)
            SOURCE_FILES+=("$arg")
            ARGS+=("$arg")
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
done

# If this is a compilation command and we have source files
if [ "$IS_COMPILE" = true ] && [ ${#SOURCE_FILES[@]} -gt 0 ]; then
    for src in "${SOURCE_FILES[@]}"; do
        if [ ! -f "$src" ]; then
            # File doesn't exist, pass through to normal clang
            exec clang "$@"
        fi
    done
    
    # Determine output file
    if [ -z "$OUTPUT_FILE" ]; then
        if [ "$IS_COMPILE" = true ]; then
            # Generate .o file name from first source
            OUTPUT_FILE="${SOURCE_FILES[0]%.c}.o"
            OUTPUT_FILE="${OUTPUT_FILE%.cpp}.o"
            OUTPUT_FILE="${OUTPUT_FILE%.cc}.o"
            ARGS+=("-o" "$OUTPUT_FILE")
        else
            OUTPUT_FILE="a.out"
        fi
    fi
    
    # Create temporary files
    TEMP_DIR=$(mktemp -d)
    LLVM_IR="$TEMP_DIR/output.ll"
    OBF_LLVM_IR="$TEMP_DIR/output-obf.ll"
    
    echo "[OLLVM] Compiling: ${SOURCE_FILES[*]}"
    
    # Stage 1: Generate LLVM IR
    echo "[OLLVM] Stage 1: Generating LLVM IR..."
    clang -emit-llvm -S "${ARGS[@]}" -o "$LLVM_IR" || {
        echo "[OLLVM] Failed to generate IR, falling back to normal compilation"
        exec clang "$@"
    }
    
    # Stage 2: Apply OLLVM passes using environment variables
    echo "[OLLVM] Stage 2: Applying obfuscation passes..."
    if command -v opt &> /dev/null; then
        opt -load-pass-plugin="$OLLVM_PLUGIN" \
            -passes="${OLLVM_PASSES:-flattening,bogus,substitution}" \
            "$LLVM_IR" \
            -o "$OBF_LLVM_IR" || {
            echo "[OLLVM] Warning: Failed to apply passes, using original IR"
            cp "$LLVM_IR" "$OBF_LLVM_IR"
        }
    else
        echo "[OLLVM] Warning: opt not found, skipping pass application"
        cp "$LLVM_IR" "$OBF_LLVM_IR"
    fi
    
    # Stage 3: Compile obfuscated IR to object
    echo "[OLLVM] Stage 3: Compiling to object file..."
    clang -c "$OBF_LLVM_IR" -o "$OUTPUT_FILE" $TARGET $SYSROOT || {
        echo "[OLLVM] Failed to compile IR, falling back to normal compilation"
        exec clang "$@"
    }
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    echo "[OLLVM] ✓ Compiled with obfuscation: $OUTPUT_FILE"
else
    # Not a compilation command, pass through
    exec clang "$@"
fi
