# Dynamic Campaign Tools (DCT-WM) - War Machine (working title)

A fork of the popular DCT framework.

WM is focused on improving the gameplay experience from a strategic perspective.

Several new features have been added and are planned. Some core functionality has been completely revamped.

Features:
- Inventory system of all possible detectable game assets (please harass ED to add TPODs: https://forum.dcs.world/topic/264426-scripting-engine-means-to-determine-if-an-aircraft-has-a-targeting-or-other-pod-equipped)
- Commander system that allows for dispatch and command of pre-defined unit templates
    -To be added: ability to create FOBs and FARPs
    -To be added: interaction with mission system
    -To be added: additional gameplay mechanics
- Revamped mission system aimed to enhance cooordination and tasking.
- Multiplayer voting system
To come:
- Enhanced region control system
- Recon system
- Full fledged logistics
- More

## Gameplay:

Recon finds targets 
Targets create strike missions

CAS missions:
On station --> Friendlies approach FOB, Town, SP --> Enemies are spawned --> CAS Target added, all on mission are notified
(persistent)

Successful missions earn Command Points
Command Points buy new equipment, dispatch AI, or do other things

Ground Forces:
- Convoys of any vehicle type can be created and dispatched
- Formations of military units: from company level to batallion

A formation is required to create a FOB in enemy territory

Whenever a ground unit, or a recon unit within range approaches a FOB, strategic point or town, all the equipment contained inside it
is spawned (for recon, a strike mission is created, but will time out if not acted on quickly). If ground units approach, both sides will be
issues attack commands.

Still very much a work in progress, hope to have a demo server running stage 1 a demo operation soon.

## Description

**D**ynamic **C**ampaign **T**ools relies on content that can be built
directly in the mission editor, these individuals need little to no
programming skills to provide content to a DCT enabled mission.

Scenarios are created through a theater definition consisting of templates,
created in the Mission Editor and configuration files. There is an initial
learning curve but it is no more difficult than initially learning the DCS
Mission Editor.

## Installation

See installation instructions in the [Administrators' guide](doc/02-administrators.md).

## Contribution Guide

Contributions can be made with a standard github pull request. Code is
licensed under LGPLv3 and contributions must be licenced under the same.
For any issues or feature requests please use the issue tracker and file
a new issue. Please make sure to provide as much detail about the problem
or feature as possible. New development is done in feature branches which
are eventually merged into master, base your features and fixes off master.

## Contact Us

You can join the VMFA-169 discord(https://discord.gg/6z8uERVW5Y) if you
would like to discuss DCT topics. The channel is
`#dynamic-campaign-tools-discussion`.
