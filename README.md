# Magma: A Ground-Truth Fuzzing Benchmark

Playing with the `nix` build system and package manager lately. Rewrote part of magma for practice.

## Several observations
- Total build time sees a 2.73x inprovement, due to images are built concurrently. This may overbook the cpu and increase context switching cost, especially when you have multiple tasks compiling. But we still see speedup because a significant portion of the build process is spend on I/O. 15 minute window of cpu utilization viewed in htop is not very high.
- 2.43x total disk usage improvement is not as impressive as the reduction in individual image size. (Measured by `df -h` before and after build) Possibly due to caching between layers and compression.
- The most heart felt benefit of nix is its declarative nature and type system.
    - Defining the build process is much more concise and structured. (1/2 lines of code when compared to `prebuild.sh`, `fetch.sh`, `build.sh` added together)
    - Many functions such as fetching, patching, and configurating is built in, reducing the need for shell script.
    - Type system catch simple errors before build, greatly reducing write, build, debug loop time. Waiting 10 minutes to see a build fail due to a syntax error in your script or a directory doesn't exist can be a bit frustrating...

- Overall I think nix is worth a try if you're developing a new benchmark. It speedups development and ease maintainence considerably.

## Bench
- Setup: Xeon E5-2683 v3, 8c16t @ 2.0 Ghz, 32GiB of RAM
- Repo fork and bench script: https://github.com/chibinz/magma/tree/nix
```
                             | original  | with nix | ratio
total build time             | 41 min    | 15 min   | 2.73
total disk usage             | 9.7GB     | 4.0 GB   | 2.43
magma/aflplusplus/sqlite3    | 1.24GB    | 56.7MB   | 21.8
magma/aflplusplus/poppler    | 1.69GB    | 156MB    | 10.8
magma/aflplusplus/php        | 2.55GB    | 132MB    | 19.3
magma/aflplusplus/openssl    | 2.01GB    | 109MB    | 18.4
magma/aflplusplus/lua        | 1.06GB    | 48.6MB   | 21.8
magma/aflplusplus/libxml2    | 1.24GB    | 1.6GB    | 0.77
magma/aflplusplus/libtiff    | 1.1GB     | 67.4MB   | 16.3
magma/aflplusplus/libsndfile | 1.17GB    | 224MB    | 5.22
magma/aflplusplus/libpng     | 1.1GB     | 45.4MB   | 24.2
magma/afl/sqlite3            | 1.16GB    | 59.1MB   | 19.6
magma/afl/poppler            | 1.56GB    | 175MB    | 8.91
magma/afl/php                | 2.3GB     | 171MB    | 13.4
magma/afl/openssl            | 1.85GB    | 142MB    | 13.0
magma/afl/lua                | 981MB     | 48.5MB   | 20.2
magma/afl/libxml2            | 1.14GB    | 1.38GB   | 0.82
magma/afl/libtiff            | 1.02GB    | 69.7MB   | 14.6
magma/afl/libsndfile         | 1.09GB    | 225MB    | 4.84
magma/afl/libpng             | 1.02GB    | 46.4MB   | 21.9
```
