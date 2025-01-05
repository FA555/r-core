use core::panic::PanicInfo;

#[panic_handler]
fn manic(_info: &PanicInfo) -> ! {
    loop {}
}
