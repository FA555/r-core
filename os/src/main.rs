#![no_main]
#![no_std]

#[macro_use]
mod console;
mod lang_items;
mod logger;
mod sbi;
mod sections;

use crate::sbi::shutdown;
use crate::sections::{Section, Sections};
use core::arch::global_asm;
use log::{info, trace};

global_asm!(include_str!("entry.asm"));

#[no_mangle]
pub fn rust_main() -> ! {
    logger::init(option_env!("LOG_LEVEL"));
    trace!("Kernel booted");

    let sections = Sections::get();
    clear_section(&sections.bss);
    print_sections(&sections);

    shutdown(false)
}

fn print_sections(sections: &Sections) {
    fn print_section(section: &Section, name: &str) {
        info!(
            "[kernel] {:>7} section: [{:#x}, {:#x})",
            name, section.start, section.end
        );
    }

    info!(
        "The whole kernel: [{:#x}, {:#x})",
        sections.kernel.start, sections.kernel.end
    );
    print_section(&sections.text, ".text");
    print_section(&sections.rodata, ".rodata");
    print_section(&sections.data, ".data");
    print_section(&sections.bss, ".bss");
    info!(
        "[kernel] Boot stack: top = bottom = {:#x}, lower bound = {:#x}",
        sections.boot_stack.top, sections.boot_stack.lower_bound
    );
}

fn clear_section(section: &Section) {
    (section.start..section.end).for_each(|addr| unsafe { (addr as *mut u8).write_volatile(0) });
}
