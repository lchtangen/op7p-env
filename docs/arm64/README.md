# docs/arm64/ — ARM64 / aarch64 Platform

ARM64 development, toolchains, cross-compilation, and platform notes for SM8150.

---

## Documents

| File | Description |
|------|-------------|
| `README.md` | This file — toolchain overview, compiler flags, cross-compile |
| `sm8150-hardware.md` | Full SM8150 hardware reference: sysfs paths, governors, power management |

---

## Compiler Flags (SM8150 / Cortex-A76 class)

### GCC / Clang ARM64 flags for Snapdragon 855

```bash
# Optimal for Kryo 485 (ARM Cortex-A76 derivative)
CFLAGS="-O2 -march=armv8.2-a+crypto+simd -mtune=cortex-a76 -pipe"
CXXFLAGS="$CFLAGS"

# For maximum performance (FP, SIMD, crypto extensions)
CFLAGS="-O3 -march=armv8.2-a+aes+sha2+sha3+sm4+dotprod+fp16 -mtune=cortex-a76"

# LLVM/Clang (same flags work)
clang --target=aarch64-linux-gnu -march=armv8.2-a+crypto
```

### Go (already native ARM64)

```bash
export GOARCH=aarch64        # not needed — already native
go build -ldflags="-s -w" ./...   # strip debug info for smaller binary
```

### Rust (native ARM64)

```bash
rustup target add aarch64-unknown-linux-gnu
cargo build --release --target aarch64-unknown-linux-gnu
```

### Python (native, no cross-compile needed)

```bash
uname -m     # aarch64 — Python runs natively
```

---

## Cross-Compilation (from x86_64 host to ARM64 target)

```bash
# Install cross toolchain on x86_64 host:
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Cross-compile C:
aarch64-linux-gnu-gcc -march=armv8.2-a -o mybin-arm64 main.c

# Cross-compile Go:
GOOS=linux GOARCH=arm64 go build -o mybin-arm64 ./cmd/myapp

# Cross-compile Rust:
cargo build --release --target aarch64-unknown-linux-gnu
# Binary: target/aarch64-unknown-linux-gnu/release/mybin
```

---

## Docker Multi-Arch Builds

```bash
# Build ARM64 image from any architecture:
docker buildx create --use
docker buildx build --platform linux/arm64 -t myapp:arm64 --load .

# Verify
docker run --rm myapp:arm64 uname -m    # aarch64
```

---

## ARM64 Tool Binaries (GitHub releases pattern)

All tools in the stack ship ARM64 binaries. Pattern for fetching:
```bash
# GitHub releases — look for: linux_arm64, linux-arm64, Linux_arm64
VERSION=$(curl -fsSL https://api.github.com/repos/OWNER/REPO/releases/latest \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
curl -fsSL "https://github.com/OWNER/REPO/releases/download/${VERSION}/TOOL_Linux_arm64.tar.gz" \
  | tar -xzf - -C ~/.local/bin TOOLNAME
```

---

## ARM64 Extension Support (SM8150)

```
ARMv8.2-A base
  ✅ AES (hardware AES encryption)
  ✅ SHA-2 (SHA-256, SHA-512)
  ✅ SHA-3
  ✅ NEON SIMD (128-bit vectors)
  ✅ FP16 (half-precision float)
  ✅ DotProd (int8 dot product — AI/ML acceleration)
  ✅ RDM (rounding doubling multiply)
  ❌ SVE (Scalable Vector Extension — SM8250+ only)
  ❌ BFloat16 (SM8350+ only)
```

---

## Hardware Reference

See `sm8150-hardware.md` for complete sysfs paths, CPU cluster layout, GPU power levels, and kernel tuning interfaces.
