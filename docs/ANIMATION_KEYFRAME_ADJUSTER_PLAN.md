# Animation Keyframe Adjuster Plan

Status: discussion note only. Do not implement until the user explicitly asks to start this tool.

## Goal

Build a lightweight in-project animation adjuster for rigged characters and monsters. The tool should let the user edit a small number of meaningful key poses for each gameplay action, while the tool/game code handles interpolation, contact constraints, timing, and event frames.

## Core Principle

Do not treat "feet on ground" as a global rule. The correct shared system is contact constraints:

- no contact: jump air time, leap attack, fall, recoil
- ground contact: walk, run, landing, crouch
- wall contact: climbing, wall crawl
- ceiling contact: ceiling run, ceiling ambush
- custom contact: one hand, one foot, knee, attack limb, or authored helper point

Each keyframe can choose its own contact mode, contact body parts, and contact strength. Jumping or pouncing actions must be allowed to release all contacts.

## First Useful Scope

Start with the Nightmare hearing monster only.

Candidate actions:

- idle
- walk
- run
- alert_listen
- attack
- jump
- jump_attack
- climb_wall
- ceiling_run
- ceiling_drop_attack
- hurt
- death

## Keyframe Templates

walk/run:

- start
- left contact
- pass-through
- right contact
- loop return

alert/listen:

- idle
- stop
- turn head/body toward sound
- confirm/lock direction
- launch/run prep

jump:

- crouch/preload with ground contact
- takeoff contact release
- airborne apex
- landing contact
- recovery

jump_attack:

- prepare
- takeoff/drop
- airborne strike
- hit frame
- landing/recovery

climb/ceiling:

- attach contact
- crawl cycle A
- crawl cycle B
- near-player prepare
- release/drop

## Editor Shape

Preferred UI:

- left: model/action/keyframe list
- center: 3D preview
- right: body-part pose controls and contact constraints
- bottom: timeline, play/stop, speed, loop, event markers

Do not expose every bone by default. Group controls by body part:

- root/body position and yaw
- head
- torso
- left/right arms
- left/right legs
- hands/feet
- attack point/event frames

## Save Strategy

Do not overwrite imported animation assets directly. Save a separate adjustment layer:

- source animation clip
- authored key pose overrides
- interpolation settings
- contact constraint data
- gameplay event frames

Runtime result = source animation + adjustment layer + interpolation + contact solve.

