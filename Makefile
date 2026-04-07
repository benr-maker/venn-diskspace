all: dev

# Install Tauri CLI and Rust dependencies
setup:
	npm install
	rustup target add aarch64-apple-darwin x86_64-apple-darwin  # macOS universal

# Run in development mode (hot-reload)
dev:
	npm run tauri dev

# Build release binary for the current platform
build:
	npm run tauri build

# Build universal macOS binary (arm64 + x86_64)
build-mac-universal:
	npm run tauri build -- --target universal-apple-darwin

clean:
	rm -rf src-tauri/target node_modules
