#!/bin/sh
binaries="$@"

# Get paths of all dependencies of binaries
deps=$(ldd "$binaries" | grep '/' | cut -d '>' -f 2 | cut -d '(' -f 1 | sort | uniq)

mkdir -p bundled
mkdir -p bundled/lib

# Copy all binaries to bundled
for bin in $binaries
do
cp "$bin" bundled/
done

# Copy all deps in host machine to bundled/lib
for dep in $deps
do
if [ -L "$dep" ]
then
target=$(realpath "$dep")
cp "$target" bundled/lib
targetfile=$(basename "$target")
linkname=$(basename "$dep")
cd bundled/lib
ln -sf "$targetfile" "$linkname"
cd ..
cd ..
else
cp "$dep" bundled/lib
fi
done

# Make everything executable
chmod +rwx -R bundled 

# Add rpath to binaries in bundled as $ORIGIN/lib
for fl in bundled/*
do
if [ -f "$fl" ] && [ -x "$fl" ] 
then
echo "Patching binary $fl to" '$ORIGIN/lib'
patchelf --add-rpath '$ORIGIN/lib' "$fl"
fi
done

# Add rpath to libraries in bundled/lib as $ORIGIN
for fl in bundled/lib/*
do
if [ -f "$fl" ] && [ -x "$fl" ] 
then
echo "Patching library $fl to" '$ORIGIN'
patchelf --add-rpath '$ORIGIN' "$fl"
fi
done