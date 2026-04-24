# Commande 

## Sur machine hôte
Build le docker
```
docker build -t node-workshop-app:v1 . 
```

Lancer le docker 
```
docker run -d -p 3000:3000 --name test-app \
  -e DB_USER="mon_user_local" \
  -e DB_PASSWORD="mon_super_mot_de_passe" \
  node-workshop-app:v1
```

Transmettre le docker en .tar pour teter avant de le mettre sur un repo 
```
docker save node-workshop-app:v1 > node-app.tar
multipass transfer node-app.tar k3s-master:
```

Importer dans l'environnement d'exécution de K3s
```
multipass exec k3s-master -- sudo k3s ctr images import node-app.tar
```

Transférer deployment.yaml et l'appliquer
```
multipass transfer deployment.yaml k3s-master:
multipass exec k3s-master -- sudo k3s kubectl apply -f deployment.yaml
```

Voir les pods avec un alias pour multipass
```
alias kubectl='multipass exec k3s-master -- sudo k3s kubectl'
kubectl get pods -l app=node-workshop
```

Voir ip vm multipass 
```
multipass info k3s-master
```

Config.json
```
multipass transfer configmap.yaml k3s-master:
multipass transfer deployment.yaml k3s-master:
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
multipass exec k3s-master -- curl http://localhost:30080
```
MDP argo CD = U9qjVyw08zZfr-wm

## Étape 5 — GitOps avec ArgoCD

### Structure des manifests K8s
Les manifests sont dans le dossier `k8s/` pour éviter que ArgoCD parse les fichiers non-K8s (ex: package.json).
```
k8s/
├── deployment.yaml
├── service.yaml
├── configmap.yaml
└── secret.yaml
```

### Appliquer l'application ArgoCD
```
multipass transfer argocd-app.yaml k3s-master:argocd-app.yaml
multipass exec k3s-master -- sudo kubectl apply -f argocd-app.yaml
```

### Vérifier le statut de sync
```
multipass exec k3s-master -- sudo kubectl get application node-workshop-app -n argocd -o wide
```

### Vérifier les ressources déployées par ArgoCD
```
multipass exec k3s-master -- sudo kubectl get pods,svc,configmap,secret -n default
```

### Accéder à l'UI ArgoCD
```
multipass exec k3s-master -- sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0
# Puis ouvrir https://<IP_VM>:8080
# Login: admin / U9qjVyw08zZfr-wm
```

### Tester le déploiement automatique (GitOps)
Toute modification pushée sur `main` dans `k8s/` est automatiquement répercutée dans le cluster (selfHeal + prune activés).
```
# Modifier un manifest, puis :
git add k8s/ && git commit -m "update" && git push origin main
# ArgoCD sync automatiquement dans les ~3 minutes
```