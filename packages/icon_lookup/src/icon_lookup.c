#include "icon_lookup.h"
#include "stdint.h"
#include "stdbool.h"

extern uint64_t rust_lookup_icon(const char* icon, char** out);

extern void rust_free_lookup_icon_result(char* ptr, uint64_t len);

FFI_PLUGIN_EXPORT IconLookup_String IconLookup_Lookup(const char* icon) {
  char* out = NULL;
  uint64_t len = rust_lookup_icon(icon, &out);
  return (IconLookup_String) { len, out };
}

FFI_PLUGIN_EXPORT void IconLookup_Free(IconLookup_String string) {
  rust_free_lookup_icon_result(string.ptr, string.len);
}
