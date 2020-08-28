/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://www.revolution-team.be - benitalpa1020@gmail.com
*/

//*********************************************************************
//*                       CORE MAIN FORWADS                           *
//*********************************************************************

forward void rp_OnClientDeath(int attacker, int victim, const char[] weapon, bool headshot);
forward void rp_OnClientSpawn(int client);
forward void rp_OnClientConnect(int client);
forward void rp_OnClientDisconnect(int client);
forward Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName);
forward Action rp_OnRunCmd(int client, int &buttons, int &impulse, int &weapon);
forward Action rp_OnTasedItem(int client, int aim, int reward, const char[] entName, const char[] entModel, const char[] entClassName);
forward Action rp_SayOnPublic(int client, const char[] arg, const char[] Cmd, int args);
forward Action rp_SayOnTeam(int client, const char[] arg, const char[] Cmd, int args);
forward Action rp_OnClientTakeDamage(int client, int attacker, int inflictor, float damage, int damagetype, const char[] weapon);
forward Action rp_OnWeaponFire(int client, int aim, const char[] weaponName);
forward Action rp_MenuBuild(int client, Menu menu);
forward int rp_HandlerMenuBuild(int client, const char[] info);
forward Action rp_MenuRoleplay(int client, Menu menu);
forward int rp_HandlerMenuRoleplay(int client, const char[] info);
forward Action rp_MenuMetier(int client, Menu menu);
forward int rp_HandlerMenuMetier(int client, const char[] info);
forward Action rp_MenuInventory(int client, Menu menu);
forward int rp_HandlerMenuInventory(int client, char[] info);
forward Action rp_MenuVendre(Menu menu, int client, int target);
forward int rp_HandleMenuVendre(int client, const char[] info);
forward Action rp_PushToInteraction(Menu menu, int client);
forward int rp_Handle_PushToInteraction(int client, const char[] info);
forward Action rp_reloadData();