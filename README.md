# Player Scaling by Addi

Hi, thanks for checking out my addon. I made this because I like geometry
and the idea of resizing players in pvp settings (such as TTT or deathmatch)
for dynamic gameplay. Although, I think it would be cool to see applications
in other gamemodes.

You can make big changes to it if you like (pls give me credit for original
addon design), but if you just want to configure some settings then see the
ConVars and settings table.

### Addon Features:
- Scale yourself with an sv_cheats console command, **"playerscale scale speed? jump? time"**
- Scale a player in code with a function, **playerscaling.setscale(ply, scale, dospeed, dojump, length)**
- When scaling completes, a hook **playerscaling_finish** runs with arguments **ply** and **info** table *(see lerp table in playerscaling.setscale)*
- (Adjustable) Players scale up or down gradually in a smooth animation
- (Toggleable) Player scaling moves players away from walls/ceiling so they don't get stuck, and halts if impossible
- (Toggleable/Adjustable) Player speed scales automatically
- (Toggleable/Adjustable) Player jump power scales automatically
- (Toggleable) Player view offset scales automatically
- (Toggleable) Player scales resets to 0 on death
- (Toggleable/Adjustable) Scaled player gravity is adjusted to feel more natural
- (Toggleable/Adjustable) Scaled up players take more speed to take fall damage
- (Adjustable) Clamps player scale to avoid breaking the game
- (Toggleable) Addon credits are printed into player consoles *(disabled by default)*

##### Friends
- Thanks to Meepen, Veri, and Opalium for tips as I made this