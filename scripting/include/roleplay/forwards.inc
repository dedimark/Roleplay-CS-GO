/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://vr-hosting.fr - benitalpa1020@gmail.com
*/

//*********************************************************************
//*                       CORE MAIN FORWADS                           *
//*********************************************************************

/*
	Forward when a player death		
	@Param1 -> int attacker
	@Param2 -> int victim
	@Param3 -> int respawnTime	
	@return -
*/
forward void RP_OnPlayerDeath(int attacker, int victim, int respawnTime);

/*
	Forward when a player spawn	
	@Param1 -> int client
	@return -
*/
forward void RP_OnPlayerSpawn(int client);

/*
	Forward when a player join the server	
	@Param1 -> int client
	@return -
*/
forward void RP_OnPlayerConnect(int client);

/*
	Forward when a player left the server	
	@Param1 -> int client
	@return -
*/
forward void RP_OnPlayerDisconnect(int client);

/*
	Forward when a player press 'E'
	@Param1 -> int client
	@Param2 -> int target
	@Param3 -> int buttons
	@return -
*/
forward Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name);

/*
	Forward when a player press 'CTRL'(Duck)
	@Param1 -> int client
	@return -
*/
forward Action RP_OnPlayerDuck(int client);

/*
	Forward when a player press 'R'
	@Param1 -> int client
	@return -
*/
forward Action RP_OnPlayerReload(int client);

/*
	Forward when a player tase an entity
	@Param1 -> int client
	@Param2 -> int target
	@Param3 -> int reward
	@return -
*/
forward Action RP_OnPlayerTase(int client, int target, int reward, const char[] class, const char[] model, const char[] name);

/*
	Forward when a player use public chat
	@Param1 -> int client
	@Param2 -> char arg
	@return -
*/
forward Action RP_OnPlayerSay(int client, const char[] arg);

/*
	Forward when a player takes damage
	@Param1 -> int client
	@Param2 -> int attacker
	@Param2 -> int attacker
	@return -
*/
forward Action RP_OnPlayerTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype);

/*
	Forward when a player get hurted
	@Param1 -> int attacker
	@Param2 -> int victim
	@Param3 -> int dmg_armor
	@Param4 -> int dmg_health
	@Param5 -> char weapon
	@return -
*/
forward Action RP_OnPlayerGetHurt(int attacker, int victim, int dmg_armor, int dmg_health, const char[] weapon);

/*
	Forward when a player shot with a weapon
	@Param1 -> int client
	@Param2 -> int target
	@Param3 -> char weapon
	@return -
*/
forward Action RP_OnPlayerFire(int client, int target, const char[] weapon);

/*
	Forward when a player use /build command
	@Param1 -> int client
	@Param2 -> Menu menu
	@return -
*/
forward Action RP_OnPlayerBuild(int client, Menu menu);

/*
	Forward /build callback command
	@Param1 -> int client
	@Param2 -> char info
	@return -
*/
forward int RP_OnPlayerBuildHandle(int client, const char[] info);

/*
	Forward when a player use /rp command
	@Param1 -> int client
	@Param2 -> Menu menu
	@return -
*/
forward Action RP_OnPlayerRoleplay(int client, Menu menu);

/*
	Forward /rp callback command
	@Param1 -> int client
	@Param2 -> char info
	@return -
*/
forward int RP_OnPlayerRoleplayHandle(int client, const char[] info);

/*
	Forward when a player use /rp -> Settings command
	@Param1 -> int client
	@Param2 -> Menu menu
	@return -
*/
forward Action RP_OnPlayerSettings(int client, Menu menu);

/*
	Forward /rp -> Settings callback command
	@Param1 -> int client
	@Param2 -> char info
	@return -
*/
forward int RP_OnPlayerSettingsHandle(int client, const char[] info);

/*
	Forward when a player use metier menu
	@Param1 -> int client
	@Param2 -> Menu menu
	@return -
*/
forward Action RP_OnPlayerMetier(int client, Menu menu);

/*
	Forward metier menu callback
	@Param1 -> int client
	@Param2 -> char info
	@return -
*/
forward int RP_OnPlayerMetierHandle(int client, const char[] info);

/*
	Forward when a player use inventory menu
	@Param1 -> int client
	@Param2 -> Menu menu
	@return -
*/
forward Action RP_OnPlayerInventory(int client, Menu menu);

/*
	Forward inventory menu callback
	@Param1 -> int client
	@Param2 -> char info
	@return -
*/
forward int RP_OnPlayerInventoryHandle(int client, char[] info);

/*
	Forward sell menu
	@Param1 -> Menu client
	@Param2 -> int client
	@Param3 -> int target
	@return -
*/
forward Action RP_OnPlayerSell(Menu menu, int client, int target);

/*
	Forward sell menu callback
	@Param1 -> int client
	@Param2 -> char info
	@return -
*/
forward int RP_OnPlayerSellHandle(int client, const char[] info);

/*
	Forward E button player menu
	@Param1 -> Menu menu
	@Param2 -> int client
	@return -
*/
forward Action RP_PushToInteraction(Menu menu, int client);

/*
	Forward E button player menu callback
	@Param1 -> Menu menu
	@Param2 -> int client
	@return -
*/
forward int RP_PushToInteractionHandle(int client, const char[] info);

/*
	Forward when MYSQL Connection 
	@Param1 -> Database db
	@return -
*/
forward void RP_OnDatabaseLoaded(Database db);

/*
	Forward when licence loaded
	@Param1 -> bool licenceValid
	@return -
*/
forward void RP_OnLicenceLoaded(bool licenceValid);