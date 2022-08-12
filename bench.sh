#!/bin/bash

TARGETS=$(ls targets/)
FUZZERS="afl aflplusplus"

echo "Targets: $TARGETS"
echo "Fuzzers: $FUZZERS"

checkpoint() {
    # Prune all caches
    docker images -aq | xargs docker rmi -f
    nix store gc

    echo "*** Checkpoint ***"
    date
    docker images
    df -h
    echo "******************"
}

checkpoint

for fuzzer in $FUZZERS; do
    for target in $TARGETS; do
        echo "building $fuzzer-$target with build.sh"
        env TARGET=$target FUZZER=$fuzzer tools/captain/build.sh
    done
done

checkpoint
