// THE SWITCH READER: a switch's variable reads `1`/`true` on and `0`/`false`
// off, unset is its declared default, and any other value stops the program
// naming the variable (exit 2), as the Avra projections read it.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "../avra_settings.h"

static int g_checks = 0;
static int g_fails = 0;
#define CHECK(cond, what) do { g_checks++; if (!(cond)) { g_fails++; fprintf(stderr, "settings_test: FAILED %s (%s:%d)\n", what, __FILE__, __LINE__); } } while (0)

static const char* NAME = "AVRA_SETTINGS_TEST_SWITCH";

static int read_as(const char* value, int unset) {
    if (value) setenv(NAME, value, 1); else unsetenv(NAME);
    return avra_setting_switch(NAME, unset);
}

// The child's exit status and the first line it wrote to stderr.
static int trapped(const char* value, char* said, size_t room) {
    int pipe_fds[2];
    if (pipe(pipe_fds) != 0) return -1;
    pid_t pid = fork();
    if (pid == 0) {
        dup2(pipe_fds[1], 2);
        close(pipe_fds[0]);
        read_as(value, 0);
        _exit(0);
    }
    close(pipe_fds[1]);
    ssize_t n = read(pipe_fds[0], said, room - 1);
    said[n > 0 ? n : 0] = 0;
    close(pipe_fds[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}

int main(void) {
    CHECK(read_as(NULL, 0) == 0, "unset reads its default, off");
    CHECK(read_as(NULL, 1) == 1, "unset reads its default, on");
    CHECK(read_as("1", 0) == 1, "1 is on");
    CHECK(read_as("true", 0) == 1, "true is on");
    CHECK(read_as("0", 1) == 0, "0 is off, whatever the default");
    CHECK(read_as("false", 1) == 0, "false is off, whatever the default");
    char said[512];
    CHECK(trapped("yes", said, sizeof said) == 2, "a word that is no switch traps, exit 2");
    CHECK(strstr(said, "`AVRA_SETTINGS_TEST_SWITCH=yes` is not a switch") != NULL, "the trap names the variable and its value");
    CHECK(trapped("", said, sizeof said) == 2, "an empty value is no switch");
    CHECK(strcmp(AVRA_SET_RC_GUARD, "AVRA_RC_GUARD") == 0, "a name is its exact variable");
    unsetenv(NAME);
    if (g_fails) {
        fprintf(stderr, "settings_test: %d of %d checks failed\n", g_fails, g_checks);
        return 1;
    }
    printf("settings_test: %d checks passed\n", g_checks);
    return 0;
}
