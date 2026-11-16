// Yodo1MasLinkFixes: link-time fixes for building the Yodo1 MAS SDK with the
// AIR SDK's (iOS 17-era) system stubs. Compiled into libYodo1MasLinkFixes.a and
// linked into the app by ADT on macOS (Xcode ld-classic) and Windows (AIR lld)
// alike, so no post-processing of the IPA is needed.
//
// Everything is in ONE object file on purpose: the linker pulls this member in
// because of the FORCE_LOAD references below, and that brings the Network
// forwarders with it.

#include <dlfcn.h>
#include <stddef.h>

// ---------------------------------------------------------------------------
// 1. Swift 6 system-shim "force load" markers
// ---------------------------------------------------------------------------
// Swift objects built with Xcode 16+ reference __swift_FORCE_LOAD_$_<lib> for
// each Swift system shim module they import (swift_errno, swift_math, ...).
// Xcode satisfies them from the iOS SDK's .tbd files; the AIR SDK's stub
// directory does not have those libraries. The markers carry no behaviour.
// They are forced into __DATA,__data: ld64 does not pull an archive member to
// resolve a symbol that the member only defines as a common/zero-fill symbol.
#define FORCE_LOAD(name) \
    __attribute__((used, section("__DATA,__data"))) \
    char __swift_FORCE_LOAD_$_##name __asm__("__swift_FORCE_LOAD_$_" #name) = 0;
FORCE_LOAD(swift_Builtin_float)
FORCE_LOAD(swift_errno)
FORCE_LOAD(swift_math)
FORCE_LOAD(swift_signal)
FORCE_LOAD(swift_stdio)
FORCE_LOAD(swift_time)
FORCE_LOAD(swiftsys_time)
FORCE_LOAD(swiftunistd)

// ---------------------------------------------------------------------------
// 2. Network.framework forwarders
// ---------------------------------------------------------------------------
// The AIR SDK's libSystem stub still exports nw_* functions that iOS used to
// ship in libsystem_network, and ADT always puts -lSystem.B ahead of the
// app's frameworks. The linker therefore binds these imports to libSystem,
// which no longer exports them on current iOS: dyld aborts with
// "Symbol not found: _nw_interface_get_type (expected in libSystem.B.dylib)".
// Defining them here makes the link resolve locally; each forwarder calls the
// real function in Network.framework.
//
// The set is exactly the nw_* imports that bound to libSystem (verified with
// tools/check_ios_binds.py against the Xcode iOS SDK). If an SDK update adds
// more, add them here.

static void *yodo1mas_nw_symbol(const char *name) {
    static void *handle;
    if (!handle) {
        handle = dlopen("/System/Library/Frameworks/Network.framework/Network", RTLD_LAZY | RTLD_NOLOAD);
        if (!handle) {
            handle = dlopen("/System/Library/Frameworks/Network.framework/Network", RTLD_LAZY);
        }
    }
    return handle ? dlsym(handle, name) : NULL;
}

// nw_path_status_t nw_path_get_status(nw_path_t path);
int nw_path_get_status(void *path) {
    static int (*fn)(void *);
    if (!fn) fn = (int (*)(void *))yodo1mas_nw_symbol("nw_path_get_status");
    return fn ? fn(path) : 0; // nw_path_status_invalid
}

// nw_interface_type_t nw_interface_get_type(nw_interface_t interface);
int nw_interface_get_type(void *interface) {
    static int (*fn)(void *);
    if (!fn) fn = (int (*)(void *))yodo1mas_nw_symbol("nw_interface_get_type");
    return fn ? fn(interface) : 0; // nw_interface_type_other
}
