FROM ubuntu:20.04

# Install necessary libraries and tools
RUN apt-get update && apt-get install -y \
    qemu \
    qemu-user-static \
    binfmt-support \
    gcc-multilib \
    libc6 \
    wget \
    ca-certificates \
    build-essential \
    git

# Install Go
RUN wget https://golang.org/dl/go1.22.4.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin

# Copy the project files into the container
WORKDIR /workspace
COPY . .

# Install Go dependencies
RUN go mod tidy
