// A BOX'S HEADER LENGTH DESCRIBES ITS ALLOCATION: free reads the length
// to file the box by size and to count what is live, so a body that
// shrinks the length after allocating misfiles the box and the count
// drifts — every such mint must leave live bytes where they began.
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "../avra_runtime.h"

const char* avra_int_text(int64_t v);
const char* avra_selfhost_read_file(const char* path);

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

    printf("box sizes: %d checks, %d failed\n", g_checks, g_fails);
    return g_fails ? 1 : 0;
}
