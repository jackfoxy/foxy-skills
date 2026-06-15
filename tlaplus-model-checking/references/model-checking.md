# TLC Model Checking Reference

Primary local sources:

- `USE.md`
- `general/docs/current-tools.md`
- `docs/invariants-and-properties.md`
- `docs/assumptions-and-invariants.md`
- `docs/module-coverage-statistics.md`
- `tlatools/org.lamport.tlatools/test-model/`

Important `.cfg` keys:

- `SPECIFICATION`
- `INIT`, `NEXT`
- `CONSTANT`, including replacement/override assignments
- `INVARIANT`, `INVARIANTS`
- `PROPERTY`, `PROPERTIES`
- `CONSTRAINT`
- `POSTCONDITION`

Trace/state export:

```bash
java -cp dist/tla2tools.jar tlc2.TLC -dump dot output.gv -config Spec.cfg Spec.tla
java -cp dist/tla2tools.jar tlc2.TLC -dumpTrace json trace.json -config Spec.cfg Spec.tla
java -cp dist/tla2tools.jar tlc2.TLC -loadTrace json trace.json -config Spec.cfg Spec.tla
```

Progress operators from `TLC.tla`: `TLCGet`, `TLCSet`, `Print`, `PrintT`, `TLCEval`.
