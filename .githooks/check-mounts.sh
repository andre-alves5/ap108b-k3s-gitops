#!/bin/bash
# Check if we can reach the node and if mounts are active
if ! ssh -o ConnectTimeout=2 andre@10.108.4.252 "mountpoint -q /mnt/k3s-system"; then
    echo "❌ ERROR: NAS Mount /mnt/k3s-system is NOT active on .252. Fix it before committing!"
    exit 1
fi
echo "✅ NAS Mounts Verified."