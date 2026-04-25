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
    <title>DrupalForge Interactive Demo</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
EOF

mkdir -p src

cat > src/main.js <<'EOF'
import './style.css'

const app = document.querySelector('#app')

app.innerHTML = `
  <main class="page">
    <section class="hero">
      <div class="badge">DrupalForge Demo Template</div>

      <h1>Launch your app faster</h1>

      <p>
        This is a Bun + Vite demo running inside your DevPanel / DrupalForge
        template test environment.
      </p>

      <div class="actions">
        <button id="colorBtn">Change Theme</button>
        <button id="countBtn">Click Counter: <span id="count">0</span></button>
      </div>

      <div class="card-grid">
        <div class="card">
          <h2>Fast setup</h2>
          <p>Generated during template initialization.</p>
        </div>
        <div class="card">
          <h2>Static hosting</h2>
          <p>Built with Vite and served by nginx on port 80.</p>
        </div>
        <div class="card">
          <h2>Ready to test</h2>
          <p>Use this to verify purchase, deploy, and app access flow.</p>
        </div>
      </div>
    </section>
  </main>
`

let count = 0
let theme = 0

const themes = [
  ['#7c3aed', '#06b6d4'],
  ['#f97316', '#ec4899'],
  ['#16a34a', '#84cc16'],
  ['#2563eb', '#9333ea']
]

document.querySelector('#countBtn').addEventListener('click', () => {
  count++
  document.querySelector('#count').textContent = count
})

document.querySelector('#colorBtn').addEventListener('click', () => {
  theme = (theme + 1) % themes.length
  document.documentElement.style.setProperty('--primary', themes[theme][0])
  document.documentElement.style.setProperty('--secondary', themes[theme][1])
})
EOF

cat > src/style.css <<'EOF'
:root {
  --primary: #7c3aed;
  --secondary: #06b6d4;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: Inter, Arial, sans-serif;
  color: white;
  background:
    radial-gradient(circle at top left, var(--secondary), transparent 35%),
    linear-gradient(135deg, var(--primary), #111827 70%);
  min-height: 100vh;
}

.page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 32px;
}

.hero {
  width: min(960px, 100%);
  padding: 48px;
  border-radius: 28px;
  background: rgba(255, 255, 255, 0.12);
  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.28);
  backdrop-filter: blur(14px);
}

.badge {
  display: inline-block;
  padding: 8px 14px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.18);
  font-weight: 700;
  letter-spacing: 0.04em;
}

h1 {
  margin: 22px 0 12px;
  font-size: clamp(40px, 7vw, 76px);
  line-height: 0.95;
}

p {
  font-size: 18px;
  line-height: 1.6;
  opacity: 0.9;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  margin: 28px 0;
}

button {
  border: 0;
  padding: 14px 20px;
  border-radius: 14px;
  color: #111827;
  background: white;
  font-size: 16px;
  font-weight: 800;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

button:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.25);
}

.card-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 18px;
  margin-top: 24px;
}

.card {
  padding: 22px;
  border-radius: 22px;
  background: rgba(255, 255, 255, 0.16);
}

.card h2 {
  margin: 0 0 8px;
}

.card p {
  margin: 0;
  font-size: 15px;
}

@media (max-width: 760px) {
  .hero {
    padding: 28px;
  }

  .card-grid {
    grid-template-columns: 1fr;
  }
}
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