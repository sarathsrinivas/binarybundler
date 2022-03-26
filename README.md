## Description

BinaryBundler is a shell script that bundles all
shared object dependencies of a given
binary/binaries into a portable folder which can
be moved to a different system with same
architecture.

__N.B.__: Only works for ELF linux binaries.


## Requirements

1. `/bin/sh`
1. `ldd`
1. `patchelf`
2. `sha256sum`
3. `coreutils`

Most linux distros already have all of the above.

## Installation

Just clone and run.

```
> git clone https://gitlab.com/srinix/binarybundler.git
> chmod +x binarybundler/bundle.sh
> ./binarybundler/bundle.sh <binary_file1> <binary_file2> ... 
```

## Usage

Let's say you have a host system where you compile
your codes and the compilation is successful
resulting in a binary executable `a.out`.

Then you can create bundle that contains all the
shared object dependencies of `a.out` which
can be moved to another linux system with the same
architecture (mostly x86_64).

```
> ./bundle.sh ./a.out 
```

This will create a folder named as `bundle_<hash>`
where `<hash>` is first 10 character of sha256sum
of sha256sums.txt which inturn contains sha256sum
hashes of all files in the bundle.

Once the `bundle_<hash>` is created, it can be
moved to another linux system (to a HPC Cluster)
and `a.out` can be run using the shell script
`run.sh` provided in the bundle.

```
> scp -r bundle_jgg345juio user@cluster:~/
> ssh user@cluster
cluster> cd bundle_jgg345juio 
cluster> ./run.sh a.out
```

## How it works (if it works)

1. The binary executable is copied to
   `bundle_<hash>` folder.
2. Locations of all the shared objects of the
   binary and their dependencies are read from 
   output of `ldd` and copied to
   `bundle_<hash>/lib`.
3. `patchelf` is used to add `RUNPATH` for all the
   libs as `$ORIGIN` and for the binary as `$ORIGIN/lib`.
4. The interpreter `ld-linux.so` is copied to
   `bundle_<hash>/interpreter`.
5. A shell script is used to invoke a.out using
   the local interpreter as `ld-linux-*-so.* a.out`.
