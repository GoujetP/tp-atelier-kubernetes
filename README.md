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
