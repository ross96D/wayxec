#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

struct IconLookup_String {
    uint64_t len;
    char* ptr;
};

typedef struct IconLookup_String IconLookup_String;

FFI_PLUGIN_EXPORT void IconLookup_Free(IconLookup_String string);

FFI_PLUGIN_EXPORT IconLookup_String IconLookup_Lookup(const char* icon);
