# Cross-platform build on ARM64 NAS
# This enables building amd64 images on arm64 hosts using QEMU

# Enable buildx
docker buildx create --name multiarch --driver docker-container --use
docker buildx inspect --bootstrap

# Build for arm64 (native)
docker buildx build --platform linux/arm64 -t waterlou/openclaw:arm64-latest --load .

# Or build for both architectures
docker buildx build --platform linux/amd64,linux/arm64 -t waterlou/openclaw:latest --load .

# Update docker-compose.yml to use local image
# Change image: ghcr.io/waterlou/openclaw:latest
# to image: waterlou/openclaw:arm64-latest
