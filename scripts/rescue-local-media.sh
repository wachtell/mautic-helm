#!/usr/bin/env bash
# One-time rescue before upgrading to chart 0.2.1+ (explicit media/images and
# media/files mounts).
#
# The Mautic image declares VOLUMEs at docroot/media/images and media/files.
# Older chart versions only mounted the shared media PVC at docroot/media, so
# the container runtime put a per-pod local directory on top of those two
# paths: uploads landed on whichever pod handled the request and vanished when
# the pod was recreated.
#
# This copies everything from each running web pod's local images/ and files/
# onto the shared volume, never overwriting a file that is already there, and
# hands it to www-data. Run it with your admin kubeconfig right before
# `helm upgrade`, and don't upload anything in between.
set -euo pipefail

NS=mautic
DEPLOY=mautic-mautic
PVC=mautic-mautic-media
SELECTOR=app.kubernetes.io/name=mautic,app.kubernetes.io/instance=mautic
HELPER=media-rescue

# Same image as the web pods: GNU tar (--skip-old-files) and the www-data uid
IMAGE=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}')

echo "Starting helper pod with the shared media volume at /pvc ..."
kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $HELPER
spec:
  restartPolicy: Never
  containers:
    - name: rescue
      image: $IMAGE
      command: ["sleep", "3600"]
      volumeMounts:
        - name: media
          mountPath: /pvc
  volumes:
    - name: media
      persistentVolumeClaim:
        claimName: $PVC
EOF
kubectl wait -n "$NS" --for=condition=Ready "pod/$HELPER" --timeout=180s
kubectl exec -n "$NS" "$HELPER" -- mkdir -p /pvc/images /pvc/files

for POD in $(kubectl get pods -n "$NS" -l "$SELECTOR" -o name); do
  POD=${POD#pod/}
  for DIR in images files; do
    echo "== $POD: media/$DIR"
    kubectl exec -n "$NS" "$POD" -c mautic -- tar -C "/var/www/html/docroot/media/$DIR" -cf - . \
      | kubectl exec -i -n "$NS" "$HELPER" -- tar -C "/pvc/$DIR" -xvf - --skip-old-files
  done
done

kubectl exec -n "$NS" "$HELPER" -- chown -R 33:33 /pvc/images /pvc/files
echo
echo "Now on the shared volume:"
kubectl exec -n "$NS" "$HELPER" -- sh -c 'echo "images/:"; ls -la /pvc/images; echo; echo "files/:"; ls -la /pvc/files'

kubectl delete pod -n "$NS" "$HELPER" --wait=false
echo
echo "Done. Now run helm upgrade with the fixed chart, without uploading anything first."
