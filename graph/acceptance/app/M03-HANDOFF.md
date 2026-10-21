# M03: personal/event/task declarations and startup

Base: `df8a43f6`; the commit adding this receipt is the task head.

Seven application models: Pet, Appointment, Trip, TravelBooking, Event,
PersonalTask and Commitment. Avra reserves `Task` for its built-in task type;
the application declaration is `PersonalTask`. No engine workaround or
production ontology branch was introduced. Existing package-level model
collection automatically includes the new declarations and reference targets.
The executable imports that collection and calls the shared graph CLI with
its exit status. No hand-maintained second ontology registry is needed.

The declarations represent q41–q47 without conflating scheduled attendance,
clinical outcomes, one cancelled hotel versus an entire trip/flight, requested
guest limits versus venue confirmation, or a promise versus actual completion.
Unknown booleans and outcomes stay null. A model-local rule rejects completion
timestamps on non-completed tasks. Date-only values stay dates; precise
instants use UTC Unix milliseconds. Automatic date normalization and historical
question execution remain Q05, not behavior inferred from field descriptions.

Verification:

```sh
sh tools/watch.sh 3500 ./build/avra test graph/acceptance/app/src/tests
# 30/30 tests; people_models and personal_models: eval == native == expected
sh tools/watch.sh 3500 ./build/avra check --baseline tools/idioms.baseline graph/acceptance/app
# exit 0, no baseline growth
sh tools/watch.sh 3500 ./build/avra build graph/acceptance/app
python3 graph/acceptance/app/smoke.py
# both exit 0; schema metadata, independent-process reopening, manual records,
# unknown attendance/diagnosis/confirmation, omitted defaults not claims,
# invalid completion refusal with unchanged revision
```

Unit witnesses also refuse empty names/actions, absent task states, negative
capacities and invented status values. Booking reference identity is explicitly
declared in the application, never guessed from its property name.

This is model representation and storage of manually supplied facts, not
automatic extraction, contextual English answers or scored q41–q47 success.
Business declarations still require M02/P02. Startup uses the existing generic
CLI/HTTP protocol; no new personal-specific transport operation was added.
