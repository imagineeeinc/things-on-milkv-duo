# Things on on Milk V duo

This is a guide/ write up on getting things working on the the Milk V Duo. This repo is mainly looking into getting software and programming languages runnning on the default buildroot system.

## Contents

- [Image Requirements](#os-image-requirements)
- [Compilers for Duo](#compiling-for-milk-v-duo)
  - [C Flags](#cflags)
  - [Other Compiler](#acquiring-other-compilers) (**Status**: Non of them working ⛔)
- [C on Duo](#wasm-on-milk-v-duo) (**Status**: Working, Offical Method ✅)
- [WASM on Duo](#wasm-on-milk-v-duo) (**Status**: Working, more testing 🟨)
- [Nim on Duo](#nim-on-milk-v-duo) (**Status**: Working, testing required ✅)
- [Rust on Duo](#rust-on-milk-v-duo) (**Status**: Working, I haven't tested ✅)
- [Go on Duo](#go-on-milk-v-duo) (**Status**: Working, more testing 🟨)
- [Contributing](#contributing)

## OS Image requirements

All of my testing is done on [Milk V Duo Buildroot V1](https://github.com/milkv-duo/duo-buildroot-sdk) on the Milk V Duo 64mb. These should also work on the [Buildroot V2](https://github.com/milkv-duo/duo-buildroot-sdk-v2), but I haven't tested them.

**Note**: I am using V1 as that is the only one I was able to build with a larger sd card image size. As I wasn't able to expand the root parition after boot and wasn't able to get the V2 to compile with the larger size.

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

### Acquiring Other Compilers

I have found some other compilers that might also work, ~~I haven't tested them~~ and after testing I couldn't get any of them to work.
- ⛔ [toolchains.bootlin.com/releases_riscv64.html](https://toolchains.bootlin.com/releases_riscv64.html): Ensure to get the `musl` version if you are compiling for the default buildroot os.
  - **Cannot get this to work**, gives me error: `error: unrecognized command-line option ‘-mcpu=c906fdv’`, I need the this specific C Flag as that defines the CPU version of the Duo.
  - Trying the [riscv64-lp64d](https://toolchains.bootlin.com/releases_riscv64-lp64d.html) version gives me diffrent error of `error: ‘-mcpu=c906fdv’: unknown CPU`.
- ⛔ [github.com/riscv-collab/riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain): Under the [releases](https://github.com/riscv-collab/riscv-gnu-toolchain/releases) section get the latest `riscv64-musl-ubuntu-*` version.4
  - **Cannot get this to work**, gives me error: `lib/x86_64-linux-gnu/libc.so.6: version 'GLIBC_2.36' not found`
- ⛔ [github.com/ejortega/milkv-host-tools  ](https://github.com/ejortega/milkv-host-tools): Under the [releases](https://github.com/ejortega/milkv-host-tools/releases) section get the toolchain for your host platform. The only one with arm64 version.
  - **Cannot get this to work**, gives me error: `error: '-march=rv64imafdcv0p7xthead': extension 'xthead' starts with 'x' but is unsupported non-standard extension`
  - Removing `xthead` from the `-march` flag, gives me error: `error: '-mcpu=c906fdv': unknown CPU`
  - Removing the `-mcpu` flag leads to it compling but not having the correct linking, it has ` /lib/ld-musl-riscv64.so.1`, which will not run. (Correct one: `/lib/ld-musl-riscv64v0p7_xthead.so.1`)
I think the official compiler has a custom extra config for that specific cpu.
## C on Milk V Duo

This section isn't a guide. I am just accumlating info.

Simpily use the toolchain from the [compiler section](#compiling-for-milk-v-duo). Use the compiler provided at `host-tools/gcc/riscv64-linux-musl-x86_64/bin/riscv64-unknown-linux-musl-gcc` and use the [compiler flags](#cflags) for the Milk V Duo specifically.

I think if you compile for riscv64 but ask it to build static, you can ignore the `CFLAGS` which set custom cpu and cpu version flags.

### Programs

Some C programs I have got compiled.

#### [llama2.c](https://github.com/karpathy/llama2.c)

An LLM inference in pure C. Edited the Makefile to not overwrite the compiler and added the CFLAGS and compiled without an issue.
Uploaded the executable, tokens.bin and the smallest model it recommends and took 0.25 tokens per second, 11 mins to generate a small story.
I posted about it [here](https://mastodon.social/@imagineee/114342880196230040)

#### [QuickJS](https://bellard.org/quickjs/)

A JS interpreter with ES2023 support. For this compiling took some trial and error. I modified the Makefile to use my C Flags and had to add a library.
I wasn't able to get it working with the version string being injected into the source, so I just hard coded it.
You can apply my patch to the [Github Mirror](https://github.com/bellard/quickjs), ensure your `PREFIX` is set to a temp location you want to store the files.
Ensure to set the `CROSS_PREFIX` enviornment variable to the toolchain prefix (like this: `host-tools/gcc/riscv64-linux-musl-x86_64/bin/riscv64-unknown-linux-musl-`, point to your actual location and keep the ending blank, removing the gcc).
And run `make qjs` and `make install`. Go to the location of install and transfer the files to the duo and place the contents in the corresponding directories in `/usr/local`.

Also I ran [calculating Pi](https://bellard.org/quickjs/pi.html) on the the Duo with quickjs.
For 100,000 numbers it takes 26.16 seconds to complete. Which 100 times slower than the benchmark on a Core i5 4570 CPU at 3.2 GHz.

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
--gcc.exe="$CC" \
--gcc.linkerexe="$CC" \
--passC="$CFLAGS" \
--passL="$CFLAGS"

# Nim
nim c --cc:gcc \
--gcc.exe="$CC" \
--gcc.linkerexe="$CC" \
--passC="$CFLAGS" \
--passL="$CFLAGS"
```
Again, if you have your toolchain in a more permanent location, replace the `$("CC")` with the location of the gcc compiler. And hard code the `CFLAGS` from the [compiler section](#compiling-for-milk-v-duo).

The compiler produces an executable that will not run on the host system, but runs on the MilkV.

In conculsion, you have to do is use the riscv64 musl toolchain c compiler and  the custom C compiler flags used for the MilkV Duo.

## Rust on Milk V Duo

[github.com/ejortega/milkv-duo-rust](https://github.com/ejortega/milkv-duo-rust)

## Go on Milk V Duo

After reading a bit online, it seems like go has the best cross compilation system. All you do is ask the go compiler to build for a diffrent arch.
No having to ask it to use a diffent compiler, no custom configs and linking and custom flags.

All you do is set `GOOS` to `linux` and `GOARCH` to `riscv64`.

```bash
env GOOS=linux GOARCH=riscv64 go build
```

Because go builds static binaries by default, it dosen't need any custom custom flags and cpu version. However the downside is larger binaries.

Also, to run go binaries on the duo, you need all the 64 mb of ram. If you are using the default official image, the ram is limited to ~23mb, some of it is allocated to camera processing.
You can disable it by building your own version and setting `ION` to 0, mentiond [here](https://github.com/milkv-duo/duo-buildroot-sdk?tab=readme-ov-file#faqs).

## Contributing

If you would like to contribute your knowledge to this repo, open a pull request with the any modifications in it. Or open an issue and provide any info there.
