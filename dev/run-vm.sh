#!/bin/bash

# Check if the required argument is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <path_to_image_file> [-c]"
    exit 1
fi

# Default values
copy_image=true

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--no-copy)
            copy_image=false
            shift
            ;;
        *)
            image_file="$1"
            shift
            ;;
    esac
done

# Ensure an image file is provided
if [ -z "$image_file" ]; then
    echo "Usage: $0 <path_to_image_file> [-c]"
    exit 1
fi

# Variables
seed_iso="seed.iso"
qcow2_image="image.qcow2"
image_size="64G"
bios_image="edk2-aarch64-code.fd"
memory="2G"
cpus="2"

# Create seed file
mkisofs -output "$seed_iso" -volid CIDATA -joliet -rock user-data meta-data

# Copy image file (if requested)
if $copy_image; then
    cp "$image_file" "$qcow2_image"
fi

# Resize image
qemu-img resize "$qcow2_image" "$image_size"

# Run VM
qemu-system-aarch64 \
    -machine virt,accel=hvf,highmem=off \
    -bios "$bios_image" \
    -net nic -net user,hostfwd=tcp::2222-:420 \
    -drive file="$qcow2_image" \
    -drive driver=raw,file="$seed_iso",if=virtio \
    -cpu host \
    -smp "$cpus" \
    -m "$memory" \
    -nographic

# Clean up the temporary seed file
rm -f "$seed_iso"
