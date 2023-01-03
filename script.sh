{
  ### Clone this repo to get the manifests
  git clone --depth 1 https://github.com/kodekloudhub/kubernetes-challenges.git

  ### Create PV directories on node01
  # See https://www.cyberciti.biz/faq/unix-linux-execute-command-using-ssh/
  ssh node01 'for i in $(seq 1 6) ; do mkdir "/redis0$i" ; done'

  ### Create PVs
  for i in $(seq 1 6)
  do
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis0$i
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /redis0$i
EOF
  done

  ### Create service
  kubectl apply -f kubernetes-challenges/challenge-4/redis-cluster-service.yaml

  ### Create redis-cluster
  kubectl apply -f kubernetes-challenges/challenge-4/redis-statefulset.yaml

  # It takes about a minute for all pods to be running
  echo "Waiting up to 120s for all pods in statefulset to start"
  sleep 15 # First pod needs to appear before following wait will work
  kubectl wait --for jsonpath='{.status.readyReplicas}'=6 statefulset/redis-cluster --timeout 105s

  if [ $? -ne 0 ]
  then
      echo "The statefulset did not start correctly. Please reload the lab and try again."
      echo "If the issue persists, please report it in Slack in kubernetes-challenges channel"
      echo "https://kodekloud.slack.com/archives/C02LS58EGQ4"
      cd ~
      echo "Press CTRL-C to exit"
      read x
  fi

  ### Cluster config.
  # Here we have to automatically answer the question, so we pipe "yes" into the command
  echo "yes" | kubectl exec -it redis-cluster-0 -- redis-cli --cluster create --cluster-replicas 1 \
      $(kubectl get pods -l app=redis-cluster -o jsonpath='{range.items[*]}{.status.podIP}:6379 {end}')

  echo -e "\nAutomation complete. Press the Check button.\n"
}