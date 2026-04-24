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

### Accéder à l'UI ArgoCD (Solution Multipass/VirtualBox)
Sur Windows avec Multipass + VirtualBox, l'IP de la VM est bloquée par un NAT. La façon la plus simple d'accéder à l'interface est d'utiliser un tunnel Cloudflare temporaire gratuit.

Transférez le script et exécutez-le sur la VM :
```bash
multipass transfer start-argocd-ui.sh k3s-master:start-argocd-ui.sh
multipass exec k3s-master -- bash start-argocd-ui.sh
```

SI ça prend plus de 6 sec faire cette commande sur la vm et regarder dans les logs pour voir l'url : 
```
cat /tmp/cloudflare.log
```
Le script affichera une URL publique de type `https://<nom-aleatoire>.trycloudflare.com`.

# Login: admin / U9qjVyw08zZfr-wm

### Tester le déploiement automatique (GitOps)
Toute modification pushée sur `main` dans `k8s/` est automatiquement répercutée dans le cluster (selfHeal + prune activés).
```
# Modifier un manifest, puis :
git add k8s/ && git commit -m "update" && git push origin main
# ArgoCD sync automatiquement dans les ~3 minutes
```

## Étape 6 — Déploiement multi-environnement (Dev / Prod)

Pour gérer deux environnements (Développement et Production), nous utilisons **Kustomize** avec la structure suivante :

```
k8s/
├── base/                   # Manifests communs (Deployment, Service, etc.)
└── overlays/
    ├── dev/                # Surcharge pour l'environnement DEV
    └── prod/               # Surcharge pour l'environnement PROD
```

### 1. Applications ArgoCD par environnement

Nous avons défini deux applications distinctes dans ArgoCD :
- `argocd-app-dev.yaml` : pointe vers `k8s/overlays/dev` et déploie dans le namespace `dev`.
- `argocd-app-prod.yaml` : pointe vers `k8s/overlays/prod` et déploie dans le namespace `prod`.

### 2. Appliquer les environnements

Transférez et appliquez les manifests sur le cluster :
```bash
multipass transfer argocd-app-dev.yaml k3s-master:argocd-app-dev.yaml
multipass transfer argocd-app-prod.yaml k3s-master:argocd-app-prod.yaml
multipass exec k3s-master -- sudo kubectl apply -f argocd-app-dev.yaml
multipass exec k3s-master -- sudo kubectl apply -f argocd-app-prod.yaml
```

### 3. Vérification des environnements isolés

Chaque environnement tourne dans son propre namespace et sur son propre NodePort (30083 pour dev, 30082 pour prod) :
```bash
# Vérifier l'environnement DEV (1 replica)
multipass exec k3s-master -- sudo kubectl get pods,svc -n dev

# Vérifier l'environnement PROD (2 replicas)
multipass exec k3s-master -- sudo kubectl get pods,svc -n prod
```

### 4. Cycle de vie Git (Git Flow)

Pour tester une évolution :
1. Modifiez `k8s/overlays/dev/deployment-patch.yaml` (ex: changer l'image Docker).
2. Poussez sur `main` : ArgoCD mettra à jour l'environnement de DEV.
3. Une fois validé, reportez la modification dans `k8s/overlays/prod/deployment-patch.yaml` pour déployer en PROD.