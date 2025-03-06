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
        fs::create_dir_all(Path::new("/home/mitko/fe/folder1"))?;
        fs::create_dir_all(Path::new("/home/mitko/fe/folder2"))?;
        Ok(())
    }

    fn get_repo<'a>() -> DocsRepo<'a> {
        create_folders().expect("Folder fixtures should've been created");

        DocsRepo::new(Path::new("/home/mitko/repos/github/help"))
    }

    #[test]
    fn find_files_with_search_pattern_in_titles() {}

    #[test]
    fn find_files_with_search_pattern_in_contents() {}

    #[test]
    fn find_hidden_files_with_search_pattern_in_titles() {}

    #[test]
    fn find_hidden_files_with_search_pattern_in_contents() {}

    #[test]
    fn no_results_in_empty_repo() {}

    #[test]
    fn view_doc_in_terminal() {}

    #[test]
    fn view_docs_in_terminal() {}

    #[test]
    fn view_doc_in_browser() {}

    #[test]
    fn edit_doc_with_editor() {}

    #[test]
    fn run_doc() {}
}
