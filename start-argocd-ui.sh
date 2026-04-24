#!/bin/bash
# Expose ArgoCD via un tunnel Cloudflare gratuit
# Solution de contournement pour le NAT VirtualBox de Multipass

# 1. Telecharger cloudflared si absent
if [ ! -f "/tmp/cloudflared" ]; then
    echo "Telechargement de cloudflared..."
    curl -sL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" -o /tmp/cloudflared
    chmod +x /tmp/cloudflared
fi

# 2. Arreter les anciens tunnels
pkill -f "cloudflared tunnel" 2>/dev/null || true
rm -f /tmp/cloudflare.log
sleep 1

# 3. Lancer le tunnel vers le NodePort HTTPS d'ArgoCD (30081)
echo "Demarrage du tunnel..."
nohup /tmp/cloudflared tunnel --url https://127.0.0.1:30081 --no-tls-verify > /tmp/cloudflare.log 2>&1 &

# 4. Attendre et extraire l'URL
echo "En attente de l'URL publique (patientez 5-10 secondes)..."
sleep 6

URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' /tmp/cloudflare.log | head -1)

if [ -n "$URL" ]; then
    echo "=========================================================="
    echo "✅ ArgoCD UI est accessible publiquement via :"
    echo "🔗 $URL"
    echo "Login: admin / U9qjVyw08zZfr-wm"
    echo "=========================================================="
    echo "Note: Ce lien est temporaire et disparaitra au redemarrage."
else
    echo "❌ Erreur: Impossible d'obtenir l'URL. Logs :"
    cat /tmp/cloudflare.log
fi
