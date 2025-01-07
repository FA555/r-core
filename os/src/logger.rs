use log::{Metadata, Record};

struct Logger;

fn color_of_level(level: log::Level) -> &'static str {
    match level {
        log::Level::Error => "31",
        log::Level::Warn => "93",
        log::Level::Info => "34",
        log::Level::Debug => "32",
        log::Level::Trace => "90",
    }
}

fn str_of_level(level: log::Level) -> &'static str {
    match level {
        log::Level::Error => "[ERROR]",
        log::Level::Warn => " [WARN]",
        log::Level::Info => " [INFO]",
        log::Level::Debug => "[DEBUG]",
        log::Level::Trace => "[TRACE]",
    }
}

impl log::Log for Logger {
    fn enabled(&self, _metadata: &Metadata) -> bool {
        true
    }

    fn log(&self, record: &Record) {
        if !self.enabled(record.metadata()) {
            return;
        }

        // do not use fmt::Display for Level in order to align
        let (color, level_str) = match record.level() {
            log::Level::Error => (31, "[ERROR]"),
            log::Level::Warn => (33, " [WARN]"), // do not use suggest color
            log::Level::Info => (34, " [INFO]"),
            log::Level::Debug => (32, "[DEBUG]"),
            log::Level::Trace => (90, "[TRACE]"),
        };

        println!("\u{1b}[{}m{} {}\u{1b}[0m", color, level_str, record.args());
    }

    fn flush(&self) {}
}

static LOGGER: Logger = Logger;

pub fn init(level_str: Option<&str>) {
    log::set_logger(&LOGGER)
        .map(|()| {
            log::set_max_level(match level_str {
                Some("ERROR") => log::LevelFilter::Error,
                Some("WARN") => log::LevelFilter::Warn,
                Some("INFO") => log::LevelFilter::Info,
                Some("DEBUG") => log::LevelFilter::Debug,
                Some("TRACE") => log::LevelFilter::Trace,
                _ => log::LevelFilter::Info,
            })
        })
        .expect("Failed to set logger");
}
