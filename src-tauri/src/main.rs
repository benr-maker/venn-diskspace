// Hides the terminal window on Windows release builds.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod scanner;

use scanner::get_directory_tree;
use std::path::Path;

#[tauri::command]
fn scan_directory(path: String) -> Result<scanner::DirNode, String> {
    let p = Path::new(&path);
    if !p.is_absolute() {
        return Err("Path must be absolute".to_string());
    }
    if !p.is_dir() {
        return Err("Path does not exist or is not a directory".to_string());
    }
    Ok(get_directory_tree(p))
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![scan_directory])
        .run(tauri::generate_context!())
        .expect("error running Venn Diskspace");
}
