// A BOX'S HEADER LENGTH DESCRIBES ITS ALLOCATION: free reads the length
// to file the box by size and to count what is live, so a body that
// shrinks the length after allocating misfiles the box and the count
// drifts — every such mint must leave live bytes where they began.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "../avra_runtime.h"

const char* avra_int_text(int64_t v);
const char* avra_selfhost_read_file(const char* path);
const char* avra_bytes_with_room(int64_t n);
const char* avra_bytes_adopted(const void* p, int64_t n);
const char* avra_bytes_concat_reusing(const char* a, const char* b);
int64_t avra_bytes_len(const char* b);

static int g_checks = 0, g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "box_size_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

int main(void) {
    int64_t live = avra_mem_live();
    for (int64_t i = 0; i < 1000; i++) avra_rc_release((void*)avra_int_text(i * 7919));
    CHECK(avra_mem_live() == live, "an int's text, released, leaves the live count where it began");

    char path[] = "/tmp/avra_box_size_XXXXXX";
    int fd = mkstemp(path);
    CHECK(fd >= 0 && write(fd, "abc", 3) == 3, "a three-byte file");
    close(fd);
    live = avra_mem_live();
    const char* text = avra_selfhost_read_file(path);
    CHECK(strcmp(text, "abc") == 0, "the file reads back");
    avra_rc_release((void*)text);
    CHECK(avra_mem_live() == live, "a file's text, released, leaves the live count where it began");
    unlink(path);

    live = avra_mem_live();
    const char* room = avra_bytes_with_room(4096);
    CHECK(avra_bytes_len(room) == 0, "a buffer with room is empty");
    const char* piece = avra_bytes_adopted("abcdefgh", 8);
    const char* grown = room;
    for (int i = 0; i < 400; i++) grown = avra_bytes_concat_reusing(grown, piece);
    CHECK(grown == room, "appends within the room grow the buffer in place");
    CHECK(avra_bytes_len(grown) == 3200, "every append is kept");
    avra_rc_release((void*)grown);
    avra_rc_release((void*)piece);
    CHECK(avra_mem_live() == live, "a buffer with room, grown and released, leaves the live count where it began");

    printf("box sizes: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}
