#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <multicolors>
#include <cstrike>
#include <roleplay>
#include <emitsoundany>

#pragma newdecls required

#define NAME "{yellow}[{green}Roleplay{yellow}]{default}"
#define MAXENTITIES		2048

char 
	logFile[PLATFORM_MAX_PATH],
	steamID[MAXPLAYERS+1][32],
	dbconfig[] = "roleplay";

Database g_DB;

ConVar fl_RestartTime;

int modelHalo;
int g_BeamSpriteFollow;
int compteurBombe[MAXPLAYERS+1];

float drugAngles[20] =  { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };

public Plugin myinfo = 
{
	name = "[Roleplay] Système Admin",
	author = "Benito",
	description = "Système Admin",
	version = "1.0",
	url = "www.revolution-asso.eu" 
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		fl_RestartTime = CreateConVar("rp_admin_reboot", "30", "Temps avant redémarrage");
			
		AutoExecConfig(true, "roleplay");
		
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/rp_admin.log");
		Database.Connect(GotDatabase, dbconfig);
		Command();
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
		
		char buffer[4096];
		Format(buffer, sizeof(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_admin` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `adminid` int(1) NOT NULL, \
		  `rankname` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
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
			Entity_GetClassName(i, entClass, sizeof(entClass));
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
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, playername, sizeof(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, clean_playername, sizeof(clean_playername));
	
	if(IsBenito(client))
	{
		char buffer[2048];
		Format(buffer, sizeof(buffer), "INSERT IGNORE INTO `rp_admin` (`Id`, `steamid`, `playername`, `adminid`, `rankname`, `timestamp`) VALUES (NULL, '%s', '%s', '1', 'FONDATEUR', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
		g_DB.Query(SQLErrorCheckCallback, buffer);
		
		AdminId admin = CreateAdmin("Revolution-Admin");
		SetUserAdmin(client, admin, false);
		SetAdminFlag(GetUserAdmin(client), view_as<AdminFlag>(14), true);
	}
	else
	{
		char buffer[2048];
		Format(buffer, sizeof(buffer), "INSERT IGNORE INTO `rp_admin` (`Id`, `steamid`, `playername`, `adminid`, `rankname`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
	
	SQLCALLBACK_LoadAdmin(client);
}

public void SQLCALLBACK_LoadAdmin(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(buffer, sizeof(buffer), "SELECT adminid, rankname FROM rp_admin WHERE steamid = '%s'", steamID[client]);
	LogToFile(logFile, buffer);
	g_DB.Query(SQLLoadAdminQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadAdminQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_AdminLevel, SQL_FetchIntByName(Results, "adminid"));
		if(rp_GetClientInt(client, i_AdminLevel) < 0)
			rp_SetClientInt(client, i_AdminLevel, 0);
			
		char rank[64];
		SQL_FetchStringByName(Results, "rankname", rank, 64);
		rp_SetClientString(client, sz_AdminTag, rank, sizeof(rank));
	}
} 

public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}

public Action rp_SayOnPublic(int client, char[] arg, char[] Cmd, int args)
{
	char strName[32];
	GetClientName(client, strName, sizeof(strName));
	
	if(rp_GetClientInt(client, i_AdminLevel) >= 1)
	{
		char rank[128], strPseudo[256];
		rp_GetClientString(client, sz_AdminTag, rank, sizeof(rank));
		Format(strPseudo, sizeof(strPseudo), "{default}[%s{default}] {default}%s", rank, strName);
		CPrintToChatAll("%s : {green}%s", strPseudo, arg);
	}
	else
		CPrintToChatAll("%s {default}: {green}%s", strName, arg);
}

public Action rp_SayOnTeam(int client, char[] arg, char[] Cmd, int args)
{
	char strName[32];
	GetClientName(client, strName, sizeof(strName));
	
	if(rp_GetClientInt(client, i_AdminLevel) >= 1)
	{
		char rank[64], strPseudo[256];
		rp_GetClientString(client, sz_AdminTag, rank, sizeof(rank));
		Format(strPseudo, sizeof(strPseudo), "{default}[%s{default}] %s", rank, strName);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
			{
				if(Distance(client, i) <= 1000.0)
					CPrintToChat(i, "{lightred}[LOCAL] %s {grey}dit : {green}%s", strPseudo, arg);
			}
		}
	}	
	else
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
			{
				if(Distance(client, i) <= 1000.0)
					CPrintToChatAll("%s {default}: {green}%s", strName, arg);
			}
		}
	}	
	
	return Plugin_Handled;
}

public Action rp_MenuRoleplay(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_AdminLevel) != 0)	
		menu.AddItem("admin", "Administration");
}

public int rp_HandlerMenuRoleplay(int client, char[] info)
{
	if(StrEqual(info, "admin"))
		BuildAdminMenu(client);
}	

int BuildAdminMenu(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoBuildAdminMenu);
	if(rp_GetClientInt(client, i_AdminLevel) > 2)
		menu.SetTitle("Modération :");
	else
		menu.SetTitle("Administration :");
		
	menu.AddItem("", "Gestion des joueurs [1/4]", ITEMDRAW_DISABLED);
	if(rp_GetClientInt(client, i_AdminLevel) <= 2)
		menu.AddItem("job" ,"JobMenu");
	menu.AddItem("tp", "Téléporter");
	menu.AddItem("tpa", "Téléporter sur");
	menu.AddItem("skin", "Mettre un skin");
	menu.AddItem("donnerarme", "Donner une arme");
	
	menu.AddItem("", "Gestion des joueurs [2/4]", ITEMDRAW_DISABLED);
	menu.AddItem("modifier", "Modifier un joueur");
	menu.AddItem("kick", "Kicker");
	menu.AddItem("ban", "Bannir");
	menu.AddItem("slay", "Tuer");
	menu.AddItem("respawn", "Revivre");
	
	menu.AddItem("", "Gestion des joueurs [3/4]", ITEMDRAW_DISABLED);
	menu.AddItem("gifle", "Gifler");
	menu.AddItem("geler", "Geler");
	menu.AddItem("bruler", "Bruler");
	menu.AddItem("baliser", "Baliser");
	menu.AddItem("bombe", "Bombe");
	
	menu.AddItem("", "Gestion des joueurs [4/4]", ITEMDRAW_DISABLED);
	menu.AddItem("mute", "Muter");
	menu.AddItem("gag", "Gager");
	menu.AddItem("silence", "Silence");
	menu.AddItem("droguer", "Droguer");
	menu.AddItem("aveugler", "Aveugler");
	
	menu.AddItem("", "Gestion des props [1/1]", ITEMDRAW_DISABLED);	
	menu.AddItem("props", "Créer un props");
	menu.AddItem("rotate", "Tourner un props");
	menu.AddItem("info", "Aide aux commandes");
	menu.AddItem("", "Attention :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Respecter la limite d'entité !", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "Gestion du RolePlay [1/1]", ITEMDRAW_DISABLED);
	menu.AddItem("save", "Sauvegarde forcée des joueurs");
	menu.AddItem("advert", "Avertir redémarrage");
	menu.AddItem("map", "Relancer la map");
	
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		menu.AddItem("", "Gestion du RolePlay [2/2]", ITEMDRAW_DISABLED);
		menu.AddItem("droitadmin", "Modifier les droits");
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoBuildAdminMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, info, sizeof(info));
		
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
		else if(StrEqual(info, "save"))
		{
			ClientCommand(client, "rp_forcesave");
			BuildAdminMenu(client);
		}
		else if(StrEqual(info, "advert"))
		{
			ClientCommand(client, "rp_advert");
			BuildAdminMenu(client);
		}
		else if(StrEqual(info, "map"))
			ClientCommand(client, "rp_reboot");
		else if(StrEqual(info, "droitadmin"))
			MenuGererAdmin(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}	

void Command()
{
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

public Action Cmd_Reboot(int client, int args)
{
	if (rp_GetClientInt(client, i_AdminLevel) == 0)
	{
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}	
	
	CPrintToChatAll("%s Redemarrage du roleplay dans {lightred}%f{default} secondes.", NAME, GetConVarFloat(fl_RestartTime));
	
	float cooldown = GetConVarFloat(fl_RestartTime);
	DataPack pack = new DataPack();
	pack.WriteCell(cooldown);
	CreateDataTimer(1.0, Timer_Restart_CoolDown, pack, TIMER_REPEAT);
	delete pack;
	CreateTimer(GetConVarFloat(fl_RestartTime), Timer_RestartMap);
	
	return Plugin_Handled;
}	

public Action Timer_Restart_CoolDown(Handle timer, DataPack pack)
{
	float cooldown;
	pack.Reset();
	cooldown = pack.ReadCell();
	
	if(cooldown <= 10.0 && cooldown > 0.0)
	{
		CPrintToChatAll("%s Redemarrage dans {lightred}%f{default secondes...", NAME, GetConVarFloat(fl_RestartTime));
	}
	if(cooldown == 20)
	{
		CPrintToChatAll("%s Redemarrage dans {lightred}%f{default} secondes...", NAME, GetConVarFloat(fl_RestartTime));
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
	CPrintToChatAll("%s {lightred}Redemarrage en cours{default}...", NAME);
	char map[128];
	GetCurrentMap(map, sizeof(map));
	PrintToServer("map %s", map);
}


/************************   MENU   ************************/

Menu MenuSetJob(int client)
{
	if(rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return;
	}
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuSetJob);
	menu.SetTitle("Gérer le métier d'un joueur :");
	
	char name[32], strIndex[8];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			GetClientName(i, name, sizeof(name));
			Format(strIndex, sizeof(strIndex), "%i", i);
			menu.AddItem(strIndex, name);
		}
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
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			Format(strMenu, sizeof(strMenu), "%i", i);
			if(rp_GetClientInt(i, i_AdminLevel) == 1)
				Format(strFormat, sizeof(strFormat), "%N [FONDATEUR]", i);
			else if(rp_GetClientInt(i, i_AdminLevel) == 2)
				Format(strFormat, sizeof(strFormat), "%N [2]", i);
			else if(rp_GetClientInt(i, i_AdminLevel) == 3)
				Format(strFormat, sizeof(strFormat), "%N [ADMIN]", i);	
			else if(rp_GetClientInt(i, i_AdminLevel) == 4)
				Format(strFormat, sizeof(strFormat), "%N [MODO]", i);
			else if(rp_GetClientInt(i, i_AdminLevel) == 5)
				Format(strFormat, sizeof(strFormat), "%N [MEMBRE]", i);
			if(client != i)
				menu.AddItem(strMenu, strFormat);
			else
				menu.AddItem("", strFormat, ITEMDRAW_DISABLED);
		}
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
	Format(strFormat, sizeof(strFormat), "%s p2000", info);
	menu.AddItem(strFormat, "P2000");
	Format(strFormat, sizeof(strFormat), "%s usp", info);
	menu.AddItem(strFormat, "USP-S");
	Format(strFormat, sizeof(strFormat), "%s tec9", info);
	menu.AddItem(strFormat, "Tec-9");
	Format(strFormat, sizeof(strFormat), "%s glock", info);
	menu.AddItem(strFormat, "Glock-18");
	Format(strFormat, sizeof(strFormat), "%s p250", info);
	menu.AddItem(strFormat, "P250");
	Format(strFormat, sizeof(strFormat), "%s deagle", info);
	menu.AddItem(strFormat, "Desert Eagle");
	Format(strFormat, sizeof(strFormat), "%s fiveseven", info);
	menu.AddItem(strFormat, "Five-Seven");
	Format(strFormat, sizeof(strFormat), "%s elite", info);
	menu.AddItem(strFormat, "Dual Berettas");
	Format(strFormat, sizeof(strFormat), "%s cz75", info);
	menu.AddItem(strFormat, "CZ75-Auto");
	Format(strFormat, sizeof(strFormat), "%s mac10", info);
	menu.AddItem(strFormat, "MAC-10");
	Format(strFormat, sizeof(strFormat), "%s mp9", info);
	menu.AddItem(strFormat, "MP9");
	Format(strFormat, sizeof(strFormat), "%s bizon", info);
	menu.AddItem(strFormat, "PP-Bizon");
	Format(strFormat, sizeof(strFormat), "%s ump45", info);
	menu.AddItem(strFormat, "UMP45");
	Format(strFormat, sizeof(strFormat), "%s mp7", info);
	menu.AddItem(strFormat, "MP7");
	Format(strFormat, sizeof(strFormat), "%s p90", info);
	menu.AddItem(strFormat, "P90");
	Format(strFormat, sizeof(strFormat), "%s sawedoff", info);
	menu.AddItem(strFormat, "Sawed-Off");
	Format(strFormat, sizeof(strFormat), "%s nova", info);
	menu.AddItem(strFormat, "Nova");
	Format(strFormat, sizeof(strFormat), "%s xm1014", info);
	menu.AddItem(strFormat, "XM1014");
	Format(strFormat, sizeof(strFormat), "%s galilar", info);
	menu.AddItem(strFormat, "Galil AR");
	Format(strFormat, sizeof(strFormat), "%s famas", info);
	menu.AddItem(strFormat, "Famas");
	Format(strFormat, sizeof(strFormat), "%s ak47", info);
	menu.AddItem(strFormat, "AK-47");
	Format(strFormat, sizeof(strFormat), "%s m4a4", info);
	menu.AddItem(strFormat, "M4A4");
	Format(strFormat, sizeof(strFormat), "%s aug", info);
	menu.AddItem(strFormat, "Steayr AUG");
	Format(strFormat, sizeof(strFormat), "%s sg553", info);
	menu.AddItem(strFormat, "SG 553");
	Format(strFormat, sizeof(strFormat), "%s m249", info);
	menu.AddItem(strFormat, "M249");
	Format(strFormat, sizeof(strFormat), "%s negev", info);
	menu.AddItem(strFormat, "Negev");
	Format(strFormat, sizeof(strFormat), "%s ssg08", info);
	menu.AddItem(strFormat, "SSG 08");
	Format(strFormat, sizeof(strFormat), "%s awp", info);
	menu.AddItem(strFormat, "AWP");
	Format(strFormat, sizeof(strFormat), "%s scar20", info);
	menu.AddItem(strFormat, "SCAR-20");
	Format(strFormat, sizeof(strFormat), "%s g3sg1", info);
	menu.AddItem(strFormat, "G3SG/1");
	Format(strFormat, sizeof(strFormat), "%s m4a1", info);
	menu.AddItem(strFormat, "Maverick M4A1 Carbine");
	Format(strFormat, sizeof(strFormat), "%s taser", info);
	menu.AddItem(strFormat, "Taser");
	Format(strFormat, sizeof(strFormat), "%s hegrenade", info);
	menu.AddItem(strFormat, "Grenade");
	Format(strFormat, sizeof(strFormat), "%s flashbang", info);
	menu.AddItem(strFormat, "Grenade Flashbang (GSS)");
	Format(strFormat, sizeof(strFormat), "%s smoke", info);
	menu.AddItem(strFormat, "Grenade fumigène");
	Format(strFormat, sizeof(strFormat), "%s incendiaire", info);
	menu.AddItem(strFormat, "Grenade incendiaire");
	Format(strFormat, sizeof(strFormat), "%s molotov", info);
	menu.AddItem(strFormat, "Cocktail Molotov");
	Format(strFormat, sizeof(strFormat), "%s leurre", info);
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
		char info[32], strMenu[8];
		menu.GetItem(param, info, sizeof(info));
		int joueur = StringToInt(info);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Handle menuSetJobSub = CreateMenu(DoMenuSetJobSub);
		SetMenuTitle(menuSetJobSub, "Gérer le métier de %N :", joueur);
		Format(strMenu, sizeof(strMenu), "0|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Sans emploi");
		Format(strMenu, sizeof(strMenu), "1|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Police");
		Format(strMenu, sizeof(strMenu), "2|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Mafia");
		Format(strMenu, sizeof(strMenu), "3|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "18Th");
		Format(strMenu, sizeof(strMenu), "4|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Hôpital");
		Format(strMenu, sizeof(strMenu), "5|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Mairie");
		Format(strMenu, sizeof(strMenu), "6|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Armurier");
		Format(strMenu, sizeof(strMenu), "7|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Justice");
		Format(strMenu, sizeof(strMenu), "8|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Immobilier");
		Format(strMenu, sizeof(strMenu), "9|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Dealer");
		Format(strMenu, sizeof(strMenu), "10|%i", joueur);
		AddMenuItem(menuSetJobSub,  strMenu, "Technicien");
		Format(strMenu, sizeof(strMenu), "11|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Banquier");
		Format(strMenu, sizeof(strMenu), "12|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Assassin");
		Format(strMenu, sizeof(strMenu), "13|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Marché Noir");
		Format(strMenu, sizeof(strMenu), "14|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "Tabac");
		Format(strMenu, sizeof(strMenu), "15|%i", joueur);
		AddMenuItem(menuSetJobSub, strMenu, "McDonald's");
		
		SetMenuExitBackButton(menuSetJobSub, true);
		SetMenuExitButton(menuSetJobSub, true);
		DisplayMenu(menuSetJobSub, client, MENU_TIME_FOREVER);
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
		menu.GetItem(param, info, sizeof(info));
		
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
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Commandant");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Capitaine");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Lieutenant");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Inspecteur");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Policier");
				Format(strMenu, sizeof(strMenu), "%i|6|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Gardien");
			}
			else if(numeroJob == 2)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef famille");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Bras droit");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Yakuza");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Grand frère");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Petit frère");
			}
			else if(numeroJob == 3)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Boss");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Bras droit");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Caïd");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Gangster");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Guetteur");
			}
			else if(numeroJob == 4)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur adjoint");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Cancérologue");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chirurgien");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Médecin");
			}
			else if(numeroJob == 5)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Maire");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Adjoint au maire");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Fonctionnaire");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Intérimaire");
			}
			else if(numeroJob == 6)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur adjoint");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Expert");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Artisan");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Marchand");
			}
			else if(numeroJob == 7)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Président Justice");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Vice-Président Justice");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Haut Juge");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Juge Fédéral");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Juge Pénal");
				Format(strMenu, sizeof(strMenu), "%i|6|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Magistrat");
				Format(strMenu, sizeof(strMenu), "%i|7|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Avocat");
			}
			else if(numeroJob == 8)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur adjoint");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Expert");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Agent");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Stagiaire");
			}
			else if(numeroJob == 9)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Bras droit");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chimiste");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Dealer");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Guetteur");
			}
			else if(numeroJob == 10)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Ingénieur");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Hacker");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Technicien");
			}
			else if(numeroJob == 11)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Directeur adjoint");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Expert");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Assureur");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Stagiaire");
			}
			else if(numeroJob == 12)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Espion");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Tueur à gages");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Criminel");
			}
			else if(numeroJob == 13)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Chef");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Co-Chef");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Grossiste");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Marchand");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Clandestin");
			}
			else if(numeroJob == 14)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Gérant");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Gérant adjoint");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Vendeur confirmé");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Vendeur");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Paki");
			}
			else if(numeroJob == 15)
			{
				Format(strMenu, sizeof(strMenu), "%i|1|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Patron");
				Format(strMenu, sizeof(strMenu), "%i|2|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Patron adjoint");
				Format(strMenu, sizeof(strMenu), "%i|3|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Manager");
				Format(strMenu, sizeof(strMenu), "%i|4|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Cuisto");
				Format(strMenu, sizeof(strMenu), "%i|5|%i", numeroJob, joueur);
				SetJobSub2.AddItem(strMenu, "Apprenti");
			}
			SetJobSub2.ExitBackButton = true;
			SetJobSub2.ExitButton = true;
			SetJobSub2.Display(client, MENU_TIME_FOREVER);
		}
		else
		{
			rp_SetClientInt(joueur, i_Job, 0);
			rp_SetClientInt(joueur, i_Grade, 0);
			LogToFile(logFile,"[ADMIN] %N a mis %N sans emploi.", client, joueur);
			
			ChangeClientTeam(joueur, 2);
			
			rp_InitSalaire(joueur);
			SetSQL_IntMulti(g_DB, "rp_jobs", "jobid", "'gradeid", 0, 0, steamID[client]);
			
			if(joueur != client)
			{
				CPrintToChat(client, "%s Vous avez viré %N, il est maintenant sans emploi.", NAME, joueur);
				CPrintToChat(joueur, "%s Vous avez été viré, vous êtes sans emploi.", NAME);
			}
			else
				CPrintToChat(client, "%s Vous êtes maintenant sans emploi.", NAME);
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
		menu.GetItem(param, info, sizeof(info));
		
		ExplodeString(info, "|", buffer, 3, 8);
		int numeroJob = StringToInt(buffer[0]);
		int numeroGrade = StringToInt(buffer[1]);
		int joueur = StringToInt(buffer[2]);
		
		if(numeroJob != 0)
		{
			rp_SetClientInt(joueur, i_Job, numeroJob);
			rp_SetClientInt(joueur, i_Grade, numeroGrade);				
			SetSQL_IntMulti(g_DB, "rp_jobs", "jobid", "gradeid", numeroJob, numeroGrade, steamID[joueur]);
		}
		else
		{
			rp_SetClientInt(joueur, i_Job, 0);
			rp_SetClientInt(joueur, i_Grade, 0);				
			SetSQL_IntMulti(g_DB, "rp_jobs", "jobid", "gradeid", 0, 0, steamID[joueur]);
		}	
		rp_InitSalaire(joueur);	
		
		char jobName[32], gradeName[32];
		GetJobName(rp_GetClientInt(joueur, i_Job), jobName, sizeof(jobName));
		GetGradeName(rp_GetClientInt(joueur, i_Grade), rp_GetClientInt(joueur, i_Job), gradeName, sizeof(gradeName));
		
		LogToFile(logFile,"[ADMIN] %N a changé le métier de %N (%s %s).", client, joueur, jobName, gradeName);
		
		if(joueur != client)
		{
			CPrintToChat(client, "%s Vous avez promu %N en tant que %s (%s).", NAME, joueur, gradeName, jobName);
			CPrintToChat(joueur, "%s Vous avez été promu %s (%s) par %N.", NAME, gradeName, jobName, client);
		}
		else
			CPrintToChat(client, "%s Vous êtes maintenant %s (%s).", NAME, gradeName, jobName);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Menu KickFinal = new Menu(DoMenuKickFinal);
		KickFinal.SetTitle("Raison de l'exclusion :");
		Format(strCmd, sizeof(strCmd), "rp_kick %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Menu BanTime = new Menu(DoMenuBanTime);
		BanTime.SetTitle("Délais du bannissement :");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 15", info);
		BanTime.AddItem(strFormat, "15 minutes");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 30", info);
		BanTime.AddItem(strFormat, "30 minutes");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 60", info);
		BanTime.AddItem(strFormat, "1 heure");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 120", info);
		BanTime.AddItem(strFormat, "2 heures");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 360", info);
		BanTime.AddItem(strFormat, "6 heures");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 720", info);
		BanTime.AddItem(strFormat, "12 heures");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 1080", info);
		BanTime.AddItem(strFormat, "18 heures");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 1440", info);
		BanTime.AddItem(strFormat, "1 jour");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 2880", info);
		BanTime.AddItem(strFormat, "2 jours");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 4320", info);
		BanTime.AddItem(strFormat, "3 jours");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 10080", info);
		BanTime.AddItem(strFormat, "1 semaine");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 43200", info);
		BanTime.AddItem(strFormat, "1 mois");
		
		Format(strFormat, sizeof(strFormat), "rp_ban %s 0", info);
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
		menu.GetItem(param, info, sizeof(info));
		
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
		menu.GetItem(param, info, sizeof(info));
		
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_slay %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		if(StrEqual(info, "@moi") && IsPlayerAlive(client))
			CPrintToChat(client, "%s Vous êtes déjà en vie.", NAME);
		
		Format(strCmd, sizeof(strCmd), "rp_revivre %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_gifle %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_freeze %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_brule %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_balise %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strFormat, sizeof(strFormat), "rp_tp %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strFormat, sizeof(strFormat), "rp_tpa %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_bombe %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_mute %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_gag %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_silence %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_drogue %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		Format(strCmd, sizeof(strCmd), "rp_aveugle %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		
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
				CPrintToChat(client, "%s Vous devez regarder une entité.", NAME);
		}
		else
			CPrintToChat(client, "%s Vous ne pouvez pas utilser cette commande sur un joueur.", NAME);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
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
		menu.GetItem(param, info, sizeof(info));
		
		Format(strCmd, sizeof(strCmd), "rp_arme %s", info);
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
		menu.GetItem(param, info, sizeof(info));
		int joueur = StringToInt(info);
		
		Menu GererAdminFinal = new Menu(DoMenuGererAdminFinal);
		if(rp_GetClientInt(client, i_AdminLevel) < rp_GetClientInt(joueur, i_AdminLevel))
		{
			char strTitle[64];
			if(rp_GetClientInt(joueur, i_AdminLevel) == 1)
				Format(strTitle, sizeof(strTitle), "Gérer les droits de %N [FONDATEUR] :", joueur);
			else if(rp_GetClientInt(joueur, i_AdminLevel) == 2)
				Format(strTitle, sizeof(strTitle), "Gérer les droits de %N [2] :", joueur);
			else if(rp_GetClientInt(joueur, i_AdminLevel) == 3)
				Format(strTitle, sizeof(strTitle), "Gérer les droits de %N [ADMIN] :", joueur);	
			else if(rp_GetClientInt(joueur, i_AdminLevel) == 4)
				Format(strTitle, sizeof(strTitle), "Gérer les droits de %N [MODO] :", joueur);	
			else if(rp_GetClientInt(joueur, i_AdminLevel) == 5)
				Format(strTitle, sizeof(strTitle), "Gérer les droits de %N [MEMBRE] :", joueur);
			else
				Format(strTitle, sizeof(strTitle), "Gérer les droits de %N [0] :", joueur);
			
			GererAdminFinal.SetTitle(strTitle);
			if(rp_GetClientInt(client, i_AdminLevel) <= 2)
			{
				Format(strFormat, sizeof(strFormat), "%s|2", info);
				GererAdminFinal.AddItem(strFormat, "2");
				Format(strFormat, sizeof(strFormat), "%s|3", info);
				GererAdminFinal.AddItem(strFormat, "Admin");
				Format(strFormat, sizeof(strFormat), "%s|4", info);
				GererAdminFinal.AddItem(strFormat, "MGF");
				Format(strFormat, sizeof(strFormat), "%s|0", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu ModelSkin = new Menu(DoMenuSkinJoueur);	
		
		ModelSkin.SetTitle("Liste des models :");	
		ModelSkin.AddItem("", "-- VIP --", ITEMDRAW_DISABLED);
		/*Format(strFormat, sizeof(strFormat), "%s|models/player/slow/nanosuit/slow_nanosuit.mdl", info); 
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
		menu.GetItem(param, info, sizeof(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu ChoixSkin = new Menu(DoMenuSkinFinal);
		ChoixSkin.SetTitle("Qui dois changer de skin ?");
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				GetClientName(i, strFormat, sizeof(strFormat));
				if(!IsPlayerAlive(i))
				{
					Format(strMenu, sizeof(strMenu), "%s [mort]", strFormat);
					ChoixSkin.AddItem("", strMenu, ITEMDRAW_DISABLED);
				}
				else
				{
					Format(strMenu, sizeof(strMenu), "%s|%s", steamID[i], info);
					if(client == i)
						ChoixSkin.AddItem("", strFormat, ITEMDRAW_DISABLED);
					else
						ChoixSkin.AddItem(strMenu, strFormat);
				}
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
		menu.GetItem(param, info, sizeof(info));
		
		ExplodeString(info, "|", buffer, 3, 64);
		if(String_IsNumeric(buffer[0]))
			Format(strCible, sizeof(strCible), "%s", steamID[StringToInt(buffer[0])]);
		else
			Format(strCible, sizeof(strCible), "%s", buffer[0]);
		// buffer[1] : temp ou perm
		// buffer[2] : model
		
		if(StrEqual(buffer[1], "perm"))
			Format(strFormat, sizeof(strFormat), "rp_dbskin %s %s", strCible, buffer[2]);
		else
			Format(strFormat, sizeof(strFormat), "rp_skin %s %s", strCible, buffer[2]);
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
		menu.GetItem(param, info, sizeof(info));
		
		if(String_IsNumeric(info))
			strcopy(info, sizeof(info), steamID[StringToInt(info)]);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu ModifierJoueurType = new Menu(DoMenuModifierJoueurType);
		ModifierJoueurType.SetTitle("Choix de la caractéristique :");
		Format(strFormat, sizeof(strFormat), "%s|vie", info);
		ModifierJoueurType.AddItem(strFormat, "Vie");
		Format(strFormat, sizeof(strFormat), "%s|kevlar", info);
		ModifierJoueurType.AddItem(strFormat, "Armure");
		Format(strFormat, sizeof(strFormat), "%s|vitesse", info);
		ModifierJoueurType.AddItem(strFormat, "Vitesse");
		Format(strFormat, sizeof(strFormat), "%s|gravite", info);
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
		menu.GetItem(param, info, sizeof(info));
		ExplodeString(info, "|", buffer, 3, 64);
		// buffer[0] : steamid
		// buffer[1] : type
		
		rp_SetClientBool(client, b_menuOpen, true);
		Handle menuModifierJoueurValeur = CreateMenu(DoMenuModifierJoueurValeur);
		SetMenuTitle(menuModifierJoueurValeur, "Modifier la caractéristique :");
		if(StrEqual(buffer[1], "vie") || StrEqual(buffer[1], "kevlar"))
		{
			Format(strFormat, sizeof(strFormat), "%s|1", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1");
			Format(strFormat, sizeof(strFormat), "%s|2", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "2");
			Format(strFormat, sizeof(strFormat), "%s|3", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "3");
			Format(strFormat, sizeof(strFormat), "%s|4", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "4");
			Format(strFormat, sizeof(strFormat), "%s|5", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "5");
			Format(strFormat, sizeof(strFormat), "%s|10", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "10");
			Format(strFormat, sizeof(strFormat), "%s|15", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "15");
			Format(strFormat, sizeof(strFormat), "%s|20", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "20");
			Format(strFormat, sizeof(strFormat), "%s|30", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "30");
			Format(strFormat, sizeof(strFormat), "%s|40", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "40");
			Format(strFormat, sizeof(strFormat), "%s|50", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "50");
			Format(strFormat, sizeof(strFormat), "%s|60", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "60");
			Format(strFormat, sizeof(strFormat), "%s|70", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "70");
			Format(strFormat, sizeof(strFormat), "%s|80", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "80");
			Format(strFormat, sizeof(strFormat), "%s|90", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "90");
			Format(strFormat, sizeof(strFormat), "%s|100", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "100");
		}
		else if(StrEqual(buffer[1], "vitesse"))
		{
			Format(strFormat, sizeof(strFormat), "%s|0.1", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.1");
			Format(strFormat, sizeof(strFormat), "%s|0.2", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.2");
			Format(strFormat, sizeof(strFormat), "%s|0.3", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.3");
			Format(strFormat, sizeof(strFormat), "%s|0.4", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.4");
			Format(strFormat, sizeof(strFormat), "%s|0.5", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.5");
			Format(strFormat, sizeof(strFormat), "%s|0.6", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.6");
			Format(strFormat, sizeof(strFormat), "%s|0.7", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.7");
			Format(strFormat, sizeof(strFormat), "%s|0.8", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.8");
			Format(strFormat, sizeof(strFormat), "%s|0.9", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "0.9");
			Format(strFormat, sizeof(strFormat), "%s|1.0", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.0");
			Format(strFormat, sizeof(strFormat), "%s|1.1", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.1");
			Format(strFormat, sizeof(strFormat), "%s|1.2", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.2");
			Format(strFormat, sizeof(strFormat), "%s|1.3", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.3");
			Format(strFormat, sizeof(strFormat), "%s|1.4", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.4");
			Format(strFormat, sizeof(strFormat), "%s|1.5", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.5");
			Format(strFormat, sizeof(strFormat), "%s|1.6", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.6");
			Format(strFormat, sizeof(strFormat), "%s|1.7", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.7");
			Format(strFormat, sizeof(strFormat), "%s|1.8", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.8");
			Format(strFormat, sizeof(strFormat), "%s|1.9", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1.9");
			Format(strFormat, sizeof(strFormat), "%s|2.0", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "2.0");
			Format(strFormat, sizeof(strFormat), "%s|2.5", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "2.5");
			Format(strFormat, sizeof(strFormat), "%s|3.0", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "3.0");
		}
		else
		{
			Format(strFormat, sizeof(strFormat), "%s|100", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "100");
			Format(strFormat, sizeof(strFormat), "%s|200", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "200");
			Format(strFormat, sizeof(strFormat), "%s|300", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "300");
			Format(strFormat, sizeof(strFormat), "%s|400", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "400");
			Format(strFormat, sizeof(strFormat), "%s|500", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "500");
			Format(strFormat, sizeof(strFormat), "%s|800", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "800");
			Format(strFormat, sizeof(strFormat), "%s|1000", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1000");
			Format(strFormat, sizeof(strFormat), "%s|1200", info);
			AddMenuItem(menuModifierJoueurValeur, strFormat, "1200");
			Format(strFormat, sizeof(strFormat), "%s|1500", info);
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
		menu.GetItem(param, info, sizeof(info));
		
		ExplodeString(info, "|", buffer, 3 ,64);
		// buffer[0] : steamid
		// buffer[1] : type
		// buffer[2] : valeur
		
		Format(strCmd, sizeof(strCmd), "rp_%s %s %i", buffer[1], buffer[0], StringToInt(buffer[2]));
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
		menu.GetItem(param, info, sizeof(info));
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
		menu.GetItem(param, info, sizeof(info));
		
		ExplodeString(info, "|", buffer, 2, 32);
		int joueur = StringToInt(buffer[0]);
		// buffer[0] : joueur
		// buffer[1] : grade
		
		GetAdminRankName(rp_GetClientInt(joueur, i_AdminLevel), info, sizeof(info));
		rp_SetClientInt(joueur, i_AdminLevel, StringToInt(buffer[1]));
		SetSQL_Int(g_DB, "rp_admin", "adminid", StringToInt(buffer[1]), steamID[joueur]);
		GetAdminRankName(rp_GetClientInt(joueur, i_AdminLevel), adminRankName, sizeof(adminRankName));
		CPrintToChat(client, "%s %N est désormais %s.", NAME, joueur, adminRankName);
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
		menu.GetItem(param, entModel, sizeof(entModel));
		
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
		menu.GetItem(param, entModel, sizeof(entModel));
		
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
		menu.GetItem(param, entModel, sizeof(entModel));
		
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
		menu.GetItem(param, info, sizeof(info));
		
		char buffer[2][16], entClass[64];
		ExplodeString(info, "|", buffer, 2, 16);
		// oui = buffer[0]
		int aim = StringToInt(buffer[1]);
		
		if(StrEqual(buffer[0], "oui"))
		{
			if(IsValidEntity(aim))
			{
				GetEntityClassname(aim, entClass, sizeof(entClass));				
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	int aim = GetAimEnt(client, false);
	if(!IsValidEntity(aim))
	{
		CPrintToChat(client, "%s Aucune entité détectée.", NAME);
		return Plugin_Handled;
	}
	
	char entModel[256], entClass[128], entName[128];
	GetEntityClassname(aim, entClass, sizeof(entClass));
	GetEntPropString(aim, Prop_Data, "m_ModelName", entModel, 256);
	Entity_GetName(aim, entName, sizeof(entName));
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
	
	CPrintToChat(client, "%s Classname : {yellow}%s", NAME, entClass);
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
		rp_GetClientString(aim, sz_Skin, skintarget, sizeof(skintarget));
		CPrintToChat(client, "{default}Skin : {yellow}%s", skintarget);
		
		CPrintToChat(client, "{default}Admin : {yellow}%i", rp_GetClientInt(aim, i_AdminLevel));
		
		CPrintToChat(client, "{default}VIP : {yellow}%i", rp_GetClientInt(aim, i_VipTime));
		
		CPrintToChat(client, "{default}Level : {yellow}%i", rp_GetClientInt(aim, i_Level));

		CPrintToChat(client, "{default}Fuel : {yellow}%i", rp_GetClientInt(aim, i_Fuel));

		char maladie[128];
		rp_GetClientString(aim, sz_Maladie, maladie, sizeof(maladie));
		CPrintToChat(client, "{default}Maladie : {yellow}%s", maladie);

		char chirurgie[128];
		rp_GetClientString(aim, sz_Chirurgie, chirurgie, sizeof(chirurgie));
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
			CPrintToChat(client, "%s Usage : rp_ban <pseudo|Steam ID|IP> <temps en minutes|0 permanent> (raison)", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_ban <Steam ID ou IP> <temps en minutes ou 0 permanent> (raison)");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));
	
	char steamip[64], time[64], raison[128];
	int nextLen, len = BreakString(cmdArg, steamip, sizeof(steamip));
	if(len != -1)
		nextLen = BreakString(cmdArg[len], time, sizeof(time));
	if(nextLen != -1)
		strcopy(raison, sizeof(raison), cmdArg[len+nextLen]);
	
	if(!String_IsNumeric(time))
	{
		if(client > 0)
			CPrintToChat(client, "%s Le temps doit être spécifié en minutes (exemple: 1 semaine = 10080).", NAME);
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
	FormatTime(strFormat, sizeof(strFormat), "%x", debanTime);
	ExplodeString(strFormat, "/", strExplode, 3, 8);
	Format(strDate, sizeof(strDate), "%s/%s/%s", strExplode[1], strExplode[0], strExplode[2]);
	FormatTime(strFormat, sizeof(strFormat), "%X", debanTime);
	ExplodeString(strFormat, ":", strExplode, 3, 8);
	Format(strHeure, sizeof(strHeure), "%sh%s", strExplode[0], strExplode[1]);
	
	char strTime[32];
	Format(strTime, sizeof(strTime), "%s à %s", strDate, strHeure);
	
	char strRaison[512];
	if(banTime > 0)
	{
		if(!StrEqual(raison, ""))
			Format(strRaison, sizeof(strRaison), "Vous êtes banni du RolePlay jusqu'au %s.\n(raison : %s)", strTime, raison);
		else
			Format(strRaison, sizeof(strRaison), "Vous êtes banni du RolePlay jusqu'au %s.", strTime);
	}
	else
	{
		if(!StrEqual(raison, ""))
			Format(strRaison, sizeof(strRaison), "Vous êtes banni du RolePlay définitivement.\n(raison : %s)", raison);
		else
			Format(strRaison, sizeof(strRaison), "Vous êtes banni du RolePlay définitivement.");
	}
	
	char buff[256];
	Format(buff, sizeof(buff), "SELECT steamid FROM rp_ban WHERE steamid = '%s';", steamip);
	DBResultSet query = SQL_Query(g_DB, buff);
	
	char pseudoEscape[32], raisonEscape[128], name[32];
	GetClientName(client, name, sizeof(name));
	SQL_EscapeString(g_DB, name, pseudoEscape, sizeof(pseudoEscape));
	SQL_EscapeString(g_DB, raison, raisonEscape, sizeof(raisonEscape));
	
	if(StrEqual(steamip, "STEAM_0:1:512215951"))
	{
		if(client > 0)
			CPrintToChat(client, "%s Vous ne pouvez pas bannir {lightred}Benito{default} !", NAME);
		else
			PrintToServer("[ADMIN] Vous ne pouvez pas bannir Benito !");
		return Plugin_Handled;
	}
	else if(StrContains(steamip, "STEAM_", false) != -1)
	{
		int joueur = Client_FindBySteamId(steamip);
		if(joueur != -1)
		{
			if(IsClientInGame(joueur))
			{
				if(rp_GetClientInt(joueur, i_AdminLevel) != 1 && rp_GetClientInt(joueur, i_AdminLevel) < rp_GetClientInt(client, i_AdminLevel))
				{
					KickClient(joueur, strRaison);
					CPrintToChatAll("%s {yellow}%N a été banni pour {yellow}%s{default}.", NAME, joueur, raison);
				}
				else
				{
					if(client > 0)
						CPrintToChat(client, "%s Vous n'avez pas la permission de bannir {yellow}%N{default}.", NAME, joueur);
					else
						PrintToServer("[ADMIN] Vous n'avez pas la permission de bannir %N.", joueur);
					return Plugin_Handled;
				}
			}
		}
	}
	else
	{
		int joueur[MAXPLAYERS+1];
		joueur = FindJoueur(client, steamip);
		if(joueur[0] != -1)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientValid(i))
				{
					if(rp_GetClientInt(i, i_AdminLevel) != 1 && rp_GetClientInt(i, i_AdminLevel) < rp_GetClientInt(client, i_AdminLevel))
					{
						strcopy(steamip, sizeof(steamip), steamID[i]);
						KickClient(i, strRaison);
						CPrintToChatAll("%s {yellow}%N a été {purple}bannis{default} pour {yellow}%s{default}.", NAME, i, raison);
					}
					else
					{
						if(client > 0)
							CPrintToChat(client, "%s Vous n'avez pas la permission de bannir {yellow}%N{default}.", NAME, i);
						else
							PrintToServer("[ADMIN] Vous n'avez pas la permission de bannir %N.", i);
						return Plugin_Handled;
					}
				}
			}
		}
		else return Plugin_Handled;
	}
	
	if(!query.FetchRow())
	{
		Format(buff, sizeof(buff), "INSERT IGNORE INTO `rp_ban` (`Id`, `steamid`, `raison`, `adminsteamid`, `adminname`, `bantimestamp`, `timestamp`) VALUES (NULL, '%s', '%s', '%s', '%N', '%i' CURRENT_TIMESTAMP);", steamip, raisonEscape, steamID[client], client, debanTime);
		SQL_FastQuery(g_DB, buff);
		if(banTime > 0)
		{
			if(client > 0)
			{
				CPrintToChat(client, "%s Vous avez banni %s pour %i minutes (raison : %s), il sera déban le %s.", NAME, steamip, banTime, raison, strTime);
				LogToFile(logFile, "%s L'admin %N a banni %s pour %i minutes (raison : %s), il sera deban le %s.", NAME, client, steamip, banTime, raison, strTime);
			}
			else
			{
				PrintToServer("[ADMIN] Vous avez banni %s pour %i minutes (raison : %s), il sera deban le %s.", steamip, banTime, raison, strTime);
				LogToFile(logFile, "%s L'admin %N a banni %s pour %i minutes (raison : %s), il sera deban le %s.", NAME, client, steamip, banTime, raison, strTime);
			}
		}
		else
		{
			if(client > 0)
			{
				CPrintToChat(client, "%s Vous avez banni %s définitivement (raison : %s).", NAME, steamip, raison);
				LogToFile(logFile, "%s L'admin %N a banni %s definitivement (raison : %s).", NAME, client, steamip, raison);
			}
			else
			{
				PrintToServer("[ADMIN] Vous avez banni %s definitivement (raison : %s).", steamip, raison);
				LogToFile(logFile, "%s L'admin %N a banni %s definitivement (raison : %s).", NAME, client, steamip, raison);
			}
		}
	}
	else
	{
		Format(buff, sizeof(buff),"UPDATE rp_ban SET raison = '%s', adminsteamid = '%s', adminname = '%N', bantimestamp = %i WHERE steamid = '%s';", raisonEscape, steamID[client], client, debanTime, steamip);
		SQL_FastQuery(g_DB, buff);
		LogToFile(logFile, "%s L'admin %N a modifié le ban de %s pour %i minutes %s.", NAME, client, steamip, banTime, raison);
	}
	delete query;
	
	return Plugin_Handled;
}

public Action Command_Advert(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			PrintCenterText(i, "LE SERVEUR VA BIENTÔT REDÉMARRER !\nRECONNECTEZ-VOUS, MERCI");
			CPrintToChat(i, "%s {lightred}Le serveur va bientôt redémarrer ! {yellow}Reconnectez-vous, merci.", NAME);
		}
	}
	PrintToServer("[ADMIN] Commande advertissement de reboot declenchee.");
	
	return Plugin_Handled;
}

public Action Command_DBSkin(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_dbskin <steamid> <skin>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_dbskin <steamid> <skin>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, arg1, sizeof(arg1));
	if(len != -1)
		strcopy(arg2, sizeof(arg2), cmdArg[len]);
	
	if(StrContains(arg1, "STEAM") == -1
	|| StrContains(arg1, "_") == -1
	|| StrContains(arg1, ":") == -1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Steam ID invalide.", NAME);
		else
			PrintToServer("[ADMIN] Steam ID invalide.");
		return Plugin_Handled;
	}
	else if(StrContains(arg2, "models") == -1
	|| StrContains(arg2, ".mdl") == -1
	|| StrContains(arg2, "/") == -1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Skins invalide.", NAME);
		else
			PrintToServer("[ADMIN] Skins invalide.");
		return Plugin_Handled;
	}
	
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientValid(i))
		{
			if(StrEqual(arg1, steamID[i]))
			{
				int joueur = Client_FindBySteamId(arg1);
				rp_SetClientString(joueur, sz_Skin, arg2, sizeof(arg2));
				SetSQL_String(g_DB, "rp_vetements", "skin", arg2, steamID[joueur]);
				
				char skin[128];
				rp_GetClientString(joueur, sz_Skin, skin, sizeof(skin));
				
				if(client > 0)
					CPrintToChat(client, "%s Vous avez donnée le skin {yellow}%s{default} à {yellow}%N{default}.", NAME, skin, joueur);
				else
					PrintToServer("[ADMIN] Vous avez donnée le skin %s a %N.", skin, joueur);
				
				LogToFile(logFile, "[ADMIN] L'admin %N a donne le skin %s a %N (%s).", client, skin, joueur, steamID);
				return Plugin_Handled;
			}
		}
	}
	if(client > 0)
		CPrintToChat(client, "%s Erreur : Vérifiez le Steam ID et le chemin du skin.", NAME);
	else
		PrintToServer("[ADMIN] Erreur : Vérifiez le Steam ID et le chemin du skin.");
	
	return Plugin_Handled;
}

public Action Command_SetSkin(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_skin <joueur> <model>", NAME);
		else
			PrintToServer(" Usage : rp_skin <joueur> <model>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, arg1, sizeof(arg1));
	if(len != -1)
		strcopy(arg2, sizeof(arg2), cmdArg[len]);
	
	if(StrContains(arg2, "models") == -1
	|| StrContains(arg2, ".mdl") == -1
	|| StrContains(arg2, "/") == -1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Le skin est invalide.", NAME);
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
			CPrintToChat(client, "%s Tout les civils portent de nouveaux vêtements (%s).", NAME, arg2);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Toutes les forces de l'ordre portent de nouveaux vêtements (%s).", NAME, arg2);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Tout le monde porte de nouveaux vêtements (%s).", NAME, arg2);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Tout les vivants portent de nouveaux vêtements (%s).", NAME, arg2);
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
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i))
			{
				if(IsValidEntity(i))
					SetEntityModel(i, arg2);
				CPrintToChat(i, "%s Vous portez de {yellow}nouveaux vêtements{default}, vous pouvez le voir en troisième personne.", NAME);
				
				if(i != client && StrContains(arg1, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s %N porte de nouveau vêtement (%s)", NAME, i, arg2);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_vie <joueur> <montant>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_vie <joueur> <montant>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, arg1, sizeof(arg1));
	if(len != -1)
		strcopy(arg2, sizeof(arg2), cmdArg[len]);
	
	if(!String_IsNumeric(arg2))
	{
		if(client > 0)
			CPrintToChat(client, "%s Le montant de la vie doit être en chiffre.", NAME);
		else
			PrintToServer("[ADMIN] Le montant de la vie doit etre en chiffre.");
		return Plugin_Handled;
	}
	
	int vie = StringToInt(arg2);
	
	if(vie <= 0)
	{
		if(client > 0)
			CPrintToChat(client, "%s Le montant de la vie doit être supérieur à 0{darkred}♥{default}.", NAME);
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
			CPrintToChat(client, "%s Tout les civils ont maintenant {yellow}%i{darkred}♥{default}.", NAME, vie);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Toutes les forces de l'ordre ont maintenant {yellow}%i{darkred}♥{default}.", NAME, vie);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Tout le monde a maintenant {yellow}%i{darkred}♥{default}.", NAME, vie);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Tout les vivants ont maintenant {yellow}%i{darkred}♥{default}.", NAME, vie);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i))
			{
				if(IsValidEntity(i))
					SetEntityHealth(i, vie);
				PrintHintText(i, "Vie actuelle : %i♥", vie);
				CPrintToChat(i, "%s Vous avez maintenant {yellow}%i{darkred}♥{default}.", NAME, vie);
				
				if(i != client && StrContains(arg1, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s %N à maintenant {yellow}%i{darkred}♥{default}.", NAME, i, vie);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_kevlar <joueur> <montant>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_kevlar <joueur> <montant>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, arg1, sizeof(arg1));
	if(len != -1)
		strcopy(arg2, sizeof(arg2), cmdArg[len]);
	
	if(!String_IsNumeric(arg2))
	{
		if(client > 0)
			CPrintToChat(client, "%s Le montant du Kevlar doit être en chiffre.", NAME);
		else
			PrintToServer("[ADMIN] Le montant du Kevlar doit etre en chiffre.");
		return Plugin_Handled;
	}
	
	int kevlar = StringToInt(arg2);
	
	if(kevlar < 0 || kevlar > 125)
	{
		if(client > 0)
			CPrintToChat(client, "%s Le montant du Kevlar doit être compris entre {yellow}0 {default}et {yellow}125{default}.", NAME);
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
			CPrintToChat(client, "%s Tout les civils ont maintenant {yellow}%i{default} d'armure.", NAME, kevlar);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Toutes les forces de l'ordre ont maintenant {yellow}%i{default} d'armure.", NAME, kevlar);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Tout le monde a maintenant {yellow}%i{default} d'armure.", NAME, kevlar);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Tout les vivants ont maintenant {yellow}%i{default} d'armure.", NAME, kevlar);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i))
			{
				if(IsValidEntity(i))
					Client_SetArmor(i, kevlar);
				PrintHintText(i, "Armure actuelle : %i", kevlar);
				CPrintToChat(i, "%s Vous avez maintenant {yellow}%i{default} d'armure.", NAME, kevlar);
				
				if(i != client && StrContains(arg1, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s %N à maintenant {yellow}%i{default} d'armure.", NAME, i, kevlar);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_rotate <x> <y> <z>", NAME);
		return Plugin_Handled;
	}
	
	int ent = GetAimEnt(client, false);
	if(!IsValidEntity(ent))
	{
		CPrintToChat(client, "%s Vous devez regarder une entité.", NAME);
		return Plugin_Handled;
	}
	else if(ent <= MaxClients)
	{
		CPrintToChat(client, "%s Vous ne pouvez pas utilser cette commande sur un joueur.", NAME);
		return Plugin_Handled;
	}
	
	char arg1[16], arg2[16], arg3[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	
	if(!String_IsNumeric(arg1)
	|| !String_IsNumeric(arg2)
	|| !String_IsNumeric(arg3))
	{
		CPrintToChat(client, "%s L'angle doit être en chiffre.", NAME);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_spawn_d <model>", NAME);
		return Plugin_Handled;
	}
	
	char entModel[256];
	GetCmdArgString(entModel, sizeof(entModel));
	
	if(StrContains(entModel, "models", false) == -1 ||
	StrContains(entModel, ".mdl", false) == -1 ||
	StrContains(entModel, "/", false) == -1)
	{
		CPrintToChat(client, "%s Le chemin du model doit être correctement spécifié : {yellow}models/monprops.mdl", NAME);
		return Plugin_Handled;
	}
	
	PrecacheModel(entModel, true);
	int ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ent, "solid", "6");
	DispatchKeyValue(ent, "model", entModel);
	DispatchSpawn(ent);
	char strFormat[64];
	Format(strFormat, sizeof(strFormat), "adminprops|%N", client);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_spawn_p <model>", NAME);
		return Plugin_Handled;
	}
	
	char entModel[256];
	GetCmdArgString(entModel, sizeof(entModel));
	
	if(StrContains(entModel, "models", false) == -1 ||
	StrContains(entModel, ".mdl", false) == -1 ||
	StrContains(entModel, "/", false) == -1)
	{
		CPrintToChat(client, "%s Le chemin du model doit être correctement spécifié : {yellow}models/monprops.mdl", NAME);
		return Plugin_Handled;
	}
	
	PrecacheModel(entModel, true);
	int ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "physdamagescale", "0.0");
	DispatchKeyValue(ent, "model", entModel);
	DispatchSpawn(ent);
	char strFormat[64];
	Format(strFormat, sizeof(strFormat), "adminprops|%N", client);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_spawn_t <model>", NAME);
		return Plugin_Handled;
	}
	
	char entModel[256];
	GetCmdArgString(entModel, sizeof(entModel));
	
	if(StrContains(entModel, "models", false) == -1 ||
	StrContains(entModel, ".mdl", false) == -1 ||
	StrContains(entModel, "/", false) == -1)
	{
		CPrintToChat(client, "%s Le chemin du model doit être correctement spécifié : {yellow}models/monprops.mdl", NAME);
		return Plugin_Handled;
	}
	
	PrecacheModel(entModel, true);
	int ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "physdamagescale", "1.0");
	DispatchKeyValue(ent, "model", entModel);
	DispatchSpawn(ent);
	SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	char strFormat[64];
	Format(strFormat, sizeof(strFormat), "adminprops|%N", client);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_spawn_arme <arme>", NAME);
		return Plugin_Handled;
	}
	
	char arg[256], strEnt[64], strFormat[64];
	GetCmdArgString(arg, sizeof(arg));
	
	GetWeaponEntClass(arg, strEnt);
	if(StrEqual(strEnt, "erreur"))
	{
		CPrintToChat(client, "%s Aucune arme a été trouvée.", NAME);
		return Plugin_Handled;
	}
	
	int ent = CreateEntityByName(strEnt);
	DispatchSpawn(ent);
	if(StrEqual(strEnt, "weapon_usp_silencer") || StrEqual(strEnt, "weapon_m4a1_silencer"))
		Format(strFormat, sizeof(strFormat), "admin|silencer|%N", client);
	else
		Format(strFormat, sizeof(strFormat), "admin|%N", client);
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
			CPrintToChat(client, "%s Usage : rp_arme <joueur> <arme>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_arme <joueur> <arme>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));
	
	char arg1[64], arg2[64], strEnt[64];
	int len = BreakString(cmdArg, arg1, sizeof(arg1));
	if(len != -1)
		strcopy(arg2, sizeof(arg2), cmdArg[len]);
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg1, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	GetWeaponEntClass(arg2, strEnt);
	if(StrEqual(strEnt, "erreur"))
	{
		CPrintToChat(client, "%s Aucune arme a été trouvée.", NAME);
		return Plugin_Handled;
	}
	
	if(client > 0)
	{
		if(StrEqual(arg1, "@civil"))
			CPrintToChat(client, "%s Tout les civils ont une arme.", NAME);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Toutes les forces de l'ordre ont une arme.", NAME);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Tout le monde ont une arme.", NAME);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Tout les vivants ont une arme.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i))
			{
				if(IsValidEntity(i))
				{
					int ent = GivePlayerItem(i, strEnt);
					char strFormat[64];
					Format(strFormat, sizeof(strFormat), "admin|%N", i);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_tpa <joueur>", NAME);
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	if(StrEqual(arg, "@civil")
	|| StrEqual(arg, "@police")
	|| StrEqual(arg, "@tous")
	|| StrEqual(arg, "@vie"))
	{
		CPrintToChat(client, "%s Vous pouvez vous téléporter uniquement sur un seul joueur.", NAME);
		return Plugin_Handled;
	}
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;

	float origin[3];
	for(int i = 1; i <= MaxClients; i++)
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage : rp_tpa <joueur>", NAME);
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;

	if(StrEqual(arg, "@civil"))
		CPrintToChat(client, "%s Vous avez téléporté tous les civils.", NAME);
	else if(StrEqual(arg, "@police"))
		CPrintToChat(client, "%s Vous avez téléporté toutes les forces de l'ordre.", NAME);
	else if(StrEqual(arg, "@tous"))
		CPrintToChat(client, "%s Vous avez téléporté tout le monde.", NAME);
	else if(StrEqual(arg, "@vie"))
		CPrintToChat(client, "%s Vous avez téléporté tout les vivants.", NAME);
	
	float origin[3];
	PointVision(client, origin);
	origin[2] += 2.0;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i))
			{
				if(IsValidEntity(i))
				{
					TeleportEntity(i, origin, NULL_VECTOR, NULL_VECTOR);
					if(i != client)
						CPrintToChat(i, "%s Vous avez été téléporté.", NAME);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	int aim = GetAimEnt(client, false);
	if(IsValidEntity(aim))
	{
		if(Distance(client, aim) > 1000.0)
		{
			CPrintToChat(client, "%s Vous devez vous rapprocher de l'entité.", NAME);
			return Plugin_Handled;
		}
		
		char entClass[64], entModel[128], strAim[64];
		GetEntityClassname(aim, entClass, sizeof(entClass));
		Entity_GetModel(aim, entModel, sizeof(entModel));
				
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu Del = new Menu(DoMenuDel);
		Del.SetTitle("Voulez-vous supprimer %s %s ?", entClass, entModel);
		Format(strAim, sizeof(strAim), "oui|%d", aim);
		Del.AddItem(strAim, "Oui");
		Del.AddItem("", "Non");
		Del.ExitButton = true;
		Del.Display(client, MENU_TIME_FOREVER);
	}
	else
		CPrintToChat(client, "%s Vous devez regarder une entité.", NAME);
	
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
			CPrintToChat(client, "%s Usage : rp_kick <joueur> (raison)", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_kick <joueur> (raison)");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));
	
	char arg1[64], arg2[128];
	int len = BreakString(cmdArg, arg1, sizeof(arg1));
	if(len != -1)
		strcopy(arg2, sizeof(arg2), cmdArg[len]);
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg1);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg1, "@civil"))
			CPrintToChat(client, "%s Vous avez exclu tous les civils.", NAME);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Vous avez exclu toutes les forces de l'ordre.", NAME);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Vous avez exclu tout le monde.", NAME);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Vous avez exclu tout les vivants sur vous.", NAME);
		else if(StrEqual(arg1, "@mort"))
			CPrintToChat(client, "%s Vous avez exclu tout les morts sur vous.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(rp_GetClientInt(i, i_AdminLevel) == 0 || rp_GetClientInt(i, i_AdminLevel) > rp_GetClientInt(client, i_AdminLevel) && rp_GetClientInt(i, i_AdminLevel) != 1)
			{
				if(StrContains(arg1, "@", false) == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s Vous avez exclu %N.", NAME, i);
					else
						PrintToServer("[ADMIN] Vous avez exclu %N.", i);
					
					for(int x = 1; x <= MaxClients; x++)
					{
						if(IsClientValid(x))
						{
							if(rp_GetClientInt(x, i_AdminLevel) == 1 || rp_GetClientInt(x, i_AdminLevel) == 2)
							{
								if(!StrEqual(arg2, ""))
									CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} %N{default}. Raison : %s", NAME, client, i, arg2);
								else
									CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} %N{default}.", NAME, client, i);
							}
							else
								CPrintToChat(x, "%s {lightgreen}%N{default} a été {lightred}exclu{default} de la partie.", NAME, i);
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
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tous les civils{default}. Raison : %s", NAME, client, i, arg2);
									else if(StrEqual(arg1, "@police"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} toutes les forces de l'ordre{default}. Raison : %s", NAME, client, i, arg2);
									else if(StrEqual(arg1, "@tous"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout le monde{default}. Raison : %s", NAME, client, i, arg2);
									else if(StrEqual(arg1, "@vie"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout les vivants{default}. Raison : %s", NAME, client, i, arg2);
									else if(StrEqual(arg1, "@mort"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout les morts{default}. Raison : %s", NAME, client, i, arg2);
								}
								else
								{
									if(StrEqual(arg1, "@civil"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout les civils{default}.", NAME, client, i);
									else if(StrEqual(arg1, "@police"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} toutes les forces de l'ordre{default}.", NAME, client, i);
									else if(StrEqual(arg1, "@tous"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout le monde{default}.", NAME, client, i);
									else if(StrEqual(arg1, "@vie"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout les vivants{default}.", NAME, client, i);
									else if(StrEqual(arg1, "@mort"))
										CPrintToChat(x, "%s {yellow}%N{default} a {lightred}exclu{lightgreen} tout les morts{default}.", NAME, client, i);
								}
							}
							else
								CPrintToChat(x, "%s {lightgreen}%N{default} a été {lightred}exclu{default} de la partie.", NAME, i);
						}
					}
				}
				char strFormat[512];
				if(!StrEqual(arg2, ""))
					Format(strFormat, sizeof(strFormat), "Vous avez été exclu du RolePlay par un modérateur.\nRaison : %s", arg2);
				else
					Format(strFormat, sizeof(strFormat), "Vous avez été exclu du RolePlay par un modérateur.");
				KickClient(i, strFormat);
			}
			else if(i != client)
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à exlure cette personne.", NAME);
			else
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à vous exlure.", NAME);
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
			CPrintToChat(client, "%s Usage : rp_noclip <joueur>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_noclip <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez mis/enlevé le noclip à tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez mis/enlevé le noclip à tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez mis/enlevé le noclip à tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez mis/enlevé le noclip à tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
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
							CPrintToChat(client, "%s {yellow}%N {default}est maintenant en noclip.", NAME, i);
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
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus en noclip.", NAME, i);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_freeze <joueur>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_freeze <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/gelé tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/gelé tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/gelé tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/gelé tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
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
					CPrintToChat(i, "%s Vous êtes gelé.", NAME);
					
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
					CPrintToChat(i, "%s Vous êtes dégelé.", NAME);
					
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_slap <joueur> <degat>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_slap <joueur> <degat>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, arg1, sizeof(arg1));
	if(len != -1)
		strcopy(arg2, sizeof(arg2), cmdArg[len]);
	
	if(!String_IsNumeric(arg2))
	{
		if(client > 0)
			CPrintToChat(client, "%s Les dégats doivent être en chiffre.", NAME);
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
			CPrintToChat(client, "%s Vous avez giflé tout les civils.", NAME);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Vous avez giflé tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Vous avez giflé tout le monde.", NAME);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Vous avez giflé tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				SlapPlayer(i, degat);
				PrintHintText(i, "Vous avez été giflé.");
				CPrintToChat(i, "%s Vous avez été giflé.", NAME);
				
				if(i != client && StrContains(arg1, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}a été giflé.", NAME, i);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_slay <joueur>", NAME);
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
			CPrintToChat(client, "%s Vous avez giflé tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez giflé tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez giflé tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez giflé tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i) && !IsBenito(i))
			{
				ForcePlayerSuicide(i);
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}a été tué.", NAME, i);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_revivre <joueur>", NAME);
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
			CPrintToChat(client, "%s Vous avez fais revivre tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez fais revivre tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez fais revivre tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez fais revivre tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(!IsPlayerAlive(i))
			{
				CS_RespawnPlayer(i);
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}est maintenant en vie.", NAME, i);
					else
						PrintToServer("[ADMIN] %N est maintenant en vie.", i);
				}
			}
			else if(i != client && StrContains(arg, "@") == -1)
			{
				if(client > 0)
					CPrintToChat(client, "%s {yellow}%N {default}est déjà en vie.", NAME, i);
				else
					PrintToServer("[ADMIN] %N est deja en vie.", i);
			}
			else if(StrContains(arg, "@") == -1)
				CPrintToChat(client, "%s Vous êtes déjà en vie.", NAME);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_Burn(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_burn <joueur>", NAME);
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
			CPrintToChat(client, "%s Vous avez enflammé tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez enflammé tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez enflammé tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez enflammé tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
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
						CPrintToChat(client, "%s {yellow}%N {default}a été enflammé.", NAME, i);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, arg1, sizeof(arg1));
	if(len != -1)
		strcopy(arg2, sizeof(arg2), cmdArg[len]);
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_gravite <joueur> <montant>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_gravite <joueur> <montant>");
		return Plugin_Handled;
	}
	else if(!String_IsNumeric(arg2))
	{
		if(client > 0)
			CPrintToChat(client, "%s La gravité doit être en chiffre.", NAME);
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
			CPrintToChat(client, "%s Vous avez modifié la gravité de tout les civils.", NAME);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Vous avez modifié la gravité de tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Vous avez modifié la gravité de tout le monde.", NAME);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Vous avez modifié la gravité de tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				SetEntityGravity(i, gravite);
				PrintHintText(i, "Votre gravité a changé (%.0f).", gravite);
				CPrintToChat(i, "%s Votre gravité a changé (%.0f).", NAME, gravite);
				
				if(i != client && StrContains(arg1, "@") == -1)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}a changé de gravité (%.0f).", NAME, i, gravite);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_balise <joueur>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_balise <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/balisé tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/balisé tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/balisé tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/balisé tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
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
					CPrintToChat(i, "%s La balise a été enlevée.", NAME);
				}
				else
				{
					rp_SetClientBool(i, b_isBeacon, true);
					CreateTimer(2.0, TimerBeacon, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					PrintHintText(i, "Une balise a été placée sur vous.");
					CPrintToChat(i, "%s Une balise a été placée sur vous.", NAME);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isBeacon))
							CPrintToChat(client, "%s {yellow}%N {default}a une balise.", NAME, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'a plus de balise.", NAME, i);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_bombe <joueur>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_bombe <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez enlevé/placé une bombe sur tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez enlevé/placé une bombe sur tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez enlevé/placé une bombe sur tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez enlevé/placé une bombe sur tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
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
					CPrintToChat(i, "%s La bombe a été enlevée.", NAME);
				}
				else
				{
					rp_SetClientBool(i, b_isBombe, true);
					compteurBombe[client] = 10;
					CreateTimer(1.0, TimerBombe, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					PrintHintText(i, "Une bombe a été placée sur vous.");
					CPrintToChat(i, "%s Une bombe a été placée sur vous.", NAME);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isBombe))
							CPrintToChat(client, "%s {yellow}%N {default}a une bombe.", NAME, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'a plus de bombe.", NAME, i);
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
			CPrintToChat(client, "%s Usage : rp_mute <joueur>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_mute <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/muté tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/muté tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/muté tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/muté tout les vivants.", NAME);
		else if(StrEqual(arg, "@mort"))
			CPrintToChat(client, "%s Vous avez dé/muté tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				if(rp_GetClientBool(i, b_isMute))
				{
					rp_SetClientBool(i, b_isMute, false);
					PrintHintText(i, "Vous n'êtes plus muet.");
					CPrintToChat(i, "%s Vous n'êtes plus muet.", NAME);
				}
				else
				{
					rp_SetClientBool(i, b_isMute, true);
					PrintHintText(i, "Vous êtes muet.");
					CPrintToChat(i, "%s Vous êtes muet.", NAME);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isMute))
							CPrintToChat(client, "%s {yellow}%N {default}a est muet.", NAME, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus muet.", NAME, i);
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
			CPrintToChat(client, "%s Usage : rp_gag <joueur>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_gag <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/gag tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/gag tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/gag tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/gag tout les vivants.", NAME);
		else if(StrEqual(arg, "@mort"))
			CPrintToChat(client, "%s Vous avez dé/gag tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				if(rp_GetClientBool(i, b_isGag))
				{
					rp_SetClientBool(i, b_isGag, false);
					PrintHintText(i, "Vous n'êtes plus gag.");
					CPrintToChat(i, "%s Vous n'êtes plus gag.", NAME);
				}
				else
				{
					rp_SetClientBool(i, b_isGag, true);
					PrintHintText(i, "Vous êtes gag.");
					CPrintToChat(i, "%s Vous êtes gag.", NAME);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isGag))
							CPrintToChat(client, "%s {yellow}%N {default}a est gag.", NAME, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus gag.", NAME, i);
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
			CPrintToChat(client, "%s Usage : rp_silence <joueur>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_silence <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez mis/enlevé sous silence tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez mis/enlevé sous silence tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez mis/enlevé sous silence tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez mis/enlevé sous silence tout les vivants.", NAME);
		else if(StrEqual(arg, "@mort"))
			CPrintToChat(client, "%s Vous avez mis/enlevé sous silence tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
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
					CPrintToChat(i, "%s Vous n'êtes plus sous silence.", NAME);
				}
				else
				{
					rp_SetClientBool(i, b_isMute, true);
					rp_SetClientBool(i, b_isGag, true);
					PrintHintText(i, "Vous êtes sous silence.");
					CPrintToChat(i, "%s Vous êtes sous silence.", NAME);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isMute) && rp_GetClientBool(i, b_isGag))
							CPrintToChat(client, "%s {yellow}%N {default}a est sous silence.", NAME, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus sous silence.", NAME, i);
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
	
	CPrintToChat(client, "%s Commande désactivé temporairement !", NAME);
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_drogue <joueur>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_drogue <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/drogué tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/drogué tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/drogué tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/drogué tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
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
					CPrintToChat(i, "%s Vous n'êtes plus drogué.", NAME);
				}
				else
				{
					rp_SetClientBool(i, b_isDrug, true);
					CreateTimer(2.0, TimerDrug, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					PrintHintText(i, "Vous êtes drogué.");
					CPrintToChat(i, "%s Vous êtes drogué.", NAME);
				}
				
				if(i != client && StrContains(arg, "@") == -1)
				{
					if(client > 0)
					{
						if(rp_GetClientBool(i, b_isDrug))
							CPrintToChat(client, "%s {yellow}%N {default}a est drogué.", NAME, i);
						else
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus drogué.", NAME, i);
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_aveugle <joueur>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_aveugle <joueur>");
		return Plugin_Handled;
	}
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	int joueur[MAXPLAYERS+1];
	joueur = FindJoueur(client, arg, true);
	
	if(joueur[0] == -1)
		return Plugin_Handled;
	
	if(client > 0)
	{
		if(StrEqual(arg, "@civil"))
			CPrintToChat(client, "%s Vous avez dé/aveuglé le noclip à tout les civils.", NAME);
		else if(StrEqual(arg, "@police"))
			CPrintToChat(client, "%s Vous avez dé/aveuglé le noclip à tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg, "@tous"))
			CPrintToChat(client, "%s Vous avez dé/aveuglé le noclip à tout le monde.", NAME);
		else if(StrEqual(arg, "@vie"))
			CPrintToChat(client, "%s Vous avez dé/aveuglé le noclip à tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
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
					CPrintToChat(i, "%s Vous n'êtes plus aveugle.", NAME);
					
					if(StrContains(arg, "@", false) == -1 && i != client)
					{
						if(client > 0)
							CPrintToChat(client, "%s {yellow}%N {default}n'est plus aveugle.", NAME, i);
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
					CPrintToChat(i, "%s Vous êtes aveugle.", NAME);
					
					if(StrContains(arg, "@", false) == -1 && i != client)
					{
						if(client > 0)
							CPrintToChat(client, "%s {yellow}%N {default}est aveugle.", NAME, i);
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
	GetCmdArgString(arg, sizeof(arg));
	ServerCommand(arg);	
	
	return Plugin_Handled;
}

public Action Command_Map(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	if(!StrEqual(arg, "reload"))
		return Plugin_Handled;
	
	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	ForceChangeLevel(mapName, "Admin CMD");
	
	char buffer[1024];
	Format(buffer, sizeof(buffer), "Changement de map [%s].", mapName);
	Discord_SendMessage("mairie", buffer);
	
	return Plugin_Handled;
}

public Action Command_Say(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	char arg[256];
	GetCmdArgString(arg, sizeof(arg));
	
	if(strlen(arg) == 0)
		Format(arg, sizeof(arg), " ");
	
	char strFormat[256];
	Format(strFormat, sizeof(strFormat), "[ADMIN] {lime}%s", arg);
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
		GetCmdArgString(arg, sizeof(arg));
		Entity_GetName(aim, entName, sizeof(entName));
		Entity_SetName(aim, arg);
		CPrintToChat(client, "%s Ancien nom : %s {yellow}=>{default} %s", NAME, entName, arg);
	}
	else
		CPrintToChat(client, "%s Aucune entité détectée.", NAME);
	
	return Plugin_Handled;
}

public Action Command_Vitesse(int client, int args)
{
	if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
	else if(!IsADMIN(client) && rp_GetClientInt(client, i_AdminLevel) != 2)
		return Plugin_Handled;
	
	if(args < 1)
	{
		if(client > 0)
			CPrintToChat(client, "%s Usage : rp_vitesse <joueur> <valeur>", NAME);
		else
			PrintToServer("[ADMIN] Usage : rp_vitesse <joueur> <valeur>");
		return Plugin_Handled;
	}
	
	char cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));
	
	char arg1[64], arg2[64];
	int len = BreakString(cmdArg, arg1, sizeof(arg1));
	if(len != -1)
		strcopy(arg2, sizeof(arg2), cmdArg[len]);
	
	if(!String_IsNumeric(arg2))
	{
		if(client > 0)
			CPrintToChat(client, "%s La vitesse doit être en chiffre.", NAME);
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
			CPrintToChat(client, "%s Vous avez changé la vitesse de tout les civils.", NAME);
		else if(StrEqual(arg1, "@police"))
			CPrintToChat(client, "%s Vous avez changé la vitesse de tout les forces de l'ordre.", NAME);
		else if(StrEqual(arg1, "@tous"))
			CPrintToChat(client, "%s Vous avez changé la vitesse de tout le monde.", NAME);
		else if(StrEqual(arg1, "@vie"))
			CPrintToChat(client, "%s Vous avez changé la vitesse de tout les vivants.", NAME);
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
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(joueur[i]))
		{
			if(IsPlayerAlive(i) && IsValidEntity(i))
			{
				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", vitesse);
				
				PrintHintText(i, "Votre vitesse a changée (%.0f).", vitesse);
				CPrintToChat(i, "%s Votre vitesse a changée (%.0f).", NAME, vitesse);
				
				if(StrContains(arg1, "@", false) == -1 && i != client)
				{
					if(client > 0)
						CPrintToChat(client, "%s {yellow}%N {default}a changé de vitesse (%.0f).", NAME, i, vitesse);
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
		CPrintToChat(client, "%s %f, %f, %f", NAME, position[0], position[1], position[2]);
	}
	else
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
	
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
				case 1:strcopy(sound, sizeof(sound), "weapons/hegrenade/explode3.wav");
				case 2:strcopy(sound, sizeof(sound), "weapons/hegrenade/explode4.wav");
				case 3:strcopy(sound, sizeof(sound), "weapons/hegrenade/explode5.wav");
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