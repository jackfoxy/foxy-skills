---
name: hoon-migrate-workflow
description: Safe state migration workflow for Gall agents covering versioning, backwards compatibility, and zero-downtime upgrades
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
---

# Hoon State Migration Command

Comprehensive workflow for safely migrating Gall agent state across versions without data loss or downtime.

## Purpose

This command guides developers through planning, implementing, and testing state migrations for Urbit applications, ensuring smooth upgrades for all users.

## When to Use

- Adding new fields to state
- Changing state structure
- Removing deprecated fields
- Splitting or merging state components
- Major refactoring with state changes
- Before releasing breaking changes

## Migration Principles

1. **Never Break Existing Piers** - Users must not lose data
2. **Version Everything** - Explicit version numbers
3. **Migration is Code** - Treat migrations as first-class code
4. **Test Migrations** - Test all upgrade paths
5. **Document Changes** - Clear migration notes
6. **Backwards Compatible** - Support old clients when possible

---

## 5-Phase Migration Workflow

### Phase 1: Version Planning

**Objective**: Plan the migration strategy and version scheme.

**Version Scheme**:

```hoon
::  Always use versioned state
+$  versioned-state
  $%  [%0 state-0]
      [%1 state-1]
      [%2 state-2]
      ::  Add new versions here
  ==

::  Each version gets its own mold
+$  state-0  [count=@ud]
+$  state-1  [count=@ud name=@t]
+$  state-2  [count=@ud name=@t items=(list item)]
```

**Migration Path Planning**:

```
State-0 → State-1 → State-2
  |         |         |
  ↓         ↓         ↓
 Add       Add      Add
name=     items=   created=
'default'   ~      now.bowl
```

**Change Assessment**:

| Change Type | Risk | Strategy |
|-------------|------|----------|
| Add optional field | Low | Default value |
| Add required field | Medium | Compute from existing |
| Remove field | Low | Drop data |
| Change field type | High | Convert with validation |
| Restructure | Very High | Multi-step migration |

**Success Criteria**:
- Migration path documented
- Default values defined
- Risk assessment complete
- Testing plan created

---

### Phase 2: Migration Implementation

**Objective**: Write migration code for each version transition.

**Pattern 1: Simple Field Addition**

```hoon
::  Old state (v0)
+$  state-0  [count=@ud]

::  New state (v1) - added name
+$  state-1  [count=@ud name=@t]

::  Migration
++  migrate-0-to-1
  |=  old=state-0
  ^-  state-1
  [count.old 'default-name']

::  In on-load
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state old-vase)
  ?-  -.old
    %0  `this(state [%1 (migrate-0-to-1 +.old)])
    %1  `this(state old)
  ==
```

**Pattern 2: Computed Field Addition**

```hoon
::  Old state (v0)
+$  state-0  [items=(list @t)]

::  New state (v1) - added count
+$  state-1  [items=(list @t) count=@ud]

::  Migration: Compute count from items
++  migrate-0-to-1
  |=  old=state-0
  ^-  state-1
  [items.old (lent items.old)]
```

**Pattern 3: Type Conversion**

```hoon
::  Old state (v0) - using list
+$  state-0  [users=(list [@p @t])]

::  New state (v1) - using map
+$  state-1  [users=(map @p @t)]

::  Migration: Convert list to map
++  migrate-0-to-1
  |=  old=state-0
  ^-  state-1
  :_  ~
  users+(my users.old)
```

**Pattern 4: Nested Structure Changes**

```hoon
::  Old state (v0)
+$  item-0  [id=@ud name=@t]
+$  state-0  [items=(list item-0)]

::  New state (v1) - items now have metadata
+$  item-1  [id=@ud name=@t created=@da modified=@da]
+$  state-1  [items=(list item-1)]

::  Migration
++  migrate-item-0-to-1
  |=  [item=item-0 now=@da]
  ^-  item-1
  [id.item name.item now now]

++  migrate-0-to-1
  |=  [old=state-0 now=@da]
  ^-  state-1
  :_  ~
  items+(turn items.old |=(i=item-0 (migrate-item-0-to-1 i now)))
```

**Pattern 5: Field Removal**

```hoon
::  Old state (v0)
+$  state-0  [count=@ud deprecated=@t name=@t]

::  New state (v1) - removed deprecated
+$  state-1  [count=@ud name=@t]

::  Migration: Drop deprecated field
++  migrate-0-to-1
  |=  old=state-0
  ^-  state-1
  [count.old name.old]
```

**Pattern 6: Multi-Step Migration**

```hoon
::  Old state (v0)
+$  state-0  [data=@t]

::  Intermediate (v1) - parsed data
+$  state-1  [data=(unit parsed-data)]

::  New state (v2) - restructured
+$  state-2  [items=(list item) metadata=metadata]

::  Two-step migration
++  migrate-0-to-1
  |=  old=state-0
  ^-  state-1
  [data=(parse-data data.old)]

++  migrate-1-to-2
  |=  old=state-1
  ^-  state-2
  ?~  data.old
    [items=~ metadata=*metadata]
  (restructure-data u.data.old)

::  In on-load: chain migrations
++  on-load
  |=  old-vase=vase
  =/  old  !<(versioned-state old-vase)
  ?-  -.old
    %0  `this(state [%2 (migrate-1-to-2 (migrate-0-to-1 +.old))])
    %1  `this(state [%2 (migrate-1-to-2 +.old)])
    %2  `this(state old)
  ==
```

---

### Phase 3: Validation and Safety

**Objective**: Ensure migration preserves data integrity.

**Validation Strategies**:

#### Strategy 1: Pre-Migration Validation

```hoon
++  validate-state-0
  |=  state=state-0
  ^-  ?
  &(
    (gte count.state 0)
    (lte count.state 1.000.000)
  )

++  on-load
  |=  old-vase=vase
  =/  old  !<(versioned-state old-vase)
  ?-  -.old
    %0
      ?>  (validate-state-0 +.old)
      `this(state [%1 (migrate-0-to-1 +.old)])
    %1  `this(state old)
  ==
```

#### Strategy 2: Post-Migration Validation

```hoon
++  validate-state-1
  |=  state=state-1
  ^-  ?
  &(
    (gte count.state 0)
    (gth (lent name.state) 0)
  )

++  on-load
  |=  old-vase=vase
  =/  old  !<(versioned-state old-vase)
  ?-  -.old
    %0
      =/  new-state  (migrate-0-to-1 +.old)
      ?>  (validate-state-1 new-state)
      `this(state [%1 new-state])
    %1  `this(state old)
  ==
```

#### Strategy 3: Invariant Checking

```hoon
++  check-invariants
  |=  state=state-1
  ^-  ?
  &(
    ::  Count matches items length
    .=(count.state (lent items.state))
    ::  All IDs unique
    .=  (lent items.state)
        ~(wyt in (~(gas in *(set @ud)) (turn items.state |=(i=item id.i))))
    ::  All items valid
    (levy items.state validate-item)
  )

++  on-load
  |=  old-vase=vase
  =/  old  !<(versioned-state old-vase)
  ?-  -.old
    %0
      =/  new-state  (migrate-0-to-1 +.old)
      ?>  (check-invariants new-state)
      `this(state [%1 new-state])
    %1
      ?>  (check-invariants +.old)
      `this(state old)
  ==
```

#### Strategy 4: Error Handling

```hoon
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  =/  result
    %-  mule  |.
    !<(versioned-state old-vase)
  ?:  ?=(%.n -.result)
    ~&  >>>  "Failed to parse old state: {<p.result>}"
    `this  ::  Keep current state
  =/  old  p.result
  ?-  -.old
    %0
      =/  migration-result
        %-  mule  |.
        (migrate-0-to-1 +.old)
      ?:  ?=(%.n -.migration-result)
        ~&  >>>  "Migration failed: {<p.migration-result>}"
        `this
      `this(state [%1 p.migration-result])
    %1  `this(state old)
  ==
```

---

### Phase 4: Testing Strategy

**Objective**: Verify all migration paths work correctly.

**Test Categories**:

#### Test 1: Forward Migration

```hoon
::  gen/test-migration.hoon
::
::  Test v0 → v1 migration
::
/+  *my-app
::
:-  %say
|=  *
:-  %noun
::
=/  old-state  [%0 count=42]
=/  old-vase  !>(old-state)
::
::  Simulate on-load
=/  [cards new-agent]  (on-load:my-app old-vase)
=/  new-state  state:new-agent
::
::  Verify migration
&(
  .=(-.new-state %1)
  .=(count.new-state 42)
  .=(name.new-state 'default-name')
)
```

#### Test 2: Migration Preserves Data

```hoon
++  test-data-preservation
  ^-  ?
  ::  Create old state
  =/  old-state  [%0 items=~['a' 'b' 'c']]
  ::  Migrate
  =/  new-state  (migrate-0-to-1 old-state)
  ::  Verify all items present
  .=(items.old-state items.new-state)
```

#### Test 3: Idempotent Migration

```hoon
++  test-idempotent
  ^-  ?
  ::  Migrate once
  =/  state-1  (migrate-0-to-1 [%0 count=5])
  ::  Loading v1 state should not change it
  =/  vase-1  !>([%1 state-1])
  =/  [cards agent-1]  (on-load:my-app vase-1)
  ::  Verify unchanged
  .=(state-1 state:agent-1)
```

#### Test 4: Multi-Hop Migration

```hoon
++  test-multi-hop
  ^-  ?
  ::  Start at v0
  =/  state-0  [%0 data='raw']
  ::  Migrate to v2 (skipping v1)
  =/  state-1  (migrate-0-to-1 state-0)
  =/  state-2  (migrate-1-to-2 state-1)
  ::  Verify final state
  (validate-state-2 state-2)
```

---

### Phase 5: Deployment and Monitoring

**Objective**: Deploy migration safely and monitor for issues.

**Pre-Deployment Checklist**:

- [ ] All migration paths tested
- [ ] Validation functions in place
- [ ] Error handling implemented
- [ ] Documentation updated
- [ ] Backup instructions provided
- [ ] Rollback plan documented

**Deployment Steps**:

#### Step 1: Test on Fake Ship

```bash
::  Create fake ship
urbit -F zod

::  Install old version
|mount %app-name
::  Copy old code
|commit %app-name

::  Generate test data
+generate-test-data

::  Update to new version
::  Copy new code
|commit %app-name

::  Verify migration successful
:app-name +dbug [%state]
```

#### Step 2: Backup Instructions

```hoon
::  Document for users
::
::  Before updating:
::  1. Stop your ship: |exit
::  2. Backup pier: cp -r ship-name ship-name-backup
::  3. Restart: urbit ship-name
::  4. Update app: |install ~publisher %app-name
::
::  If issues occur:
::  1. Stop ship: |exit
::  2. Restore: rm -rf ship-name && mv ship-name-backup ship-name
::  3. Restart: urbit ship-name
```

#### Step 3: Phased Rollout

```
Phase 1: Internal testing (1-2 days)
  - Deploy to team ships
  - Monitor for issues
  - Collect feedback

Phase 2: Beta testing (3-7 days)
  - Deploy to beta users
  - Monitor migration logs
  - Fix any issues

Phase 3: General release
  - Announce migration
  - Provide documentation
  - Monitor support requests
```

**Monitoring**:

```hoon
::  Add migration logging
++  on-load
  |=  old-vase=vase
  =/  old  !<(versioned-state old-vase)
  ~&  >  "Migration starting from version: {<-.old>}"
  ?-  -.old
    %0
      ~&  >  "Migrating v0 → v1"
      =/  new-state  (migrate-0-to-1 +.old)
      ~&  >  "Migration complete: {<count.new-state>} items"
      `this(state [%1 new-state])
    %1
      ~&  >  "Already at v1, no migration needed"
      `this(state old)
  ==
```

---

## Migration Patterns Reference

### Pattern: Add Field with Default
```hoon
[old 'default-value']
```

### Pattern: Compute New Field
```hoon
[old (compute-from-existing old)]
```

### Pattern: Remove Field
```hoon
:_  ~
field-1+field-1.old
field-2+field-2.old
::  field-3 dropped
```

### Pattern: Convert Type
```hoon
[field+(convert-type field.old)]
```

### Pattern: Restructure
```hoon
(build-new-structure old)
```

---

## Migration Checklist

### Planning
- [ ] Version numbers assigned
- [ ] Default values defined
- [ ] Migration logic planned
- [ ] Risk assessment done
- [ ] Testing strategy defined

### Implementation
- [ ] All migrations coded
- [ ] Validation added
- [ ] Error handling implemented
- [ ] Logging added
- [ ] Comments explain changes

### Testing
- [ ] Forward migrations tested
- [ ] Data preservation verified
- [ ] Invariants checked
- [ ] Multi-hop tested
- [ ] Error cases handled

### Deployment
- [ ] Tested on fake ship
- [ ] Documentation written
- [ ] Backup instructions provided
- [ ] Rollback plan ready
- [ ] Monitoring in place

---

## Integration with Skills

This command references:
- **gall-agents** - Agent structure
- **type-system** - Mold design
- **functional-programming-patterns** - Data transformation
- **hoon-fundamentals** - Type safety

---

## Common Migration Mistakes

1. **No versioning** - Always version state
2. **Breaking migrations** - Test all paths
3. **No validation** - Check invariants
4. **No rollback plan** - Always have backup
5. **Poor documentation** - Explain migrations clearly

---

## Success Metrics

- **Zero data loss** - All data preserved
- **Smooth upgrades** - No user intervention required
- **Fast migration** - Completes in <10 seconds
- **Clear errors** - Issues easy to diagnose
- **Well documented** - Users understand changes

