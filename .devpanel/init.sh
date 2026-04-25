#!/usr/bin/env bash
if [ -n "${DEBUG_SCRIPT:-}" ]; then
  set -x
fi
set -eu -o pipefail

APP_ROOT="${APP_ROOT:-/usr/share/nginx/html}"

cd "$APP_ROOT"

mkdir -p logs
LOG_FILE="logs/init-$(date +%F-%T).log"
exec > >(tee "$LOG_FILE") 2>&1

echo
echo "Starting Bun + Vite demo setup..."

echo
echo "Install required packages."
if command -v apk >/dev/null 2>&1; then
  apk add --no-cache bash curl unzip nodejs npm
fi

echo
echo "Install Bun if needed."
if ! command -v bun >/dev/null 2>&1; then
  curl -fsSL https://bun.sh/install | bash
fi

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

bun --version

echo
echo "Create Vite demo app files."

cat > package.json <<'EOF'
{
  "name": "drupalforge-vite-demo",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "vite build",
    "dev": "vite --host 0.0.0.0"
  },
  "dependencies": {
    "vite": "^7.0.0"
  },
  "devDependencies": {}
}
EOF

cat > index.html <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>DrupalForge Demo Template</title>
  </head>
  <body>
    <main style="font-family: Arial, sans-serif; padding: 40px;">
      <h1>DrupalForge Demo Template</h1>
      <p>This demo page is running with Bun + Vite.</p>
      <p>If you can see this page, nginx is serving the built static files correctly.</p>
    </main>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
EOF

mkdir -p src

cat > src/main.js <<'EOF'
console.log("DrupalForge demo template loaded successfully.");
EOF

cat > vite.config.js <<'EOF'
import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    outDir: 'dist',
    emptyOutDir: true
  }
})
EOF

echo
echo "Install dependencies."
bun install

echo
echo "Build Vite demo app."
bun run build

echo
echo "Copy built files to nginx web root."
cp -r dist/* .

echo
echo "Clean build directory."
rm -rf dist || true

INIT_DURATION=$SECONDS
INIT_HOURS=$(($INIT_DURATION / 3600))
INIT_MINUTES=$(($INIT_DURATION % 3600 / 60))
INIT_SECONDS=$(($INIT_DURATION % 60))
printf "\nTotal elapsed time: %d:%02d:%02d\n" $INIT_HOURS $INIT_MINUTES $INIT_SECONDS