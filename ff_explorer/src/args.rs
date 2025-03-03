use clap::Parser;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    source_dir: String,
}

pub fn run() {
    let args = Args::parse();
}
