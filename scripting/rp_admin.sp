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

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							C O M P I L E  -  O P T I O N S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#pragma semicolon 1
#pragma newdecls required

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N C L U D E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>
#include <emitsoundany>
#tryinclude <sourcebanspp>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  D E F I N E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#define MAXENTITIES		2048

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
char logFile[PLATFORM_MAX_PATH];
char steamID[MAXPLAYERS + 1][32];
char dbconfig[] = "roleplay";

Database g_DB;

ConVar fl_RestartTime;

int modelHalo;
int g_BeamSpriteFollow;
int compteurBombe[MAXPLAYERS+1];

float drugAngles[20] =  { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/

public Plugin myinfo = 
{
	name = "[Roleplay] Système Admin",
	author = "Benito",
	description = "Système Admin",
	version = VERSION,
	url = URL
};

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  E V E N T S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		GameCheck();
		
		fl_RestartTime = CreateConVar("rp_admin_reboot", "30.0", "Time to wait before the map restart.");
			
		AutoExecConfig(true, "rp_admin");
		
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_admin.log");
		LoadTranslations("rp_admin.phrases");
		Database.Connect(GotDatabase, dbconfig);
		
		RegConsoleCmd("rp_reboot", Cmd_Reboot);	
		RegConsoleCmd("rp_job", Command_SetJob);
		
		RegConsoleCmd("rp_info", Command_Info);
		
		RegConsoleCmd("rp_admin", Command_AdminGeneral);
		RegConsoleCmd("rp_dbskin", Command_DBSkin);
		RegConsoleCmd("rp_del", Command_Remove);
		RegConsoleCmd("rp_spawn_d", Command_SpawnDynamic);
		RegConsoleCmd("rp_spawn_p", Command_SpawnPhysics);
		RegConsoleCmd("rp_spawn_t", Command_SpawnThrow);
		RegConsoleCmd("rp_spawn_arme", Command_SpawnArme);
		RegConsoleCmd("rp_arme", Command_Arme);
		RegConsoleCmd("rp_tpa", Command_TPA);
		RegConsoleCmd("rp_tp", Command_TP);
		RegConsoleCmd("rp_rotate", Command_Rotate);
		RegConsoleCmd("rp_skin", Command_SetSkin);
		RegConsoleCmd("rp_vie", Command_Vie);
		RegConsoleCmd("rp_kevlar", Command_Kevlar);
		RegConsoleCmd("rp_advert", Command_Advert);
		RegConsoleCmd("rp_kick", Command_Kick);
		RegConsoleCmd("rp_noclip", Command_Noclip);
		RegConsoleCmd("rp_freeze", Command_Freeze);
		RegConsoleCmd("rp_gele", Command_Freeze);
		RegConsoleCmd("rp_slap", Command_Slap);
		RegConsoleCmd("rp_gifle", Command_Slap);
		RegConsoleCmd("rp_slay", Command_Slay);
		RegConsoleCmd("rp_tue", Command_Slay);
		RegConsoleCmd("rp_respawn", Command_Respawn);
		RegConsoleCmd("rp_revivre", Command_Respawn);
		RegConsoleCmd("rp_burn", Command_Burn);
		RegConsoleCmd("rp_brule", Command_Burn);
		RegConsoleCmd("rp_gravity", Command_Gravity);
		RegConsoleCmd("rp_gravite", Command_Gravity);
		RegConsoleCmd("rp_beacon", Command_Beacon);
		RegConsoleCmd("rp_balise", Command_Beacon);
		RegConsoleCmd("rp_bombe", Command_Bombe);
		RegConsoleCmd("rp_mute", Command_Mute);
		RegConsoleCmd("rp_gag", Command_Gag);
		RegConsoleCmd("rp_silence", Command_Silence);
		RegConsoleCmd("rp_drug", Command_Drug);
		RegConsoleCmd("rp_drogue", Command_Drug);
		RegConsoleCmd("rp_blind", Command_Blind);
		RegConsoleCmd("rp_aveugle", Command_Blind);
		RegConsoleCmd("rp_speed", Command_Vitesse);
		RegConsoleCmd("rp_vitesse", Command_Vitesse);
		RegConsoleCmd("rp_ban", Command_Ban);
		RegConsoleCmd("rp_map", Command_Map);
		RegConsoleCmd("rp_say", Command_Say);
		RegConsoleCmd("rp_dire", Command_Say);
		RegConsoleCmd("rp_setname", Command_EntitySetName);
		RegConsoleCmd("rp_invisibilite", Command_Invisibilite);
		RegConsoleCmd("rp_getpos", Command_GetPos);
	}
	else
		UnloadPlugin();	
}

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("DatabaseError", error);
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
	}
}

public void OnMapStart()
{
	modelHalo = PrecacheModel("sprites/halo.vmt", true);
	g_BeamSpriteFollow = PrecacheModel("materials/sprites/laserbeam.vmt");
	
	for(int i = MaxClients; i <= MAXENTITIES; i++)
	{
		if(IsValidEntity(i))
		{
			char entClass[64];
			Entity_GetClassName(i, STRING(entClass));
			if(StrEqual(entClass, "prop_door_rootating"))
				RemoveEdict(i);
		}
	}	
}	

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPostAdminCheck(int client) 
{	
	LoadAdmin(client);
}

public void LoadAdmin(int client) 
{
	if (!IsClientValid(client))
		return;
			
	KeyValues kv = new KeyValues("Admin");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/admins.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/admins.cfg : NOT FOUND");
	}	

	if(kv.JumpToKey(steamID[client]))
	{	
		char clientName[64];
		kv.GetString("adminname", STRING(clientName));	
		SetClientName(client, clientName);
		
		rp_SetClientInt(client, i_AdminLevel, kv.GetNum("level"));
		
		char rank[64];
		kv.GetString("displayrank", STRING(rank));
		rp_SetClientString(client, sz_AdminTag, STRING(rank));
		
		UpdateSQL(g_DB, "UPDATE api_players SET adminlevel = %i WHERE steamid = '%s';", kv.GetNum("level"), steamID[client]);	
		
		AdminId admin = CreateAdmin("VR-Hosting");
		SetUserAdmin(client, admin, false);
		SetAdminFlag(GetUserAdmin(client), view_as<AdminFlag>(14), true);
	}	
	
	kv.Rewind();	
	delete kv;
}

public Action rp_MenuRoleplay(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_AdminLevel) != 0)
	{	
		char display[64];
		Format(STRING(display), "%T", "Menu_Admin", LANG_SERVER);
		menu.AddItem("admin", display);
	}
}

public int rp_HandlerMenuRoleplay(int client, const char[] info)
{
	if(StrEqual(info, "admin"))
		BuildAdminMenu(client);
}	

int BuildAdminMenu(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoBuildAdminMenu);
	if(rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		menu.SetTitle("%T", "Menu_Moderator", LANG_SERVER);
	}	
	else
		menu.SetTitle("%T", "Menu_Admin", LANG_SERVER);
		
	char display[64];
	
	Format(STRING(display), "%T", "Menu_Setting_Players", LANG_SERVER, 1);
	menu.AddItem("", display, ITEMDRAW_DISABLED);
	
	if(rp_GetClientInt(client, i_AdminLevel) <= 2)
	{
		Format(STRING(display), "%T", "Menu_JobMenu", LANG_SERVER);
		menu.AddItem("job", display);
	}	
	
	Format(STRING(display), "%T", "Menu_Teleport", LANG_SERVER);
	menu.AddItem("tp", display);
	
	Format(STRING(display), "%T", "Menu_TeleportAt", LANG_SERVER);
	menu.AddItem("tpa", display);
	
	Format(STRING(display), "%T", "Menu_Skin", LANG_SERVER);
	menu.AddItem("skin", display);
	
	Format(STRING(display), "%T", "Menu_Weapon", LANG_SERVER);
	menu.AddItem("donnerarme", display);	
	
	Format(STRING(display), "%T", "Menu_Setting_Players", LANG_SERVER, 2);
	menu.AddItem("", display, ITEMDRAW_DISABLED);
	
	Format(STRING(display), "%T", "Menu_EditPlayer", LANG_SERVER);
	menu.AddItem("modifier", display);
	
	Format(STRING(display), "%T", "Menu_Kick", LANG_SERVER);
	menu.AddItem("kick", display);
	
	Format(STRING(display), "%T", "Menu_Ban", LANG_SERVER);
	menu.AddItem("ban", display);
	
	Format(STRING(display), "%T", "Menu_Slay", LANG_SERVER);
	menu.AddItem("slay", display);
	
	Format(STRING(display), "%T", "Menu_Respawn", LANG_SERVER);
	menu.AddItem("respawn", display);

	
	Format(STRING(display), "%T", "Menu_Setting_Players", LANG_SERVER, 3);
	menu.AddItem("", display, ITEMDRAW_DISABLED);
	
	Format(STRING(display), "%T", "Menu_Slap", LANG_SERVER);
	menu.AddItem("gifle", display);
	
	Format(STRING(display), "%T", "Menu_Freeze", LANG_SERVER);
	menu.AddItem("geler", display);
	
	Format(STRING(display), "%T", "Menu_Fire", LANG_SERVER);
	menu.AddItem("bruler", display);
	
	Format(STRING(display), "%T", "Menu_Mark", LANG_SERVER);
	menu.AddItem("baliser", display);
	
	Format(STRING(display), "%T", "Menu_Bomb", LANG_SERVER);
	menu.AddItem("bombe", display);
	
	Format(STRING(display), "%T", "Menu_Setting_Players", LANG_SERVER, 4);
	menu.AddItem("", display, ITEMDRAW_DISABLED);
	
	Format(STRING(display), "%T", "Menu_Mute", LANG_SERVER);
	menu.AddItem("mute", display);
	
	Format(STRING(display), "%T", "Menu_Silence", LANG_SERVER);
	menu.AddItem("silence", display);
	
	Format(STRING(display), "%T", "Menu_Drug", LANG_SERVER);
	menu.AddItem("drogueur", display);
	
	Format(STRING(display), "%T", "Menu_Blind", LANG_SERVER);
	menu.AddItem("aveugler", display);
	
	Format(STRING(display), "%T", "Menu_Setting_Prop", LANG_SERVER);
	menu.AddItem("", display, ITEMDRAW_DISABLED);
	
	Format(STRING(display), "%T", "Menu_Props", LANG_SERVER);
	menu.AddItem("props", display);
	
	Format(STRING(display), "%T", "Menu_Rotation", LANG_SERVER);
	menu.AddItem("rotate", display);
	
	Format(STRING(display), "%T", "Menu_Info", LANG_SERVER);
	menu.AddItem("info", display);
	
	Format(STRING(display), "%T", "Menu_Setting_Roleplay", LANG_SERVER, 1);
	menu.AddItem("", display, ITEMDRAW_DISABLED);
	
	Format(STRING(display), "%T", "Menu_Advert", LANG_SERVER);
	menu.AddItem("advert", display);
	
	Format(STRING(display), "%T", "Menu_RestartMap", LANG_SERVER);
	menu.AddItem("map", display);
	
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		Format(STRING(display), "%T", "Menu_Setting_Roleplay", LANG_SERVER, 2);
		menu.AddItem("", display, ITEMDRAW_DISABLED);
		
		Format(STRING(display), "%T", "Menu_Permissions", LANG_SERVER);
		menu.AddItem("droitadmin", display);
		
		Format(STRING(display), "%T", "Menu_Zoning", LANG_SERVER);
		menu.AddItem("zoning", display);
		
		Format(STRING(display), "%T", "Menu_Plugins", LANG_SERVER);
		menu.AddItem("plugins", display);
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoBuildAdminMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "job"))
			MenuSetJob(client);
		else if(StrEqual(info, "tp"))
			MenuTp(client);
		else if(StrEqual(info, "tpa"))
			MenuTpa(client);
		else if(StrEqual(info, "skin"))
			MenuSkin(client);
		else if(StrEqual(info, "donnerarme"))
			MenuArme(client);
		else if(StrEqual(info, "modifier"))
			MenuModifierJoueur(client);
		else if(StrEqual(info, "kick"))
			MenuKick(client);
		else if(StrEqual(info, "ban"))
			MenuBan(client);
		else if(StrEqual(info, "slay"))
			MenuSlay(client);
		else if(StrEqual(info, "respawn"))
			MenuRespawn(client);
		else if(StrEqual(info, "gifle"))
			MenuGifle(client);
		else if(StrEqual(info, "geler"))
			MenuGeler(client);
		else if(StrEqual(info, "bruler"))
			MenuBruler(client);
		else if(StrEqual(info, "baliser"))
			MenuBaliser(client);
		else if(StrEqual(info, "bombe"))
			MenuBombe(client);
		else if(StrEqual(info, "mute"))
			MenuMute(client);
		else if(StrEqual(info, "gag"))
			MenuGag(client);
		else if(StrEqual(info, "silence"))
			MenuSilence(client);
		else if(StrEqual(info, "droguer"))
			MenuDroguer(client);
		else if(StrEqual(info, "aveugler"))
			MenuAveugler(client);
		else if(StrEqual(info, "info"))
		{
			ClientCommand(client, "rp_admininfo");
			BuildAdminMenu(client);
		}
		else if(StrEqual(info, "props"))
			MenuPropsType(client);
		else if(StrEqual(info, "rotate"))
			MenuRotation(client);
		else if(StrEqual(info, "advert"))
		{
			ClientCommand(client, "rp_advert");
			BuildAdminMenu(client);
		}
		else if(StrEqual(info, "map"))
			ClientCommand(client, "rp_reboot");
		else if(StrEqual(info, "droitadmin"))
			MenuGererAdmin(client);
		else if(StrEqual(info, "plugins"))	
			MenuDisplayPlugins(client);	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}	

public Action Cmd_Reboot(int client, int args)
{
	if (rp_GetClientInt(client, i_AdminLevel) == 0)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}	
	
	char translate[128];
	Format(STRING(translate), "%T", "RebootIn", LANG_SERVER, GetConVarInt(fl_RestartTime));	
	CPrintToChatAll("%s %s", TEAM, translate);
	
	int cooldown = GetConVarInt(fl_RestartTime);
	DataPack pack = new DataPack();
	pack.WriteCell(cooldown);
	CreateDataTimer(1.0, Timer_Restart_CoolDown, pack, TIMER_REPEAT);
	delete pack;
	CreateTimer(GetConVarFloat(fl_RestartTime), Timer_RestartMap);
	
	return Plugin_Handled;
}	

public Action Timer_Restart_CoolDown(Handle timer, DataPack pack)
{
	int cooldown;
	pack.Reset();
	cooldown = pack.ReadCell();
	
	if(cooldown <= 10 && cooldown > 0)
	{
		char translate[128];
		Format(STRING(translate), "%T", "RebootIn", LANG_SERVER, GetConVarInt(fl_RestartTime));	
		CPrintToChatAll("%s %s", TEAM, translate);
	}
	if(cooldown == 20)
	{
		char translate[128];
		Format(STRING(translate), "%T", "RebootIn", LANG_SERVER, GetConVarInt(fl_RestartTime));	
		CPrintToChatAll("%s %s", TEAM, translate);
	}
	cooldown--;
	
	if(cooldown == 0.0)
	{
		TrashTimer(timer, true);
		delete timer;
	}	
}

public Action Timer_RestartMap(Handle timer)
{
	char translate[64];
	Format(STRING(translate), "%T", "Reboot", LANG_SERVER, GetConVarInt(fl_RestartTime));	
	CPrintToChatAll("%s %s", TEAM, translate);
	
	char map[128];
	rp_GetCurrentMap(map);
	
	PrintToServer("map %s", map);
	
	char hostname[128];
	GetConVarString(FindConVar("hostname"), STRING(hostname));
	
	DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
	hook.SlackMode = true;	
	hook.SetUsername("Roleplay");	
	
	MessageEmbed Embed = new MessageEmbed();	
	Embed.SetColor("#00fd29");
	Embed.SetTitle(hostname);
	Embed.SetTitleLink("steam://connect/163.172.72.143:27115");
	Embed.AddField("Message", "%T", true, "Discord_Reboot", LANG_SERVER, map);
	Embed.SetFooter("Roleplay CS:GO By VR-Hosting");
	Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
	Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
	
	hook.Embed(Embed);	
	hook.Send();
	delete hook;
}


/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  M E N U

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/

Menu MenuSetJob(int client)
{
	if(rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return;
	}
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuSetJob);
	menu.SetTitle("%T", "SubMenu_JobMenu", LANG_SERVER);
	
	char name[32], strIndex[8];
	LoopClients(i)
	{
		GetClientName(i, STRING(name));
		Format(STRING(strIndex), "%i", i);
		menu.AddItem(strIndex, name);
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

Menu MenuKick(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuKick);
	menu.SetTitle("Qui voulez-vous exlure ?");
	PerformListeJoueur(menu, client, false, false, false);
}

Menu MenuBan(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuBan);
	menu.SetTitle("Qui voulez-vous bannir ?");
	PerformListeJoueur(menu, client, false, false, false);
}

Menu MenuTp(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuTp);
	menu.SetTitle("Qui voulez-vous téléporter ?");
	PerformListeJoueur(menu, client, true, true, true);
}

Menu MenuTpa(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuTpa);
	menu.SetTitle("Qui voulez-vous téléporter sur vous ?");
	PerformListeJoueur(menu, client, true, true, false);
}

Menu MenuSlay(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuSlay);
	menu.SetTitle("Qui voulez-vous tuer ?");
	PerformListeJoueur(menu, client, true, true, true);
}

Menu MenuRespawn(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuRespawn);
	menu.SetTitle("Qui voulez-vous faire revivre ?");
	PerformListeJoueur(menu, client, true, false, true);
}

Menu MenuGifle(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuGifle);
	menu.SetTitle("Qui voulez-vous gifler ?");
	PerformListeJoueur(menu, client, true, true, true);
}

Menu MenuGeler(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuGeler);
	menu.SetTitle("Qui voulez-vous geler ?");
	PerformListeJoueur(menu, client, true, true, true);
}

Menu MenuBruler(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuBruler);
	menu.SetTitle("Qui voulez-vous bruler ?");
	PerformListeJoueur(menu, client, true, true, true);
}

Menu MenuBaliser(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuBalise);
	menu.SetTitle("Qui voulez-vous baliser ?");
	PerformListeJoueur(menu, client, true, true, true);
}

Menu MenuBombe(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuBombe);
	menu.SetTitle("Qui va reçevoir une bombe ?");
	PerformListeJoueur(menu, client, true, true, true);
}

Menu MenuMute(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuMute);
	menu.SetTitle("Qui voulez-vous muter ?");
	PerformListeJoueur(menu, client, true, true, false);
}

Menu MenuGag(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuGag);
	menu.SetTitle("Qui voulez-vous gager ?");
	PerformListeJoueur(menu, client, true, true, false);
}

Menu MenuSilence(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuSilence);
	menu.SetTitle("Qui doit-être silence ?");
	PerformListeJoueur(menu, client, true, true, false);
}

Menu MenuDroguer(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuDroguer);
	menu.SetTitle("Qui voulez-vous droguer ?");
	PerformListeJoueur(menu, client, true, true, true);
}

Menu MenuAveugler(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuAveugler);
	menu.SetTitle("Qui voulez-vous aveugler ?");
	PerformListeJoueur(menu, client, true, true, true);
}

Menu MenuPropsDynamic(int client)
{
	Menu menu = new Menu(DoMenuPropsDyn);
	menu.SetTitle("Prop dynamique :");
	
	menu.AddItem("models/props/de_vertigo/barrelwarning_clean.mdl", "Plot");
	menu.AddItem("models/props_fortifications/orange_cone001_reference.mdl", "Petit Plot");
	menu.AddItem("modeleprefabriques", "> Modèles pré-fabriqués", ITEMDRAW_DISABLED);
	menu.AddItem("models/props/de_nuke/hr_nuke/nuke_vending_machine/nuke_vending_machine.mdl", "Distributeur de nourriture");
	menu.AddItem("models/props_unique/atm01.mdl", "Distributeur de billet");
	menu.AddItem("models/props_equipment/phone_booth.mdl", "Cabine téléphonique");
	menu.AddItem("models/props_wasteland/interior_fence002c.mdl", "(Petite) Barrière en métal");
	menu.AddItem("models/props_wasteland/interior_fence002d.mdl", "(Moyenne) Barrière en métal");
	menu.AddItem("models/props_wasteland/exterior_fence002e.mdl", "(Grande) Barrière en métal");
	menu.AddItem("models/props/cs_office/rolling_gate.mdl", "Grande porte grillagée");
	menu.AddItem("models/props/de_nuke/nuclearcontainerboxclosed.mdl", "Boite en carton");
	menu.AddItem("models/props_office/file_cabinet_03.mdl", "Casier de rangement");
	menu.AddItem("models/props_office/desk_01.mdl", "Bureau");
	menu.AddItem("models/props_office/computer_monitor_01.mdl", "Ecran d'ordinateur");
	menu.AddItem("models/props/cs_office/computer.mdl", "Ordinateur");
	menu.AddItem("models/props_interiors/chair_office2.mdl", "Chaise de bureau");
	menu.AddItem("models/props/cs_assault/box_stack1.mdl", "Caisse de boites en carton");
	menu.AddItem("models/props/cs_assault/forklift_new.mdl", "Transpalette");
	menu.AddItem("models/props/cs_assault/moneypallet02.mdl", "Palette de billets");
	menu.AddItem("models/props/cs_assault/pylon.mdl", "Plot jaune");
	menu.AddItem("models/props/cs_militia/crate_extrasmallmill.mdl", "Caisse en bois (1)");
	menu.AddItem("models/props/cs_office/crate_office_indoor_64.mdl", "Caisse en bois (2)");
	menu.AddItem("models/props/cs_militia/militiarock03.mdl", "Rocher (1)");
	menu.AddItem("models/props/cs_militia/militiarock06.mdl", "Rocher (2)");
	menu.AddItem("models/props/cs_office/plant01.mdl", "Plant de drogue");
	menu.AddItem("models/props/cs_office/table_meeting.mdl", "Table de réunion");
	menu.AddItem("models/props/cs_militia/haybale_target.mdl", "Cible de tir n°1");
	menu.AddItem("models/props/cs_militia/haybale_target_02.mdl", "Cible de tir n°2");
	menu.AddItem("models/props/cs_militia/haybale_target_03.mdl", "Cible de tir n°3");
	menu.AddItem("models/props/de_boathouse/boat_inflatable01.mdl", "Bateau n°1");
	menu.AddItem("models/props/de_shacks/boat_smash.mdl", "Bateau n°2");
	menu.AddItem("models/props/de_cbble/cobble_flagpole.mdl", "Drapeau");
	menu.AddItem("models/props_survival/dronegun/dronegun.mdl", "Sentry Gun");
	menu.AddItem("", "Plus via rp_spawn_d models/monprops.mdl", ITEMDRAW_DISABLED);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

Menu MenuPropsPhysics(int client)
{
	Menu menu = new Menu(DoMenuPropsPhys);
	menu.SetTitle("Prop physique :");
	menu.AddItem("models/props/cs_office/water_bottle.mdl", "Bouteille d'eau");
	menu.AddItem("models/props/cs_italy/orange.mdl", "Orange");
	menu.AddItem("models/props/de_inferno/goldfish.mdl", "Poisson rouge");
	if (IsBenito(client))
		menu.AddItem("models/props/cs_italy/bananna_bunch.mdl", "Banane");
	menu.AddItem("", "Plus via rp_spawn_p models/monprops.mdl", ITEMDRAW_DISABLED);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

Menu MenuPropsThrow(int client)
{
	Menu menu = new Menu(DoMenuPropsThr);
	menu.SetTitle("Prop jetable :");
	menu.AddItem("models/props/cs_italy/orange.mdl", "Orange");
	menu.AddItem("models/props_unique/airport/atlas_break_ball.mdl", "Globe Terrestre");
	menu.AddItem("", "Plus via rp_spawn_t models/monprops.mdl", ITEMDRAW_DISABLED);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

Menu MenuRotation(int client)
{
	Menu menu = new Menu(DoMenuRotation);
	menu.SetTitle("Tourner un prop :");
	menu.AddItem("x", "Selon l'axe i");
	menu.AddItem("y", "Selon l'axe Y");
	menu.AddItem("z", "Selon l'axe Z");
	menu.ExitButton = true;
	menu.Display( client, MENU_TIME_FOREVER);
}

Menu MenuGererAdmin(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuGererAdmin);
	menu.SetTitle("Éditer les droits de :");
	char strMenu[32], strFormat[64];
	LoopClients(i)
	{
		Format(STRING(strMenu), "%i", i);
		if(rp_GetClientInt(i, i_AdminLevel) == 1)
			Format(STRING(strFormat), "%N [FONDATEUR]", i);
		else if(rp_GetClientInt(i, i_AdminLevel) == 2)
			Format(STRING(strFormat), "%N [2]", i);
		else if(rp_GetClientInt(i, i_AdminLevel) == 3)
			Format(STRING(strFormat), "%N [ADMIN]", i);	
		else if(rp_GetClientInt(i, i_AdminLevel) == 4)
			Format(STRING(strFormat), "%N [MODO]", i);
		else if(rp_GetClientInt(i, i_AdminLevel) == 5)
			Format(STRING(strFormat), "%N [MEMBRE]", i);
		if(client != i)
			menu.AddItem(strMenu, strFormat);
		else
			menu.AddItem("", strFormat, ITEMDRAW_DISABLED);
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

Menu MenuSkin(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuSkin);
	menu.SetTitle("Modifier un skin :");
	menu.AddItem("temp", "Temporairement");
	menu.AddItem("perm", "Permanent");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

Menu MenuArme(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuArmeChoix);
	PerformListeJoueur(menu, true, true, true);
}

Menu MenuModifierJoueur(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuModifierJoueur);
	menu.SetTitle("Qui voulez-vous modifier ?");
	PerformListeJoueur(menu, client, true, true, true);
}

Menu MenuPropsType(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuChoixTypeProps);
	menu.SetTitle( "Créer un props de type:");
	menu.AddItem("dynamic", "Dynamique");
	menu.AddItem("physics", "Physique");
	menu.AddItem("throw", "Jetable");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

Menu MenuArmeChoix(int client, char[] info)
{
	char strFormat[128];
	Menu menu = new Menu(DoMenuArmeFinal);
	menu.SetTitle("Choix de l'arme :");
	Format(STRING(strFormat), "%s p2000", info);
	menu.AddItem(strFormat, "P2000");
	Format(STRING(strFormat), "%s usp", info);
	menu.AddItem(strFormat, "USP-S");
	Format(STRING(strFormat), "%s tec9", info);
	menu.AddItem(strFormat, "Tec-9");
	Format(STRING(strFormat), "%s glock", info);
	menu.AddItem(strFormat, "Glock-18");
	Format(STRING(strFormat), "%s p250", info);
	menu.AddItem(strFormat, "P250");
	Format(STRING(strFormat), "%s deagle", info);
	menu.AddItem(strFormat, "Desert Eagle");
	Format(STRING(strFormat), "%s fiveseven", info);
	menu.AddItem(strFormat, "Five-Seven");
	Format(STRING(strFormat), "%s elite", info);
	menu.AddItem(strFormat, "Dual Berettas");
	Format(STRING(strFormat), "%s cz75", info);
	menu.AddItem(strFormat, "CZ75-Auto");
	Format(STRING(strFormat), "%s mac10", info);
	menu.AddItem(strFormat, "MAC-10");
	Format(STRING(strFormat), "%s mp9", info);
	menu.AddItem(strFormat, "MP9");
	Format(STRING(strFormat), "%s bizon", info);
	menu.AddItem(strFormat, "PP-Bizon");
	Format(STRING(strFormat), "%s ump45", info);
	menu.AddItem(strFormat, "UMP45");
	Format(STRING(strFormat), "%s mp7", info);
	menu.AddItem(strFormat, "MP7");
	Format(STRING(strFormat), "%s p90", info);
	menu.AddItem(strFormat, "P90");
	Format(STRING(strFormat), "%s sawedoff", info);
	menu.AddItem(strFormat, "Sawed-Off");
	Format(STRING(strFormat), "%s nova", info);
	menu.AddItem(strFormat, "Nova");
	Format(STRING(strFormat), "%s xm1014", info);
	menu.AddItem(strFormat, "XM1014");
	Format(STRING(strFormat), "%s galilar", info);
	menu.AddItem(strFormat, "Galil AR");
	Format(STRING(strFormat), "%s famas", info);
	menu.AddItem(strFormat, "Famas");
	Format(STRING(strFormat), "%s ak47", info);
	menu.AddItem(strFormat, "AK-47");
	Format(STRING(strFormat), "%s m4a4", info);
	menu.AddItem(strFormat, "M4A4");
	Format(STRING(strFormat), "%s aug", info);
	menu.AddItem(strFormat, "Steayr AUG");
	Format(STRING(strFormat), "%s sg553", info);
	menu.AddItem(strFormat, "SG 553");
	Format(STRING(strFormat), "%s m249", info);
	menu.AddItem(strFormat, "M249");
	Format(STRING(strFormat), "%s negev", info);
	menu.AddItem(strFormat, "Negev");
	Format(STRING(strFormat), "%s ssg08", info);
	menu.AddItem(strFormat, "SSG 08");
	Format(STRING(strFormat), "%s awp", info);
	menu.AddItem(strFormat, "AWP");
	Format(STRING(strFormat), "%s scar20", info);
	menu.AddItem(strFormat, "SCAR-20");
	Format(STRING(strFormat), "%s g3sg1", info);
	menu.AddItem(strFormat, "G3SG/1");
	Format(STRING(strFormat), "%s m4a1", info);
	menu.AddItem(strFormat, "Maverick M4A1 Carbine");
	Format(STRING(strFormat), "%s taser", info);
	menu.AddItem(strFormat, "Taser");
	Format(STRING(strFormat), "%s hegrenade", info);
	menu.AddItem(strFormat, "Grenade");
	Format(STRING(strFormat), "%s flashbang", info);
	menu.AddItem(strFormat, "Grenade Flashbang (GSS)");
	Format(STRING(strFormat), "%s smoke", info);
	menu.AddItem(strFormat, "Grenade fumigène");
	Format(STRING(strFormat), "%s incendiaire", info);
	menu.AddItem(strFormat, "Grenade incendiaire");
	Format(STRING(strFormat), "%s molotov", info);
	menu.AddItem(strFormat, "Cocktail Molotov");
	Format(STRING(strFormat), "%s leurre", info);
	menu.AddItem(strFormat, "Grenade leurre");
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

/**********************************************************/

/******************* Menu Handler *********************/

public int DoMenuSetJob(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strMenu[64];
		menu.GetItem(param, STRING(info));
		int joueur = StringToInt(info);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu SetJob = new Menu(DoMenuSetJobSub);
		SetJob.SetTitle("Gérer le métier de %N :", joueur);
		
		Format(STRING(strMenu), "0|%i", joueur);
		SetJob.AddItem(strMenu, "Sans emploi");
		
		Format(STRING(strMenu), "1|%i", joueur);
		SetJob.AddItem(strMenu, "Police");
		
		Format(STRING(strMenu), "2|%i", joueur);
		SetJob.AddItem(strMenu, "Mafia");
		
		Format(STRING(strMenu), "3|%i", joueur);
		SetJob.AddItem(strMenu, "18Th");
		
		Format(STRING(strMenu), "4|%i", joueur);
		SetJob.AddItem(strMenu, "Hôpital");
		
		Format(STRING(strMenu), "5|%i", joueur);
		SetJob.AddItem(strMenu, "Mairie");
		
		Format(STRING(strMenu), "6|%i", joueur);
		SetJob.AddItem(strMenu, "Armurier");
		
		Format(STRING(strMenu), "7|%i", joueur);
		SetJob.AddItem(strMenu, "Justice");
		
		Format(STRING(strMenu), "8|%i", joueur);
		SetJob.AddItem(strMenu, "Immobilier");
		
		Format(STRING(strMenu), "9|%i", joueur);
		SetJob.AddItem(strMenu, "Dealer");
		
		Format(STRING(strMenu), "10|%i", joueur);
		SetJob.AddItem( strMenu, "Technicien");
		
		Format(STRING(strMenu), "11|%i", joueur);
		SetJob.AddItem(strMenu, "Banquier");
		
		Format(STRING(strMenu), "12|%i", joueur);
		SetJob.AddItem(strMenu, "Assassin");
		
		Format(STRING(strMenu), "13|%i", joueur);
		SetJob.AddItem(strMenu, "Artificier");
		
		Format(STRING(strMenu), "14|%i", joueur);
		SetJob.AddItem(strMenu, "Vendeur de skin");
		
		Format(STRING(strMenu), "15|%i", joueur);
		SetJob.AddItem(strMenu, "McDonald's");
		
		Format(STRING(strMenu), "16|%i", joueur);
		SetJob.AddItem(strMenu, "Loto");
		
		Format(STRING(strMenu), "17|%i", joueur);
		SetJob.AddItem(strMenu, "Coach");
		
		Format(STRING(strMenu), "18|%i", joueur);
		SetJob.AddItem(strMenu, "SexShop");
		
		Format(STRING(strMenu), "19|%i", joueur);
		SetJob.AddItem(strMenu, "Eboueur");
		
		SetJob.ExitBackButton = true;
		SetJob.ExitButton = true;
		SetJob.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuSetJobSub(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32], buffer[2][8];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 2, 8);
		int numeroJob = StringToInt(buffer[0]);
		int joueur = StringToInt(buffer[1]);
		
		if(numeroJob != 0)
		{
			rp_SetClientBool(client, b_menuOpen, true);
			Menu SetJobSub2 = new Menu(DoMenuSetJobFinal);
			SetJobSub2.SetTitle("Gérer le grade de %N :", joueur);
			
			char strMenu[32];
			if(numeroJob == 1)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Commandant");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Capitaine");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Lieutenant");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Inspecteur");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Policier");
				Format(STRING(strMenu), "%i|6|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Gardien");
			}
			else if(numeroJob == 2)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef famille");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Bras droit");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Yakuza");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Grand frère");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Petit frère");
			}
			else if(numeroJob == 3)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Boss");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Bras droit");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Caïd");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Gangster");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Guetteur");
			}
			else if(numeroJob == 4)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur adjoint");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Cancérologue");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chirurgien");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Médecin");
			}
			else if(numeroJob == 5)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Maire");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Adjoint au maire");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Fonctionnaire");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Intérimaire");
			}
			else if(numeroJob == 6)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur adjoint");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Expert");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Artisan");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Marchand");
			}
			else if(numeroJob == 7)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Président Justice");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Vice-Président Justice");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Haut Juge");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Juge Fédéral");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Juge Pénal");
				Format(STRING(strMenu), "%i|6|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Magistrat");
				Format(STRING(strMenu), "%i|7|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Avocat");
			}
			else if(numeroJob == 8)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur adjoint");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Expert");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Agent");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Stagiaire");
			}
			else if(numeroJob == 9)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Bras droit");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chimiste");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Dealer");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Guetteur");
			}
			else if(numeroJob == 10)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Ingénieur");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Hacker");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Technicien");
			}
			else if(numeroJob == 11)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur adjoint");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Expert");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Assureur");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Stagiaire");
			}
			else if(numeroJob == 12)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Espion");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Tueur à gages");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Criminel");
			}
			else if(numeroJob == 13)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Artificier Pro");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Artificier Novice");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Artificier");
			}
			else if(numeroJob == 14)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Sapeur");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Vendeur confirmé");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Vendeur");
			}
			else if(numeroJob == 15)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Patron");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Patron adjoint");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Manager");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Cuisto");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Apprenti");
			}
			else if(numeroJob == 16)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Huissier");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Buraliste");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Vendeur de Tickets");
			}
			else if(numeroJob == 17)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Manager");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Coach");
			}
			else if(numeroJob == 18)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Manager");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Garde d'entrée");
			}
			else if(numeroJob == 19)
			{
				Format(STRING(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(STRING(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(STRING(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Surveillant");
				Format(STRING(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Recycleur");
				Format(STRING(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Eboueur");
			}
			SetJobSub2.ExitBackButton = true;
			SetJobSub2.ExitButton = true;
			SetJobSub2.Display(client, MENU_TIME_FOREVER);
		}
		else
		{
			char oldJob[64];
			GetJobName(rp_GetClientInt(joueur, i_Job), oldJob);
			
			rp_SetClientInt(joueur, i_Job, 0);
			rp_SetClientInt(joueur, i_Grade, 0);
			
			char newJob[64];
			GetJobName(rp_GetClientInt(joueur, i_Job), newJob);
			
			char hostname[128];
			GetConVarString(FindConVar("hostname"), STRING(hostname));
			
			char patronName[64];
			GetClientName(client, STRING(patronName));
			
			char employeName[64];
			GetClientName(joueur, STRING(employeName));
			
			DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
			hook.SlackMode = true;	
			hook.SetUsername("Roleplay");	
			
			MessageEmbed Embed = new MessageEmbed();	
			Embed.SetColor("#00fd29");
			Embed.SetTitle(hostname);
			Embed.SetTitleLink("steam://connect/163.172.72.143:27115");
			Embed.AddField("Message", "%N a mis %N %s" , false, client, joueur, newJob);
			Embed.AddField("Ancien Job", oldJob, false);
			Embed.AddField("Nouveau job", newJob, false);
			Embed.AddField("Patron", "%N", true, client);
			Embed.AddField("Employé", "%N", true, joueur);
			Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
			Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
			Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
			
			hook.Embed(Embed);	
			hook.Send();
			delete hook;
			
			ChangeClientTeam(joueur, 2);
			
			LoadSalaire(joueur);			
			UpdateSQL(g_DB, "UPDATE rp_jobs SET jobid = %i, gradeid = %i WHERE steamid = '%s';", 0, 0, steamID[joueur]);
	
			if(joueur != client)
			{
				CPrintToChat(client, "%s Vous avez viré %N, il est maintenant sans emploi.", TEAM, joueur);
				CPrintToChat(joueur, "%s Vous avez été viré, vous êtes sans emploi.", TEAM);
			}
			else
				CPrintToChat(client, "%s Vous êtes maintenant sans emploi.", TEAM);
			rp_SetClientBool(client, b_menuOpen, false);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuSetJobFinal(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		rp_SetClientBool(client, b_menuOpen, false);
		char info[32], buffer[3][8];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 3, 8);
		int numeroJob = StringToInt(buffer[0]);
		int numeroGrade = StringToInt(buffer[1]);
		int joueur = StringToInt(buffer[2]);
		
		char oldJobName[64], oldGrade[64], oldJob[64];	
		GetJobName(rp_GetClientInt(joueur, i_Job), oldJobName);
		GetGradeName(rp_GetClientInt(joueur, i_Grade), rp_GetClientInt(joueur, i_Job), oldGrade);
		Format(STRING(oldJob), "%s %s", oldGrade, oldJobName);
		
		if(numeroJob != 0)
		{
			rp_SetClientInt(joueur, i_Job, numeroJob);
			rp_SetClientInt(joueur, i_Grade, numeroGrade);				
			UpdateSQL(g_DB, "UPDATE rp_jobs SET jobid = %i, gradeid = %i WHERE steamid = '%s';", numeroJob, numeroGrade, steamID[joueur]);
		}
		else
		{
			rp_SetClientInt(joueur, i_Job, 0);
			rp_SetClientInt(joueur, i_Grade, 0);				
			UpdateSQL(g_DB, "UPDATE rp_jobs SET jobid = %i, gradeid = %i WHERE steamid = '%s';", 0, 0, steamID[joueur]);
		}	
		LoadSalaire(joueur);	
		
		char jobName[64], gradeName[64];
		GetJobName(rp_GetClientInt(joueur, i_Job), jobName);
		GetGradeName(rp_GetClientInt(joueur, i_Grade), rp_GetClientInt(joueur, i_Job), gradeName);
		
		char hostname[128];
		GetConVarString(FindConVar("hostname"), STRING(hostname));
		
		DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
		hook.SlackMode = true;	
		hook.SetUsername("Roleplay");	
		
		MessageEmbed Embed = new MessageEmbed();	
		Embed.SetColor("#00fd29");
		Embed.SetTitle(hostname);
		Embed.SetTitleLink("steam://connect/163.172.72.143:27115");
		Embed.AddField("Message", "%N a mis %N (%s %s)", false, client, joueur, gradeName, jobName);		
		Embed.AddField("Ancien Job", oldJob, false);
		Embed.AddField("Nouveau job", "%s %s", false, gradeName, jobName);
		Embed.AddField("Patron", "%N", true, client);
		Embed.AddField("Employé", "%N", true, joueur);
		Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
		Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
		Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
		
		hook.Embed(Embed);	
		hook.Send();
		delete hook;
		
		if(joueur != client)
		{
			CPrintToChat(client, "%s Vous avez promu %N en tant que %s (%s).", TEAM, joueur, gradeName, jobName);
			CPrintToChat(joueur, "%s Vous avez été promu %s (%s) par %N.", TEAM, gradeName, jobName, client);
		}
		else
			CPrintToChat(client, "%s Vous êtes maintenant %s (%s).", TEAM, gradeName, jobName);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuKick(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32], strCmd[64];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Menu KickFinal = new Menu(DoMenuKickFinal);
		KickFinal.SetTitle("Raison de l'exclusion :");
		Format(STRING(strCmd), "rp_kick %s", info);
		PerformRaison(KickFinal, client, strCmd);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuKickFinal(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128];
		menu.GetItem(param, STRING(info));
		
		ClientCommand(client, info);
		MenuKick(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuKick(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuBan(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32], strFormat[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Menu BanTime = new Menu(DoMenuBanTime);
		BanTime.SetTitle("Délais du bannissement :");
		
		Format(STRING(strFormat), "rp_ban %s 15", info);
		BanTime.AddItem(strFormat, "15 minutes");
		
		Format(STRING(strFormat), "rp_ban %s 30", info);
		BanTime.AddItem(strFormat, "30 minutes");
		
		Format(STRING(strFormat), "rp_ban %s 60", info);
		BanTime.AddItem(strFormat, "1 heure");
		
		Format(STRING(strFormat), "rp_ban %s 120", info);
		BanTime.AddItem(strFormat, "2 heures");
		
		Format(STRING(strFormat), "rp_ban %s 360", info);
		BanTime.AddItem(strFormat, "6 heures");
		
		Format(STRING(strFormat), "rp_ban %s 720", info);
		BanTime.AddItem(strFormat, "12 heures");
		
		Format(STRING(strFormat), "rp_ban %s 1080", info);
		BanTime.AddItem(strFormat, "18 heures");
		
		Format(STRING(strFormat), "rp_ban %s 1440", info);
		BanTime.AddItem(strFormat, "1 jour");
		
		Format(STRING(strFormat), "rp_ban %s 2880", info);
		BanTime.AddItem(strFormat, "2 jours");
		
		Format(STRING(strFormat), "rp_ban %s 4320", info);
		BanTime.AddItem(strFormat, "3 jours");
		
		Format(STRING(strFormat), "rp_ban %s 10080", info);
		BanTime.AddItem(strFormat, "1 semaine");
		
		Format(STRING(strFormat), "rp_ban %s 43200", info);
		BanTime.AddItem(strFormat, "1 mois");
		
		Format(STRING(strFormat), "rp_ban %s 0", info);
		BanTime.AddItem(strFormat, "Permanent");
		
		BanTime.ExitBackButton = true;
		BanTime.ExitButton = true;
		BanTime.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuBanTime(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128];
		menu.GetItem(param, STRING(info));
		
		Menu BanFinal = new Menu(DoMenuBanFinal);
		BanFinal.SetTitle("Quel est la raison du bannissement ?");
		PerformRaison(BanFinal, client, info);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuBan(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuBanFinal(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128];
		menu.GetItem(param, STRING(info));
		
		ClientCommand(client, info);
		MenuBan(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuBan(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuSlay(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_slay %s", info);
		ClientCommand(client, strCmd);
		MenuSlay(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuRespawn(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		if(StrEqual(info, "@moi") && IsPlayerAlive(client))
			CPrintToChat(client, "%s Vous êtes déjà en vie.", TEAM);
		
		Format(STRING(strCmd), "rp_revivre %s", info);
		ClientCommand(client, strCmd);
		MenuRespawn(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuGifle(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_gifle %s", info);
		ClientCommand(client, strCmd);
		MenuGifle(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuGeler(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_freeze %s", info);
		ClientCommand(client, strCmd);
		MenuGeler(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuBruler(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_brule %s", info);
		ClientCommand(client, strCmd);
		MenuBruler(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuBalise(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_balise %s", info);
		ClientCommand(client, strCmd);
		MenuBaliser(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuTp(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strFormat[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strFormat), "rp_tp %s", info);
		ClientCommand(client, strFormat);
		MenuTp(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuTpa(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strFormat[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strFormat), "rp_tpa %s", info);
		ClientCommand(client, strFormat);
		MenuTpa(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuBombe(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_bombe %s", info);
		ClientCommand(client, strCmd);
		MenuBombe(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuMute(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_mute %s", info);
		ClientCommand(client, strCmd);
		MenuMute(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuGag(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_gag %s", info);
		ClientCommand(client, strCmd);
		MenuGag(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuSilence(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_silence %s", info);
		ClientCommand(client, strCmd);
		MenuSilence(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuDroguer(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_drogue %s", info);
		ClientCommand(client, strCmd);
		MenuDroguer(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuAveugler(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		Format(STRING(strCmd), "rp_aveugle %s", info);
		ClientCommand(client, strCmd);
		MenuAveugler(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuRotation(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		int ent = GetAimEnt(client, false);
		if(ent > MaxClients)
		{
			if(IsValidEntity(ent))
			{
				PrecacheSound("npc/scanner/scanner_nearmiss1.wav", true);
				EmitSoundToAll("npc/scanner/scanner_nearmiss1.wav", ent, 0, 70);
				float angles[3];
				GetEntPropVector(ent, Prop_Data, "m_angRotation", angles);
				
				if(StrEqual(info, "x"))
					angles[0] += 5.0;
				else if(StrEqual(info, "y"))
					angles[1] += 5.0;
				else if(StrEqual(info, "z"))
					angles[2] += 5.0;
				
				TeleportEntity(ent, NULL_VECTOR, angles, NULL_VECTOR);
				PrintHintText(client ,"X:%fY:%fZ:%f", angles[0], angles[1], angles[2]);
			}
			else
				CPrintToChat(client, "%s Vous devez regarder une entité.", TEAM);
		}
		else
			CPrintToChat(client, "%s Vous ne pouvez pas utilser cette commande sur un joueur.", TEAM);
		MenuRotation(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuArmeChoix(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[256];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		MenuArmeChoix(client, info);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuArmeFinal(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		Format(STRING(strCmd), "rp_arme %s", info);
		ClientCommand(client, strCmd);
		MenuArme(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuArme(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuGererAdmin(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32], strFormat[32];
		menu.GetItem(param, STRING(info));
		int joueur = StringToInt(info);
		
		Menu GererAdminFinal = new Menu(DoMenuGererAdminFinal);
		if(rp_GetClientInt(client, i_AdminLevel) < rp_GetClientInt(joueur, i_AdminLevel))
		{
			char strTitle[64];
			if(rp_GetClientInt(joueur, i_AdminLevel) == 1)
				Format(STRING(strTitle), "Gérer les droits de %N [FONDATEUR] :", joueur);
			else if(rp_GetClientInt(joueur, i_AdminLevel) == 2)
				Format(STRING(strTitle), "Gérer les droits de %N [2] :", joueur);
			else if(rp_GetClientInt(joueur, i_AdminLevel) == 3)
				Format(STRING(strTitle), "Gérer les droits de %N [ADMIN] :", joueur);	
			else if(rp_GetClientInt(joueur, i_AdminLevel) == 4)
				Format(STRING(strTitle), "Gérer les droits de %N [MODO] :", joueur);	
			else if(rp_GetClientInt(joueur, i_AdminLevel) == 5)
				Format(STRING(strTitle), "Gérer les droits de %N [MEMBRE] :", joueur);
			else
				Format(STRING(strTitle), "Gérer les droits de %N [0] :", joueur);
			
			GererAdminFinal.SetTitle(strTitle);
			if(rp_GetClientInt(client, i_AdminLevel) <= 2)
			{
				Format(STRING(strFormat), "%s|2", info);
				GererAdminFinal.AddItem(strFormat, "2");
				Format(STRING(strFormat), "%s|3", info);
				GererAdminFinal.AddItem(strFormat, "Admin");
				Format(STRING(strFormat), "%s|4", info);
				GererAdminFinal.AddItem(strFormat, "MGF");
				Format(STRING(strFormat), "%s|0", info);
				GererAdminFinal.AddItem(strFormat, "Joueur");
			}
		}
		else
			GererAdminFinal.AddItem("", "Vous n'avez pas assez de droits.", ITEMDRAW_DISABLED);
		
		GererAdminFinal.ExitBackButton = true;
		GererAdminFinal.ExitButton = true;
		GererAdminFinal.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuSkin(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu ModelSkin = new Menu(DoMenuSkinJoueur);	
		
		ModelSkin.SetTitle("Liste des models :");	
		ModelSkin.AddItem("", "-- VIP --", ITEMDRAW_DISABLED);
		/*Format(STRING(strFormat), "%s|models/player/slow/nanosuit/slow_nanosuit.mdl", info); 
		ModelSkin.AddItem(strFormat, "Nanosuit");*/
		ModelSkin.AddItem("", "--ACHAT--", ITEMDRAW_DISABLED);
		ModelSkin.AddItem("", "--ADMIN--", ITEMDRAW_DISABLED);
	
		ModelSkin.ExitBackButton = true;
		ModelSkin.ExitButton = true;
		ModelSkin.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuSkinJoueur(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strFormat[128], strMenu[64];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu ChoixSkin = new Menu(DoMenuSkinFinal);
		ChoixSkin.SetTitle("Qui dois changer de skin ?");
		LoopClients(i)
		{
			GetClientName(i, STRING(strFormat));
			if(!IsPlayerAlive(i))
			{
				Format(STRING(strMenu), "%s [mort]", strFormat);
				ChoixSkin.AddItem("", strMenu, ITEMDRAW_DISABLED);
			}
			else
			{
				Format(STRING(strMenu), "%s|%s", steamID[i], info);
				if(client == i)
					ChoixSkin.AddItem("", strFormat, ITEMDRAW_DISABLED);
				else
					ChoixSkin.AddItem(strMenu, strFormat);
			}
		}
		ChoixSkin.ExitBackButton = true;
		ChoixSkin.ExitButton = true;
		ChoixSkin.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuSkinFinal(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], buffer[3][64], strFormat[128], strCible[64];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 3, 64);
		if(String_IsNumeric(buffer[0]))
			Format(STRING(strCible), "%s", steamID[StringToInt(buffer[0])]);
		else
			Format(STRING(strCible), "%s", buffer[0]);
		// buffer[1] : temp ou perm
		// buffer[2] : model
		
		if(StrEqual(buffer[1], "perm"))
			Format(STRING(strFormat), "rp_dbskin %s %s", strCible, buffer[2]);
		else
			Format(STRING(strFormat), "rp_skin %s %s", strCible, buffer[2]);
		ClientCommand(client, strFormat);
		MenuSkin(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuModifierJoueur(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], strFormat[64];
		menu.GetItem(param, STRING(info));
		
		if(String_IsNumeric(info))
			strcopy(STRING(info), steamID[StringToInt(info)]);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu ModifierJoueurType = new Menu(DoMenuModifierJoueurType);
		ModifierJoueurType.SetTitle("Choix de la caractéristique :");
		Format(STRING(strFormat), "%s|vie", info);
		ModifierJoueurType.AddItem(strFormat, "Vie");
		Format(STRING(strFormat), "%s|kevlar", info);
		ModifierJoueurType.AddItem(strFormat, "Armure");
		Format(STRING(strFormat), "%s|vitesse", info);
		ModifierJoueurType.AddItem(strFormat, "Vitesse");
		Format(STRING(strFormat), "%s|gravite", info);
		ModifierJoueurType.AddItem(strFormat, "Gravité");
		
		ModifierJoueurType.ExitBackButton = true;
		ModifierJoueurType.ExitButton = true;
		ModifierJoueurType.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuModifierJoueurType(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], strFormat[128], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 3, 64);
		// buffer[0] : steamid
		// buffer[1] : type
		
		rp_SetClientBool(client, b_menuOpen, true);
		Handle menuModifierJoueurValeur = CreateMenu(DoMenuModifierJoueurValeur);
		SetMenuTitle(menuModifierJoueurValeur, "Modifier la caractéristique :");
		if(StrEqual(buffer[1], "vie") || StrEqual(buffer[1], "kevlar"))
		{
			Format(STRING(strFormat), "%s|1", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1");
			Format(STRING(strFormat), "%s|2", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "2");
			Format(STRING(strFormat), "%s|3", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "3");
			Format(STRING(strFormat), "%s|4", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "4");
			Format(STRING(strFormat), "%s|5", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "5");
			Format(STRING(strFormat), "%s|10", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "10");
			Format(STRING(strFormat), "%s|15", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "15");
			Format(STRING(strFormat), "%s|20", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "20");
			Format(STRING(strFormat), "%s|30", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "30");
			Format(STRING(strFormat), "%s|40", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "40");
			Format(STRING(strFormat), "%s|50", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "50");
			Format(STRING(strFormat), "%s|60", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "60");
			Format(STRING(strFormat), "%s|70", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "70");
			Format(STRING(strFormat), "%s|80", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "80");
			Format(STRING(strFormat), "%s|90", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "90");
			Format(STRING(strFormat), "%s|100", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "100");
		}
		else if(StrEqual(buffer[1], "vitesse"))
		{
			Format(STRING(strFormat), "%s|0.1", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.1");
			Format(STRING(strFormat), "%s|0.2", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.2");
			Format(STRING(strFormat), "%s|0.3", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.3");
			Format(STRING(strFormat), "%s|0.4", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.4");
			Format(STRING(strFormat), "%s|0.5", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.5");
			Format(STRING(strFormat), "%s|0.6", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.6");
			Format(STRING(strFormat), "%s|0.7", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.7");
			Format(STRING(strFormat), "%s|0.8", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.8");
			Format(STRING(strFormat), "%s|0.9", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.9");
			Format(STRING(strFormat), "%s|1.0", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.0");
			Format(STRING(strFormat), "%s|1.1", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.1");
			Format(STRING(strFormat), "%s|1.2", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.2");
			Format(STRING(strFormat), "%s|1.3", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.3");
			Format(STRING(strFormat), "%s|1.4", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.4");
			Format(STRING(strFormat), "%s|1.5", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.5");
			Format(STRING(strFormat), "%s|1.6", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.6");
			Format(STRING(strFormat), "%s|1.7", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.7");
			Format(STRING(strFormat), "%s|1.8", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.8");
			Format(STRING(strFormat), "%s|1.9", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.9");
			Format(STRING(strFormat), "%s|2.0", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "2.0");
			Format(STRING(strFormat), "%s|2.5", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "2.5");
			Format(STRING(strFormat), "%s|3.0", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "3.0");
		}
		else
		{
			Format(STRING(strFormat), "%s|100", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "100");
			Format(STRING(strFormat), "%s|200", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "200");
			Format(STRING(strFormat), "%s|300", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "300");
			Format(STRING(strFormat), "%s|400", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "400");
			Format(STRING(strFormat), "%s|500", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "500");
			Format(STRING(strFormat), "%s|800", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "800");
			Format(STRING(strFormat), "%s|1000", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1000");
			Format(STRING(strFormat), "%s|1200", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1200");
			Format(STRING(strFormat), "%s|1500", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1500");
		}

		SetMenuExitBackButton(menuModifierJoueurValeur, true);
		SetMenuExitButton(menuModifierJoueurValeur, true);
		DisplayMenu(menuModifierJoueurValeur, client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuModifierJoueur(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuModifierJoueurValeur(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], buffer[3][64], strCmd[128];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 3 ,64);
		// buffer[0] : steamid
		// buffer[1] : type
		// buffer[2] : valeur
		
		Format(STRING(strCmd), "rp_%s %s %i", buffer[1], buffer[0], StringToInt(buffer[2]));
		ClientCommand(client, strCmd);
		MenuModifierJoueur(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuModifierJoueur(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuChoixTypeProps(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		if(StrEqual(info, "dynamic"))
			MenuPropsDynamic(client);
		else if(StrEqual(info, "physics"))
			MenuPropsPhysics(client);
		else if(StrEqual(info, "throw"))
			MenuPropsThrow(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuGererAdminFinal(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], buffer[2][32], adminRankName[32];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 2, 32);
		int joueur = StringToInt(buffer[0]);
		// buffer[0] : joueur
		// buffer[1] : grade
		
		GetAdminRankName(rp_GetClientInt(joueur, i_AdminLevel), STRING(info));
		rp_SetClientInt(joueur, i_AdminLevel, StringToInt(buffer[1]));
		SetSQL_Int(g_DB, "rp_admin", "adminid", StringToInt(buffer[1]), steamID[joueur]);
		GetAdminRankName(rp_GetClientInt(joueur, i_AdminLevel), STRING(adminRankName));
		CPrintToChat(client, "%s %N est désormais %s.", TEAM, joueur, adminRankName);
		LogToFile(logFile, "[ADMIN] %N a changé les droits de %N : %s->%s.", client, joueur, info, adminRankName);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuGererAdmin(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuPropsDyn(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char entModel[256];
		menu.GetItem(param, STRING(entModel));
		
		PrecacheModel(entModel, true);
		int ent = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(ent, "solid", "6");
		DispatchKeyValue(ent, "model", entModel);
		DispatchSpawn(ent);
		PrecacheSound("weapons/stunstick/stunstick_fleshhit1.wav", true);
		EmitSoundToAll("weapons/stunstick/stunstick_fleshhit1.wav", ent, 0, 70);
		
		float teleportOrigin[3], joueurOrigin[3];
		PointVision(client, joueurOrigin);
		teleportOrigin[0] = joueurOrigin[0];
		teleportOrigin[1] = joueurOrigin[1];
		teleportOrigin[2] = joueurOrigin[2];
		
		TeleportEntity(ent, teleportOrigin, NULL_VECTOR, NULL_VECTOR);
		
		PrintHintText(client ,"%s", entModel);

		LogToFile(logFile, "[ADMIN] %N a cree une entite dynamic : %s", client, entModel);
		
		MenuPropsDynamic(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuPropsType(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuPropsPhys(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char entModel[256];
		menu.GetItem(param, STRING(entModel));
		
		PrecacheModel(entModel, true);
		int ent = CreateEntityByName("prop_physics_override");
		DispatchKeyValue(ent, "physdamagescale", "0.0");
		DispatchKeyValue(ent, "model", entModel);
		DispatchSpawn(ent);
		PrecacheSound("weapons/stunstick/stunstick_fleshhit1.wav", true);
		EmitSoundToAll("weapons/stunstick/stunstick_fleshhit1.wav", ent, 0, 70);

		float teleportOrigin[3], joueurOrigin[3];
		PointVision(client, joueurOrigin);
		teleportOrigin[0] = joueurOrigin[0];
		teleportOrigin[1] = joueurOrigin[1];
		teleportOrigin[2] = (joueurOrigin[2] + 1);

		TeleportEntity(ent, teleportOrigin, NULL_VECTOR, NULL_VECTOR);
		PrintHintText(client, "%s", entModel);
		LogToFile(logFile, "[ADMIN] %N a cree une entite physics : %s", client, entModel);
		MenuPropsPhysics(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuPropsType(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuPropsThr(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char entModel[256];
		menu.GetItem(param, STRING(entModel));
		
		PrecacheModel(entModel,true);
		int ent = CreateEntityByName("prop_physics_override");
		DispatchKeyValue(ent, "physdamagescale", "1.0");
		DispatchKeyValue(ent, "model", entModel);
		DispatchSpawn(ent);
		PrecacheSound("ambient/machines/catapult_throw.wav", true);
		EmitSoundToAll("ambient/machines/catapult_throw.wav", ent, 0, 70);

		float furnitureOrigin[3], clientOrigin[3], eyeAngles[3], push[3];
		GetClientEyeAngles(client, eyeAngles);
		GetClientAbsOrigin(client, clientOrigin);
		push[0] = (5000.0 * Cosine(DegToRad(eyeAngles[1])));
		push[1] = (5000.0 * Sine(DegToRad(eyeAngles[1])));
		push[2] = (-12000.0 * Sine(DegToRad(eyeAngles[0])));
		furnitureOrigin[0] = (clientOrigin[0] + (50 * Cosine(DegToRad(eyeAngles[1]))));
		furnitureOrigin[1] = (clientOrigin[1] + (50 * Sine(DegToRad(eyeAngles[1]))));
		furnitureOrigin[2] = (clientOrigin[2]);

		int AltBeamColor[4] = {255, 100, 100, 200}; 
		TE_SetupBeamFollow(ent, -1, modelHalo, 1.0, 8.0, 8.0, 1000, AltBeamColor);
		TE_SendToAll();

		TeleportEntity(ent, furnitureOrigin, NULL_VECTOR, push);
		IgniteEntity(ent, 5.0);
		SetEntityMoveType(ent, MOVETYPE_VPHYSICS);

		PrintHintText(client, "%s", entModel);
		LogToFile(logFile, "[ADMIN] %N a lance une entite physics : %s", client, entModel);
		
		MenuPropsThrow(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuPropsType(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuDel(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		char buffer[2][16], entClass[64];
		ExplodeString(info, "|", buffer, 2, 16);
		// oui = buffer[0]
		int aim = StringToInt(buffer[1]);
		
		if(StrEqual(buffer[0], "oui"))
		{
			if(IsValidEntity(aim))
			{
				GetEntityClassname(aim, STRING(entClass));				
				RemoveEdict(aim);			
				PrintHintText(client ,"Entité supprimé !");
				LogToFile(logFile, "[ADMIN] %N a supprime %s.", client, entClass);
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			BuildAdminMenu(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

// ================================================================
//                           COMMANDS
// ================================================================

public Action Command_Info(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	int aim = GetAimEnt(client, false);
	if(!IsValidEntity(aim))
	{
		CPrintToChat(client, "%s Aucune entité détectée.", TEAM);
		return Plugin_Handled;
	}
	
	char entModel[256], entClass[128], entName[128];
	GetEntityClassname(aim, STRING(entClass));
	GetEntPropString(aim, Prop_Data, "m_ModelName", entModel, 256);
	Entity_GetName(aim, STRING(entName));
	float position[3], angles[3];
	GetEntPropVector(aim, Prop_Send, "m_vecOrigin", position);
	GetEntPropVector(aim, Prop_Data, "m_angRotation", angles); 
	int hammerID = Entity_GetHammerId(aim);
	
	if(StrEqual(entName, ""))
		entName = "*aucun*";
	
	for(int i; i <= 2; i++)
	{
		if(angles[i] > 360.0)
			angles[i] -= 360.0;
		else if(angles[i] < 0.0)
			angles[i] = 0.0;
	}
	
	CPrintToChat(client, "%s Classname : {yellow}%s", TEAM, entClass);
	PrintToConsole(client, "Classname : %s", entClass);
	CPrintToChat(client, "{default}Nom : {yellow}%s", entName);
	PrintToConsole(client, "Nom : %s", entName);
	CPrintToChat(client, "{default}Model : {yellow}%s", entModel);
	PrintToConsole(client, "Model : %s", entModel);
	CPrintToChat(client, "{default}ID : {yellow}%i", aim);
	PrintToConsole(client, "ID : %i", aim);
	CPrintToChat(client, "{default}Position : {yellow}%f, %f, %f", position[0], position[1], position[2]);
	PrintToConsole(client, "Position : %f, %f, %f", position[0], position[1], position[2]);
	CPrintToChat(client, "{default}Angle : {yellow}%f, %f, %f", angles[0], angles[1], angles[2]);
	PrintToConsole(client, "Angle : %f, %f, %f", angles[0], angles[1], angles[2]);
	CPrintToChat(client, "\x01Hammer ID : \x06%i", hammerID);
	PrintToConsole(client, "Hammer ID : %i", hammerID);
	
	if(aim <= MaxClients)
	{
		int id = GetClientUserId(aim);
		
		CPrintToChat(client, "{default}Steam ID : {yellow}%s", steamID[aim]);
		
		CPrintToChat(client, "{default}User ID : {yellow}%i", id);
		
		CPrintToChat(client, "{default}Argent : {yellow}%i$", rp_GetClientInt(aim, i_Money));
		
		CPrintToChat(client, "{default}Banque : {yellow}%i$", rp_GetClientInt(aim, i_Bank));
		
		char skintarget[128];
		rp_GetClientString(aim, sz_Skin, STRING(skintarget));
		CPrintToChat(client, "{default}Skin : {yellow}%s", skintarget);
		
		CPrintToChat(client, "{default}Admin : {yellow}%i", rp_GetClientInt(aim, i_AdminLevel));
		
		CPrintToChat(client, "{default}VIP : {yellow}%i", rp_GetClientInt(aim, i_VipTime));

		CPrintToChat(client, "{default}Fuel : {yellow}%i", rp_GetClientInt(aim, i_Fuel));

		char maladie[128];
		rp_GetClientString(aim, sz_Maladie, STRING(maladie));
		CPrintToChat(client, "{default}Maladie : {yellow}%s", maladie);

		char chirurgie[128];
		rp_GetClientString(aim, sz_Chirurgie, STRING(chirurgie));
		CPrintToChat(client, "{default}Chirurgie : {yellow}%s", chirurgie);
	}
	
	return Plugin_Handled;
}

public Action Command_AdminGeneral(int client, int args)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 0)
		return Plugin_Handled;
	
	BuildAdminMenu(client);
	
	return Plugin_Continue;
}

public Action Command_Ban(int client, int args)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 0)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_ban <pseudo|Steam ID|IP> <temps en minutes|0 permanent> (raison)", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_ban <Steam ID ou IP> <temps en minutes ou 0 permanent> (raison)");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(STRING(cmdArg));
	
	char steamip[64], time[64], raison[128];
	int nextLen, len = BreakString(cmdArg, STRING(steamip));
	if(len != -1)
		nextLen = BreakString(cmdArg[len], STRING(time));
	if(nextLen != -1)
		strcopy(STRING(raison), cmdArg[len+nextLen]);
	
	if(!String_IsNumeric(time))
	{
		if(client > 0)
			CPrintToChat(client, "%s Le temps doit être spécifié en minutes (exemple: 1 semaine = 10080).", TEAM);
		else
			PrintToServer("[ADMIN] Le temps doit etre specifie en minutes (exemple: 1 semaine = 10080).");
		return Plugin_Handled;
	}
	
	int banTime = StringToInt(time);
	int debanTime;
	if(rp_GetClientInt(client, i_AdminLevel) != 2 && !IsADMIN(client))
	{
		if(banTime == 0 || banTime > 1440)
			banTime = 1440;
	}
	if(banTime != 0)
		debanTime = GetTime() + banTime * 60;
	
	char strFormat[32], strDate[32], strHeure[32], strExplode[3][8];
	FormatTime(STRING(strFormat), "%x", debanTime);
	ExplodeString(strFormat, "/", strExplode, 3, 8);
	Format(STRING(strDate), "%s/%s/%s", strExplode[1], strExplode[0], strExplode[2]);
	FormatTime(STRING(strFormat), "%X", debanTime);
	ExplodeString(strFormat, ":", strExplode, 3, 8);
	Format(STRING(strHeure), "%sh%s", strExplode[0], strExplode[1]);
	
	char strTime[32];
	Format(STRING(strTime), "%s à %s", strDate, strHeure);
	
	char strRaison[512], strDiscordRaison[512];
	if(banTime > 0)
	{
		if(!StrEqual(raison, ""))
			Format(STRING(strRaison), "Vous êtes banni du RolePlay jusqu'au %s.\n(raison : %s)", strTime, raison);
		else
			Format(STRING(strRaison), "Vous êtes banni du RolePlay jusqu'au %s.", strTime);
			
		if(!StrEqual(raison, ""))
			Format(STRING(strDiscordRaison), "a été banni du RolePlay jusqu'au %s.\n(raison : %s)", strTime, raison);
		else
			Format(STRING(strDiscordRaison), "a été banni du RolePlay jusqu'au %s.", strTime);
	}
	else
	{
		if(!StrEqual(raison, ""))
			Format(STRING(strRaison), "Vous êtes banni du RolePlay définitivement.\n(raison : %s)", raison);
		else
			Format(STRING(strRaison), "Vous êtes banni du RolePlay définitivement.");
			
		if(!StrEqual(raison, ""))
			Format(STRING(strDiscordRaison), "a été banni définitivement du RolePlay .\n(raison : %s)", raison);
		else
			Format(STRING(strDiscordRaison), "a été banni définitivement du RolePlay .");	
	}
	
	char name[32];
	GetClientName(client, STRING(name));
	
	if(StrContains(steamip, "STEAM_", false) != -1)
	{
		int joueur = Client_FindBySteamId(steamip);
		if(joueur != -1)
		{
			if(IsClientInGame(joueur))
			{
				if(rp_GetClientInt(joueur, i_AdminLevel) != 1 && rp_GetClientInt(joueur, i_AdminLevel) < rp_GetClientInt(client, i_AdminLevel))
				{
					CPrintToChatAll("%s {yellow}%N %s pour {yellow}%s{default}.", TEAM, joueur, raison);
					SBPP_BanPlayer(client, joueur, debanTime, raison);
					
					char hostname[128];
					GetConVarString(FindConVar("hostname"), STRING(hostname));				
					
					DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
					hook.SlackMode = true;	
					hook.SetUsername("Roleplay");	
					
					MessageEmbed Embed = new MessageEmbed();	
					Embed.SetColor("#00fd29");
					Embed.SetTitle(hostname);
					Embed.SetTitleLink("steam://connect/163.172.72.143:27115");
					Embed.AddField("Punissement", "Ban", false);
					Embed.AddField("Admin", "%N", false, client);
					Embed.AddField("Joueur", "%N", false, joueur);
					Embed.AddField("Raison", raison, false);
					Embed.AddField("Date", strTime, false);
					Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
					Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
					Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
					
					hook.Embed(Embed);	
					hook.Send();
					delete hook;
					
					KickClient(joueur, strRaison);
				}
				else
				{
					if(client > 0)
						CPrintToChat(client, "%s Vous n'avez pas la permission de bannir {yellow}%N{default}.", TEAM, joueur);
					else
						PrintToServer("[ADMIN] Vous n'avez pas la permission de bannir %N.", joueur);
					return Plugin_Handled;
				}
				SBPP_BanPlayer(client, joueur, debanTime, raison);
			}
		}
	}
	else
	{
		int joueur[MAXPLAYERS+1];
		joueur = FindJoueur(client, steamip);
		if(joueur[0] != -1)
		{
			LoopClients(i)
			{
				if(rp_GetClientInt(i, i_AdminLevel) != 1 && rp_GetClientInt(i, i_AdminLevel) < rp_GetClientInt(client, i_AdminLevel))
				{
					strcopy(STRING(steamip), steamID[i]);
					KickClient(i, strRaison);
					CPrintToChatAll("%s {yellow}%N a été {purple}bannis{default} pour {yellow}%s{default}.", TEAM, i, raison);
					SBPP_BanPlayer(client, i, debanTime, strRaison);
					
					char hostname[128];
					GetConVarString(FindConVar("hostname"), STRING(hostname));
					
					DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
					hook.SlackMode = true;	
					hook.SetUsername("Roleplay");	
					
					MessageEmbed Embed = new MessageEmbed();	
					Embed.SetColor("#00fd29");
					Embed.SetTitle(hostname);
					Embed.SetTitleLink("steam://connect/163.172.72.143:27115");
					Embed.AddField("Punissement", "Ban", false);
					Embed.AddField("Admin", "%N", false, client);
					Embed.AddField("Joueur", "%N", false, i);
					Embed.AddField("Raison", raison, false);
					Embed.AddField("Date", strTime, false);
					Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
					Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
					Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
					
					hook.Embed(Embed);	
					hook.Send();
					delete hook;
				}
				else
				{
					if(client > 0)
						CPrintToChat(client, "%s Vous n'avez pas la permission de bannir {yellow}%N{default}.", TEAM, i);
					else
						PrintToServer("[ADMIN] Vous n'avez pas la permission de bannir %N.", i);
					return Plugin_Handled;
				}
			}
		}
		else 
			return Plugin_Handled;
	}
	
	if(banTime > 0)
	{
		if(client > 0)
		{
			CPrintToChat(client, "%s Vous avez banni %s pour %i minutes (raison : %s), il sera déban le %s.", TEAM, steamip, banTime, raison, strTime);
			LogToFile(logFile, "%s L'admin %N a banni %s pour %i minutes (raison : %s), il sera deban le %s.", TEAM, client, steamip, banTime, raison, strTime);
		}
		else
		{
			PrintToServer("[ADMIN] Vous avez banni %s pour %i minutes (raison : %s), il sera deban le %s.", steamip, banTime, raison, strTime);
			LogToFile(logFile, "%s L'admin %N a banni %s pour %i minutes (raison : %s), il sera deban le %s.", TEAM, client, steamip, banTime, raison, strTime);
		}
	}
	else
	{
		if(client > 0)
		{
			CPrintToChat(client, "%s Vous avez banni %s définitivement (raison : %s).", TEAM, steamip, raison);
			LogToFile(logFile, "%s L'admin %N a banni %s definitivement (raison : %s).", TEAM, client, steamip, raison);
		}
		else
		{
			PrintToServer("[ADMIN] Vous avez banni %s definitivement (raison : %s).", steamip, raison);
			LogToFile(logFile, "%s L'admin %N a banni %s definitivement (raison : %s).", TEAM, client, steamip, raison);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Advert(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	LoopClients(i)
	{
		PrintCenterText(i, "LE SERVEUR VA BIENTÔT REDÉMARRER !\nRECONNECTEZ-VOUS, MERCI");
		CPrintToChat(i, "%s {lightred}Le serveur va bientôt redémarrer ! {yellow}Reconnectez-vous, merci.", TEAM);
	}
	PrintToServer("[ADMIN] Commande advertissement de reboot declenchee.");
	
	return Plugin_Handled;
}

public Action Command_DBSkin(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_dbskin <steamid> <skin>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_dbskin <steamid> <skin>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(STRING(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, STRING(arg1));
	if(len != -1)
		strcopy(STRING(arg2), cmdArg[len]);
	
	if(StrContains(arg1, "STEAM") == -1
	|| StrContains(arg1, "_") == -1
	|| StrContains(arg1, ":") == -1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Steam ID invalide.", TEAM);
		else
			PrintToServer("[ADMIN] Steam ID invalide.");
		return Plugin_Handled;
	}
	else if(StrContains(arg2, "models") == -1
	|| StrContains(arg2, ".mdl") == -1
	|| StrContains(arg2, "/") == -1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Skins invalide.", TEAM);
		else
			PrintToServer("[ADMIN] Skins invalide.");
		return Plugin_Handled;
	}
	
	LoopClients(i) 
	{
		if(StrEqual(arg1, steamID[i]))
		{
			int joueur = Client_FindBySteamId(arg1);
			rp_SetClientString(joueur, sz_Skin, STRING(arg2));
			UpdateSQL(g_DB, "UPDATE rp_vetements SET skin = '%s' WHERE steamid = '%s';", arg2, steamID[joueur]);
			
			char skin[128];
			rp_GetClientString(joueur, sz_Skin, STRING(skin));
			
			if(client > 0)
				CPrintToChat(client, "%s Vous avez donnée le skin {yellow}%s{default} à {yellow}%N{default}.", TEAM, skin, joueur);
			else
				PrintToServer("[ADMIN] Vous avez donnée le skin %s a %N.", skin, joueur);
			
			LogToFile(logFile, "[ADMIN] L'admin %N a donne le skin %s a %N (%s).", client, skin, joueur, steamID);
			return Plugin_Handled;
		}
	}
	if(client > 0)
		CPrintToChat(client, "%s Erreur : Vérifiez le Steam ID et le chemin du skin.", TEAM);
	else
		PrintToServer("[ADMIN] Erreur : Vérifiez le Steam ID et le chemin du skin.");
	
	return Plugin_Handled;
}

public Action Command_SetSkin(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_skin <joueur> <model>", TEAM);
		else
			PrintToServer(" Usage : rp_skin <joueur> <model>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(STRING(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, STRING(arg1));
	if(len != -1)
		strcopy(STRING(arg2), cmdArg[len]);
	
	if(StrContains(arg2, "models") == -1
	|| StrContains(arg2, ".mdl") == -1
	|| StrContains(arg2, "/") == -1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Le skin est invalide.", TEAM);
		else
			PrintToServer("[ADMIN] Le skin est invalide.");
		return Plugin_Handled;
	}
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg1, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg1, "@civil"))
			CPrintToChat(client, "%s Tout les civils portent de nouveaux vêtements (%s).", TEAM, arg2);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Toutes les forces de l'ordre portent de nouveaux vêtements (%s).", TEAM, arg2);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Tout le monde porte de nouveaux vêtements (%s).", TEAM, arg2);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Tout les vivants portent de nouveaux vêtements (%s).", TEAM, arg2);
	}
	else
	{
		if(StrEqual(arg1, "@civil"))
			PrintToServer("[ADMIN] Tout les civils portent de nouveaux vêtements (%s).", arg2);
		else if(StrEqual(arg1, "@police"))
			PrintToServer("[ADMIN] Toutes les forces de l'ordre portent de nouveaux vêtements (%s).", arg2);
		else if(StrEqual(arg1, "@tous"))
			PrintToServer("[ADMIN] Tout le monde porte de nouveaux vêtements (%s).", arg2);
		else if(StrEqual(arg1, "@vie"))
			PrintToServer("[ADMIN] Tout les vivants portent de nouveaux vêtements (%s).", arg2);
	}
	
	if(client > 0)
		PrintHintText(client, "Skin appliqué :\n%s", arg2);
	else
		PrintToServer("[ADMIN] Skin appliqué : %s", arg2);
	
	PrecacheModel(arg2, true);
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i))
			{
				if(IsValidEntity(i))
					SetEntityModel(i, arg2);
				CPrintToChat(i, "%s Vous portez de {yellow}nouveaux vêtements{default}, vous pouvez le voir en troisième personne.", TEAM);
				
				if(i != client && StrContains(arg1, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s %N porte de nouveau vêtement (%s)", TEAM, i, arg2);
					else
						PrintToServer("[ADMIN] %N porte de nouveau vêtement (%s)", i, arg2);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Vie(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_vie <joueur> <montant>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_vie <joueur> <montant>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(STRING(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, STRING(arg1));
	if(len != -1)
		strcopy(STRING(arg2), cmdArg[len]);
	
	if(!String_IsNumeric(arg2))
	{
		if(client > 0)
			CPrintToChat(client, "%s Le montant de la vie doit être en chiffre.", TEAM);
		else
			PrintToServer("[ADMIN] Le montant de la vie doit etre en chiffre.");
		return Plugin_Handled;
	}
	
	int vie = StringToInt(arg2);
	
	if(vie <= 0)
	{
		if(client > 0)
			CPrintToChat(client, "%s Le montant de la vie doit être supérieur à 0{darkred}♥{default}.", TEAM);
		else
			PrintToServer("[ADMIN] Le montant de la vie doit être supérieur à 0 HP.");
		return Plugin_Handled;
	}
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg1, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;

	if(client > 0)
	{
		if(StrEqual(arg1, "@civil"))
			CPrintToChat(client, "%s Tout les civils ont maintenant {yellow}%i{darkred}♥{default}.", TEAM, vie);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Toutes les forces de l'ordre ont maintenant {yellow}%i{darkred}♥{default}.", TEAM, vie);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Tout le monde a maintenant {yellow}%i{darkred}♥{default}.", TEAM, vie);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Tout les vivants ont maintenant {yellow}%i{darkred}♥{default}.", TEAM, vie);
	}
	else
	{
		if(StrEqual(arg1, "@civil"))
			PrintToServer("[ADMIN] Tout les civils ont maintenant %i HP.", vie);
		else if(StrEqual(arg1, "@police"))
			PrintToServer("[ADMIN] Toutes les forces de l'ordre ont maintenant %i HP.", vie);
		else if(StrEqual(arg1, "@tous"))
			PrintToServer("[ADMIN] Tout le monde a maintenant %i HP.", vie);
		else if(StrEqual(arg1, "@vie"))
			PrintToServer("[ADMIN] Tout les vivants ont maintenant %i HP.", vie);
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i))
			{
				if(IsValidEntity(i))
					SetEntityHealth(i, vie);
				PrintHintText(i, "Vie actuelle : %i♥", vie);
				CPrintToChat(i, "%s Vous avez maintenant {yellow}%i{darkred}♥{default}.", TEAM, vie);
				
				if(i != client && StrContains(arg1, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s %N à maintenant {yellow}%i{darkred}♥{default}.", TEAM, i, vie);
					else
						PrintToServer("[ADMIN] %N a maintenant %i HP.", i, vie);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Kevlar(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_kevlar <joueur> <montant>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_kevlar <joueur> <montant>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(STRING(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, STRING(arg1));
	if(len != -1)
		strcopy(STRING(arg2), cmdArg[len]);
	
	if(!String_IsNumeric(arg2))
	{
		if(client > 0)
			CPrintToChat(client, "%s Le montant du Kevlar doit être en chiffre.", TEAM);
		else
			PrintToServer("[ADMIN] Le montant du Kevlar doit etre en chiffre.");
		return Plugin_Handled;
	}
	
	int kevlar = StringToInt(arg2);
	
	if(kevlar < 0 || kevlar > 125)
	{
		if(client > 0)
			CPrintToChat(client, "%s Le montant du Kevlar doit être compris entre {yellow}0 {default}et {yellow}125{default}.", TEAM);
		else
			PrintToServer("[ADMIN] Le montant du Kevlar doit être compris entre 0 et 125.");
		return Plugin_Handled;
	}
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg1, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;

	if(client > 0)
	{
		if(StrEqual(arg1, "@civil"))
			CPrintToChat(client, "%s Tout les civils ont maintenant {yellow}%i{default} d'armure.", TEAM, kevlar);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Toutes les forces de l'ordre ont maintenant {yellow}%i{default} d'armure.", TEAM, kevlar);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Tout le monde a maintenant {yellow}%i{default} d'armure.", TEAM, kevlar);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Tout les vivants ont maintenant {yellow}%i{default} d'armure.", TEAM, kevlar);
	}
	else
	{
		if(StrEqual(arg1, "@civil"))
			PrintToServer("[ADMIN] Tout les civils ont maintenant %i d'armure.", kevlar);
		else if(StrEqual(arg1, "@police"))
			PrintToServer("[ADMIN] Toutes les forces de l'ordre ont maintenant %i d'armure.", kevlar);
		else if(StrEqual(arg1, "@tous"))
			PrintToServer("[ADMIN] Tout le monde a maintenant %i d'armure.", kevlar);
		else if(StrEqual(arg1, "@vie"))
			PrintToServer("[ADMIN] Tout les vivants a maintenant %i d'armure.", kevlar);
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i))
			{
				if(IsValidEntity(i))
					Client_SetArmor(i, kevlar);
				PrintHintText(i, "Armure actuelle : %i", kevlar);
				CPrintToChat(i, "%s Vous avez maintenant {yellow}%i{default} d'armure.", TEAM, kevlar);
				
				if(i != client && StrContains(arg1, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s %N à maintenant {yellow}%i{default} d'armure.", TEAM, i, kevlar);
					else
						PrintToServer("[ADMIN] %N a maintenant %i d'armure.", i, kevlar);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Rotate(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_rotate <x> <y> <z>", TEAM);
		return Plugin_Handled;
	}
	
	int ent = GetAimEnt(client, false);
	if(!IsValidEntity(ent))
	{
		CPrintToChat(client, "%s Vous devez regarder une entité.", TEAM);
		return Plugin_Handled;
	}
	else if(ent <= MaxClients)
	{
		CPrintToChat(client, "%s Vous ne pouvez pas utilser cette commande sur un joueur.", TEAM);
		return Plugin_Handled;
	}
	
	char arg1[16], arg2[16], arg3[16];
	GetCmdArg(1, STRING(arg1));
	GetCmdArg(2, STRING(arg2));
	GetCmdArg(3, STRING(arg3));
	
	if(!String_IsNumeric(arg1)
	|| !String_IsNumeric(arg2)
	|| !String_IsNumeric(arg3))
	{
		CPrintToChat(client, "%s L'angle doit être en chiffre.", TEAM);
		return Plugin_Handled;
	}
	
	float angles[3];
	GetEntPropVector(ent, Prop_Data, "m_angRotation", angles);
	
	angles[0] += StringToInt(arg1);
	angles[1] += StringToInt(arg2);
	angles[2] += StringToInt(arg3);
	
	PrecacheSoundAny("ambient/energy/weld1.wav", true);
	EmitSoundToAllAny("ambient/energy/weld1.wav", ent, _, _, _, 1.0);
	
	TeleportEntity(ent, NULL_VECTOR, angles, NULL_VECTOR);
	PrintHintText(client, "%f %f %f", angles[0], angles[1], angles[2]);
	
	return Plugin_Handled;
}

public Action Command_SpawnDynamic(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_spawn_d <model>", TEAM);
		return Plugin_Handled;
	}
	
	char entModel[256];
	GetCmdArgString(STRING(entModel));
	
	if(StrContains(entModel, "models", false) == -1 ||
	StrContains(entModel, ".mdl", false) == -1 ||
	StrContains(entModel, "/", false) == -1)
	{
		CPrintToChat(client, "%s Le chemin du model doit être correctement spécifié : {yellow}models/monprops.mdl", TEAM);
		return Plugin_Handled;
	}
	
	PrecacheModel(entModel, true);
	int ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ent, "solid", "6");
	DispatchKeyValue(ent, "model", entModel);
	DispatchSpawn(ent);
	char strFormat[64];
	Format(STRING(strFormat), "adminprops|%N", client);
	Entity_SetName(ent, strFormat);
	
	float origin[3];
	PointVision(client, origin);
	PrecacheSoundAny("ambient/energy/weld1.wav", true);
	EmitSoundToAllAny("ambient/energy/weld1.wav", ent, _, _, _, 1.0, _, _, origin);
	TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
	
	PrintHintText(client, "Entité dynamic crée :\n%s", entModel);
	LogToFile(logFile, "[ADMIN] %N a crée une entité dynamic : %s", client, entModel);
	
	return Plugin_Handled;
}

public Action Command_SpawnPhysics(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_spawn_p <model>", TEAM);
		return Plugin_Handled;
	}
	
	char entModel[256];
	GetCmdArgString(STRING(entModel));
	
	if(StrContains(entModel, "models", false) == -1 ||
	StrContains(entModel, ".mdl", false) == -1 ||
	StrContains(entModel, "/", false) == -1)
	{
		CPrintToChat(client, "%s Le chemin du model doit être correctement spécifié : {yellow}models/monprops.mdl", TEAM);
		return Plugin_Handled;
	}
	
	PrecacheModel(entModel, true);
	int ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "physdamagescale", "0.0");
	DispatchKeyValue(ent, "model", entModel);
	DispatchSpawn(ent);
	char strFormat[64];
	Format(STRING(strFormat), "adminprops|%N", client);
	Entity_SetName(ent, strFormat);
	
	float origin[3];
	PointVision(client, origin);
	origin[2] += 8.0;
	PrecacheSoundAny("ambient/energy/weld1.wav", true);
	EmitSoundToAllAny("ambient/energy/weld1.wav", ent, _, _, _, 1.0, _, _, origin);
	TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
	
	PrintHintText(client, "Entité physics crée :\n%s", entModel);
	LogToFile(logFile, "[ADMIN] %N a crée une entité physics : %s", client, entModel);
	
	return Plugin_Handled;
}

public Action Command_SpawnThrow(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_spawn_t <model>", TEAM);
		return Plugin_Handled;
	}
	
	char entModel[256];
	GetCmdArgString(STRING(entModel));
	
	if(StrContains(entModel, "models", false) == -1 ||
	StrContains(entModel, ".mdl", false) == -1 ||
	StrContains(entModel, "/", false) == -1)
	{
		CPrintToChat(client, "%s Le chemin du model doit être correctement spécifié : {yellow}models/monprops.mdl", TEAM);
		return Plugin_Handled;
	}
	
	PrecacheModel(entModel, true);
	int ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "physdamagescale", "1.0");
	DispatchKeyValue(ent, "model", entModel);
	DispatchSpawn(ent);
	SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	char strFormat[64];
	Format(STRING(strFormat), "adminprops|%N", client);
	Entity_SetName(ent, strFormat);
	
	float origin[3], clientOrigin[3], eyeAngles[3], velocity[3];
	
	GetClientEyeAngles(client, eyeAngles);
	GetClientAbsOrigin(client, clientOrigin);
	
	velocity[0] = (5000.0 * Cosine(DegToRad(eyeAngles[1])));
	velocity[1] = (5000.0 * Sine(DegToRad(eyeAngles[1])));
	velocity[2] = (-12000.0 * Sine(DegToRad(eyeAngles[0])));
	origin[0] = (clientOrigin[0] + (50 * Cosine(DegToRad(eyeAngles[1]))));
	origin[1] = (clientOrigin[1] + (50 * Sine(DegToRad(eyeAngles[1]))));
	origin[2] = (clientOrigin[2]);
	
	TeleportEntity(ent, origin, NULL_VECTOR, velocity);
	
	int color[4];
	for(int i; i <= 2; i++)
		color[i] = GetRandomInt(0, 255);
	color[3] = 220;
	TE_SetupBeamFollow(ent, g_BeamSpriteFollow, 0, 2.0, 8.0, 8.0, 1000, color);
	TE_SendToAll();
	PrecacheSoundAny("ambient/energy/weld1.wav", true);
	EmitSoundToAllAny("ambient/energy/weld1.wav", ent, _, _, _, 1.0, _, _, origin);
	
	PrintHintText(client, "Entité lancé :\n%s", entModel);
	LogToFile(logFile, "[ADMIN] %N a lancé une entité physics : %s", client, entModel);
	
	return Plugin_Handled;
}

public Action Command_SpawnArme(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_spawn_arme <arme>", TEAM);
		return Plugin_Handled;
	}
	
	char arg[256], strEnt[64], strFormat[64];
	GetCmdArgString(STRING(arg));
	
	GetWeaponEntClass(arg, strEnt);
	if(StrEqual(strEnt, "erreur"))
	{
		CPrintToChat(client, "%s Aucune arme a été trouvée.", TEAM);
		return Plugin_Handled;
	}
	
	int ent = CreateEntityByName(strEnt);
	DispatchSpawn(ent);
	if(StrEqual(strEnt, "weapon_usp_silencer") || StrEqual(strEnt, "weapon_m4a1_silencer"))
		Format(STRING(strFormat), "admin|silencer|%N", client);
	else
		Format(STRING(strFormat), "admin|%N", client);
	Entity_SetName(ent, strFormat);
	
	float position[3];
	PointVision(client, position);
	TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
	
	PrecacheSoundAny("ambient/energy/weld1.wav", true);
	EmitSoundToAllAny("ambient/energy/weld1.wav", ent, _, _, _, 1.0, _, _, position);
	
	return Plugin_Handled;
}

public Action Command_Arme(int client, int args)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 0)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_arme <joueur> <arme>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_arme <joueur> <arme>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(STRING(cmdArg));
	
	char arg1[64], arg2[64], strEnt[64];
	int len = BreakString(cmdArg, STRING(arg1));
	if(len != -1)
		strcopy(STRING(arg2), cmdArg[len]);
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg1, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	GetWeaponEntClass(arg2, strEnt);
	if(StrEqual(strEnt, "erreur"))
	{
		CPrintToChat(client, "%s Aucune arme a été trouvée.", TEAM);
		return Plugin_Handled;
	}
	
	if(client > 0)
	{
		if(StrEqual(arg1, "@civil"))
			CPrintToChat(client, "%s Tout les civils ont une arme.", TEAM);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Toutes les forces de l'ordre ont une arme.", TEAM);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Tout le monde ont une arme.", TEAM);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Tout les vivants ont une arme.", TEAM);
	}
	else
	{
		if(StrEqual(arg1, "@civil"))
			PrintToServer("[ADMIN] Tout les civils ont une arme.");
		else if(StrEqual(arg1, "@police"))
			PrintToServer("[ADMIN] Toutes les forces de l'ordre ont une arme.");
		else if(StrEqual(arg1, "@tous"))
			PrintToServer("[ADMIN] Tout le monde ont une arme.");
		else if(StrEqual(arg1, "@vie"))
			PrintToServer("[ADMIN] Tout les vivants ont une arme.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i))
			{
				if(IsValidEntity(i))
				{
					int ent = GivePlayerItem(i, strEnt);
					char strFormat[64];
					Format(STRING(strFormat), "admin|%N", i);
					Entity_SetName(ent, strFormat);
					PrintHintText(i, "Vous avez ramassé une arme.");
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_TPA(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_tpa <joueur>", TEAM);
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	if(StrEqual(arg, "@civil")
	|| StrEqual(arg, "@police")
	|| StrEqual(arg, "@tous")
	|| StrEqual(arg, "@vie"))
	{
		CPrintToChat(client, "%s Vous pouvez vous téléporter uniquement sur un seul joueur.", TEAM);
		return Plugin_Handled;
	}
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;

	float origin[3];
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
			GetClientAbsOrigin(joueur[i], origin);
	}
	
	origin[2] += 72.0;
	TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action Command_TP(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_tpa <joueur>", TEAM);
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;

	if(StrEqual(arg, "@civil"))
		CPrintToChat(client, "%s Vous avez téléporté tous les civils.", TEAM);
	else if(StrEqual(arg, "@police"))
		CPrintToChat(client, "%s Vous avez téléporté toutes les forces de l'ordre.", TEAM);
	else if(StrEqual(arg, "@tous"))
		CPrintToChat(client, "%s Vous avez téléporté tout le monde.", TEAM);
	else if(StrEqual(arg, "@vie"))
		CPrintToChat(client, "%s Vous avez téléporté tout les vivants.", TEAM);
	
	float origin[3];
	PointVision(client, origin);
	origin[2] += 2.0;
	
	PrecacheSound("ambient.electrical_zap_9");
	EmitSoundToClient(client, "ambient.electrical_zap_9", client, _, _, _, 1.0);
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i))
			{
				if(IsValidEntity(i))
				{
					TeleportEntity(i, origin, NULL_VECTOR, NULL_VECTOR);
					if(i != client)
						CPrintToChat(i, "%s Vous avez été téléporté.", TEAM);
						
					PrecacheSound("ambient.electrical_zap_9", true);
					EmitAmbientGameSound("ambient.electrical_zap_9", origin);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Remove(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	int aim = GetAimEnt(client, false);
	if(IsValidEntity(aim))
	{
		if(Distance(client, aim) > 1000.0)
		{
			CPrintToChat(client, "%s Vous devez vous rapprocher de l'entité.", TEAM);
			return Plugin_Handled;
		}
		
		char entClass[64], entModel[128], strAim[64];
		GetEntityClassname(aim, STRING(entClass));
		Entity_GetModel(aim, STRING(entModel));
				
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu Del = new Menu(DoMenuDel);
		Del.SetTitle("Voulez-vous supprimer %s %s ?", entClass, entModel);
		Format(STRING(strAim), "oui|%d", aim);
		Del.AddItem(strAim, "Oui");
		Del.AddItem("", "Non");
		Del.ExitButton = true;
		Del.Display(client, MENU_TIME_FOREVER);
	}
	else
		CPrintToChat(client, "%s Vous devez regarder une entité.", TEAM);
	
	return Plugin_Handled;
}

public Action Command_SetJob(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	MenuSetJob(client);
	
	return Plugin_Handled;
}

public Action Command_Kick(int client, int args)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 0)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_kick <joueur> (raison)", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_kick <joueur> (raison)");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(STRING(cmdArg));
	
	char arg1[64], arg2[128];
	int len = BreakString(cmdArg, STRING(arg1));
	if(len != -1)
		strcopy(STRING(arg2), cmdArg[len]);
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg1);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg1, "@civil"))
			CPrintToChat(client, "%s Vous avez exclu tous les civils.", TEAM);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Vous avez exclu toutes les forces de l'ordre.", TEAM);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Vous avez exclu tout le monde.", TEAM);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Vous avez exclu tout les vivants sur vous.", TEAM);
		else if(StrEqual(arg1, "@mort"))
			CPrintToChat(client, "%s Vous avez exclu tout les morts sur vous.", TEAM);
	}
	else
	{
		if(StrEqual(arg1, "@civil"))
			PrintToServer("[ADMIN] Vous avez exclu tous les civils.");
		else if(StrEqual(arg1, "@police"))
			PrintToServer("[ADMIN] Vous avez exclu toutes les forces de l'ordre.");
		else if(StrEqual(arg1, "@tous"))
			PrintToServer("[ADMIN] Vous avez exclu tout le monde.");
		else if(StrEqual(arg1, "@vie"))
			PrintToServer("[ADMIN] Vous avez exclu tout les vivants.");
		else if(StrEqual(arg1, "@mort"))
			PrintToServer("[ADMIN] Vous avez exclu tout les morts.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(rp_GetClientInt(i, i_AdminLevel) == 0 || rp_GetClientInt(i, i_AdminLevel) > rp_GetClientInt(client, i_AdminLevel) && rp_GetClientInt(i, i_AdminLevel) != 1)
			{
				if(StrContains(arg1, "@", false) == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s Vous avez exclu %N.", TEAM, i);
					else
						PrintToServer("[ADMIN] Vous avez exclu %N.", i);
					
					for(int x = 1; x <= MaxClients; x++)
					{
						if(IsClientValid(x))
						{
							if(rp_GetClientInt(x, i_AdminLevel) == 1 || rp_GetClientInt(x, i_AdminLevel) == 2)
							{
								if(!StrEqual(arg2, ""))
									CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} %N{default}. Raison : %s", TEAM, client, i, arg2);
								else
									CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} %N{default}.", TEAM, client, i);
							}
							else
								CPrintToChat(x, "%s {lightgreen}%N{default} a été {lightred}exclu{default} de la partie.", TEAM, i);
						}
					}
				}
				else
				{
					for(int x = 1; x <= MaxClients; x++)
					{
						if(IsClientValid(x))
						{
							if(rp_GetClientInt(x, i_AdminLevel) == 1 || rp_GetClientInt(x, i_AdminLevel) == 2)
							{
								if(!StrEqual(arg2, ""))
								{
									if(StrEqual(arg1, "@civil"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tous les civils{default}. Raison : %s", TEAM, client, i, arg2);
									else if(StrEqual(arg1, "@police"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} toutes les forces de l'ordre{default}. Raison : %s", TEAM, client, i, arg2);
									else if(StrEqual(arg1, "@tous"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout le monde{default}. Raison : %s", TEAM, client, i, arg2);
									else if(StrEqual(arg1, "@vie"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout les vivants{default}. Raison : %s", TEAM, client, i, arg2);
									else if(StrEqual(arg1, "@mort"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout les morts{default}. Raison : %s", TEAM, client, i, arg2);
								}
								else
								{
									if(StrEqual(arg1, "@civil"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout les civils{default}.", TEAM, client, i);
									else if(StrEqual(arg1, "@police"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} toutes les forces de l'ordre{default}.", TEAM, client, i);
									else if(StrEqual(arg1, "@tous"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout le monde{default}.", TEAM, client, i);
									else if(StrEqual(arg1, "@vie"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout les vivants{default}.", TEAM, client, i);
									else if(StrEqual(arg1, "@mort"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout les morts{default}.", TEAM, client, i);
								}
							}
							else
								CPrintToChat(x, "%s {lightgreen}%N{default} a été {lightred}exclu{default} de la partie.", TEAM, i);
						}
					}
				}
				char strFormat[512];
				if(!StrEqual(arg2, ""))
					Format(STRING(strFormat), "Vous avez été exclu du RolePlay par un modérateur.\nRaison : %s", arg2);
				else
					Format(STRING(strFormat), "Vous avez été exclu du RolePlay par un modérateur.");
				KickClient(i, strFormat);
			}
			else if(i != client)
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à exlure cette personne.", TEAM);
			else
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à vous exlure.", TEAM);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Noclip(int client, int args)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 0)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_noclip <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_noclip <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez mis/enlevé le noclip à tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez mis/enlevé le noclip à tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez mis/enlevé le noclip à tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez mis/enlevé le noclip à tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez mis/enleve le noclip a tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez mis/enleve le noclip a tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez mis/enleve le noclip a tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez mis/enleve le noclip a tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				if(GetEntityMoveType(i) != MOVETYPE_NOCLIP)
				{
					SetEntityMoveType(i, MOVETYPE_NOCLIP);
					PrintHintText(i, "Noclip activé.");
					
					if(StrContains(arg, "@", false) == -1 && i != client)
					{
						if(client > 0)
							CPrintToChat(client, "%s {yellow}%N {default}est maintenant en noclip.", TEAM, i);
						else
							PrintToServer("[ADMIN] %N est maintenant en noclip.", i);
					}
				}
				else
				{
					SetEntityMoveType(i, MOVETYPE_WALK);
					PrintHintText(i, "Noclip désactivé.");
					
					if(StrContains(arg, "@", false) == -1 && i != client)
					{
						if(client > 0)
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus en noclip.", TEAM, i);
						else
							PrintToServer("[ADMIN] %N n'est plus en noclip.", i);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Freeze(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_freeze <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_freeze <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/gelé tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/gelé tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/gelé tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/gelé tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez de/gele tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez de/gele tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez de/gele tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez de/gele tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				PrecacheSound("physics/glass/glass_impact_bullet4.wav");
				EmitSoundToAll("physics/glass/glass_impact_bullet4.wav", i, _, _, _, 1.0);
				
				if(GetEntProp(i, Prop_Send, "m_iPlayerState") == 0)
				{
					SetEntProp(i, Prop_Send, "m_iPlayerState", 1);
					SetEntityRenderColor(i, 0, 128, 255, 192);
					
					PrintHintText(i, "Vous êtes gelé.");
					CPrintToChat(i, "%s Vous êtes gelé.", TEAM);
					
					if(StrContains(arg, "@", false) == -1 && i != client)
					{
						if(client > 0)
							PrintHintText(client, "%N est gelé.", i);
						else
							PrintToServer("[ADMIN] %N est gele.", i);
					}
				}
				else
				{
					SetEntProp(i, Prop_Send, "m_iPlayerState", 0);
					SetEntityRenderColor(i, 255, 255, 255, 255);
					
					PrintHintText(i, "Vous êtes dégelé.");
					CPrintToChat(i, "%s Vous êtes dégelé.", TEAM);
					
					if(StrContains(arg, "@", false) == -1 && i != client)
					{
						if(client > 0)
							PrintHintText(client, "%N est dégelé.", i);
						else
							PrintToServer("[ADMIN] %N est degele.", i);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Slap(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_slap <joueur> <degat>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_slap <joueur> <degat>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(STRING(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, STRING(arg1));
	if(len != -1)
		strcopy(STRING(arg2), cmdArg[len]);
	
	if(!String_IsNumeric(arg2))
	{
		if(client > 0)
			CPrintToChat(client, "%s Les dégats doivent être en chiffre.", TEAM);
		else
			PrintToServer("[ADMIN] Les degats doivent etre en chiffre.");
		return Plugin_Handled;
	}
	
	int degat = StringToInt(arg2);
	if(degat < 0)
		degat = 0;
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg1, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg1, "@civil"))
			CPrintToChat(client, "%s Vous avez giflé tout les civils.", TEAM);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Vous avez giflé tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Vous avez giflé tout le monde.", TEAM);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Vous avez giflé tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg1, "@civil"))
			PrintToServer("[ADMIN] Vous avez gifle tout les civils.");
		else if(StrEqual(arg1, "@police"))
			PrintToServer("[ADMIN] Vous avez gifle tout les forces de l'ordre.");
		else if(StrEqual(arg1, "@tous"))
			PrintToServer("[ADMIN] Vous avez gifle tout le monde.");
		else if(StrEqual(arg1, "@vie"))
			PrintToServer("[ADMIN] Vous avez gifle tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				SlapPlayer(i, degat);
				PrintHintText(i, "Vous avez été giflé.");
				CPrintToChat(i, "%s Vous avez été giflé.", TEAM);
				
				if(i != client && StrContains(arg1, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}a été giflé.", TEAM, i);
					else
						PrintToServer("[ADMIN] %N a ete gifle.", i);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Slay(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_slay <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_slay <joueur>");
		return Plugin_Handled;
	}
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez giflé tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez giflé tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez giflé tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez giflé tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez gifle tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez gifle tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez gifle tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez gifle tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i) && !IsBenito(i))
			{
				ForcePlayerSuicide(i);
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}a été tué.", TEAM, i);
					else
						PrintToServer("[ADMIN] %N a ete tue.", i);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Respawn(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_revivre <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_revivre <joueur>");
		return Plugin_Handled;
	}
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez fais revivre tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez fais revivre tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez fais revivre tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez fais revivre tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez fais revivre tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez fais revivre tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez fais revivre tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez fais revivre tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(!IsPlayerAlive(i))
			{
				CS_RespawnPlayer(i);
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}est maintenant en vie.", TEAM, i);
					else
						PrintToServer("[ADMIN] %N est maintenant en vie.", i);
				}
			}
			else if(i != client && StrContains(arg, "@") == -1)
			{
				if(client > 0)
					CPrintToChat(client, "%s {yellow}%N {default}est déjà en vie.", TEAM, i);
				else
					PrintToServer("[ADMIN] %N est deja en vie.", i);
			}
			else if(StrContains(arg, "@") == -1)
				CPrintToChat(client, "%s Vous êtes déjà en vie.", TEAM);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Burn(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_burn <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_burn <joueur>");
		return Plugin_Handled;
	}
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez enflammé tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez enflammé tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez enflammé tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez enflammé tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez enflamme tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez enflamme tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez enflamme tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez enflamme tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				IgniteEntity(i, 20.0);
				PrintCenterText(client, "Vous êtes en feu !");
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}a été enflammé.", TEAM, i);
					else
						PrintToServer("[ADMIN] %N a ete enflamme.", i);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Gravity(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char cmdArg[256];
	GetCmdArgString(STRING(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, STRING(arg1));
	if(len != -1)
		strcopy(STRING(arg2), cmdArg[len]);
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_gravite <joueur> <montant>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_gravite <joueur> <montant>");
		return Plugin_Handled;
	}
	else if(!String_IsNumeric(arg2))
	{
		if(client > 0)
			CPrintToChat(client, "%s La gravité doit être en chiffre.", TEAM);
		else
			PrintToServer("[ADMIN] La gravite doit etre en chiffre.");
		return Plugin_Handled;
	}
	
	float gravite = StringToFloat(arg2);
	if(gravite < 0.0)
		gravite = 0.0;
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg1, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg1, "@civil"))
			CPrintToChat(client, "%s Vous avez modifié la gravité de tout les civils.", TEAM);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Vous avez modifié la gravité de tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Vous avez modifié la gravité de tout le monde.", TEAM);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Vous avez modifié la gravité de tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg1, "@civil"))
			PrintToServer("[ADMIN] Vous avez modifie la gravite de tout les civils.");
		else if(StrEqual(arg1, "@police"))
			PrintToServer("[ADMIN] Vous avez modifie la gravite de tout les forces de l'ordre.");
		else if(StrEqual(arg1, "@tous"))
			PrintToServer("[ADMIN] Vous avez modifie la gravite de tout le monde.");
		else if(StrEqual(arg1, "@vie"))
			PrintToServer("[ADMIN] Vous avez modifie la gravite de tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				SetEntityGravity(i, gravite);
				PrintHintText(i, "Votre gravité a changé (%.0f).", gravite);
				CPrintToChat(i, "%s Votre gravité a changé (%.0f).", TEAM, gravite);
				
				if(i != client && StrContains(arg1, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}a changé de gravité (%.0f).", TEAM, i, gravite);
					else
						PrintToServer("[ADMIN] %N a change de gravite (%.0f).", i, gravite);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Beacon(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_balise <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_balise <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/balisé tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/balisé tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/balisé tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/balisé tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez de/balise tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez de/balise tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez de/balise tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez de/balise tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				if(rp_GetClientBool(i, b_isBeacon))
				{
					rp_SetClientBool(i, b_isBeacon, false);
					CreateTimer(0.1, TimerBeacon, i);
					PrintHintText(i, "La balise a été enlevée.");
					CPrintToChat(i, "%s La balise a été enlevée.", TEAM);
				}
				else
				{
					rp_SetClientBool(i, b_isBeacon, true);
					CreateTimer(2.0, TimerBeacon, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					PrintHintText(i, "Une balise a été placée sur vous.");
					CPrintToChat(i, "%s Une balise a été placée sur vous.", TEAM);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isBeacon))
							CPrintToChat(client, "%s {yellow}%N {default}a une balise.", TEAM, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'a plus de balise.", TEAM, i);
					}
					else
					{
						if(rp_GetClientBool(i, b_isBeacon))
							PrintToServer("[ADMIN] %N a une balise.", i);
						else
							PrintToServer("[ADMIN] %N n'a plus de balise.", i);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Bombe(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_bombe <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_bombe <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez enlevé/placé une bombe sur tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez enlevé/placé une bombe sur tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez enlevé/placé une bombe sur tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez enlevé/placé une bombe sur tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez enleve/place une bombe sur tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez enleve/place une bombe sur tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez enleve/place une bombe sur tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez enleve/place une bombe sur tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				if(rp_GetClientBool(i, b_isBombe))
				{
					rp_SetClientBool(i, b_isBombe, false);
					compteurBombe[client] = -1;
					CreateTimer(0.1, TimerBombe, i);
					PrintHintText(i, "La bombe a été enlevée.");
					CPrintToChat(i, "%s La bombe a été enlevée.", TEAM);
				}
				else
				{
					rp_SetClientBool(i, b_isBombe, true);
					compteurBombe[client] = 10;
					CreateTimer(1.0, TimerBombe, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					PrintHintText(i, "Une bombe a été placée sur vous.");
					CPrintToChat(i, "%s Une bombe a été placée sur vous.", TEAM);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isBombe))
							CPrintToChat(client, "%s {yellow}%N {default}a une bombe.", TEAM, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'a plus de bombe.", TEAM, i);
					}
					else
					{
						if(rp_GetClientBool(i, b_isBombe))
							PrintToServer("[ADMIN] %N a une bombe.", i);
						else
							PrintToServer("[ADMIN] %N n'a plus de bombe.", i);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Mute(int client, int args)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 0)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_mute <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_mute <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/muté tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/muté tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/muté tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/muté tout les vivants.", TEAM);
		else if(StrEqual(arg, "@mort"))
			CPrintToChat(client, "%s Vous avez dé/muté tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez de/mute tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez de/mute tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez de/mute tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez de/mute tout les vivants.");
		else if(StrEqual(arg, "@mort"))
			PrintToServer("[ADMIN] Vous avez de/mute tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				if(rp_GetClientBool(i, b_isMute))
				{
					rp_SetClientBool(i, b_isMute, false);
					PrintHintText(i, "Vous n'êtes plus muet.");
					CPrintToChat(i, "%s Vous n'êtes plus muet.", TEAM);
				}
				else
				{
					rp_SetClientBool(i, b_isMute, true);
					PrintHintText(i, "Vous êtes muet.");
					CPrintToChat(i, "%s Vous êtes muet.", TEAM);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isMute))
							CPrintToChat(client, "%s {yellow}%N {default}a est muet.", TEAM, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus muet.", TEAM, i);
					}
					else
					{
						if(rp_GetClientBool(i, b_isMute))
							PrintToServer("[ADMIN] %N est muet.", i);
						else
							PrintToServer("[ADMIN] %N n'est plus muet.", i);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Gag(int client, int args)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 0)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_gag <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_gag <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/gag tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/gag tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/gag tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/gag tout les vivants.", TEAM);
		else if(StrEqual(arg, "@mort"))
			CPrintToChat(client, "%s Vous avez dé/gag tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez de/gag tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez de/gag tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez de/gag tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez de/gag tout les vivants.");
		else if(StrEqual(arg, "@mort"))
			PrintToServer("[ADMIN] Vous avez de/gag tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				if(rp_GetClientBool(i, b_isGag))
				{
					rp_SetClientBool(i, b_isGag, false);
					PrintHintText(i, "Vous n'êtes plus gag.");
					CPrintToChat(i, "%s Vous n'êtes plus gag.", TEAM);
				}
				else
				{
					rp_SetClientBool(i, b_isGag, true);
					PrintHintText(i, "Vous êtes gag.");
					CPrintToChat(i, "%s Vous êtes gag.", TEAM);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isGag))
							CPrintToChat(client, "%s {yellow}%N {default}a est gag.", TEAM, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus gag.", TEAM, i);
					}
					else
					{
						if(rp_GetClientBool(i, b_isGag))
							PrintToServer("[ADMIN] %N est gag.", i);
						else
							PrintToServer("[ADMIN] %N n'est plus gag.", i);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Silence(int client, int args)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 0)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_silence <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_silence <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez mis/enlevé sous silence tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez mis/enlevé sous silence tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez mis/enlevé sous silence tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez mis/enlevé sous silence tout les vivants.", TEAM);
		else if(StrEqual(arg, "@mort"))
			CPrintToChat(client, "%s Vous avez mis/enlevé sous silence tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez mis/enleve sous silence tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez mis/enleve sous silence tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez mis/enleve sous silence tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez mis/enleve sous silence tout les vivants.");
		else if(StrEqual(arg, "@mort"))
			PrintToServer("[ADMIN] Vous avez mis/enleve sous silence tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				if(rp_GetClientBool(i, b_isMute) && rp_GetClientBool(i, b_isGag))
				{
					rp_SetClientBool(i, b_isGag, false);
					rp_SetClientBool(i, b_isMute, false);
					PrintHintText(i, "Vous n'êtes plus sous silence.");
					CPrintToChat(i, "%s Vous n'êtes plus sous silence.", TEAM);
				}
				else
				{
					rp_SetClientBool(i, b_isMute, true);
					rp_SetClientBool(i, b_isGag, true);
					PrintHintText(i, "Vous êtes sous silence.");
					CPrintToChat(i, "%s Vous êtes sous silence.", TEAM);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isMute) && rp_GetClientBool(i, b_isGag))
							CPrintToChat(client, "%s {yellow}%N {default}a est sous silence.", TEAM, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus sous silence.", TEAM, i);
					}
					else
					{
						if(rp_GetClientBool(i, b_isMute) && rp_GetClientBool(i, b_isGag))
							PrintToServer("[ADMIN] %N est sous silence.", i);
						else
							PrintToServer("[ADMIN] %N n'est plus sous silence.", i);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Drug(int client, int args)
{
	if(rp_GetClientInt(client, i_AdminLevel) == 0)
		return Plugin_Handled;
	
	CPrintToChat(client, "%s Commande désactivé temporairement !", TEAM);
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_drogue <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_drogue <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/drogué tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/drogué tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/drogué tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/drogué tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez de/drogue tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez de/drogue tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez de/drogue tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez de/drogue tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				if(rp_GetClientBool(i, b_isDrug))
				{
					rp_SetClientBool(i, b_isDrug, false);
					CreateTimer(0.1, TimerDrug, i);
					PrintHintText(i, "Vous n'êtes plus drogué.");
					CPrintToChat(i, "%s Vous n'êtes plus drogué.", TEAM);
				}
				else
				{
					rp_SetClientBool(i, b_isDrug, true);
					CreateTimer(2.0, TimerDrug, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					PrintHintText(i, "Vous êtes drogué.");
					CPrintToChat(i, "%s Vous êtes drogué.", TEAM);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isDrug))
							CPrintToChat(client, "%s {yellow}%N {default}a est drogué.", TEAM, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus drogué.", TEAM, i);
					}
					else
					{
						if(rp_GetClientBool(i, b_isDrug))
							PrintToServer("[ADMIN] %N est drogue.", i);
						else
							PrintToServer("[ADMIN] %N n'est plus drogue.", i);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Blind(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_aveugle <joueur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_aveugle <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/aveuglé le noclip à tout les civils.", TEAM);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/aveuglé le noclip à tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/aveuglé le noclip à tout le monde.", TEAM);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/aveuglé le noclip à tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg, "@civil"))
			PrintToServer("[ADMIN] Vous avez de/aveugle le noclip a tout les civils.");
		else if(StrEqual(arg, "@police"))
			PrintToServer("[ADMIN] Vous avez de/aveugle le noclip a tout les forces de l'ordre.");
		else if(StrEqual(arg, "@tous"))
			PrintToServer("[ADMIN] Vous avez de/aveugle le noclip a tout le monde.");
		else if(StrEqual(arg, "@vie"))
			PrintToServer("[ADMIN] Vous avez de/aveugle le noclip a tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				if(rp_GetClientBool(i, b_isBlind))
				{
					rp_SetClientBool(i, b_isBlind, false);
					
					int clients[2];
					clients[0] = client;
					int color[4] = {0, 0, 0, 0};
					
					Handle message = StartMessage("Fade", clients, 1);
					Protobuf bf = UserMessageToProtobuf(message);
					bf.SetInt("duration", 1);
					bf.SetInt("hold_time", 1);
					bf.SetInt("flags", FFADE_PURGE);
					bf.SetColor("clr", color);
					EndMessage();
					
					PrintHintText(i, "Vous n'êtes plus aveugle.");
					CPrintToChat(i, "%s Vous n'êtes plus aveugle.", TEAM);
					
					if(StrContains(arg, "@", false) == -1 && i != client)
					{
						if(client > 0)
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus aveugle.", TEAM, i);
						else
							PrintToServer("[ADMIN] %N n'est plus aveugle.", i);
					}
				}
				else
				{
					rp_SetClientBool(i, b_isBlind, true);
					
					int clients[2];
					clients[0] = client;
					int color[4] = {0, 0, 0, 255};
					
					Handle message = StartMessage("Fade", clients, 1);
					Protobuf bf = UserMessageToProtobuf(message);
					bf.SetInt("duration", 1000000000);
					bf.SetInt("hold_time", 1000000000);
					bf.SetInt("flags", FFADE_STAYOUT);
					bf.SetColor("clr", color);
					EndMessage();
					
					PrintHintText(i, "Vous êtes aveugle.");
					CPrintToChat(i, "%s Vous êtes aveugle.", TEAM);
					
					if(StrContains(arg, "@", false) == -1 && i != client)
					{
						if(client > 0)
							CPrintToChat(client, "%s {yellow}%N {default}est aveugle.", TEAM, i);
						else
							PrintToServer("[ADMIN] %N est aveugle.", i);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Rcon(int client, int args)
{
	if(client == 0 || rp_GetClientInt(client, i_AdminLevel) != 1)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	ServerCommand(arg);	
	
	return Plugin_Handled;
}

public Action Command_Map(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	if(!StrEqual(arg, "reload"))
		return Plugin_Handled;
	
	char mapName[128];
	rp_GetCurrentMap(mapName);
	ForceChangeLevel(mapName, "Admin CMD");
	
	char hostname[128];
	GetConVarString(FindConVar("hostname"), STRING(hostname));
	
	DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
	hook.SlackMode = true;	
	hook.SetUsername("Roleplay");	
	
	MessageEmbed Embed = new MessageEmbed();	
	Embed.SetColor("#00fd29");
	Embed.SetTitle(hostname);
	Embed.SetTitleLink("steam://connect/163.172.72.143:27115");
	Embed.AddField("Action", "Changement de map", false);
	Embed.AddField("Nouvelle Map", mapName, false);
	Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
	Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
	Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/Logogros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
	
	hook.Embed(Embed);	
	hook.Send();
	delete hook;
	
	return Plugin_Handled;
}

public Action Command_Say(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(STRING(arg));
	
	if(strlen(arg) == 0)
		Format(STRING(arg), " ");
	
	char strFormat[256];
	Format(STRING(strFormat), "[ADMIN] {lime}%s", arg);
	CPrintToChatAll(strFormat);
	
	return Plugin_Handled;
}

public Action Command_EntitySetName(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(rp_GetClientInt(client, i_AdminLevel) != 1)
		return Plugin_Handled;
	
	int aim = GetAimEnt(client, false);
	if(IsValidEntity(aim))
	{
		char arg[256], entName[128];
		GetCmdArgString(STRING(arg));
		Entity_GetName(aim, STRING(entName));
		Entity_SetName(aim, arg);
		CPrintToChat(client, "%s Ancien nom : %s {yellow}=>{default} %s", TEAM, entName, arg);
	}
	else
		CPrintToChat(client, "%s Aucune entité détectée.", TEAM);
	
	return Plugin_Handled;
}

public Action Command_Vitesse(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		NoCommandAcces(client);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_vitesse <joueur> <valeur>", TEAM);
		else
			PrintToServer("[ADMIN] Usage : rp_vitesse <joueur> <valeur>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(STRING(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, STRING(arg1));
	if(len != -1)
		strcopy(STRING(arg2), cmdArg[len]);
	
	if(!String_IsNumeric(arg2))
	{
		if(client > 0)
			CPrintToChat(client, "%s La vitesse doit être en chiffre.", TEAM);
		else
			PrintToServer("[ADMIN] La vitesse doit etre en chiffre.");
		return Plugin_Handled;
	}
	float vitesse = StringToFloat(arg2);
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg1, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg1, "@civil"))
			CPrintToChat(client, "%s Vous avez changé la vitesse de tout les civils.", TEAM);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Vous avez changé la vitesse de tout les forces de l'ordre.", TEAM);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Vous avez changé la vitesse de tout le monde.", TEAM);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Vous avez changé la vitesse de tout les vivants.", TEAM);
	}
	else
	{
		if(StrEqual(arg1, "@civil"))
			PrintToServer("[ADMIN] Vous avez change la vitesse de tout les civils.");
		else if(StrEqual(arg1, "@police"))
			PrintToServer("[ADMIN] Vous avez change la vitesse de tout les forces de l'ordre.");
		else if(StrEqual(arg1, "@tous"))
			PrintToServer("[ADMIN] Vous avez change la vitesse de tout le monde.");
		else if(StrEqual(arg1, "@vie"))
			PrintToServer("[ADMIN] Vous avez change la vitesse de tout les vivants.");
	}
	
	LoopClients(i)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", vitesse);
				
				PrintHintText(i, "Votre vitesse a changée (%.0f).", vitesse);
				CPrintToChat(i, "%s Votre vitesse a changée (%.0f).", TEAM, vitesse);
				
				if(StrContains(arg1, "@", false) == -1 && i != client)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}a changé de vitesse (%.0f).", TEAM, i, vitesse);
					else
						PrintToServer("[ADMIN] %N a change de vitesse (%.0f).", i, vitesse);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Invisibilite(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	else if(rp_GetClientInt(client, i_AdminLevel) == 0)
		return Plugin_Handled;
	
	if(!rp_GetClientBool(client, b_isInvisible))
	{
		if(IsValidEntity(client) && IsPlayerAlive(client))
		{
			rp_SetClientBool(client, b_isInvisible, true);
			
			SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
			SetEntProp(client, Prop_Send, "m_bSpotted", 0);
			PrintHintText(client, "Vous êtes invisible.");
		}
	}
	else
	{
		if(IsValidEntity(client) && IsPlayerAlive(client))
		{
			rp_SetClientBool(client, b_isInvisible, false);
			SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
			SetEntProp(client, Prop_Send, "m_bSpotted", 1);
			PrintHintText(client, "Vous êtes visible.");
		}
	}
	
	return Plugin_Handled;
}

public Action Command_GetPos(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("[ADMIN] Cette commande n'est pas disponible.");
		return Plugin_Handled;
	}
	
	if (rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		float position[3];
		PointVision(client, position);
		CPrintToChat(client, "%s %f, %f, %f", TEAM, position[0], position[1], position[2]);
	}
	else
		NoCommandAcces(client);
	
	return Plugin_Handled;
}

// ================================================================
//                           TIMERS
// ================================================================

public Action TimerBeacon(Handle timer, any client)
{
	if(!IsClientValid(client))
		return Plugin_Continue;
	
	if(rp_GetClientBool(client, b_isBeacon))
	{
		PrecacheSound("buttons/blip1.wav");
		EmitSoundToAll("buttons/blip1.wav", client, _, _, _, 1.0);
		
		float origin[3];
		GetClientAbsOrigin(client, origin);
		origin[2] += 30.0;
		TE_SetupBeamRingPoint(origin, 20.0, 300.0, g_BeamSpriteFollow, modelHalo, 0, 1, 1.0, 3.0, 1.0, {0, 128, 255, 255}, 20, 0);
		TE_SendToAll();
	}
	else return Plugin_Stop;
	
	return Plugin_Continue;
}

public Action TimerBombe(Handle timer, any client)
{
	if(!IsClientValid(client))
		return Plugin_Continue;
	
	if(rp_GetClientBool(client, b_isBombe) && compteurBombe[client] != -1)
	{
		float position[3];
		GetClientAbsOrigin(client, position);
		
		if(compteurBombe[client] <= 0)
		{
			rp_SetClientBool(client, b_isBombe, false);
			ForcePlayerSuicide(client);
			
			TE_SetupExplosion(position, -1, 1.0, 1, 0, 200, 200);
			TE_SendToAll();
			
			char sound[64];
			switch(GetRandomInt(1, 3))
			{
				case 1:strcopy(STRING(sound), "weapons/hegrenade/explode3.wav");
				case 2:strcopy(STRING(sound), "weapons/hegrenade/explode4.wav");
				case 3:strcopy(STRING(sound), "weapons/hegrenade/explode5.wav");
			}
			PrecacheSoundAny(sound);
			EmitSoundToAll(sound, client, _, _, _, 1.0, _, _, position);
			
			return Plugin_Stop;
		}
		
		compteurBombe[client]--;
		PrintHintText(client, "Explosion dans %i.", compteurBombe[client]);
		PrecacheSoundAny("buttons/blip1.wav");
		EmitSoundToAllAny("buttons/blip1.wav", client, _, _, _, 1.0, _, _, position);
	}
	else
	{
		compteurBombe[client] = 0;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action TimerDrug(Handle timer, any client)
{
	if(!IsClientValid(client))
		return Plugin_Continue;
	
	if(rp_GetClientBool(client, b_isDrug))
	{
		float angles[3];
		GetClientEyeAngles(client, angles);
		angles[2] = drugAngles[GetRandomInt(0,100) % 20];
		TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
		
		int clients[2];
		clients[0] = client;
		int color[4] = {0, 0, 0, 128};
		color[0] = GetRandomInt(0,255);
		color[1] = GetRandomInt(0,255);
		color[2] = GetRandomInt(0,255);
		
		Handle message = StartMessage("Fade", clients, 1);
		Protobuf bf = UserMessageToProtobuf(message);
		bf.SetInt("duration", 2000);
		bf.SetInt("hold_time", 2000);
		bf.SetInt("flags", FFADE_STAYOUT);
		bf.SetColor("clr", color);
		EndMessage();
	}
	else
	{
		float angles[3];
		GetClientEyeAngles(client, angles);
		angles[2] = 0.0;
		TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);
		
		int clients[2];
		clients[0] = client;
		int color[4] = {0, 0, 0, 0};
		
		Handle message = StartMessage("Fade", clients, 1);
		Protobuf bf = UserMessageToProtobuf(message);
		bf.SetInt("duration", 1);
		bf.SetInt("hold_time", 1);
		bf.SetInt("flags", FFADE_PURGE);
		bf.SetColor("clr", color);
		EndMessage();
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}


/*            HOOKS            */

public Action Hook_SetTransmit(int entity, int client)
{
	if(entity != client)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

Menu MenuDisplayPlugins(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(Handle_DisplayPlugins);
	menu.SetTitle("Roleplay - Plugins Loaded");
	
	if(FindPluginByFile("rp_appartement.smx") != null)
		menu.AddItem("rp_appartement.smx", "[Roleplay] Appartement: ✔");
	else
		menu.AddItem("rp_appartement.smx", "[Roleplay] Appartement: ✘");

	if(FindPluginByFile("rp_blockcommands.smx") != null)
		menu.AddItem("rp_blockcommands.smx", "[Roleplay] BlockCommands: ✔");
	else
		menu.AddItem("rp_blockcommands.smx", "[Roleplay] BlockCommands: ✘");
		
	if(FindPluginByFile("rp_checkplayer.smx") != null)
		menu.AddItem("rp_checkplayer.smx", "[Roleplay] CheckPlayer: ✔");
	else
		menu.AddItem("rp_checkplayer.smx", "[Roleplay] CheckPlayer: ✘");
		
	if(FindPluginByFile("rp_economy.smx") != null)
		menu.AddItem("rp_economy.smx", "[Roleplay] rp_economy: ✔");
	else
		menu.AddItem("rp_economy.smx", "[Roleplay] rp_economy: ✘");	
		
	if(FindPluginByFile("rp_globalforwards.smx") != null)
		menu.AddItem("rp_globalforwards.smx", "[Roleplay] rp_globalforwards: ✔");
	else
		menu.AddItem("rp_globalforwards.smx", "[Roleplay] rp_globalforwards: ✘");

	if(FindPluginByFile("rp_groupes_master.smx") != null)
		menu.AddItem("rp_groupes_master.smx", "[Roleplay] rp_groupes_master: ✔");
	else
		menu.AddItem("rp_groupes_master.smx", "[Roleplay] rp_groupes_master: ✘");
		
	if(FindPluginByFile("rp_holdups.smx") != null)
		menu.AddItem("rp_holdups.smx", "[Roleplay] rp_holdups: ✔");
	else
		menu.AddItem("rp_holdups.smx", "[Roleplay] rp_holdups: ✘");	
		
	if(FindPluginByFile("rp_hud.smx") != null)
		menu.AddItem("rp_hud.smx", "[Roleplay] rp_hud: ✔");
	else
		menu.AddItem("rp_hud.smx", "[Roleplay] rp_hud: ✘");	
		
	if(FindPluginByFile("rp_illegal.smx") != null)
		menu.AddItem("rp_illegal.smx", "[Roleplay] rp_illegal: ✔");
	else
		menu.AddItem("rp_illegal.smx", "[Roleplay] rp_illegal: ✘");

	if(FindPluginByFile("rp_item.smx") != null)
		menu.AddItem("rp_item.smx", "[Roleplay] rp_item: ✔");
	else
		menu.AddItem("rp_item.smx", "[Roleplay] rp_item: ✘");
		
	if(FindPluginByFile("rp_jobcore.smx") != null)
		menu.AddItem("rp_jobcore.smx", "[Roleplay] rp_jobcore: ✔");
	else
		menu.AddItem("rp_jobcore.smx", "[Roleplay] rp_jobcore: ✘");

	if(FindPluginByFile("rp_licence.smx") != null)
		menu.AddItem("rp_licence.smx", "[Roleplay] rp_licence: ✔");
	else
		menu.AddItem("rp_licence.smx", "[Roleplay] rp_licence: ✘");
		
	if(FindPluginByFile("rp_localtalk.smx") != null)
		menu.AddItem("rp_localtalk.smx", "[Roleplay] rp_localtalk: ✔");
	else
		menu.AddItem("rp_localtalk.smx", "[Roleplay] rp_localtalk: ✘");	
		
	if(FindPluginByFile("rp_menu.smx") != null)
		menu.AddItem("rp_menu.smx", "[Roleplay] rp_menu: ✔");
	else
		menu.AddItem("rp_menu.smx", "[Roleplay] rp_menu: ✘");

	if(FindPluginByFile("rp_nativeregister.smx") != null)
		menu.AddItem("rp_nativeregister.smx", "[Roleplay] rp_nativeregister: ✔");
	else
		menu.AddItem("rp_nativeregister.smx", "[Roleplay] rp_nativeregister: ✘");
		
	if(FindPluginByFile("rp_newjoueur.smx") != null)
		menu.AddItem("rp_newjoueur.smx", "[Roleplay] rp_newjoueur: ✔");
	else
		menu.AddItem("rp_newjoueur.smx", "[Roleplay] rp_newjoueur: ✘");	
		
	if(FindPluginByFile("rp_out.smx") != null)
		menu.AddItem("rp_out.smx", "[Roleplay] rp_out: ✔");
	else
		menu.AddItem("rp_out.smx", "[Roleplay] rp_out: ✘");

	if(FindPluginByFile("rp_permaprops.smx") != null)
		menu.AddItem("rp_permaprops.smx", "[Roleplay] rp_permaprops: ✔");
	else
		menu.AddItem("rp_permaprops.smx", "[Roleplay] rp_permaprops: ✘");
		
	if(FindPluginByFile("rp_respawn.smx") != null)
		menu.AddItem("rp_respawn.smx", "[Roleplay] rp_respawn: ✔");
	else
		menu.AddItem("rp_respawn.smx", "[Roleplay] rp_respawn: ✘");

	if(FindPluginByFile("rp_salaires.smx") != null)
		menu.AddItem("rp_salaires.smx", "[Roleplay] rp_salaires: ✔");
	else
		menu.AddItem("rp_salaires.smx", "[Roleplay] rp_salaires: ✘");
		
	if(FindPluginByFile("rp_vendre.smx") != null)
		menu.AddItem("rp_vendre.smx", "[Roleplay] rp_vendre: ✔");
	else
		menu.AddItem("rp_vendre.smx", "[Roleplay] rp_vendre: ✘");

	if(FindPluginByFile("rp_vip.smx") != null)
		menu.AddItem("rp_vip.smx", "[Roleplay] rp_vip: ✔");
	else
		menu.AddItem("rp_vip.smx", "[Roleplay] rp_vip: ✘");
		
	if(FindPluginByFile("rp_zones.smx") != null)
		menu.AddItem("rp_zones.smx", "[Roleplay] rp_zones: ✔");
	else
		menu.AddItem("rp_zones.smx", "[Roleplay] rp_zones: ✘");	
		
	menu.AddItem("", "---- JOBS ----", ITEMDRAW_DISABLED);		
	
	if(FindPluginByFile("rp_job_armurier.smx") != null)
		menu.AddItem("rp_job_armurier.smx", "[Roleplay] Armurier: ✔");
	else
		menu.AddItem("rp_job_armurier.smx", "[Roleplay] Armurier: ✘");
		
	if(FindPluginByFile("rp_job_artificier.smx") != null)
		menu.AddItem("rp_job_artificier.smx", "[Roleplay] Artificier: ✔");
	else
		menu.AddItem("rp_job_artificier.smx", "[Roleplay] Artificier: ✘");	
		
	if(FindPluginByFile("rp_job_banquier.smx") != null)
		menu.AddItem("rp_job_banquier.smx", "[Roleplay] Banquier: ✔");
	else
		menu.AddItem("rp_job_banquier.smx", "[Roleplay] Banquier: ✘");		
		
	if(FindPluginByFile("rp_job_dealer.smx") != null)
		menu.AddItem("rp_job_dealer.smx", "[Roleplay] Dealer: ✔");
	else
		menu.AddItem("rp_job_dealer.smx", "[Roleplay] Dealer: ✘");	

 	if(FindPluginByFile("rp_job_hopital.smx") != null)
		menu.AddItem("rp_job_hopital.smx", "[Roleplay] Hôpital: ✔");
	else
		menu.AddItem("rp_job_hopital.smx", "[Roleplay] Hôpital: ✘");
		
	if(FindPluginByFile("rp_job_immo.smx") != null)
		menu.AddItem("rp_job_immo.smx", "[Roleplay] Immobilier: ✔");
	else
		menu.AddItem("rp_job_immo.smx", "[Roleplay] Immobilier: ✘");	
		
	if(FindPluginByFile("rp_job_mafia.smx") != null)
		menu.AddItem("rp_job_mafia.smx", "[Roleplay] Mafia: ✔");
	else
		menu.AddItem("rp_job_mafia.smx", "[Roleplay] Mafia: ✘");

	if(FindPluginByFile("rp_job_mairie.smx") != null)
		menu.AddItem("rp_job_mairie.smx", "[Roleplay] Mairie: ✔");
	else
		menu.AddItem("rp_job_mairie.smx", "[Roleplay] Mairie: ✘");
	
	if(FindPluginByFile("rp_job_police.smx") != null)
		menu.AddItem("rp_job_police.smx", "[Roleplay] Police: ✔");
	else
		menu.AddItem("rp_job_police.smx", "[Roleplay] Police: ✘");	
		
	if(FindPluginByFile("rp_job_technicien.smx") != null)
		menu.AddItem("rp_job_technicien.smx", "[Roleplay] Technicien: ✔");
	else
		menu.AddItem("rp_job_technicien.smx", "[Roleplay] Technicien: ✘");	

	if(FindPluginByFile("rp_job_vendeurdeskin.smx") != null)
		menu.AddItem("rp_job_vendeurdeskin.smx", "[Roleplay] Vendeur de skin: ✔");
	else
		menu.AddItem("rp_job_vendeurdeskin.smx", "[Roleplay] Vendeur de skin: ✘");	
		
	if(FindPluginByFile("rp_job_sexshop.smx") != null)
		menu.AddItem("rp_job_sexshop.smx", "[Roleplay] SexShop: ✔");
	else
		menu.AddItem("rp_job_sexshop.smx", "[Roleplay] SexShop: ✘");		
		
	menu.AddItem("", "---- EVENTS ----", ITEMDRAW_DISABLED);			
		
	if(FindPluginByFile("rp_event_murder.smx") != null)
		menu.AddItem("rp_event_murder.smx", "[Roleplay] Event Murder: ✔");
	else
		menu.AddItem("rp_event_murder.smx", "[Roleplay] Event Murder: ✘");		
		
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int Handle_DisplayPlugins(Menu menu, MenuAction action, int client, int param) 
{
	if(action == MenuAction_Select)
	{
		char info[64], strFormat[64];
		menu.GetItem(param, STRING(info));
		
		Menu rp = new Menu(DoPluginStuff);
		rp.SetTitle("Plugin: %s", info);
		
		if(FindPluginByFile(info) == null)
		{
			Format(STRING(strFormat), "%s|load", info);
			rp.AddItem(strFormat, "Démarrer !");
		}
		else
		{
			Format(STRING(strFormat), "%s|unload", info);
			rp.AddItem(strFormat, "Arrêter");
			
			Format(STRING(strFormat), "%s|reload", info);
			rp.AddItem(strFormat, "Redémarrer");
			
			Format(STRING(strFormat), "%s|refresh", info);
			rp.AddItem(strFormat, "Rafraichir");
		}
	
		rp.ExitButton = true;
		rp.Display(client, MENU_TIME_FOREVER);		
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End) 
	{
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

public int DoPluginStuff(Menu menu, MenuAction action, int client, int param) 
{
	if(action == MenuAction_Select)
	{
		char info[64], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		
		ServerCommand("sm plugins %s %s", buffer[1], buffer[0]);
		if(FindPluginByFile(buffer[0]) == null)
		{
			LoopClients(i)
			{
				if(rp_GetClientInt(i, i_AdminLevel) == 1)
					CPrintToChat(i, "%s : Erreur de lancement", buffer[0]);
			}	
		}	
		rp_SetClientBool(client, b_menuOpen, false);
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End) 
	{
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}