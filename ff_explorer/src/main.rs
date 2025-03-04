use clap::Parser;
use std::process;

mod args;
use args::Cli;

fn main() {
    if let Err(e) = fe::run(Cli::parse()) {
        eprintln!("Application error: {e}");
        process::exit(1);
    }
}
