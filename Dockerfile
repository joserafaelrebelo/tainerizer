ARG CUDA_IMAGE=nvidia/cuda:12.8.1-runtime-ubuntu24.04
FROM ${CUDA_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG PRIMARY_CUDA=12.8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        ffmpeg \
        git \
        git-lfs \
        gnupg \
        less \
        python3 \
        python3-venv \
        python3-pybind11 \
        software-properties-common \
        wget \
        libgmp-dev build-essential libssl-dev \
        libffi-dev libmpfr-dev libmpc-dev \
        libblas-dev liblapack-dev \
        libglu1-mesa \
        libgl1 \
        libglx0 \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && held_packages="$(apt-mark showhold)" \
    && if [[ -n "${held_packages}" ]]; then apt-mark unhold ${held_packages}; fi \
    && apt-get install -y --no-install-recommends \
        cuda-toolkit-12-8 \
        cuda-toolkit-13-0 \
    && rm -rf /var/lib/apt/lists/*

RUN git lfs install --system \
    && curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && uv python install 3.10

RUN mkdir -p /root/.cache/huggingface /root/.cache/uv

ENV UV_LINK_MODE=copy \
    UV_CACHE_DIR=/root/.cache/uv \
    HF_HOME=/root/.cache/huggingface \
    HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface/hub \
    XDG_CACHE_HOME=/root/.cache \
    WORKSPACE_DIR=/workspace \
    CUDA_PRIMARY=${PRIMARY_CUDA} \
    PATH=/usr/local/cuda-${PRIMARY_CUDA}/bin:/usr/local/cuda-13.0/bin:/usr/local/cuda-12.8/bin:/usr/local/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda-${PRIMARY_CUDA}/lib64:/usr/local/cuda-13.0/lib64:/usr/local/cuda-12.8/lib64:${LD_LIBRARY_PATH}

WORKDIR /workspace

CMD ["bash"]