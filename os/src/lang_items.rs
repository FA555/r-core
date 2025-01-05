use crate::println;
use crate::sbi::shutdown;
use core::panic::PanicInfo;

#[panic_handler]
fn manic(info: &PanicInfo) -> ! {
    if let Some(location) = info.location() {
        println!(
            "Panicked ({}:{}): {}",
            location.file(),
            location.line(),
            info.message(),
        );
    } else {
        println!("Panicked: {}", info.message());
    }

    shutdown(true)
}
