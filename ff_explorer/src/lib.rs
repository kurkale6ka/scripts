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

    pub fn search_titles(&self, pattern: String) -> Vec<String> {
        let mut results: Vec<String> = Vec::new();

        for entry in self.location.read_dir().expect("read_dir call failed") {
            if let Ok(entry) = entry {
                let path = entry.path();
                let title = path.file_name().unwrap().to_str().unwrap();
                if title.contains(&pattern) {
                    results.push(title.to_string());
                }
            }
        }
        results
    }

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
    // TODO: parse args
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_folders<'a>() -> Result<&'a Path, io::Error> {
        let base = Path::new("/home/mitko/fe/");
        fs::create_dir_all(base.join("folder1"))?;
        fs::create_dir_all(base.join("folder1/subf1"))?;
        fs::create_dir_all(base.join("folder2"))?;
        Ok(base)
    }

    fn get_repo<'a>() -> DocsRepo<'a> {
        let base = create_folders().expect("Folder fixtures should've been created");

        DocsRepo::new(base)
    }

    #[test]
    fn find_files_with_search_pattern_in_titles() {
        let repo = get_repo();
        let results = repo.search_titles("ssh".to_string());
        assert!(results.len() > 1)
    }

    #[test]
    fn find_files_with_search_pattern_in_contents() {
        assert!(false)
    }

    #[test]
    fn find_hidden_files_with_search_pattern_in_titles() {
        assert!(false)
    }

    #[test]
    fn find_hidden_files_with_search_pattern_in_contents() {
        assert!(false)
    }

    #[test]
    fn no_results_in_empty_repo() {
        assert!(false)
    }

    #[test]
    fn view_doc_in_terminal() {
        assert!(false)
    }

    #[test]
    fn view_docs_in_terminal() {
        assert!(false)
    }

    #[test]
    fn view_doc_in_browser() {
        assert!(false)
    }

    #[test]
    fn edit_doc_with_editor() {
        assert!(false)
    }

    #[test]
    fn run_doc() {
        assert!(false)
    }
}
