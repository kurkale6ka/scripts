use clap::Parser;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
pub struct Cli {
    // #[arg(short, long)]
    // pub source_dir: String,
}
