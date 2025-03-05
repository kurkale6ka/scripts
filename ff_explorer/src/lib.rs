use std::error::Error;
use std::fs;
use std::io;
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
    let repo = DocsRepo::new(Path::new("/home/mitko/repos/github/help")); // TODO: use ~
    println!(
        "Is {} a dir? {}",
        repo.location.display(),
        repo.location.is_dir() // TODO: add test
    );
    // println!(args::parse());
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_folders() -> Result<(), io::Error> {
        fs::create_dir_all(Path::new("/home/mitko/ff/help"))?;
        fs::create_dir_all(Path::new("/home/mitko/ff/prog"))?;
        Ok(())
    }

    fn get_repo<'a>() -> DocsRepo<'a> {
        if let Err(_) = create_folders() {
            panic!("Couldn't create fixture folders");
        }

        DocsRepo::new(Path::new("/home/mitko/repos/github/help"))
    }

    #[test]
    fn markdown_files_present_in_help_folder() {
        let repo = get_repo();
        assert!(repo.location.is_dir());
    }
}
