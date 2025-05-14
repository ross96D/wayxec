import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart' as ffi;

import 'icon_lookup_bindings_generated.dart';

int sum(int a, int b) => _bindings.sum(a, b);

class NativeString {
  final Pointer<ffi.Utf8> address;
  final int len;

  String? _value;

  bool _free = false;

  String get value {
    _value ??= address.toDartString(length: len);
    return _value!;
  }

  NativeString(this.address, this.len);
}

NativeString? iconLookup(String icon) {
  final result = _bindings.IconLookup_Lookup(icon.toNativeUtf8().cast());
  if (result.ptr.address == 0) {
    return null;
  }
  Pointer<ffi.Utf8> ptr = result.ptr.cast();
  return NativeString(ptr, result.len);
}

void freeIconLookupResult(NativeString nativeString) {
  assert(!nativeString._free, "double free");

  final str = ffi.malloc<IconLookup_String>();
  str.ref.ptr = nativeString.address.cast();
  str.ref.len = nativeString.len;
  _bindings.IconLookup_Free(str.ref);
  ffi.malloc.free(str);

  nativeString._free = true;
}

const String _libName = 'icon_lookup';

/// The dynamic library in which the symbols for [IconLookupBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final IconLookupBindings _bindings = IconLookupBindings(_dylib);
