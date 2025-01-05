use std::io::Write;

fn main() {
    std::thread::sleep(std::time::Duration::from_secs(5));

    let message = "Hello from Rust after 5 seconds!";
    println!("{}", message);

    std::fs::File::create("0-sleep-rs.txt")
        .expect("Unable to create file")
        .write_fmt(format_args!("{}\n", message))
        .expect("Unable to write to file");
}
