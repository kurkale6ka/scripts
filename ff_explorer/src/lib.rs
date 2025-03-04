use std::error::Error;
use std::path::Path;

// TODO: why repeat, not an include, check docs
mod args;

pub struct DocsRepo<'a> {
    pub location: &'a Path, // TODO: use <generic> Source
}

// TODO: use '_
impl<'a> DocsRepo<'a> {
    pub fn new(location: &'a Path) -> Self {
        Self { location }
    }

    pub fn search_titles(&self) {}
    pub fn search_contents(&self) {}
}

pub struct DocSet;

impl DocSet {
    fn filter() {}
    pub fn get_doc(&self) {}
    pub fn get_docs(&self) {}
}

pub struct Doc;

impl Doc {
    pub fn view(&self) {}
    pub fn edit(&self) {}
    pub fn run(&self) {}
}

pub fn run(args: impl clap::Parser) -> Result<(), Box<dyn Error>> {
    let repo = DocsRepo::new(Path::new("~/repos/github/help"));
    println!(
        "Is {} a dir? {}",
        repo.location.display(),
        repo.location.is_dir() // TODO: add test
    );
    // println!(args::parse());
    Ok(())
}

// pub fn get_help_files() -> Vec<String> {
//     return ()
// }

// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn help_dir_has_got_markdown_files() {
//         let result = get_help_files();
//         assert_ne!(result, ());
//     }
// }
