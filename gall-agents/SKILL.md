---
name: gall-agents
description: Master Gall agent development including all 10 lifecycle arms, state management, subscriptions, HTTP endpoints, cards, and production patterns. Use when building Urbit applications, handling stateful logic, managing subscriptions, integrating with Arvo, or implementing production Gall agents.
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
---

# Gall Agents Skill

Master Gall agent development including lifecycle management, state handling, subscriptions, HTTP endpoints, and production patterns. Use when building Urbit applications, handling stateful logic, or integrating with Arvo.

## Overview

Gall is Urbit's application framework. Gall agents are userspace programs that maintain state, handle events, produce effects, and communicate with other agents and the system.

## Learning Objectives

1. Understand Gall agent architecture
2. Implement all agent arms correctly
3. Manage state and state migrations
4. Handle subscriptions and cards
5. Build HTTP endpoints
6. Apply production-grade patterns
7. Debug Gall agents effectively

## 1. Gall Agent Structure

### Minimal Agent

```hoon
::  /app/my-app.hoon
/-  *my-types
/+  default-agent, dbug
::
|%
+$  versioned-state
  $%  [%0 state-0]
  ==
+$  state-0  [count=@ud]
+$  card  card:agent:gall
--
::
=|  state-0
=*  state  -
::
%-  agent:dbug
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
::
++  on-init
  ^-  (quip card _this)
  `this
::
++  on-save  !>(state)
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state old-vase)
  ?-  -.old
    %0  `this(state old)
  ==
::
++  on-poke  on-poke:def
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-peek  on-peek:def
++  on-agent  on-agent:def
++  on-arvo  on-arvo:def
++  on-fail  on-fail:def
--
```

> **WARNING**: Delegating `on-poke`, `on-watch`, `on-peek`, or `on-arvo` to `default-agent` will CRASH the agent when those arms are called. The default-agent implementations of these arms intentionally crash to signal unhandled events. Only `on-init`, `on-save`, `on-load`, `on-leave`, and `on-fail` are safe to delegate to default-agent. If your agent does not handle pokes, watches, peeks, or arvo responses, you must still provide an implementation that returns `(quip card _this)` without crashing (e.g., return `` `this ``).

## 2. Agent Arms

### `++  on-init`

**Called once** when agent is first installed:

```hoon
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  [%pass /init-timer %arvo %b %wait (add now ~m1)]
      [%give %fact ~[/updates] %json !>((pairs:enjs:format ~[['status' s+'initialized'] ['time' (sect:enjs:format now)]]))]
  ==
```

**Use for**:
- Initialize state
- Set up timers
- Create subscriptions
- Start background tasks

### `++  on-save`

**Serialize state** for upgrades:

```hoon
++  on-save
  ^-  vase
  !>([%0 state])  ::  Always include version!
```

**Must**:
- Include version tag
- Return vase of state
- Be compatible with on-load

### `++  on-load`

**Deserialize and migrate state**:

```hoon
++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state old-vase)
  ?-  -.old
    %0  `this(state +.old)
    %1  `this(state (migrate-1-to-2 +.old))
    %2  `this(state +.old)
  ==
```

**Must**:
- Handle all old versions
- Migrate state to current version
- Return cards for cleanup/updates

### `++  on-poke`

**Handle incoming actions**:

```hoon
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
      %my-action
    =/  action  !<(action vase)
    ?-  -.action
      %increment  `this(count +(count.state))
      %decrement  `this(count (dec count.state))
      %reset      `this(count 0)
    ==
  ==
```

**Use for**:
- User actions
- External commands
- State modifications

### `++  on-watch`

**Handle new subscriptions**:

```hoon
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+    path  (on-watch:def path)
      [%updates ~]
    :_  this
    ~[[%give %fact ~ %json !>([%current-count count.state])]]
  ::
      [%specific id=@ ~]
    ?.  =(our.bowl src.bowl)  !!  ::  Auth check
    :_  this
    ~[[%give %fact ~ %my-data !>(data.state)]]
  ==
```

**Use for**:
- Subscription setup
- Send initial state
- Access control

### `++  on-leave`

**Handle subscription cancellation**:

```hoon
++  on-leave
  |=  =path
  ^-  (quip card _this)
  ::  Cleanup resources for this subscriber
  `this
```

**Use for**:
- Cleanup subscriber-specific resources
- Logging
- (Usually just `on-leave:def`)

### `++  on-peek`

**Handle scry requests** (read-only):

```hoon
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  (on-peek:def path)
      [%x %count ~]       ``noun+!>(count.state)
      [%x %all ~]         ``noun+!>(state)
      [%x %item id=@ ~]
    =/  item  (~(get by items.state) (slav %ud id.path))
    ?~  item  ~
    ``noun+!>(u.item)
  ==
```

**Use for**:
- Read-only queries
- External access to state
- Debugging

### `++  on-agent`

**Handle responses from other agents**:

```hoon
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  (on-agent:def wire sign)
      [%my-subscription ~]
    ?+    -.sign  (on-agent:def wire sign)
        %watch-ack
      ?~  p.sign
        ~&  >  "Subscription successful"
        `this
      ~&  >>>  "Subscription failed: {<u.p.sign>}"
      `this
    ::
        %kick
      :_  this
      ~[[%pass wire %agent [our.bowl %other-app] %watch /updates]]
    ::
        %fact
      =/  data  !<(data q.cage.sign)
      ~&  >  "Received update: {<data>}"
      `this(cache (~(put by cache.state) key data))
    ==
  ==
```

**Use for**:
- Handle subscription updates
- Process responses
- Handle kicks/reconnects

### `++  on-arvo`

**Handle responses from Arvo (OS kernel)**:

```hoon
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+    wire  (on-arvo:def wire sign-arvo)
      [%timer ~]
    ?+    +<.sign-arvo  (on-arvo:def wire sign-arvo)
        %wake
      ::  Timer fired
      :_  this(last-timer now.bowl)
      :~  [%pass /timer %arvo %b %wait (add now.bowl ~m1)]
          [%give %fact ~[/updates] %json !>([%timer-fired now.bowl])]
      ==
    ==
  ::
      [%http-response ~]
    ?+    +<.sign-arvo  (on-arvo:def wire sign-arvo)
        %http-response
      ::  Handle HTTP response
      =/  response  +>.sign-arvo
      ~&  >  "HTTP response: {<response>}"
      `this
    ==
  ==
```

**Use for**:
- Timer responses (%behn)
- HTTP responses (%iris)
- File system updates (%clay)

### `++  on-fail`

**Handle crash recovery**:

```hoon
++  on-fail
  |=  [=term =tang]
  ^-  (quip card _this)
  ~&  >>>  "Agent crashed: {<term>}"
  ~&  >>>  tang
  `this
```

**Use for**:
- Logging errors
- Recovery logic
- (Usually just log and continue)

## 3. Cards (Effects)

### Card Types

```hoon
+$  card  card:agent:gall

::  Card structure
$%  [%pass wire note]       ::  Send request
    [%give gift]            ::  Send response
==
```

### `%pass` Cards

Send a request/command:

```hoon
::  Behn (timer)
[%pass /timer-wire %arvo %b %wait (add now ~m5)]
[%pass /timer-wire %arvo %b %rest (add now ~m5)]

::  Gall (other agent)
[%pass /sub-wire %agent [ship %app] %watch /path]
[%pass /sub-wire %agent [ship %app] %leave ~]
[%pass /poke-wire %agent [ship %app] %poke %mark !>(data)]

::  Iris (HTTP request)
[%pass /http-wire %arvo %i %request request.http ~]

::  Clay (file system)
[%pass /file-wire %arvo %c %warp ship %desk `[%next %z da+now /path]]
```

### `%give` Cards

Send a response/update:

```hoon
::  Fact (subscription update)
[%give %fact ~[/path] %mark !>(data)]
[%give %fact ~ %mark !>(data)]  ::  Current duct only (used in on-watch to send initial state to subscribing duct). To send to all subscribers on a path, specify paths: [%give %fact ~[/path] ...]

::  Kick (close subscription)
[%give %kick ~[/path] ~]
[%give %kick ~ `ship]  ::  Kick specific ship

::  Watch-ack (acknowledge subscription)
[%give %watch-ack ~]             ::  Success
[%give %watch-ack `[%leaf "error"]]  ::  Failure

::  Poke-ack (acknowledge poke)
[%give %poke-ack ~]              ::  Success
[%give %poke-ack `[%leaf "error"]]  ::  Failure
```

## 4. State Management

### State Versioning

```hoon
+$  versioned-state
  $%  [%0 state-0]
      [%1 state-1]
      [%2 state-2]
  ==
::
+$  state-0
  $:  count=@ud
  ==
::
+$  state-1
  $:  count=@ud
      name=@t
  ==
::
+$  state-2
  $:  count=@ud
      name=@t
      items=(map @ud item)
  ==
```

### Migration Functions

```hoon
++  migrate-0-to-1
  |=  old=state-0
  ^-  state-1
  [count.old 'default']

++  migrate-1-to-2
  |=  old=state-1
  ^-  state-2
  [count.old name.old *(`map @ud item)]

++  on-load
  |=  old-vase=vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state old-vase)
  ?-  -.old
    %0  `this(state (migrate-1-to-2 (migrate-0-to-1 +.old)))
    %1  `this(state (migrate-1-to-2 +.old))
    %2  `this(state +.old)
  ==
```

## 5. Subscriptions

### Creating Subscriptions

```hoon
::  Subscribe to another agent
:_  this
~[[%pass /my-subscription %agent [~sampel %other-app] %watch /updates]]
```

### Handling Updates

```hoon
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  !!
      [%my-subscription ~]
    ?+    -.sign  !!
        %fact
      =/  update  !<(update q.cage.sign)
      ~&  >  "Received: {<update>}"
      `this(data (~(put by data.state) key.update val.update))
    ::
        %kick
      ~&  >  "Kicked, resubscribing"
      :_  this
      ~[[%pass wire %agent [src.bowl dap.bowl] %watch /updates]]
    ==
  ==
```

### Publishing Updates

```hoon
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  =/  action  !<(action vase)
  =/  new-state  (process-action state action)
  :_  this(state new-state)
  ~[[%give %fact ~[/updates] %my-update !>(action)]]
```

## 6. HTTP Endpoints

### Eyre Binding

```hoon
++  on-init
  ^-  (quip card _this)
  :_  this
  :~  [%pass /bind %arvo %e %connect [~ /my-app] %my-app]
  ==
```

### Handling HTTP Requests

```hoon
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  !!
      %handle-http-request
    =/  req  !<([@ta inbound-request:eyre] vase)
    =/  [req-id=@ta request=inbound-request:eyre]  req
    =/  url  (parse-request-line:server url.request.request)
    ?+    site.url  (not-found req-id)
        [%my-app %api %users ~]
      ?+    method.request.request  (method-not-allowed req-id)
          %'GET'   (get-users req-id)
          %'POST'  (create-user req-id body.request.request)
      ==
    ==
  ==

++  get-users
  |=  req-id=@ta
  ^-  (quip card _this)
  =/  json-data
    %-  pairs:enjs:format
    ~[['users' a+(turn ~(val by users.state) user-to-json)]]
  :_  this
  %+  give-simple-payload:app:server  req-id
  [[200 ~[['Content-Type' 'application/json']]] `(as-octs:mimes:html (en-json:html json-data))]

++  not-found
  |=  req-id=@ta
  ^-  (quip card _this)
  :_  this
  %+  give-simple-payload:app:server  req-id
  [[404 ~] `(as-octs:mimes:html 'Not Found')]
```

## 7. Common Agent Poke Examples

### Poking %pals (Add a Pal)

`%pals` is one of the most common agents for programmatic interaction. Its poke type requires a mandatory tag set:

```hoon
::  %pals command type: [%meet =ship in=(set @ta)]
::  The tag set (in) is MANDATORY — use ~ for empty set

::  Add a pal with no tags
:pals &pals-command [%meet ~sampel-palnet ~]

::  Add a pal with tags
:pals &pals-command [%meet ~sampel-palnet (silt ~['friend' 'dev'])]

::  Remove a pal (empty tag set = remove from all tags)
:pals &pals-command [%part ~sampel-palnet ~]

::  Remove a pal from specific tags only
:pals &pals-command [%part ~sampel-palnet (silt ~['dev'])]
```

**Gotcha**: Both `%meet` and `%part` require the `in=(set @ta)` tag set argument. Omitting it causes a silent `%exit` with no useful error message. Always include the tag set, even if empty (`~`). For `%part`, an empty set means un-target from all tags.

Via conn.c thread (file-based):
```hoon
::  /tmp/add-pal.hoon
=/  m  (strand ,vase)
;<  our=@p  bind:m  get-our
;<  ~  bind:m  (poke [our %pals] %pals-command !>([%meet ~sampel-palnet ~]))
(pure:m !>('success'))
```

```bash
click -k -i /tmp/add-pal.hoon /path/to/pier
```

## 8. Patterns and Best Practices

### Pattern 1: Action Types

```hoon
+$  action
  $%  [%add-item title=@t]
      [%remove-item id=@ud]
      [%update-item id=@ud title=@t]
      [%mark-done id=@ud]
  ==

++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?>  =(mark %my-action)
  =/  action  !<(action vase)
  ?-  -.action
    %add-item      (add-item +.action)
    %remove-item   (remove-item +.action)
    %update-item   (update-item +.action)
    %mark-done     (mark-done +.action)
  ==
```

### Pattern 2: Helper Arms

```hoon
++  add-item
  |=  [title=@t]
  ^-  (quip card _this)
  =/  id  next-id.state
  =/  item  [id=id title=title done=%.n]
  :_  this(items (~(put by items.state) id item), next-id +(id))
  ~[[%give %fact ~[/updates] %item-added !>(item)]]

++  remove-item
  |=  id=@ud
  ^-  (quip card _this)
  `this(items (~(del by items.state) id))
```

### Pattern 3: Error Handling

```hoon
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  =/  result
    %-  mule  |.
    (handle-poke mark vase)
  ?-  -.result
    %&  p.result
    %|  [[%give %poke-ack `p.result] this]
  ==
```

### Pattern 4: Timers

```hoon
++  on-init
  ^-  (quip card _this)
  :_  this
  ~[[%pass /heartbeat %arvo %b %wait (add now ~m1)]]

++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+    wire  !!
      [%heartbeat ~]
    ?>  ?=([%behn %wake *] sign-arvo)
    :_  this
    :~  [%pass /heartbeat %arvo %b %wait (add now.bowl ~m1)]
        [%give %fact ~[/heartbeat] %json !>([%heartbeat now.bowl])]
    ==
  ==
```

## 9. Testing and Debugging

### Using `dbug`

```hoon
/+  default-agent, dbug
::
%-  agent:dbug  ::  Wrap your agent
^-  agent:gall
|_  =bowl:gall
...
```

**Commands**:
```
:my-app +dbug
:my-app +dbug [%state]
:my-app +dbug [%subscriptions]
```

### Logging

```hoon
~&  >  "Debug info"
~&  >>  "Warning"
~&  >>>  "Error"
```

### Crash Inspection

```hoon
~&  >>>  [%poke-failed mark vase]
!!
```

## Resources

- [Gall Guide](https://developers.urbit.org/guides/core/app-school/intro) - Official guide
- [Gall Reference](https://docs.urbit.org/system/kernel/gall) - Technical reference
- [App Examples](https://github.com/urbit/urbit/tree/master/pkg/arvo/app) - Real apps

## Summary

Gall agents:
1. **10 arms** - Lifecycle (init, save, load, fail), Events (poke, watch, leave, peek, agent, arvo)
2. **State management** - Versioning and migrations
3. **Cards** - %pass (requests) and %give (responses)
4. **Subscriptions** - Publishing and consuming updates
5. **HTTP** - Eyre bindings and request handling
6. **Patterns** - Action types, helpers, error handling
7. **Testing** - dbug wrapper, logging

Mastering Gall enables building production-grade Urbit applications.
