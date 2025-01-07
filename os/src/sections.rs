/// Looks like this file can be simplified using proc macros into this:
///
/// ```rust
/// #[sections]
/// pub struct Sections {
///     #[section(start = "s_kernel", end = "e_kernel")]
///     pub kernel: Section,
///
///     #[section(start = "s_text", end = "e_text")]
///     pub text: Section,
///
///     #[section(start = "s_rodata", end = "e_rodata")]
///     pub rodata: Section,
///
///     #[section(start = "s_data", end = "e_data")]
///     pub data: Section,
///
///     #[section(start = "s_bss", end = "e_bss")]
///     pub bss: Section,
///
///     #[boot_stack(top = "boot_stack_top", lower_bound = "boot_stack_lower_bound")]
///     pub boot_stack: BootStack,
/// }
/// ```
///
/// Hope one day I will be able to implement this proc macro.
///

pub struct Section {
    pub start: usize,
    pub end: usize,
}

pub struct BootStack {
    pub top: usize,
    pub lower_bound: usize,
}

impl Section {
    fn new(start: usize, end: usize) -> Self {
        Self { start, end }
    }
}

pub struct Sections {
    pub kernel: Section,
    pub text: Section,
    pub rodata: Section,
    pub data: Section,
    pub bss: Section,
    pub boot_stack: BootStack,
}

impl Sections {
    pub fn get() -> Self {
        unsafe extern "C" {
            unsafe fn s_kernel();
            unsafe fn e_kernel();
            unsafe fn s_text();
            unsafe fn e_text();
            unsafe fn s_rodata();
            unsafe fn e_rodata();
            unsafe fn s_data();
            unsafe fn e_data();
            unsafe fn s_bss();
            unsafe fn e_bss();
            unsafe fn boot_stack_top();
            unsafe fn boot_stack_lower_bound();
        }

        Self {
            kernel: Section::new(s_kernel as usize, e_kernel as usize),
            text: Section::new(s_text as usize, e_text as usize),
            rodata: Section::new(s_rodata as usize, e_rodata as usize),
            data: Section::new(s_data as usize, e_data as usize),
            bss: Section::new(s_bss as usize, e_bss as usize),
            boot_stack: BootStack {
                top: boot_stack_top as usize,
                lower_bound: boot_stack_lower_bound as usize,
            },
        }
    }
}
