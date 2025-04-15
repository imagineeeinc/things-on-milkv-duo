# Things on on Milk V duo

This is a guide/ write up on getting things working on the the Milk V Duo. This repo is mainly looking into getting software and programming languages runnning on the default buildroot system.

## Contents

- [Image Requirements](#os-image-requirements)
- [Compilers for Duo](#compiling-for-milk-v-duo)
- [C on Duo](#wasm-on-milk-v-duo) (**Status**: Working, Offical Method ✅)
- [WASM on Duo](#wasm-on-milk-v-duo) (**Status**: Working, more testing 🟨)
- [Nim on Duo](#nim-on-milk-v-duo) (**Status**: Working, testing required ✅)
- [Rust on Duo](#rust-on-milk-v-duo) (**Status**: Working, I haven't tested ✅)
- [Contributing](#contributing)

## OS Image requirements

All of my testing is done on [Milk V Duo Buildroot V1](https://github.com/milkv-duo/duo-buildroot-sdk) on the Milk V Duo 64mb. These should also work on the [Buildroot V2](https://github.com/milkv-duo/duo-buildroot-sdk-v2), but I haven't tested them.

## Compiling for Milk V Duo

So far we need to use a riscv64-musl toolchain to compile C programs. It is easy to setup with the included [setup script](https://github.com/milkv-duo/duo-examples/blob/main/envsetup.sh) in the [examples repo](https://github.com/milkv-duo/duo-examples) from Milk V.

Simpily copy the `envsetup.sh` from the [example repo](https://github.com/milkv-duo/duo-examples) into the root of your project or where ever you want and run `source envsetup.sh` and select your board with 1 or 2 (I select 1 as I have the base model).
The script downloads and setups the toolchain. Sadly the toolchain only supports x86 only and has not arm64 support, there might be a hacky way around it.

The script also sets up your `CC` and `CFLAGS` env variable, so you simpliy need to run make on a project which uses the `CC` and `CFLAGS` var to compile. How ever the vars is only for this terminal instance and you need to run it every time you open a new terminal instance.

### CFLAGS

Here is the custom `CFLAGS` if you want to hardcode it:
```bash
-mcpu=c906fdv -march=rv64imafdcv0p7xthead -mcmodel=medany -mabi=lp64d -O3 -DNDEBUG -I/workspace/wasm3/platforms/openwrt/build/include/system
```
**Note**: This is only for the Milk V Duo 64mb version. For other models, look at the [setup script](https://github.com/milkv-duo/duo-examples/blob/main/envsetup.sh) for their respective flags.

## C on Milk V Duo

This section isn't a guide. I am just accumlating info.

Simpily use the toolchain from the [compiler section](#compiling-for-milk-v-duo). Use the compiler provided at `host-tools/gcc/riscv64-linux-musl-x86_64/bin/riscv64-unknown-linux-musl-gcc` and use the [compiler flags](#cflags) for the Milk V Duo specifically.

## WASM on Milk V Duo

I think that wasm will make it easier to port programs to these more obscure architectures by using **WASM (Web Assembly)** as a universal binary format.
Specially with the rise of the [WASI (Web Assembley System Interface)](https://wasi.dev/), which makes making native applications easier.

### WASM Interpreters

So far WASM interpreters I might port are Wasmer, Wasmtime, Wasmedge and [Wasm3](https://github.com/wasm3/wasm3).
I have got **Wasm3** compiled as it was the easiest to compile.
I would like to get the other working, but as of now the wasm3 is the easiest to compile.

#### Wasm3

[Wasm3](https://github.com/wasm3/wasm3) is a fast WASM runtime with wasi support. Compiling a cli tool is quite simple as using the included cli example.

Simpily setup the toolcahin ([from before](#compiling-for-duo)) and run `make` in the `/platforms/openwrt/build` (actual cli code is in `platforms/app`, and interpreter in `/source`), no modifications required.
If you try running the resulting `wasm3` binary on your host platform you will get an error, but copying to the MilkV and trying will result in the application giving you a proper message.

### Trying out programs

So, I have been trying to get some programs working on the board. The kinda hard part is that I have to compile .wasm files from scratch as no one provides me a binary.
Secondly, most wasm projects is for the browser, actual cli projects are few. So, would need to build a wrapper around it.

#### [Cowsays](https://github.com/wapm-packages/cowsay)

Fisrt thing I compiled to webassembly and uploaded to the MilkV and it worked. I posted it about it [here](https://mastodon.social/@imagineee/114336144029065032).

## Nim on Milk V Duo

The Nim compiler supports custom compilers. So I used the risv64 toolchain as my compiler by adding a `config.nim` to the root of my nimble directory and adding this config:
```nim
import std/envvars

switch("cc", "gcc")
switch("gcc.exe", getEnv("CC"))
switch("gcc.linkerexe", getEnv("CC"))

switch("passC", getEnv("CFLAGS"))
switch("passL", getEnv("CFLAGS"))
```
If you have your toolchain in a more permanent location, replace the `getEnv("CC")` with the location of the gcc compiler. And hard code the `CFLAGS` from the [compiler section](#cflags)

If you want to pass it as flags to the compiler.
```bash
# Nimble
nimble build --cc:gcc \
--gcc.exe="$(CC)" \
--gcc.linkerexe="$(CC)" \
--passC="$(CFLAGS)" \
--passL="$(CFLAGS)"

# Nim
nim c --cc:gcc \
--gcc.exe="$(CC)" \
--gcc.linkerexe="$(CC)" \
--passC="$(CFLAGS)" \
--passL="$(CFLAGS)"
```
Again, if you have your toolchain in a more permanent location, replace the `$("CC")` with the location of the gcc compiler. And hard code the `CFLAGS` from the [compiler section](#compiling-for-milk-v-duo).

The compiler produces an executable that will not run on the host system, but runs on the MilkV.

In conculsion, you have to do is use the riscv64 musl toolchain c compiler and  the custom C compiler flags used for the MilkV Duo.

## Rust on Milk V Duo

[github.com/ejortega/milkv-duo-rust](https://github.com/ejortega/milkv-duo-rust)

## Contributing

If you would like to contribute your knowledge to this repo, open a pull request with the any modifications in it. Or open an issue and provide any info there.
