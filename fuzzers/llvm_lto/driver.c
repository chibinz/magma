#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

extern void LLVMFuzzerTestOneInput(const uint8_t *, size_t);

int main(int argc, char **argv) {
  if (argc != 2) {
    fprintf(stderr, "Usage: %s <input>\n", argv[0]);
    return 1;
  } else {
    FILE *f = fopen(argv[1], "rb");
    fseek(f, 0, SEEK_END);
    long fsize = ftell(f);
    fseek(f, 0, SEEK_SET);

    uint8_t *buf = (uint8_t *)(malloc(fsize));
    fread(buf, fsize, 1, f);
    fclose(f);

    fprintf(stderr, "File size: %ld\n", fsize);
    LLVMFuzzerTestOneInput(buf, fsize);

    return 0;
  }
}
