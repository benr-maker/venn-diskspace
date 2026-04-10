#!/usr/bin/env bash
# release.sh — sets up prerequisites, builds, and publishes a GitHub release
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── helpers ───────────────────────────────────────────────────────────────────
info()    { echo ""; echo "▶ $*"; }
success() { echo "  ✓ $*"; }
error()   { echo ""; echo "ERROR: $*" >&2; exit 1; }

ask() {
    local prompt="$1" default="$2" answer
    read -r -p "  $prompt [$default]: " answer
    echo "${answer:-$default}"
}

# ── 1. prerequisites ──────────────────────────────────────────────────────────
info "Checking prerequisites..."

if ! command -v brew &>/dev/null; then
    error "Homebrew is required. Install it from https://brew.sh then re-run."
fi
success "Homebrew"

if ! command -v node &>/dev/null; then
    info "Installing Node.js..."
    brew install node
fi
success "Node.js $(node --version)"

if ! command -v rustup &>/dev/null; then
    info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi
success "Rust $(rustc --version)"

if ! command -v create-dmg &>/dev/null; then
    info "Installing create-dmg..."
    brew install create-dmg
fi
success "create-dmg"

if ! command -v gh &>/dev/null; then
    info "Installing GitHub CLI..."
    brew install gh
fi
success "GitHub CLI"

# ── 2. GitHub auth ────────────────────────────────────────────────────────────
info "Checking GitHub authentication..."
if ! gh auth status &>/dev/null; then
    echo "  You need to log in to GitHub."
    gh auth login
fi
GH_USER=$(gh api user --jq .login)
success "Logged in as $GH_USER"

# ── 3. gather inputs ──────────────────────────────────────────────────────────
info "Release configuration"
REPO_NAME=$(ask "GitHub repository name" "venn-diskspace")
VERSION=$(ask "Version" "1.0.0")
TAG="v${VERSION}"

# ── 4. build locally ──────────────────────────────────────────────────────────
info "Setting up build environment..."
make setup

info "Building app locally..."
make build
success "Local build succeeded"

# ── 5. git setup ──────────────────────────────────────────────────────────────
info "Setting up git repository..."

if [ ! -d ".git" ]; then
    git init
    success "Initialized git repository"
else
    success "Git repository already exists"
fi

git add .

if git diff --cached --quiet 2>/dev/null && git rev-parse HEAD &>/dev/null; then
    success "Nothing new to commit"
else
    git commit -m "Release $TAG"
    success "Committed"
fi

# ── 6. create GitHub repo ─────────────────────────────────────────────────────
info "Setting up GitHub repository..."

REMOTE_URL="https://github.com/$GH_USER/$REPO_NAME.git"

if gh repo view "$GH_USER/$REPO_NAME" &>/dev/null; then
    success "Repository $GH_USER/$REPO_NAME already exists"
else
    gh repo create "$REPO_NAME" --public
    success "Created $GH_USER/$REPO_NAME"
fi

if ! git remote get-url origin &>/dev/null; then
    git remote add origin "$REMOTE_URL"
else
    git remote set-url origin "$REMOTE_URL"
fi

# ── 7. push code ──────────────────────────────────────────────────────────────
info "Pushing code to GitHub..."
git push -u origin main
success "Code pushed"

# ── 8. tag and trigger CI ─────────────────────────────────────────────────────
info "Tagging release $TAG..."

if git tag | grep -q "^$TAG$"; then
    git tag -d "$TAG"
    git push origin --delete "$TAG" 2>/dev/null || true
fi

git tag "$TAG"
git push origin "$TAG"
success "Tag $TAG pushed — CI builds triggered"

# ── done ──────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Build in progress (~10 min). Monitor here:"
echo "  https://github.com/$GH_USER/$REPO_NAME/actions"
echo ""
echo "  Installers (Mac, Linux, Windows) will appear here:"
echo "  https://github.com/$GH_USER/$REPO_NAME/releases"
echo "══════════════════════════════════════════════════════"
