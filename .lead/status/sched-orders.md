sched-orders DONE: PR #921 (branch sched-orders, head 1257c7e7), armed for auto-merge.
Causes: five tests asserted one schedule's order; no runtime bug. No sleeps remain; gates order everything.
join/await_beside_arm answer only after all four waiters parked; mutation (drop parked wait-set arm wake in waiter_claims) deadlocks both.
Gap: FIFO wake order unasserted; would need a C-level test in runtime/tests.
