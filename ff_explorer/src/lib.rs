mod args;

pub struct DocsRepo {
    pub location: String, // use File
}

impl DocsRepo {
    pub fn search_titles() {}
    pub fn search_contents() {}
}

pub struct DocSet;

impl DocSet {
    fn filter() {}
    pub fn get_doc() {}
    pub fn get_docs() {}
}

pub struct Doc;

impl Doc {
    pub fn view() {}
    pub fn edit() {}
    pub fn run() {}
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
