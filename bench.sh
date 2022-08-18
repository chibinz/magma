#!/bin/bash
set +x

TARGETS=$(ls targets/)
FUZZERS="afl aflplusplus"

clean() {
    # Prune all caches
    docker images -aq | xargs docker rmi -f
    nix store gc
}

checkpoint() {
    echo "*** Checkpoint ***"
    date
    docker images
    df -h
    echo "******************"
}

bench_orig() {
    clean
    checkpoint

    for fuzzer in $FUZZERS; do
        for target in $TARGETS; do
            echo "building $fuzzer-$target with build.sh"
            env TARGET=$target FUZZER=$fuzzer tools/captain/build.sh
        done
    done

    checkpoint
}


bench_nix() {
    clean
    checkpoint

    nix build --max-jobs $(nproc)
    for im in result/*; do
        docker load -i $im
    done

    # Remove build cache, only compare loaded image size
    rm result
    nix store gc


    checkpoint
}

bench_orig

bench_nix
