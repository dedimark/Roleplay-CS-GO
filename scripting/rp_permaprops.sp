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

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  D E F I N E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#define MAX_NPCS     512
#define MAX_TYPES   640

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
char dbconfig[] = "roleplay";
Database g_DB;

int g_iLoadedTypes = 0;
char g_cNpcTypes[MAX_TYPES][128];

enum struct GlobalNpcProperties {
	int gRefId;
	char gUniqueId[128];
	char gName[256];
	char gType[128];
}

int g_iNpcId = 0;
GlobalNpcProperties g_iNpcList[MAX_NPCS];

enum struct NpcEdit {
	int nNpcId;
	bool nWaitingForName;
}

NpcEdit g_eNpcEdit[MAXPLAYERS + 1];

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Système PermaProps", 
	author = "Totenfluch & Benito", 
	description = "Spawn les atm selon la map en les chargeant de la bdd", 
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
		RegConsoleCmd("rp_perma", Cmd_SpawnProp, "Spawn a Perma Prop");
		RegConsoleCmd("rp_editperma", Cmd_EditProp, "Edits an Perma Prop");	
		HookEvent("round_start", onRoundStart);	
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();
}

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("Database failure: %s", error);
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
		
		char createTableQuery[4096];
		Format(STRING(createTableQuery), 
		  "CREATE TABLE IF NOT EXISTS `rp_props` ( \
		  `id` int(11) NOT NULL AUTO_INCREMENT, \
		  `uniqueId` varchar(128) COLLATE utf8_bin NOT NULL, \
		  `name` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `map` varchar(128) COLLATE utf8_bin NOT NULL, \
		  `model` varchar(256) COLLATE utf8_bin NOT NULL, \
		  `pos_x` float NOT NULL, \
		  `pos_y` float NOT NULL, \
		  `pos_z` float NOT NULL, \
		  `angle_x` float NOT NULL, \
		  `angle_y` float NOT NULL, \
		  `angle_z` float NOT NULL, \
		  `type` varchar(256) COLLATE utf8_bin NOT NULL, \
		  `created_by` varchar(128) COLLATE utf8_bin NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`id`), \
		  UNIQUE KEY `uniqueId` (`uniqueId`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");		
		g_DB.Query(SQLErrorCheckCallback, createTableQuery);
	}
}

public bool typeExists(char type[128]) {
	for (int i = 0; i < g_iLoadedTypes; i++)
	if (StrEqual(g_cNpcTypes[i], type))
		return true;
	return false;
}

public void resetNpcEdit(int client) {
	g_eNpcEdit[client].nNpcId = -1;
}

public Action Cmd_EditProp(int client, int args) 
{
	int TargetObject = GetTargetBlock(client);
	if (TargetObject == -1) 
	{
		ReplyToCommand(client, "Invalid target");
		return Plugin_Handled;
	}
	
	g_eNpcEdit[client].nNpcId = TargetObject;
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(editMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(TargetObject, STRING(entityName));
	Format(STRING(menuTitle), "Modification en cours (%s)", entityName);
	menu.SetTitle(menuTitle);
	menu.AddItem("position", "Modifier la position");
	menu.AddItem("angles", "Modifier les angles");
	menu.AddItem("name", "Modifier le nom");
	menu.AddItem("delete", "Supprimer le prop");
	menu.Display(client, 60);
		
	return Plugin_Handled;
}

public int editMenuHandler(Menu menu, MenuAction action, int client, int item) 
{
	if (action == MenuAction_Select) 
	{
		char info[32];
		menu.GetItem(item, STRING(info));
		
		if (StrEqual(info, "position")) 
		{
			openPositionMenu(client);
		} 
		else if (StrEqual(info, "angles")) 
		{
			openAnglesMenu(client);
		} 
		else if (StrEqual(info, "delete")) 
		{
			char npcUniqueId[128];
			GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", STRING(npcUniqueId));
			
			char removeNpcQuery[512];
			Format(STRING(removeNpcQuery), "DELETE FROM rp_props WHERE uniqueId = '%s'", npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, removeNpcQuery);
			if (IsValidEntity(g_eNpcEdit[client].nNpcId))
				AcceptEntityInput(g_eNpcEdit[client].nNpcId, "kill");
		} 
		else if (StrEqual(info, "name")) 
		{
			g_eNpcEdit[client].nWaitingForName = true;
			CPrintToChat(client, "%s Entrez le nouveau nom du prop ou 'abort' pour annuler.", TEAM);
		}
	}
	if (action == MenuAction_End) 
	{
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

public void openPositionMenu(int client) 
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(editPositionMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(g_eNpcEdit[client].nNpcId, STRING(entityName));
	Format(STRING(menuTitle), "Editer la position de %s", entityName);
	menu.SetTitle(menuTitle);
	menu.AddItem("up", "Déplacer vers le Haut");
	menu.AddItem("down", "Déplacer vers le bas");
	menu.AddItem("xPlus", "Déplacer X+");
	menu.AddItem("xMinus", "Déplacer X-");
	menu.AddItem("yPlus", "Déplacer Y+");
	menu.AddItem("yMinus", "Déplacer Y-");
	menu.AddItem("ground", "Déplacer au sol");
	menu.AddItem("tpYourself", "Téléporter à moi");
	menu.ExitBackButton = true;
	menu.Display(client, 60);
}

public int editPositionMenuHandler(Menu menu, MenuAction action, int client, int item) 
{
	if (action == MenuAction_Select) 
	{
		char cValue[32];
		float pos[3];
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", STRING(npcUniqueId));
		menu.GetItem(item, STRING(cValue));
		
		if (StrEqual(cValue, "up")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[2] += 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(STRING(updatePositionQuery), "UPDATE rp_props SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "down")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[2] -= 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(STRING(updatePositionQuery), "UPDATE rp_props SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "ground")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[2] -= GetClientDistanceToGround(client);
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(STRING(updatePositionQuery), "UPDATE rp_props SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "tpYourself")) 
		{
			float selfPos[3];
			GetClientAbsOrigin(client, selfPos);
			TeleportEntity(g_eNpcEdit[client].nNpcId, selfPos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(STRING(updatePositionQuery), "UPDATE rp_props SET pos_x = '%.2f' WHERE uniqueId = '%s'", selfPos[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
			Format(STRING(updatePositionQuery), "UPDATE rp_props SET pos_y = '%.2f' WHERE uniqueId = '%s'", selfPos[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
			Format(STRING(updatePositionQuery), "UPDATE rp_props SET pos_z = '%.2f' WHERE uniqueId = '%s'", selfPos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "xPlus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[0] += 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(STRING(updatePositionQuery), "UPDATE rp_props SET pos_x = '%.2f' WHERE uniqueId = '%s'", pos[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "xMinus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[0] -= 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(STRING(updatePositionQuery), "UPDATE rp_props SET pos_x = '%.2f' WHERE uniqueId = '%s'", pos[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "yPlus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[1] += 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(STRING(updatePositionQuery), "UPDATE rp_props SET pos_y = '%.2f' WHERE uniqueId = '%s'", pos[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "yMinus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[1] -= 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(STRING(updatePositionQuery), "UPDATE rp_props SET pos_y = '%.2f' WHERE uniqueId = '%s'", pos[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		if (item == MenuCancel_ExitBack)
			FakeClientCommand(client, "rp_perma");
	}
	else if (action == MenuAction_End) 
	{
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

public void openAnglesMenu(int client) 
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(editAnglesMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(g_eNpcEdit[client].nNpcId, STRING(entityName));
	Format(STRING(menuTitle), "Editer les angles de %s", entityName);
	menu.SetTitle(menuTitle);
	menu.AddItem("yourself", "Définir votre angle");
	menu.AddItem("yourselfInverted", "Définir votre angle contraire");
	menu.AddItem("minus", "Ajouter l'angle+");
	menu.AddItem("plus", "Diminuer l'angle-");
	menu.ExitBackButton = true;
	menu.Display(client, 60);
}

public int editAnglesMenuHandler(Menu menu, MenuAction action, int client, int item) 
{
	if (action == MenuAction_Select) 
	{
		char cValue[32];
		float angles[3];
		char npcUniqueId[128];
		if (g_eNpcEdit[client].nNpcId == -1)
			return;
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", STRING(npcUniqueId));
		menu.GetItem(item, STRING(cValue));
		if (StrEqual(cValue, "plus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_angRotation", angles);
			angles[1] += 5;
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, angles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(STRING(updateAnglesQuery), "UPDATE rp_props SET angle_y = '%.2f' WHERE uniqueId = '%s'", angles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		} 
		else if (StrEqual(cValue, "minus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_angRotation", angles);
			angles[1] -= 5;
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, angles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(STRING(updateAnglesQuery), "UPDATE rp_props SET angle_y = '%.2f' WHERE uniqueId = '%s'", angles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		} 
		else if (StrEqual(cValue, "yourself")) 
		{
			float selfAngles[3];
			GetClientAbsAngles(client, selfAngles);
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, selfAngles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(STRING(updateAnglesQuery), "UPDATE rp_props SET angle_x = '%.2f' WHERE uniqueId = '%s'", selfAngles[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(STRING(updateAnglesQuery), "UPDATE rp_props SET angle_y = '%.2f' WHERE uniqueId = '%s'", selfAngles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(STRING(updateAnglesQuery), "UPDATE rp_props SET angle_z = '%.2f' WHERE uniqueId = '%s'", selfAngles[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		} 
		else if (StrEqual(cValue, "yourselfInverted")) 
		{
			float selfAngles[3];
			GetClientAbsAngles(client, selfAngles);
			selfAngles[1] = 180 - selfAngles[1];
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, selfAngles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(STRING(updateAnglesQuery), "UPDATE rp_props SET angle_x = '%.2f' WHERE uniqueId = '%s'", selfAngles[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(STRING(updateAnglesQuery), "UPDATE rp_props SET angle_y = '%.2f' WHERE uniqueId = '%s'", selfAngles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(STRING(updateAnglesQuery), "UPDATE rp_props SET angle_z = '%.2f' WHERE uniqueId = '%s'", selfAngles[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (item == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		if (item == MenuCancel_ExitBack)
			FakeClientCommand(client, "rp_perma");
	}
	else if (action == MenuAction_End) 
	{
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

public int DoSpawnProp(Menu menu, MenuAction action, int client, int param) 
{
	if (action == MenuAction_Select)
	{
		char info[256];
		menu.GetItem(param, STRING(info));
		
		FakeClientCommand(client, "rp_editperma");
		int npc = CreateEntityByName("prop_dynamic_override");
		if (npc == -1) 
		{
			CPrintToChat(client, "%s Une erreur est survenue lors de la création du prop.", TEAM);
			return;
		}
		
		g_iNpcList[g_iNpcId].gRefId = EntIndexToEntRef(npc);
		float pos[3];
		GetClientAbsOrigin(client, pos);
		float angles[3];
		GetClientAbsAngles(client, angles);
		
		char uniqueId[128];
		int uniqueIdTime = GetTime();
		IntToString(uniqueIdTime, STRING(uniqueId));
		strcopy(g_iNpcList[g_iNpcId].gUniqueId, 128, uniqueId);
		
		char mapName[128];
		rp_GetCurrentMap(mapName);
		
		char playerid[20];
		GetClientAuthId(client, AuthId_Steam2, STRING(playerid));
		
		char createdBy[128];
		Format(STRING(createdBy), "%s %N", playerid, client);
		
		char insertNpcQuery[4096];
		Format(STRING(insertNpcQuery), "INSERT INTO `rp_props` (`id`, `uniqueId`, `name`, `map`, `model`, `pos_x`, `pos_y`, `pos_z`, `angle_x`, `angle_y`, `angle_z`, `type`, `created_by`, `timestamp`) VALUES (NULL, '%s', '', '%s', '%s', '%.2f', '%.2f', '%.2f', '%.2f', '%.2f', '%.2f', 'normal', '%s', CURRENT_TIMESTAMP);", uniqueId, mapName, info, pos[0], pos[1], pos[2], angles[0], angles[1], angles[2], createdBy);
		g_DB.Query(SQLErrorCheckCallback, insertNpcQuery);
		
		
		CreateNpc(uniqueId, "", info, pos, angles, "normal");
	}
	if (action == MenuAction_End) 
	{
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

public Action Cmd_SpawnProp(int client, int args) 
{
	if(rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", TEAM);
		return Plugin_Handled;
	}
		
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu prop = new Menu(DoSpawnProp);	
	prop.SetTitle("Roleplay - PermaProps");	
	
	prop.AddItem("models/props_unique/atm01.mdl", "Distributeur de billet");
	prop.AddItem("models/props/de_nuke/hr_nuke/nuke_vending_machine/nuke_snack_machine.mdl", "Distributeur de nourriture");
	prop.AddItem("models/props/coop_cementplant/coop_foot_locker/coop_foot_locker_closed.mdl", "Coffre");
	prop.AddItem("models/characters/hostage_01.mdl", "PNJ");
	
	prop.ExitButton = true;
	prop.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

stock int GetTargetBlock(int client) 
{
	int entity = GetClientAimTarget(client, false);
	if (IsValidEntity(entity)) 
	{
		char classname[32];
		GetEdictClassname(entity, classname, 32);
		
		if (StrContains(classname, "prop_dynamic") != -1)
			return entity;
	}
	return -1;
}

public Action rp_SayOnPublic(int client, const char[] arg, const char[] Cmd, int args)
{
	if (g_eNpcEdit[client].nWaitingForName && StrContains(arg, "abort") == -1) 
	{
		Entity_SetName(g_eNpcEdit[client].nNpcId, arg);
		PrintToChat(client, "Nom défini en %s", arg);
		g_eNpcEdit[client].nWaitingForName = false;
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", STRING(npcUniqueId));
		char updateNameQuery[512];
		Format(STRING(updateNameQuery), "UPDATE rp_props SET name = '%s' WHERE uniqueId = '%s'", arg, npcUniqueId);
		g_DB.Query(SQLErrorCheckCallback, updateNameQuery);
		strcopy(g_iNpcList[g_iNpcId].gName, 128, arg);
	} 
}

public Action rp_SayOnTeam(int client, const char[] arg, const char[] Cmd, int args)
{
	if (g_eNpcEdit[client].nWaitingForName && StrContains(arg, "abort") == -1) 
	{
		Entity_SetName(g_eNpcEdit[client].nNpcId, arg);
		PrintToChat(client, "Nom défini en %s", arg);
		g_eNpcEdit[client].nWaitingForName = false;
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", STRING(npcUniqueId));
		char updateNameQuery[512];
		Format(STRING(updateNameQuery), "UPDATE rp_props SET name = '%s' WHERE uniqueId = '%s'", arg, npcUniqueId);
		g_DB.Query(SQLErrorCheckCallback, updateNameQuery);
		strcopy(g_iNpcList[g_iNpcId].gName, 128, arg);
	} 
}	

public float GetClientDistanceToGround(int client) {
	
	float fOrigin[3];
	float fGround[3];
	GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", fOrigin);
	
	fOrigin[2] += 10.0;
	float anglePos[3];
	anglePos[0] = 90.0;
	anglePos[1] = 0.0;
	anglePos[2] = 0.0;
	
	TR_TraceRayFilter(fOrigin, anglePos, MASK_PLAYERSOLID, RayType_Infinite, TraceRayNoPlayers, client);
	if (TR_DidHit()) {
		TR_GetEndPosition(fGround);
		fOrigin[2] -= 10.0;
		return GetVectorDistance(fOrigin, fGround);
	}
	return 0.0;
}

public bool TraceRayNoPlayers(int entity, int mask, any data)
{
	if (entity == data || (entity >= 1 && entity <= MaxClients)) {
		return false;
	}
	return true;
}

public void OnMapStart() {
	g_iNpcId = 0;
	if(g_DB != null)
		LoadProps();
}	

public void onRoundStart(Event event, const char[] name, bool dontBroadcast) {
	g_iNpcId = 0;
	if(g_DB != null)
		LoadProps();
}

public void LoadProps() {
	char mapName[128];
	rp_GetCurrentMap(mapName);
	
	char LoadPropsQuery[1024];
	Format(STRING(LoadPropsQuery), "SELECT * FROM rp_props WHERE map = '%s';", mapName);
	g_DB.Query(LoadPropsQueryCallback, LoadPropsQuery);
}


public void LoadPropsQueryCallback(Database db, DBResultSet Results, const char[] error, any data) {
	while (Results.FetchRow()) {
		char uniqueId[128];
		char name[64];
		char model[256];
		float pos[3];
		float angles[3];
		char type[256];
		SQL_FetchStringByName(Results, "uniqueId", STRING(uniqueId));
		SQL_FetchStringByName(Results, "name", STRING(name));
		SQL_FetchStringByName(Results, "model", STRING(model));
		pos[0] = SQL_FetchFloatByName(Results, "pos_x");
		pos[1] = SQL_FetchFloatByName(Results, "pos_y");
		pos[2] = SQL_FetchFloatByName(Results, "pos_z");
		angles[0] = SQL_FetchFloatByName(Results, "angle_x");
		angles[1] = SQL_FetchFloatByName(Results, "angle_y");
		angles[2] = SQL_FetchFloatByName(Results, "angle_z");
		SQL_FetchStringByName(Results, "type", STRING(type));
		
		CreateNpc(uniqueId, name, model, pos, angles, type);
	}
}

public void CreateNpc(char uniqueId[128], char name[64], char model[256], float pos[3], float angles[3], char type[256]) 
{
	PrecacheModel(model, true);
	
	int npc = CreateEntityByName("prop_dynamic");
	if (npc == -1)
		return;
	
	g_iNpcList[g_iNpcId].gRefId = EntIndexToEntRef(npc);
	
	DispatchKeyValue(npc, "disablebonefollowers", "1");
	if (!DispatchKeyValue(npc, "solid", "2"))PrintToChatAll("Box Failed");
	DispatchKeyValue(npc, "model", model);
	
	SetEntProp(npc, Prop_Send, "m_nSolidType", 2);
	SetEntProp(npc, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
	//SetEntPropFloat(npc, Prop_Send, "m_flModelScale", 3.0);
	
	DispatchSpawn(npc);
	
	
	TeleportEntity(npc, pos, angles, NULL_VECTOR);
	
	strcopy(g_iNpcList[g_iNpcId].gUniqueId, 128, uniqueId);
	strcopy(g_iNpcList[g_iNpcId].gName, 128, name);
	strcopy(g_iNpcList[g_iNpcId].gType, 128, type);
	
	char entityName[128];
	if (StrEqual(name, ""))
		Format(STRING(entityName), "%i", g_iNpcId);
	else
		Format(STRING(entityName), "%s", name);
	SetEntPropString(npc, Prop_Data, "m_iName", name);
	
	if(StrEqual(model, "models/characters/hostage_01.mdl"))
	{
		SetVariantString("idle_subtle");
		AcceptEntityInput(npc, "SetAnimation");
	}	
	g_iNpcId++;
}

public void openTypeMenu(int client) 
{
	Menu menu = new Menu(typeChooserHandler);
	menu.SetTitle("Set Type for this Npc");
	for (int i = 0; i < g_iLoadedTypes; i++) 
	{
		char typeName[128];
		strcopy(STRING(typeName), g_cNpcTypes[i]);
		menu.AddItem(typeName, typeName);
	}
	menu.Display(client, 60);
}

public int typeChooserHandler(Menu menu, MenuAction action, int client, int item) 
{
	if (action == MenuAction_Select) 
	{
		char cValue[128];
		menu.GetItem(item, STRING(cValue));
		
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", STRING(npcUniqueId));
		int id;
		if ((id = getNpcLoadedIdFromUniqueId(npcUniqueId)) == -1)
			return;
		
		strcopy(g_iNpcList[id].gType, 128, cValue);
		char updateTypeQuery[512];
		Format(STRING(updateTypeQuery), "UPDATE rp_props SET type = '%s' WHERE uniqueId = '%s'", cValue, g_iNpcList[id].gUniqueId);
		g_DB.Query(SQLErrorCheckCallback, updateTypeQuery);
	}
	if (action == MenuAction_End) 
	{
		delete menu;
	}
}

stock int getNpcLoadedIdFromUniqueId(char uniqueId[128]) 
{
	for (int i = 0; i < g_iNpcId; i++) 
	{
		if (StrEqual(g_iNpcList[i].gUniqueId, uniqueId))
			return i;
	}
	return -1;
}

stock int getNpcLoadedIdFromRef(int entRef) 
{
	for (int i = 0; i < g_iNpcId; i++) 
	{
		if (g_iNpcList[i].gRefId == entRef)
			return i;
	}
	return -1;
}
