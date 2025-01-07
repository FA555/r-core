#![no_main]
#![no_std]

mod lang_items;
mod sbi;
#[macro_use]
mod console;
mod logger;

use crate::sbi::shutdown;
use core::arch::global_asm;
use log::{trace, debug, info, warn, error};

global_asm!(include_str!("entry.asm"));

#[no_mangle]
pub fn rust_main() -> ! {
    clear_bss();
    logger::init(option_env!("LOG_LEVEL"));

    println!("Hello, world!");
    trace!("Hello, world!");
    debug!("Hello, world!");
    info!("Hello, world!");
    warn!("Hello, world!");
    error!("Hello, world!");

    shutdown(false)
}

fn clear_bss() {
    unsafe extern "C" {
        unsafe fn sbss();
        unsafe fn ebss();
    }

    (sbss as usize..ebss as usize).for_each(|addr| unsafe { (addr as *mut u8).write_volatile(0) });
}
