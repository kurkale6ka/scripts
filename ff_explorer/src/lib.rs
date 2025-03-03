pub fn get_help_files() -> Vec<String> {
    return ()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn help_dir_has_got_markdown_files() {
        let result = get_help_files();
        assert_ne!(result, ());
    }
}
