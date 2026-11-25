# Authority and receipts — actions, impact, safeguards, mandates

> 2026-09-29. DESIGN, normative, nothing built, nothing ratified.
> Extracted from `2026_09_29_WEB_UI.md` (§7, §9.3, §16) because none of it
> is web-specific. Decision trail: WEB_UI §25 T3, T5, T12, T13, T14, T15.
> Rationale and scale-out research: `2026_09_24_AUTONOMOUS_SYSTEMS_AND_STATE.md`.
> All syntax is illustrative.

---

## 0. Scope

One language-wide contract, used equally by a human clicking a button, a
CLI invocation, a webhook, a worker, an agent and a deploy gate.

**Owns:**
- principals, capabilities, live witnesses
- action intent and idempotency
- the impact record and its profiles
- safeguard obligations and their context-specific discharges
- runtime delegation mandates
- build-time waiver requests and their authorizing mandates
- trust roots and attestations
- authoritative vs external receipts
- durable effects, retries, compensation

**Does not own:**
- how a principal authenticates (the mechanism)
- module visibility, exports, code ownership
- storage and transaction realization → the ORM
- presentation → each consumer's projection (§13)

---

## 1. Principals, capabilities, live witnesses

- An action receives an authenticated PRINCIPAL + attenuated CAPABILITIES.
- Reads are filtered by the SAME authority model as writes.
- Authority is re-evaluated AT COMMIT; the receipt names the policy/witness
  that authorized it.
- Outputs and errors obey disclosure laws (no existence leaks).
- Queued/offline requests carry INTENT, never durable authority.
  Revocation and expiry are ordinary refusals.
- `auth:` is sugar that builds this contract. Its presence is a floor, not
  a proof.

```avra
@action(auth: member_of(p), impact: .routine)
fn add_task(p: Project, title: string) -> Task { … }
```

## 2. The action lifecycle

| Phase | Runs at | Compiler proves |
|---|---|---|
| 1 intent + idempotency identity | invoker | identity minted, stable across retries |
| 2 preview / speculation (optional) | invoker | pure; allowed only if the impact PERMITS it (§4) |
| 3 validation + transition | authority | authority rechecked at commit; invariants hold |
| 4 durable receipt | authority | idempotency record atomic with the transition |
| 5 external effects + compensation | durable work | effects follow commit; retryable; compensable |
| 6 reconciliation / conflict | invoker | conflict type designed BY THE ACTION |

- Phases are DECLARED where they are product meaning (speculation,
  conflict type); the compiler validates them.
- A transition does not reach the world (`Net`, process): that is phase 5.

## 3. Intent, identity, replay

- Ids are minted by the invoker (UUIDv7), validated by the authority. Time
  is stamped by the authority.
- Every retry carries its identity; recording it is ATOMIC with the
  transition.
- Rebase: replay is computationally sound for pure transitions but can
  violate INTENT (a card moved relative to a now-deleted neighbour; a price
  changed). The action declares its conflict type.
- Never "exactly once" across independent systems: a replay-safe
  transition + idempotent / reconcilable effects.

## 4. Impact

- `impact:` is REQUIRED on every action; omission is refused.
- It is a PROFILE over the impact record — not a closed enum. Real cases
  overlap: a trade is external, consequential and irreversible; a deleted
  account may be recoverable for 30 days; a message may be "sending" but
  not "delivered".
- Profiles are ordinary values marked `@profile` (WEB_UI §3.1); overrides
  are one `with { … }`, checked whole.

**The impact record:**
- presentation before receipt (what may be shown, as what)
- reversibility / compensation
- external commitment
- consequence + minimum safeguard
- receipt meaning (§6)

**Starting profiles** — conservative defaults, not exhaustive categories:

| Profile | Before receipt | Recovery | Minimum safeguard |
|---|---|---|---|
| `.routine` | speculative next state may render; its semantic state is `speculative` until the receipt | none promised; failure reconciles and is announced | none |
| `.reversible` | speculative next state may render, with an undo obligation | a declared compensating action, valid under a stated window/precondition; records a new fact, never erases history | undo |
| `.destructive` | nothing shown complete before the authoritative receipt | must be named | a commitment safeguard (§5); a trash operation may relax presentation when its recovery is real |
| `.external` | "sending" after the SERVER receipt; "sent/paid/booked" only after the EXTERNAL receipt that declares it | explicit obligation | explicit obligation |

- `.routine` vs `.reversible` is a user-facing GUARANTEE (a recovery
  surface promised or not), not whether an inverse is imaginable.
- Two facts, both required: the compiler derives ELIGIBILITY to speculate
  (reach, read set); the impact grants PERMISSION.
- Ratify the impact RECORD before the profile catalogue.

## 5. Safeguards — one obligation, many discharges

- **Two levels:** the ACTION declares its recovery mechanism and MINIMUM
  safeguard; each INVOCATION discharges the context-dependent part. Every
  invocation site is checked — a safeguard wired at one site does not
  discharge another.
- **Destructive law:** a destructive impact names and implements a recovery
  or commitment safeguard. Refused, not warned, under production
  conformance profiles. An undo counts only if restoration is REAL.
  `safeguard: .none` only through an authorized waiver (§10).
- `required safeguard = impact minimum + live context − mandate discharge`

| Invoker | Typical discharges |
|---|---|
| web button / form | confirmation, real undo, trash, re-authentication, typed phrase |
| CLI, interactive | a prompt |
| CLI, non-interactive | a delegation mandate — a flag is not a discharge |
| worker, queue, schedule, webhook | a delegation mandate (no human is present) |
| agent | a delegation mandate + budget, optionally a second approver |
| deploy | a signed release mandate |

- The consumer's test harness generates the traces: accidental activation,
  keyboard activation, repeated/bulk operation, cancellation, recovery. The
  compiler proves a safeguard is WIRED; evidence judges it comprehensible.

## 6. Receipts

| Kind | Certifies |
|---|---|
| authoritative | the transition committed, under this witness |
| accepted | durable work was accepted (an `.external` action's server receipt) |
| external | another authority committed, with its evidence |
| build / release | this artifact was built under these waivers and mandates |
| deploy | this release was verified and placed |

- Each receipt NAMES the fact it certifies; nothing presents a fact before
  the receipt that certifies it.
- An action receipt records: impact version, live authorization witness,
  mandate id + budget consumed, the safeguard discharge, the predicate
  inputs, and the authoritative/external result.
- Kinds are DOMAIN-SEPARATED types and signatures: a build receipt is never
  mistaken for an external-effect receipt.

## 7. Effects, retries, compensation

- Effects run AFTER commit, as durable work with its own identity.
- Retries are idempotent or reconcilable; compensation is a declared
  action that records a new fact.
- Cancellation stops future work; committed work is compensated, never
  rolled back.

## 8. Every writer is named

- Migrations, imports, background jobs, schedules, admin repair, retention
  deletion and webhooks are actions — or a lower door with exactly named
  powers (e.g. `migration`). No privileged informal path.

## 9. Mandates

### 9.1 One algebra, two domain-separated subjects

| Mandate | Authorizes | Issued for |
|---|---|---|
| `Mandate<ActionRequest>` | runtime DELEGATION: what a principal (an agent, a worker) may invoke unattended | predicates, budgets, time window |
| `Mandate<WaiverRequest>` | a build-time WAIVER of a law | law, scope, target/profile, expiry |

- Shared machinery: scope, issuer, subject, expiry, budget, predicates,
  evidence, signature.
- Separate signature domains: a delegation mandate can never authorize a
  waiver, and the reverse.

### 9.2 The chain — anchored outside the author's write reach
1. **Root of trust:** an organization key / policy service pinned by the
   deploy environment or the trusted compiler installation. A public key in
   the same mutable tree is not an anchor.
2. **Request:** a source `@waive(…)`, `automation: .eligible`, or a new
   `LICENSED` comment. Requests only.
3. **Issuance:** human review, a protected policy workflow, or a policy
   service issues a SIGNED mandate scoped to project, subject, owner,
   policy digest, expiry and — where needed — parameters/budget. It may live
   beside the source for reproducibility; an author can copy or delete it,
   never widen it. Protected VCS review is an issuance PATH; CI turns its
   evidence into a signed attestation, and the attestation is the proof —
   not `CODEOWNERS`, not a local landing script.
4. **Verification:** the deploy environment checks mandates against its
   own trust root and the current revocation/policy epoch. The deploy
   receipt records every mandate digest and waiver discharged. Production
   never trusts "the build said it was authorized".

### 9.3 Local development
- An unendorsed waiver yields an explicitly NON-CONFORMING preview/build
  that can never mint a release or deploy receipt.
- `avra check` refusing vs reporting `UnendorsedWaiver` is a profile
  choice; the status is impossible to mistake for passage.

## 10. Waivers

- One `Waiver` row: law, scope, target/profile, reason, accountable owner,
  issued time, expiry/review time, the authorizing mandate.
- Two spellings: `@waive(…)` in Avra programs; a structured `LICENSED`
  comment for bootstrap/foreign source, projected into the same row by the
  existing keepers.
- REQUESTING and AUTHORIZING are separate powers (§9). An unauthorized
  `@waive` is itself a refusal in a conforming build.
- Every waiver appears in `explain`, generated docs and receipts.
- Build the row and receipt first; migrate spellings only where that
  removes machinery.

## 11. Delegated invocation (agents, workers)

- `auth` — may this principal REQUEST the action?
- `impact` — consequences, receipt meaning, recovery, minimum safeguard
- the delegation mandate — what THIS principal may do unattended, under
  which predicates, budgets and window
- live state — the invocation may still refuse
- Defaults from impact: `.routine` → no approval; `.destructive` →
  required; `.external` → required until its profile proves a narrower
  rule. Parameters matter: refunding $5 and $50,000 are one action with
  different predicates. Auth sensitivity and disclosure can require
  approval for a routine mutation.
- Source may declare `automation: .eligible` or request a NARROWER
  safeguard. It never authorizes unattended execution; weakening a minimum
  is a separately named waiver in a mandate.
- The authority surface is actions, never a screen or a page's content.

## 12. Laws

R = refuses

| Law | Kind | Example |
|---|---|---|
| an action names its authority; authority is live at commit | R | no `auth:`; cached/offline auth treated as durable |
| `impact:` is declared | R | an action with no `impact:` |
| retries carry identity | R | replayable action/effect without idempotency or compensation |
| a transition does not reach the world | R | `Net` in phase 3 |
| speculation is permitted, not assumed | R | speculation under an impact that does not permit it |
| nothing presents a fact before its receipt | R | "sent" on the server receipt of an `.external` action |
| a destructive impact names and implements a safeguard | R (production profiles) | no undo/trash/confirm/re-auth/approver; undo over lossy compensation |
| every invocation discharges its safeguard | R | a `.destructive` action reached from a site with no discharge there |
| source never authorizes unattended execution | R | an override granting unattended power with no mandate |
| mandate subjects do not cross | R | a delegation mandate offered for a waiver |
| an unendorsed waiver never mints a release | R | release/deploy receipt over an unverified waiver |
| every writer is named | R | a background job writing authoritative state outside an action or named door |

## 13. Consumers — each owns only its projection

| Consumer | Projects |
|---|---|
| web (`WEB_UI` §7) | speculative/pending/error presentation; forms + no-JS POST; confirmation/undo/recovery UI; invocation-site discharge; announcements; inspector rows |
| CLI (`@std/cli`) | prompts, non-interactive mandates, exit status per receipt |
| workers / queues / webhooks | delegation mandates, retry identity, dead-letter receipts |
| agents (`agent` blocks) | tool schemas from actions; approval per §11 |
| deploy | release mandates, verification, deploy receipts |
| ORM | storage and transaction realization of phases 3–4 |
| `AUTONOMOUS_SYSTEMS_AND_STATE` | rationale and scale-out research; links here for the protocol |

## 14. Open

- **DECIDED (owner, 2026-09-29):** this repo's `LICENSED` comments under
  autonomous landing (WEB_UI §23 item 0b): grandfather existing licenses as an approved
  baseline; require a mandate for every new, widened or renewed one before
  agents land autonomously.
- Signing infrastructure, trust-root distribution, revocation transport:
  unbuilt; no signing exists in the toolchain today.
- The policy-service shape (hosted, file-based, or both).
