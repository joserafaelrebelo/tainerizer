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

### X11 GUI applications

Enable X11 forwarding for desktop viewers, simulators, and other GUI applications:

```bash
GUI=1 ./scripts/run_docker.sh cuda130-devel
# Equivalent Make target:
make run CUDA=13.0 FLAVOR=devel GUI=1
```

The GUI override forwards the host display and Xauthority credentials, mounts the
X11 socket, and enables the NVIDIA `graphics` and `display` driver capabilities
through `NVIDIA_DRIVER_CAPABILITIES=all`. GPU devices continue to be allocated by
the base Compose configuration (`DOCKER_GPUS=all` by default), so the host must
have a working NVIDIA driver and NVIDIA Container Toolkit installation.

Verify GPU access independently of the GUI application with:

```bash
GUI=1 ./scripts/run_docker.sh cuda130-devel nvidia-smi
```

GUI mode requires an active X11 or XWayland session with `DISPLAY` set. If your
Xauthority file is elsewhere, pass it explicitly:

```bash
GUI=1 XAUTHORITY=/path/to/.Xauthority ./scripts/run_docker.sh cuda130-devel
```

Headless behavior remains the default when `GUI` is unset or set to `0`.

## Apptainer Usage

Build a `.sif` by pulling directly from Docker Hub via Apptainer (no Docker required).
Pass any Docker Hub image reference as the argument:

```bash
./scripts/build_apptainer.sh rafaeljose/tainerized:cu13-runtime
./scripts/build_apptainer.sh rafaeljose/tainerized:cu13-devel
```

Optional fakeroot build:

```bash
APPTAINER_FAKEROOT=1 ./scripts/build_apptainer.sh rafaeljose/tainerized:cu13-runtime
```

Useful options:

```bash
# Custom output directory
DIST_DIR=dist ./scripts/build_apptainer.sh rafaeljose/tainerized:cu13-runtime

# Override the image (e.g. for CI pin)
IMAGE_TAG_OVERRIDE=rafaeljose/tainerized:cu13-devel ./scripts/build_apptainer.sh ignored
```

Run Apptainer with all binds and GPU enabled:

```bash
./scripts/run_apptainer.sh dist/rafaeljose_tainerized_cu13-runtime.sif
./scripts/run_apptainer.sh dist/rafaeljose_tainerized_cu13-runtime.sif bash -lc 'cd "$WORKSPACE_CONTAINER_DIR" && nvidia-smi'
```

## Slurm Interactive Session

Start an interactive shell on a Slurm node with GPU, all repo bind mounts, and your `.env` config loaded:

```bash
./scripts/slurm_interactive.sh dist/rafaeljose_tainerized_cu13-runtime.sif
```

Override any Slurm resource defaults via env vars:

```bash
SLURM_TIME=08:00:00 SLURM_PARTITION=gpu SLURM_GPUS=2 \
  ./scripts/slurm_interactive.sh dist/rafaeljose_tainerized_cu13-runtime.sif
```

Available overrides (with defaults):

| Variable           | Default     |
|--------------------|-------------|
| `SLURM_NODES`      | `1`         |
| `SLURM_NTASKS`     | `1`         |
| `SLURM_CPUS`       | `16`        |
| `SLURM_MEM`        | `64G`       |
| `SLURM_GPUS`       | `1`         |
| `SLURM_TIME`       | `04:00:00`  |
| `SLURM_PARTITION`  | `ovx01`     |
| `SLURM_ACCOUNT`    | *(unset)*   |

The workspace, HuggingFace cache, and uv cache are mounted exactly as in Docker (driven by `.env`).

## Slurm Batch Usage

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