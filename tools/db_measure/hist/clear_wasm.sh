#!/bin/sh
# The Sprite's wasm runtime objects are rebuilt from the tree's runtime on the next ui-board keeper.
ls -la build/wasm32 2>/dev/null | head -n 5
rm -rf build/wasm32
ls -d build/wasm32 2>/dev/null || echo "build/wasm32 cleared"
