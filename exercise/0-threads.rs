use std::io::Write;

const NUM_THREADS: usize = 5;

fn worker(thread_id: usize) {
    println!("Thread {thread_id} is reading file...");
    std::thread::sleep(std::time::Duration::from_secs(2));

    std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open("0-threads-rs.txt")
        .expect("Failed to open file")
        .write_fmt(format_args!("Thread {thread_id} wrote this message\n"))
        .expect("Failed to write to file");
}

fn main() {
    let mut threads = Vec::new();

    for i in 0..NUM_THREADS {
        threads.push(std::thread::spawn(move || worker(i)));
    }

    println!("Main thread doing some work asynchronously...");

    for thread in threads {
        thread.join().expect("Thread panicked");
    }

    println!("All threads have finished their work.");
}
