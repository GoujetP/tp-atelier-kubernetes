#!/bin/bash
# Script pour acceder a ArgoCD depuis Windows via socat
# socat cree un pont entre 0.0.0.0:30443 et le service ArgoCD

# Installer socat si besoin
if ! command -v socat &> /dev/null; then
    echo "Installation de socat..."
    sudo apt-get install -y socat -q
fi

# Kill tout port-forward et socat existants sur ces ports
pkill -f "kubectl.*port-forward.*argocd" 2>/dev/null
pkill -f "socat.*30443" 2>/dev/null
sleep 1

# Demarrer port-forward ArgoCD en local sur la VM
sudo kubectl -n argocd port-forward svc/argocd-server 9443:443 > /tmp/pf-argocd.log 2>&1 &
sleep 3

# Verifier que le port-forward est OK
if ! grep -q "Forwarding" /tmp/pf-argocd.log; then
    echo "ERREUR port-forward:"
    cat /tmp/pf-argocd.log
    exit 1
fi

# Utiliser socat pour exposer sur toutes les interfaces
sudo socat TCP-LISTEN:30443,fork,reuseaddr TCP:127.0.0.1:9443 &
SOCAT_PID=$!
sleep 1

echo "============================================"
echo "ArgoCD UI accessible depuis Windows sur :"
echo "https://10.0.2.15:30443"
echo "Mais cette IP n'est pas accessible depuis l'hote..."
echo ""
echo "Solution alternative: utiliser curl depuis la VM"
echo "============================================"

# Verifier le NodePort directement
echo ""
echo "NodePort ArgoCD (depuis l'interieur du cluster):"
sudo kubectl -n argocd get svc argocd-server

echo ""
echo "Test de connectivite locale:"
curl -sk https://127.0.0.1:9443 | grep -o '<title>.*</title>'
