# Drop this in the root of your nim project and run `nimble build`
# This will work if your $CC and $CFLAGS are set up for the MilkV Duo from the envsetup.sh

import std/envvars

switch("cc", "gcc")
switch("gcc.exe", getEnv("CC"))
switch("gcc.linkerexe", getEnv("CC"))

switch("passC", getEnv("CFLAGS"))
switch("passL", getEnv("CFLAGS"))
