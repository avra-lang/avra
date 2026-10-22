#!/bin/sh
[ -d tools ] || exit 70
cd tools/ui-board
timeout 90 node --input-type=module -e "
import { openPage, firefoxBinary } from './firefox.mjs';
console.log('binary', firefoxBinary());
const p = await openPage(firefoxBinary(), 'about:blank');
console.log('opened');
await p.close();
" 2>&1 | head -20
id -u; env | grep -i "moz\|display\|home" | head
