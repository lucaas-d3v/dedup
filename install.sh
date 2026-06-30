set -e

zig build -Doptimize=ReleaseFast -Dcpu=native
sudo mv zig-out/bin/dedup /usr/local/bin
echo "Dedup installed"