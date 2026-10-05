# Switching from the Bitnami MariaDB/Redis charts to the official MariaDB image

Chart 0.2.0 drops the Bitnami subcharts, whose `bitnamilegacy/*` images no
longer get updates:

- **MariaDB** now runs from the official `mariadb` image
  (`templates/mariadb.yaml`). It reuses the existing volume
  `data-mautic-mariadb-0` (the data lives in its `data/` subdirectory) and runs
  as uid 1001 like Bitnami, so file ownership on the volume doesn't change.
  The Secret and Service keep their names (`mautic-mariadb`) and keys, so
  Mautic, the backup and the migrate job need no changes. Passwords stay in
  `values-secret.yaml` under `mariadb.auth`.
- **Redis** is removed. Mautic only uses it when the cache adapter is set to
  Redis; the default is the filesystem (check: `cache_adapter` doesn't appear
  in `config/local.php`).

## Switchover (one-time, ~5 minutes of downtime)

Helm creates the new StatefulSet before deleting the old one. To keep the two
database servers from ever running on the same volume at once, the new one is
first created with 0 pods and started by hand once the old one has stopped.

Run with your admin kubeconfig, from the chart directory.

1. **Fresh dump** in addition to the nightly backup:

   ```bash
   kubectl create job --from=cronjob/mautic-mautic-db-backup pre-switch-backup -n mautic
   kubectl wait --for=condition=complete job/pre-switch-backup -n mautic --timeout=300s
   kubectl logs job/pre-switch-backup -n mautic | tail -5    # newest mautic-*.sql.gz, non-trivial size
   ```

2. **Note the current Helm revision** (needed for a rollback):

   ```bash
   helm history mautic -n mautic | tail -1
   ```

3. **Upgrade with the new database at 0 pods.** The `db-migrate` job still
   runs against the old server first. Helm then removes the Bitnami MariaDB
   and Redis StatefulSets; the old server shuts down cleanly.

   ```bash
   helm upgrade mautic . -n mautic -f values-production.yaml -f values-secret.yaml --set mariadb.replicas=0
   kubectl wait --for=delete pod/mautic-mariadb-0 -n mautic --timeout=300s
   ```

4. **Start the new server** and watch it come up. On first start it runs
   `mariadb-upgrade` for the patch-level jump (`MARIADB_AUTO_UPGRADE`).

   ```bash
   kubectl scale statefulset mautic-mautic-mariadb -n mautic --replicas=1
   kubectl logs -f mautic-mautic-mariadb-0 -n mautic     # until "ready for connections"; Ctrl+C
   kubectl rollout status statefulset/mautic-mautic-mariadb -n mautic
   ```

5. **Check** that the web pods are Ready, `https://mautic.wachtell.net/` loads
   and the next cron runs complete:

   ```bash
   kubectl get pods -n mautic
   kubectl get jobs -n mautic --sort-by=.metadata.creationTimestamp | tail -5
   ```

Later `helm upgrade`s need no `--set`; `mariadb.replicas` is 1 in the values.

## Rollback

```bash
helm rollback mautic <revision from step 2> -n mautic
```

This brings back the Bitnami StatefulSets on the same volume (ownership is
unchanged). If the data itself is damaged, restore the dump from step 1:

```bash
gunzip -c <dump>.sql.gz | kubectl exec -i -n mautic <mariadb pod> -- \
  sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD"'
```

## Afterwards

- After a week without problems, delete the leftover Redis volume:
  `kubectl delete pvc redis-data-mautic-redis-master-0 -n mautic`
- Patch updates: bump `mariadb.image` (e.g. `11.8.10`) and `helm upgrade`;
  `MARIADB_AUTO_UPGRADE` handles the system tables. Take a dump before minor or
  major version jumps.
