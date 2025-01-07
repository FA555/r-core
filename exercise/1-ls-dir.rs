fn main() {
    for entry in std::fs::read_dir(".").expect("Failed to read directory `.'") {
        println!(
            "{}",
            entry
                .expect("Failed to read entry")
                .file_name()
                .to_str()
                .expect("Failed to convert path to string")
        );
    }
}
