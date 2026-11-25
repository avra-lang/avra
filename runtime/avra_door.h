// THE USER'S OWN DIRECTORY, one definition for the scheduler's listing
// door and for whoever asks through it (@std/io): a directory this user
// alone may write, opened with no link followed and held to its owner
// and mode, so every file in it is named from the open directory and a
// name in it can never be swapped for a link elsewhere.
//
// Header-only: the scheduler and @std/io each carry it without linking
// the other.
#ifndef AVRA_DOOR_H
#define AVRA_DOOR_H

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#if !defined(__wasm32__)

// `dir`, open, when it is this user's alone — a directory and no link,
// owned by whoever this process runs as, 0700 — else -errno (EPERM for
// one that stands but is not ours). Calls a signal handler may make.
static inline int avra_dir_held(const char* dir) {
    int dfd = open(dir, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (dfd < 0) {
        // a link where the directory is named is a directory not ours
        int err = errno;
        struct stat ls;
        if (fstatat(AT_FDCWD, dir, &ls, AT_SYMLINK_NOFOLLOW) == 0 && S_ISLNK(ls.st_mode)) return -EPERM;
        return -err;
    }
    struct stat st;
    if (fstat(dfd, &st) == 0 && S_ISDIR(st.st_mode) && st.st_uid == geteuid() && (st.st_mode & 077) == 0) return dfd;
    close(dfd);
    return -EPERM;
}

// The user's own directory's path, with no trailing slash: macOS's
// per-user temporary directory; elsewhere `/run/user/<uid>` when it is
// ours, else `/tmp/avra-<uid>`, which whoever asks makes 0700.
static inline void avra_user_dir(char* out, size_t cap) {
#if defined(__APPLE__)
    size_t got = confstr(_CS_DARWIN_USER_TEMP_DIR, out, cap);
    if (got == 0 || got > cap) snprintf(out, cap, "/tmp/avra-%lld", (long long)geteuid());
#else
    snprintf(out, cap, "/run/user/%lld", (long long)geteuid());
    int dfd = avra_dir_held(out);
    if (dfd >= 0) close(dfd);
    else snprintf(out, cap, "/tmp/avra-%lld", (long long)geteuid());
#endif
    size_t n = strlen(out);
    while (n > 1 && out[n - 1] == '/') out[--n] = 0;
}

#endif

#endif
