# Paperclip Helm Chart

A Helm chart for deploying [Paperclip](https://github.com/paperclipai/paperclip) — an AI-agent control plane — to a Kubernetes cluster in **authenticated** mode.

Designed for local minikube use, but works on any Kubernetes cluster.

## Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/start/) (or any K8s cluster)
- [Helm](https://helm.sh/docs/intro/install/) 3.x
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quickstart (minikube)

```bash
# 1. Start minikube (if not running)
minikube start

# 2. Generate an auth secret (64-char hex)
export AUTH_SECRET=$(openssl rand -hex 32)

# 3. Install the chart
helm install paperclip ./papaerclip-chart \
  --set auth.secret=$AUTH_SECRET

# 4. Get the access URL
minikube service paperclip --url

# 5. Check the logs for the board-claim URL on first login
kubectl logs deploy/paperclip | grep board-claim
```

Open the URL from step 4 in your browser. On first visit, register a user,
then use the board-claim URL from the logs to claim board ownership.

## Setting a Public URL

For auth callbacks to work correctly, set the public URL to the actual minikube service address:

```bash
export MINIKUBE_URL=$(minikube service paperclip --url)

helm upgrade paperclip ./papaerclip-chart \
  --set auth.secret=$AUTH_SECRET \
  --set paperclip.publicUrl=$MINIKUBE_URL
```

## Configuration

### Core Values

| Key | Default | Description |
|-----|---------|-------------|
| `image.repository` | `ghcr.io/paperclipai/paperclip` | Container image |
| `image.tag` | `""` (appVersion) | Image tag |
| `image.pullPolicy` | `IfNotPresent` | Pull policy |
| `replicaCount` | `1` | Pod replicas (only 1 with embedded PGlite) |

### Paperclip Server

| Key | Default | Description |
|-----|---------|-------------|
| `paperclip.deploymentMode` | `authenticated` | `local_trusted` or `authenticated` |
| `paperclip.deploymentExposure` | `private` | `private` or `public` |
| `paperclip.publicUrl` | `""` | Public URL for auth callbacks |
| `paperclip.home` | `/paperclip` | Data directory in the container |
| `paperclip.host` | `0.0.0.0` | Bind address |
| `paperclip.port` | `3100` | Listen port |
| `paperclip.serveUi` | `true` | Serve built UI |

### Authentication

| Key | Default | Description |
|-----|---------|-------------|
| `auth.secret` | `""` | **Required.** BETTER_AUTH_SECRET (64-char hex) |
| `auth.existingSecret` | `""` | Use a pre-created K8s Secret instead |
| `auth.existingSecretKey` | `BETTER_AUTH_SECRET` | Key in the existing secret |

### Adapter API Keys

| Key | Default | Description |
|-----|---------|-------------|
| `adapters.openaiApiKey` | `""` | OpenAI / Codex API key |
| `adapters.anthropicApiKey` | `""` | Anthropic / Claude API key |

### Service

| Key | Default | Description |
|-----|---------|-------------|
| `service.type` | `NodePort` | Service type |
| `service.port` | `3100` | Service port |
| `service.nodePort` | `31000` | NodePort port (when type=NodePort) |

### Persistence

| Key | Default | Description |
|-----|---------|-------------|
| `persistence.enabled` | `true` | Enable PVC for `/paperclip` |
| `persistence.storageClass` | `""` | Storage class (empty = default) |
| `persistence.size` | `5Gi` | Volume size |
| `persistence.accessMode` | `ReadWriteOnce` | Access mode |

### In-cluster PostgreSQL (optional)

By default, Paperclip uses embedded PGlite (no external database). Enable
in-cluster PostgreSQL when you need a dedicated database:

| Key | Default | Description |
|-----|---------|-------------|
| `postgresql.enabled` | `false` | Deploy PostgreSQL StatefulSet |
| `postgresql.image.repository` | `postgres` | PostgreSQL image |
| `postgresql.image.tag` | `17-alpine` | PostgreSQL tag |
| `postgresql.auth.username` | `paperclip` | DB username |
| `postgresql.auth.password` | `paperclip` | DB password |
| `postgresql.auth.database` | `paperclip` | DB name |
| `postgresql.persistence.size` | `5Gi` | PG data volume size |

```bash
# Install with in-cluster PostgreSQL
helm install paperclip ./papaerclip-chart \
  --set auth.secret=$AUTH_SECRET \
  --set postgresql.enabled=true
```

### External Database

Connect to an existing PostgreSQL instance instead:

| Key | Default | Description |
|-----|---------|-------------|
| `externalDatabase.url` | `""` | Full `postgres://` connection URL |

```bash
helm install paperclip ./papaerclip-chart \
  --set auth.secret=$AUTH_SECRET \
  --set externalDatabase.url="postgres://user:pass@host:5432/paperclip"
```

## Using an Existing Secret

To avoid passing `auth.secret` on the command line:

```bash
# Create a secret manually
kubectl create secret generic paperclip-auth \
  --from-literal=BETTER_AUTH_SECRET=$(openssl rand -hex 32)

# Reference it
helm install paperclip ./papaerclip-chart \
  --set auth.existingSecret=paperclip-auth
```

## Uninstall

```bash
helm uninstall paperclip
# Optionally delete the PVC to remove all data
kubectl delete pvc paperclip
```

## Troubleshooting

### Pod stuck in CrashLoopBackOff

Check logs:
```bash
kubectl logs deploy/paperclip --previous
```

The most common cause is a missing or invalid `BETTER_AUTH_SECRET`.

### Auth redirects failing

Set `paperclip.publicUrl` to the actual URL you access the UI at:
```bash
helm upgrade paperclip ./papaerclip-chart \
  --set auth.secret=$AUTH_SECRET \
  --set paperclip.publicUrl=http://192.168.49.2:31000
```

### Board claim

On first startup in authenticated mode, the server logs contain a one-time
claim URL. Retrieve it with:
```bash
kubectl logs deploy/paperclip | grep board-claim
```

## License

MIT — matching the [Paperclip](https://github.com/paperclipai/paperclip) project.
