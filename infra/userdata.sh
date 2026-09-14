Set-Content -Path "userdata.sh" -Value @"
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo ">>> Starting Provisioning..."
dnf update -y
dnf install -y python3 python3-pip git nginx

# 1. Setup Backend
mkdir -p /app/backend
cat << 'EOF' > /app/backend/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="QuickCart API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/health")
def health():
    return {"status": "healthy", "service": "FastAPI ASGI"}

@app.get("/api/products")
def get_products():
    return [
        {"id": 1, "name": "Quantum Anti-Gravity Pod", "price": 49999, "category": "Core", "in_stock": True},
        {"id": 2, "name": "Magnetic Levitation Boots", "price": 12499, "category": "Wearables", "in_stock": True},
        {"id": 3, "name": "Ion-Propulsion Thruster Mini", "price": 28999, "category": "Propulsion", "in_stock": False},
        {"id": 4, "name": "Zero-G Stabilizer Ring", "price": 7999, "category": "Accessories", "in_stock": True}
    ]
EOF

pip3 install fastapi uvicorn --break-system-packages || pip3 install fastapi uvicorn

# 2. Systemd Service
cat << 'EOF' > /etc/systemd/system/fastapi.service
[Unit]
Description=FastAPI Uvicorn Service
After=network.target

[Service]
User=root
WorkingDirectory=/app/backend
ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now fastapi

# 3. Setup Frontend
mkdir -p /usr/share/nginx/html
cat << 'EOF' > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>QuickCart — Anti-Gravity Store</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    body { background: radial-gradient(circle at center, #111827, #030712); min-height: 100vh; overflow-x: hidden; }
    canvas { position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; z-index: 0; pointer-events: none; }
    .glass { background: rgba(255, 255, 255, 0.04); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.1); }
  </style>
</head>
<body class="text-white min-h-screen relative font-sans">
  <canvas id="antiGravityCanvas"></canvas>
  <div class="relative z-10 max-w-6xl mx-auto px-6 py-10">
    <header class="flex justify-between items-center pb-8 border-b border-gray-800">
      <h1 class="text-4xl font-extrabold tracking-tight text-indigo-400">🌌 QuickCart Anti-Gravity</h1>
      <span class="px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">🟢 ASG Active</span>
    </header>
    <main class="mt-12">
      <h2 class="text-2xl font-bold mb-6 text-gray-200">Catalog</h2>
      <div id="productGrid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"></div>
    </main>
  </div>
  <script>
    const canvas = document.getElementById('antiGravityCanvas');
    const ctx = canvas.getContext('2d');
    let particles = [];
    function resize() { canvas.width = window.innerWidth; canvas.height = window.innerHeight; }
    window.addEventListener('resize', resize); resize();
    class Particle {
      constructor() { this.reset(); }
      reset() {
        this.x = Math.random() * canvas.width;
        this.y = canvas.height + 20;
        this.size = Math.random() * 2 + 1;
        this.speedY = Math.random() * 0.8 + 0.3;
        this.opacity = Math.random() * 0.6 + 0.2;
      }
      update() { this.y -= this.speedY; if (this.y < -10) this.reset(); }
      draw() { ctx.fillStyle = 'rgba(129, 140, 248,'+this.opacity+')'; ctx.beginPath(); ctx.arc(this.x, this.y, this.size, 0, Math.PI*2); ctx.fill(); }
    }
    for (let i=0; i<50; i++) particles.push(new Particle());
    function animate() { ctx.clearRect(0, 0, canvas.width, canvas.height); particles.forEach(p => { p.update(); p.draw(); }); requestAnimationFrame(animate); }
    animate();

    function render(data) {
      document.getElementById('productGrid').innerHTML = data.map(p => `
        <div class="glass p-6 rounded-xl border border-gray-800">
          <span class="text-xs bg-indigo-500/20 text-indigo-300 px-2 py-1 rounded">\${p.category}</span>
          <h3 class="font-bold text-lg text-white mt-3">\${p.name}</h3>
          <p class="text-xl font-bold text-indigo-400 mt-4">₹\${p.price.toLocaleString()}</p>
        </div>
      `).join('');
    }
    fetch('/api/products').then(r => r.json()).then(render).catch(() => {
      render([
        { id: 1, name: "Quantum Anti-Gravity Pod", price: 49999, category: "Core" },
        { id: 2, name: "Magnetic Levitation Boots", price: 12499, category: "Wearables" }
      ]);
    });
  </script>
</body>
</html>
EOF

# 4. Nginx Reverse Proxy Config
cat << 'EOF' > /etc/nginx/conf.d/default.conf
server {
    listen 80 default_server;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /health {
        proxy_pass http://127.0.0.1:8000/health;
    }
}
EOF

# Ensure SELinux allows Nginx proxying
setsebool -P httpd_can_network_connect 1 || true

systemctl restart nginx
systemctl enable nginx
echo ">>> Provisioning Complete!"
"@