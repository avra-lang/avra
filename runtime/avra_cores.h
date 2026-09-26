// The cores' rows: one process per core, sharing nothing. A group is
// handled as an int; every row answers at once, and a caller that must
// wait parks on the descriptor a row names.
#ifndef AVRA_CORES_H
#define AVRA_CORES_H

#include <stdint.h>

// The cores this process may run on — its affinity mask where the
// system has one.
int64_t avra_cores_online(void);

// A group of `n` cores, not yet forked; the handle, or -errno.
int64_t avra_cores_group(int64_t n);

// Forks the group's cores. Answers the core's index (0..n-1) in each
// core, `n` in the supervisor, or -errno. A core keeps the calling task
// alone and no descriptor but the standard three and `serving`.
int64_t avra_cores_fork(int64_t g, int64_t serving);

// A core's side: the descriptor to park on until the group stops, and
// 1 once it has — or the supervisor is gone — else 0.
int64_t avra_cores_stop_fd(int64_t g);
int64_t avra_cores_stopped(int64_t g);

// A core's open connections published; the supervisor's sum of them.
void avra_cores_count(int64_t g, int64_t core, int64_t live);
int64_t avra_cores_live(int64_t g);

// A core leaves: what it accepted and the errno it failed with (0 when
// it stopped as asked) kept for the supervisor, the process exited.
// Never returns.
int64_t avra_cores_leave(int64_t g, int64_t core, int64_t accepted, int64_t err);

// The supervisor's side: the descriptor that ends when core `core`
// does, to park on; 0 once it has ended (reaped), else -EAGAIN.
int64_t avra_cores_end_fd(int64_t g, int64_t core);
int64_t avra_cores_heard(int64_t g, int64_t core);

// Every core told to stop. Only the supervisor can; elsewhere nothing.
void avra_cores_stop(int64_t g);

// Once every core has ended: the connections they accepted, or -errno
// for the first that failed. A core that trapped or was killed traps
// here, naming it. The group is gone after.
int64_t avra_cores_result(int64_t g);

#endif
