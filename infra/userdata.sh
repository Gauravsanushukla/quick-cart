#!/bin/bash
dnf update -y
dnf install -y python3 python3-pip git nginx

# 1. Setup Backend (FastAPI)
mkdir -p /app/backend
cat << 'EOF' > /app/backend/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="QuickCart API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

products_db = [
    {"id": 1, "name": "Quantum Anti-Gravity Pod", "price": 49999, "category": "Core", "in_stock": True},
    {"id": 2, "name": "Magnetic Levitation Boots", "price": 12499, "category": "Wearables", "in_stock": True},
    {"id": 3, "name": "Ion-Propulsion Thruster Mini", "price": 28999, "category": "Propulsion", "in_stock": False},
    {"id": 4, "name": "Zero-G Stabilizer Ring", "price": 7999, "category": "Accessories", "in_stock": True}
]

@app.get("/health")
def health():
    return {"status": "healthy", "service": "FastAPI ASGI"}

@app.get("/api/products")
def get_products():
    return products_db
EOF

pip3 install fastapi uvicorn

# 2. Setup Systemd Service for FastAPI
cat << 'EOF' > /etc/systemd/system/fastapi.service
[Unit]
Description=FastAPI Uvicorn Application
After=network.target

[Service]
User=root
WorkingDirectory=/app/backend
ExecStart=/usr/local/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now fastapi

# 3. Setup Frontend (Anti-Gravity UI)
mkdir -p /usr/share/nginx/html
cat << 'EOF' > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>QuickCart — Anti-Gravity Store</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    body { background: radial-gradient(circle at center, #111827, #030712); min-height: 100vh; overflow-x: hidden; }
    canvas { position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; z-index: 0; pointer-events: none; }
    .glass { background: rgba(255, 255, 255, 0.04); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.1); }
    .floating-card { transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1); }
    .floating-card:hover { transform: translateY(-8px) scale(1.02); }
  </style>
</head>
<body class="text-white min-h-screen relative font-sans">
  <canvas id="antiGravityCanvas"></canvas>
  <div class="relative z-10 max-w-6xl mx-auto px-6 py-10">
    <header class="flex justify-between items-center pb-8 border-b border-gray-800">
      <div>
        <h1 class="text-4xl font-extrabold tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-teal-400 via-indigo-400 to-purple-500">
          ?? QuickCart Anti-Gravity
        </h1>
        <p class="text-gray-400 text-sm mt-1">AWS Multi-AZ Deployment with FastAPI Engine</p>
      </div>
      <div>
        <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
          <span class="w-2 h-2 rounded-full bg-emerald-400 mr-2 animate-pulse"></span> ASG Health OK
        </span>
      </div>
    </header>
    <main class="mt-12">
      <h2 class="text-2xl font-bold mb-6 text-gray-200">Levitation Fleet Catalog</h2>
      <div id="productGrid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"></div>
    </main>
  </div>
  <script>
    const canvas = document.getElementById('antiGravityCanvas');
    const ctx = canvas.getContext('2d');
    let particles = [];
    function resize() { canvas.width = window.innerWidth; canvas.height = window.innerHeight; }
    window.addEventListener('resize', resize);
    resize();
    class Particle {
      constructor() { this.reset(); }
      reset() {
        this.x = Math.random() * canvas.width;
        this.y = canvas.height + Math.random() * 50;
        this.size = Math.random() * 2.5 + 0.5;
        this.speedY = Math.random() * 0.8 + 0.3;
        this.speedX = (Math.random() - 0.5) * 0.4;
        this.opacity = Math.random() * 0.6 + 0.2;
      }
      update() { this.y -= this.speedY; this.x += this.speedX; if (this.y < -10) this.reset(); }
      draw() {
        ctx.fillStyle = 'rgba(129, 140, 248, ' + this.opacity + ')';
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
        ctx.fill();
      }
    }
    for (let i = 0; i < 70; i++) particles.push(new Particle());
    function animate() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      particles.forEach(p => { p.update(); p.draw(); });
      requestAnimationFrame(animate);
    }
    animate();

    function renderProducts(items) {
      const container = document.getElementById('productGrid');
      container.innerHTML = items.map(p => 
        <div class="glass floating-card rounded-2xl p-6 flex flex-col justify-between">
          <div>
            <span class="text-xs font-semibold px-2.5 py-1 rounded bg-indigo-500/20 text-indigo-300 border border-indigo-500/30">\</span>
            <h3 class="text-lg font-bold text-white mt-4">\</h3>
            <p class="text-xs text-gray-400 mt-1">\</p>
          </div>
          <div class="mt-6 flex items-center justify-between">
            <span class="text-xl font-black text-indigo-300">?\</span>
            <button class="bg-indigo-600 hover:bg-indigo-500 text-white text-xs px-4 py-2 rounded-lg font-semibold shadow-lg shadow-indigo-600/30 transition">Deploy</button>
          </div>
        </div>
      ).join('');
    }

    fetch('/api/products')
      .then(res => res.json())
      .then(data => renderProducts(data))
      .catch(() => {
        renderProducts([
          { id: 1, name: "Quantum Anti-Gravity Pod", price: 49999, category: "Core", in_stock: true },
          { id: 2, name: "Magnetic Levitation Boots", price: 12499, category: "Wearables", in_stock: true },
          { id: 3, name: "Ion-Propulsion Thruster Mini", price: 28999, category: "Propulsion", in_stock: false },
          { id: 4, name: "Zero-G Stabilizer Ring", price: 7999, category: "Accessories", in_stock: true }
        ]);
      });
  </script>
</body>
</html>
EOF

# 4. Configure Nginx Reverse Proxy for Frontend + FastAPI
cat << 'EOF' > /etc/nginx/conf.d/quickcart.conf
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files \ \/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \System.Management.Automation.Internal.Host.InternalHost;
        proxy_set_header X-Real-IP \;
        proxy_set_header X-Forwarded-For \;
        proxy_set_header X-Forwarded-Proto \;
    }

    location /health {
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

# Restart Nginx
systemctl restart nginx
systemctl enable nginx
