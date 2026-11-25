// A HASHER'S STATE CROSSES AS A VALUE, so it may be forged. Random states,
// biased toward the door's edges, go through std_hash.c's door under ASan
// and UBSan: every state it admits must update and digest inside its arrays.
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "blake3/blake3.h"

const void* avra_b3_update(const uint8_t* state, int64_t sn, const uint8_t* in, int64_t n);
const void* avra_b3_digest(const uint8_t* state, int64_t sn);

int main(void) {
    srand(7);
    static uint8_t in[70000];
    for (int i = 0; i < 70000; i++) in[i] = (uint8_t)rand();
    static const int lengths[] = {0, 1, 63, 64, 1023, 1024, 1025, 4096, 65536};
    int admitted = 0, total = 100000;
    for (int t = 0; t < total; t++) {
        blake3_hasher h;
        uint8_t* p = (uint8_t*)&h;
        for (size_t i = 0; i < sizeof h; i++) p[i] = (uint8_t)rand();
        h.cv_stack_len = (uint8_t)(rand() % 60);
        h.chunk.buf_len = (uint8_t)(rand() % 70);
        h.chunk.blocks_compressed = (uint8_t)(rand() % 20);
        int k = rand() % 5;
        h.chunk.chunk_counter = k == 0 ? 0 : k == 1 ? (~0ULL >> (rand() % 12)) : ((uint64_t)rand() << (rand() % 40));
        // Heap copies, so a read past the state is a read past an allocation.
        uint8_t* st = malloc(sizeof h);
        memcpy(st, &h, sizeof h);
        const void* u = avra_b3_update(st, sizeof h, in, lengths[rand() % 9]);
        if (u) {
            admitted++;
            uint8_t* next = malloc(sizeof h);
            memcpy(next, u, sizeof h);
            avra_b3_digest(next, sizeof h);
            free(next);
        }
        avra_b3_digest(st, sizeof h);
        free(st);
    }
    if (admitted == 0) {
        fprintf(stderr, "hash-door: no forged state was admitted, so nothing was tested\n");
        return 1;
    }
    printf("hash-door: %d of %d forged states admitted, each updated and digested in bounds\n", admitted, total);
    return 0;
}
