# **Player Scaling by Addi**

I made a prototype player scaling system for private use on my TTT server a while back, but recently decided to rework the entire thing and publish it as well. Player Scaling has a lot of potential for interesting gameplay: In pvp, players could shrink into smaller targets or grow into faster, more threatening attackers. In roleplay, players could customize their size to their liking. In sandbox, players could create tiny houses or giant lands. A creative map maker could even use player scaling to make a map with areas explorable only for players of the right size!

This addon has features that let the average player use it for fun on their own or with friends, but my real intention in making this was to create a highly customizable player scaling system that developers and server owners could use creatively to make fun experiences.

If you do end up using this in an interesting way, I'd love to hear about it! My github, of course, is https://github.com/itsmeaddof123/ and my steam profile is http://steamcommunity.com/id/add___123 . You can also contact me on discord at add___123#0773 .

## **Addon Usage:**
Scaling Console Command: **playerscale \<number scale\> \<boolean dospeed\> \<boolean dojump\> \<number time\>**
 - scale is the multiplier of player size, default 1
 - dospeed is a true/false value of if the player's speed should scale, default true
 - dojump is a true/false value of if the player's jump power should scale, default true
 - time is the length in seconds of the scaling process, calculates based on configuration if not provided
 - This commands requires sv_cheats 1
 - This console command directly calls the below function

Scaling Function: **playerscaling.setscale(\<Player ply\>, \<number scale\>, \<boolean dospeed\>, \<boolean dojump\>, \<number time\>)**
 - Same arguments with additional ply, the player to be scaled

Finished Scaling Hook: **"playerscaling_finish", function(\<Player ply\>, \<table info\>, \<string reason\>)**
 - ply is the player who was scaled
 - info is the table with information of the scaling (see playerscaling.lerp in sv_init.lua)
 - reason is whatever reason the scaling ended for
 - Not used in the code at this point, but you might find it useful if you are implementing the system

## **Customization:**
Server ConVars: (Found in sh_init.lua)
 - **playerscaling_speed** - Should scaling affect player speed by default?
 - **playerscaling_jump** - Should scaling affect player jump by default?
 - **playerscaling_uptime** - How much time should it take to scale up?
 - **playerscaling_downtime** - How much time should it take to scale down?
 - **playerscaling_death** - Should scaling reset on death?
 - **playerscaling_gravity** - Should scaling affect player gravity?
 - **playerscaling_fall** - Should scaling negate certain fall damage?
 - **playerscaling_clipping** - Should scaling prevent clipping into objects?
 - **playerscaling_pause** - Should scaling pause when stuck until unstuck?
 - **playerscaling_view** - Scale player perspective?
 - **playerscaling_step** - Scale player step size?
 - **playerscaling_maxsize** - Maximum size multiplier
 - **playerscaling_minsize** - Minimum size multiplier
 - **playerscaling_speedlarge** - Large player slowing factor
 - **playerscaling_speedsmall** - Small player speeding factor
 - **playerscaling_jumplarge** - Large player jump boost
 - **playerscaling_jumpsmall** - Small player jump lowering
 - **playerscaling_stepsmall** - Minimum step size for small players
 - **playerscaling_gravitylarge** - Large player gravity increase
 - **playerscaling_gravitysmall** - Small player gravity decrease
 - **playerscaling_falllarge** - Large player fall damage negation threshold
 - **playerscaling_credits** - If you enable this, players will see credits for this addon in console. :)

## **Other Features:**
- Players scale up and down with smooth animations
- Interrupting an in-process scale will not cause errors
- Players get moved away from potential obstructions when scaling up to avoid being stuck
- If a player cannot be moved during scaling, the scaling pauses until there is space
- Player speed scales with custom scaling
- Player jump power also has custom scaling
- Player view offset scales automatically
- Player scaling resets automatically on death
- Player gravity has custom scaling for more natural movement
- Prevents fall damage for large players below a custom speed threshold

#### Friends
 - Thanks to [Meepen](https://github.com/meepen/), Veri, and Opalium for tips as I made this
 - Also see Mee12345's [player resizing addon](https://steamcommunity.com/sharedfiles/filedetails/?id=2728389308)