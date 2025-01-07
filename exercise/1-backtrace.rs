#[inline(never)]
fn print_call_stack() {
    println!("{}", std::backtrace::Backtrace::force_capture());
}

#[inline(never)]
fn func3() {
    print_call_stack();
}

#[inline(never)]
fn func2() {
    func3();
}

#[inline(never)]
fn func1() {
    func2();
}

fn main() {
    func1();
}
