# Tainerizer: Reusable CUDA Containers

This folder provides reusable CUDA container variants and launcher scripts for experiment workspaces.

Defaults are intentionally generic: if `tainerizer` sits inside a larger workspace, setup detects the mounted host folder name and uses it inside `/workspace/<folder-name>`.

Example: if `WORKSPACE_HOST_BIND` points to an `IH` folder, the container workspace becomes `/workspace/IH`.

With default settings, container mounts are:

- host parent directory (`..`) to container `/workspace/<detected-folder-name>`
- host `../.cache/huggingface` to container `/workspace/<detected-folder-name>/.cache/huggingface`
- host `../.cache/uv` to container `/workspace/<detected-folder-name>/.cache/uv`
- host `../.cache/huggingface` to container `/root/.cache/huggingface`
- host `../.cache/uv` to container `/root/.cache/uv`

This keeps cache files persistent on host and also visible from inside the mounted workspace path.

## Services

Available images in `compose.yaml`:

- `cuda128-runtime`
- `cuda128-devel`
- `cuda130-runtime`
- `cuda130-devel`

## Configuration

Initialize configuration and directories:

```bash
make setup
```

This command:

- creates `.env` from `.env.example` if needed
- creates workspace/cache directories for bind mounts

Default `.env` values:

- `WORKSPACE_HOST_BIND=..`
- `HF_CACHE_BIND=../.cache/huggingface`
- `UV_CACHE_BIND=../.cache/uv`
- `DOCKER_GPUS=all`

Detected by `make setup` (unless manually overridden):

- `WORKSPACE_CONTAINER_DIR=/workspace/<detected-folder-name>`
- `HF_CACHE_CONTAINER_PATH=<WORKSPACE_CONTAINER_DIR>/.cache/huggingface`
- `UV_CACHE_CONTAINER_PATH=<WORKSPACE_CONTAINER_DIR>/.cache/uv`

If your workspace is elsewhere, set absolute paths in `.env`.

## Docker Usage

Build and run with Make targets:

```bash
make build CUDA=13.0 FLAVOR=devel
make run CUDA=13.0 FLAVOR=devel
```

Or with the script (recommended):

```bash
./scripts/run_docker.sh cuda130-devel
./scripts/run_docker.sh cuda130-devel bash -lc 'cd "$WORKSPACE_CONTAINER_DIR" && uv --version'
```

## Apptainer Usage

Build a `.sif` by pulling from Docker Hub (alias or full image reference):

```bash
# Alias (default if omitted: cuda130-devel)
./scripts/build_apptainer.sh cuda130-devel

# Full Docker image reference
./scripts/build_apptainer.sh nvidia/cuda:13.0.0-devel-ubuntu24.04
```

Optional fakeroot build:

```bash
APPTAINER_FAKEROOT=1 ./scripts/build_apptainer.sh cuda130-devel
```

Useful options:

```bash
# Custom output directory
DIST_DIR=dist ./scripts/build_apptainer.sh cuda130-runtime

# Skip pull and use local cached image
SKIP_DOCKER_PULL=1 ./scripts/build_apptainer.sh cuda130-devel
```

Run Apptainer with all binds and GPU enabled:

```bash
./scripts/run_apptainer.sh dist/nvidia_cuda_13.0.0-devel-ubuntu24.04.sif
./scripts/run_apptainer.sh dist/nvidia_cuda_13.0.0-devel-ubuntu24.04.sif bash -lc 'cd "$WORKSPACE_CONTAINER_DIR" && nvidia-smi'
```

## Slurm Usage

Submit the included Slurm wrapper:

```bash
sbatch ./scripts/slurm_job.sh
```

Run with Docker backend instead of Apptainer:

```bash
BACKEND=docker SERVICE=cuda130-devel JOB_CMD='cd "$WORKSPACE_CONTAINER_DIR" && python -V' sbatch ./scripts/slurm_job.sh
```

Run with Apptainer and explicit SIF path:

```bash
BACKEND=apptainer SIF_PATH=dist/cuda130-devel.sif JOB_CMD='cd "$WORKSPACE_CONTAINER_DIR" && python -V' sbatch ./scripts/slurm_job.sh
```

## Notes

- Working directory inside containers is `${WORKSPACE_CONTAINER_DIR}` and is auto-detected from `WORKSPACE_HOST_BIND` by `make setup`.
- CUDA image tag selection is defined per service in `compose.yaml`.
- The image includes `uv`, CUDA 12.8 and 13.0 toolkits, Python 3, and common build/runtime packages.