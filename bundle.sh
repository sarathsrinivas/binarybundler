#!/bin/sh
binaries="$@"

# Get paths of all dependencies of binaries
deps=$(ldd "$binaries" | grep -v ld-linux | grep '/' | cut -d '>' -f 2 | cut -d '(' -f 1 | sort | uniq)

# Get ld interpreter
interpreter="$(patchelf --print-interpreter "$1")"

# Get unique hash for bundle
touch sha256sums.txt

for fl in $binaries
do
echo "$(sha256sum "$fl" | cut -d ' ' -f 1)" "$(basename "$fl")" >> sha256sums.txt
done

for fl in $deps
do
echo "$(sha256sum "$fl" | cut -d ' ' -f 1)" "lib/$(basename "$fl")" >> sha256sums.txt
done

echo "$(sha256sum "$interpreter" | cut -d ' ' -f 1)" "interpreter/$(basename "$interpreter")" >> sha256sums.txt

uhash="$(sha256sum sha256sums.txt | cut -d ' ' -f 1 | cut -c 1-10)"

bundled="bundle_$uhash"
mkdir -p "$bundled"
mkdir -p $bundled/interpreter
mkdir -p $bundled/lib

# Copy all binaries to bundled
for bin in $binaries
do
cp "$bin" $bundled/
done

# Copy interpreter to bundled
cp "$interpreter" $bundled/interpreter/

# Copy all deps in host machine to bundled/lib
for dep in $deps
do
if [ -L "$dep" ]
then
target=$(realpath "$dep")
cp "$target" $bundled/lib
targetfile=$(basename "$target")
linkname=$(basename "$dep")
cd $bundled/lib
ln -sf "$targetfile" "$linkname"
cd ..
cd ..
else
cp "$dep" $bundled/lib
fi
done

# Make everything executable
chmod +rwx -R $bundled 

# Add rpath to binaries in bundled as $ORIGIN/lib
for fl in $bundled/*
do
if [ -f "$fl" ] && [ -x "$fl" ]
then
echo "Patching binary $fl to" '$ORIGIN/lib'
patchelf --add-rpath '$ORIGIN/lib' "$fl"
fi
done

# Add rpath to libraries in bundled/lib as $ORIGIN
for fl in $bundled/lib/*
do
if [ -f "$fl" ] && [ -x "$fl" ] 
then
echo "Patching library $fl to" '$ORIGIN'
patchelf --add-rpath '$ORIGIN' "$fl"
fi
done

# Create shell script to run binaries
runscr="$bundled/run.sh"
echo "Creating shell script for running binaries"
echo '#!/bin/sh' > "$runscr"
echo 'location="$(dirname "$(realpath "$0")")"' >> "$runscr"
interp="$(basename "$interpreter")"
echo '"$location'"/interpreter/$interp"'"' '"$location/$@"' >> "$runscr"
chmod +x "$runscr"
mv sha256sums.txt $bundled/
echo "DONE"