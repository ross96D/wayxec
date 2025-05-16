use std::{
    ffi::{CStr, OsString, c_char},
    os::unix::ffi::OsStrExt,
};

use freedesktop_icons::lookup;

#[unsafe(no_mangle)]
extern "C" fn rust_free_lookup_icon_result(ptr: *mut u8, len: u64) {
    unsafe {
        let slice = std::slice::from_raw_parts_mut(ptr, len as usize);
        let ptr = slice.as_mut_ptr();
        let boxed = Box::from_raw(ptr);
        drop(boxed)
    }
}

#[unsafe(no_mangle)]
extern "C" fn rust_lookup_icon(icon: *const c_char, result: *mut *const u8) -> u64 {
    let c_str: &CStr = unsafe { CStr::from_ptr(icon) };
    let icon_str = c_str.to_str().unwrap();

    match lookup(icon_str).with_size(128).find() {
        Some(v) => {
            let osstring: OsString = v.into();
            let boxed = osstring.into_boxed_os_str();
            let ostr = Box::leak(boxed);
            unsafe {
                (*result) = ostr.as_bytes().as_ptr();
            }
            return ostr.len() as u64;
        }
        None => {}
    };
    match lookup(icon_str).find() {
        Some(v) => {
            let osstring: OsString = v.into();
            let boxed = osstring.into_boxed_os_str();
            let ostr = Box::leak(boxed);
            unsafe {
                (*result) = ostr.as_bytes().as_ptr();
            }
            ostr.len() as u64
        }
        None => {
            unsafe {
                (*result) = std::ptr::null();
            }
            0
        }
    }
}

#[cfg(test)]
mod tests {
    use std::ffi::CString;

    use super::*;

    #[test]
    fn it_works() {
        let mut ptr = std::ptr::null();
        let str = CString::new("firefox").unwrap();

        let len = rust_lookup_icon(str.as_ref().as_ptr(), &mut ptr);
        println!("LENGTH: {}", len);
        rust_free_lookup_icon_result(ptr.cast_mut(), len);
    }
}
