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