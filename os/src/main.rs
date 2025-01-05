#![no_main]
#![no_std]

mod lang_items;
mod sbi;
#[macro_use]
mod console;

use core::arch::global_asm;

global_asm!(include_str!("entry.asm"));

#[no_mangle]
pub fn rust_main() -> ! {
    clear_bss();

    let x = 14;
    println!("1{}5{}", x, x,);
    print!("1{}", x,);
    print!("5{}", x);
    println!();

    panic!("Shutdown through panicking!")
}

fn clear_bss() {
    extern "C" {
        fn sbss();
        fn ebss();
    }

    (sbss as usize..ebss as usize).for_each(|addr| unsafe { (addr as *mut u8).write_volatile(0) });
}
