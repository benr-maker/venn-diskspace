use serde::Serialize;
use std::fs;
use std::path::Path;

const MAX_DEPTH: u32 = 20;

#[derive(Serialize, Clone)]
pub struct DirNode {
    pub name: String,
    pub size: u64,
    pub files: u64,
    pub children: Vec<DirNode>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub skipped: Option<String>,
}

#[cfg(unix)]
fn device_id(path: &Path) -> Option<u64> {
    use std::os::unix::fs::MetadataExt;
    fs::symlink_metadata(path).map(|m| m.dev()).ok()
}

#[cfg(not(unix))]
fn device_id(_path: &Path) -> Option<u64> {
    // Cross-filesystem detection is Unix-only; skip on Windows.
    None
}

pub fn get_directory_tree(path: &Path) -> DirNode {
    let root_dev = device_id(path);
    build_node(path, 0, root_dev)
}

fn build_node(dir: &Path, depth: u32, root_dev: Option<u64>) -> DirNode {
    let name = dir
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or_else(|| dir.to_str().unwrap_or(""))
        .to_string();

    if depth > MAX_DEPTH {
        return DirNode { name, size: 0, files: 0, children: vec![], skipped: None };
    }

    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(e) if e.kind() == std::io::ErrorKind::PermissionDenied => {
            return DirNode { name, size: 0, files: 0, children: vec![], skipped: None };
        }
        Err(e) => {
            return DirNode {
                name,
                size: 0,
                files: 0,
                children: vec![],
                skipped: Some(e.to_string()),
            };
        }
    };

    let mut children: Vec<DirNode> = Vec::new();
    let mut total_size: u64 = 0;
    let mut total_files: u64 = 0;

    for entry in entries.flatten() {
        let entry_path = entry.path();
        let entry_name = entry.file_name().to_str().unwrap_or("").to_string();

        let Ok(file_type) = entry.file_type() else {
            continue;
        };

        if file_type.is_dir() {
            // Skip directories on a different filesystem (network mounts, external drives).
            if let Some(root_dev) = root_dev {
                if device_id(&entry_path).map_or(false, |d| d != root_dev) {
                    children.push(DirNode {
                        name: entry_name,
                        size: 0,
                        files: 0,
                        children: vec![],
                        skipped: Some("network/remote filesystem".to_string()),
                    });
                    continue;
                }
            }

            let child = build_node(&entry_path, depth + 1, root_dev);
            total_size += child.size;
            total_files += child.files;
            children.push(child);
        } else {
            if let Ok(meta) = entry.metadata() {
                total_size += meta.len();
                total_files += 1;
            }
        }
    }

    DirNode { name, size: total_size, files: total_files, children, skipped: None }
}
