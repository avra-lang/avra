#!/bin/sh
[ -d tools ] || exit 70
mkdir -p /tmp/typo/src && cat > /tmp/typo/avra.toml <<'X'
[package]
name        = "typo"
version     = "0.0.1"
description = "probe"

[lib]
name = "typo"
path = "src/lib.av"
X
cat > /tmp/typo/src/lib.av <<'X'
use @std.meta.{derive}
use @std.validate.{Decode, Checked}

@derive(Decode)
type T = {
    @unkown x: int,
}

@derive(Checked)
type U = {
    @unkown y: int,
}
X
cd /tmp/typo && /home/sprite/avra-build/avra-ui-arm/tree/build/avra check . 2>&1 | grep -a -v "^warning" | head -24
