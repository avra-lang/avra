// What the runtime reads of the machine it stands on. Kept apart from
// avra_box.h, which is pure LAYOUT shared with the backend: a platform
// predicate is not a layout, and the backend includes the layout alone.
#ifndef AVRA_PLATFORM_H
#define AVRA_PLATFORM_H

// The caller's own address, where the accounting names a site. A
// WebAssembly module has no return-address read, so the instruments
// that use it carry no site there rather than fail to compile.
#if defined(__wasm32__)
#define AVRA_CALLER() ((void*)0)
#else
#define AVRA_CALLER() __builtin_return_address(0)
#endif

#endif
