use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_draw(
    func: *mut wire_uint_8_list,
    variable_builder: *mut wire_VariableBuilder,
    constant_provider: *mut wire_list_constant,
    change_context: bool,
) -> support::WireSyncReturn {
    wire_draw_impl(func, variable_builder, constant_provider, change_context)
}

#[no_mangle]
pub extern "C" fn wire_get_sample_for_dart() -> support::WireSyncReturn {
    wire_get_sample_for_dart_impl()
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_box_autoadd_variable_builder_0() -> *mut wire_VariableBuilder {
    support::new_leak_box_ptr(wire_VariableBuilder::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_list_constant_0(len: i32) -> *mut wire_list_constant {
    let wrap = wire_list_constant {
        ptr: support::new_leak_vec_ptr(<wire_Constant>::new_with_null_ptr(), len),
        len,
    };
    support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for *mut wire_uint_8_list {
    fn wire2api(self) -> String {
        let vec: Vec<u8> = self.wire2api();
        String::from_utf8_lossy(&vec).into_owned()
    }
}

impl Wire2Api<VariableBuilder> for *mut wire_VariableBuilder {
    fn wire2api(self) -> VariableBuilder {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<VariableBuilder>::wire2api(*wrap).into()
    }
}
impl Wire2Api<Constant> for wire_Constant {
    fn wire2api(self) -> Constant {
        Constant {
            identity: self.identity.wire2api(),
            value: self.value.wire2api(),
            max: self.max.wire2api(),
            min: self.min.wire2api(),
            step: self.step.wire2api(),
        }
    }
}

impl Wire2Api<Vec<Constant>> for *mut wire_list_constant {
    fn wire2api(self) -> Vec<Constant> {
        let vec = unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        };
        vec.into_iter().map(Wire2Api::wire2api).collect()
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}
impl Wire2Api<VariableBuilder> for wire_VariableBuilder {
    fn wire2api(self) -> VariableBuilder {
        VariableBuilder {
            identity: self.identity.wire2api(),
            uninitialized: self.uninitialized.wire2api(),
            min: self.min.wire2api(),
            max: self.max.wire2api(),
            step: self.step.wire2api(),
            value: self.value.wire2api(),
        }
    }
}
// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_Constant {
    identity: *mut wire_uint_8_list,
    value: f64,
    max: f64,
    min: f64,
    step: f64,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_constant {
    ptr: *mut wire_Constant,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_VariableBuilder {
    identity: *mut wire_uint_8_list,
    uninitialized: bool,
    min: f64,
    max: f64,
    step: f64,
    value: f64,
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

impl NewWithNullPtr for wire_Constant {
    fn new_with_null_ptr() -> Self {
        Self {
            identity: core::ptr::null_mut(),
            value: Default::default(),
            max: Default::default(),
            min: Default::default(),
            step: Default::default(),
        }
    }
}

impl Default for wire_Constant {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_VariableBuilder {
    fn new_with_null_ptr() -> Self {
        Self {
            identity: core::ptr::null_mut(),
            uninitialized: Default::default(),
            min: Default::default(),
            max: Default::default(),
            step: Default::default(),
            value: Default::default(),
        }
    }
}

impl Default for wire_VariableBuilder {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
