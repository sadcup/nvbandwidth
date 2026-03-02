FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME=/usr/local/cuda

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libboost-program-options-dev \
    libnvidia-ml-dev \
    python3 \
    python3-pip \
    bc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . /app/

RUN cmake . && make -j$(nproc)

RUN mkdir -p /results

EXPOSE 8080

CMD ["/app/entrypoint.sh"]
