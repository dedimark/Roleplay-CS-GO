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

/***************************************************************************************

							C O M P I L E  -  O P T I O N S

***************************************************************************************/
#pragma semicolon 1
#pragma newdecls required

/***************************************************************************************

							P L U G I N  -  I N C L U D E S

***************************************************************************************/
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <roleplay>
#include <smlib>
#include <multicolors>

#define MAX_NPCS 512
#define MAX_TYPES 64

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
int g_iPlayerPrevButtons[MAXPLAYERS + 1];

int g_iLoadedTypes = 0;
char g_cNpcTypes[MAX_TYPES][128];

enum struct GlobalNpcProperties {
	int gRefId;
	char gUniqueId[128];
	char gName[256];
	char gType[128];
	char gIdleAnimation[256];
	char gSecondAnimation[256];
	char gThirdAnimation[256];
	bool gEnabled;
	bool gInAnimation;
}

int g_iNpcId = 0;
GlobalNpcProperties g_iNpcList[MAX_NPCS];

enum struct NpcEdit {
	int nNpcId;
	bool nWaitingForModelName;
	bool nWaitingForIdleAnimationName;
	bool nWaitingForName;
}

NpcEdit g_eNpcEdit[MAXPLAYERS + 1];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] PermaProps", 
	author = "Benito", 
	description = "Spawns NPCs and load them in a Database", 
	version = VERSION, 
	url = URL
};

public void OnPluginStart()
{
	RegConsoleCmd("rp_npc", cmdSpawnNpc);
	RegConsoleCmd("rp_editnpc", cmdEditNpc);
	
	HookEvent("round_start", onRoundStart);
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_props` ( \
	  `id` int(11) NOT NULL AUTO_INCREMENT, \
	  `uniqueId` varchar(128) COLLATE utf8_bin NOT NULL, \
	  `name` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `map` varchar(128) COLLATE utf8_bin NOT NULL, \
	  `model` varchar(256) COLLATE utf8_bin NOT NULL, \
	  `idle_animation` varchar(256) COLLATE utf8_bin NOT NULL, \
	  `second_animation` varchar(256) COLLATE utf8_bin NOT NULL, \
	  `third_animation` varchar(256) COLLATE utf8_bin NOT NULL, \
	  `pos_x` float NOT NULL, \
	  `pos_y` float NOT NULL, \
	  `pos_z` float NOT NULL, \
	  `angle_x` float NOT NULL, \
	  `angle_y` float NOT NULL, \
	  `angle_z` float NOT NULL, \
	  `type` varchar(256) COLLATE utf8_bin NOT NULL, \
	  `flags` varchar(256) COLLATE utf8_bin NOT NULL, \
	  `special_flags` varchar(256) COLLATE utf8_bin NOT NULL, \
	  `enabled` tinyint(1) NOT NULL, \
	  `created_by` varchar(128) COLLATE utf8_bin NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`id`), \
	  UNIQUE KEY `uniqueId` (`uniqueId`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");	
	db.Query(SQLErrorCheckCallback, buffer);
}

public bool typeExists(char type[128]) 
{
	for (int i = 0; i < g_iLoadedTypes; i++)
	if (StrEqual(g_cNpcTypes[i], type))
		return true;
	return false;
}

public void resetNpcEdit(int client) 
{
	g_eNpcEdit[client].nNpcId = -1;
	g_eNpcEdit[client].nWaitingForModelName = false;
}

public Action cmdEditNpc(int client, int args) 
{
	int TargetObject = GetTargetBlock(client);
	if (TargetObject == -1) {
		ReplyToCommand(client, "Invalid target");
		return Plugin_Handled;
	}
	
	g_eNpcEdit[client].nNpcId = TargetObject;
	
	Handle menu = CreateMenu(editMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(TargetObject, entityName, sizeof(entityName));
	Format(menuTitle, sizeof(menuTitle), "Edit %s", entityName);
	SetMenuTitle(menu, menuTitle);
	AddMenuItem(menu, "model", "Edit Model");
	AddMenuItem(menu, "idleAnimation", "Edit Idle Animation");
	AddMenuItem(menu, "position", "Edit Position");
	AddMenuItem(menu, "angles", "Edit Angles");
	AddMenuItem(menu, "name", "Edit Name");
	AddMenuItem(menu, "type", "Edit Type");
	AddMenuItem(menu, "base", "Edit Base Properties");
	AddMenuItem(menu, "delete", "Delete Npc");
	DisplayMenu(menu, client, 60);
	
	
	return Plugin_Handled;
}

public int editMenuHandler(Handle menu, MenuAction action, int client, int item) 
{
	if (action == MenuAction_Select) 
	{
		char cValue[32];
		GetMenuItem(menu, item, cValue, sizeof(cValue));
		if (StrEqual(cValue, "model")) {
			g_eNpcEdit[client].nWaitingForModelName = true;
			PrintToChat(client, "Enter the new Model Name OR 'abort' to cancel");
		} 
		else if (StrEqual(cValue, "idleAnimation")) 
		{
			g_eNpcEdit[client].nWaitingForIdleAnimationName = true;
			PrintToChat(client, "Enter the new Idle Animation Name OR 'abort' to cancel");
		} 
		else if (StrEqual(cValue, "position")) 
		{
			openPositionMenu(client);
		} 
		else if (StrEqual(cValue, "angles")) 
		{
			openAnglesMenu(client);
		} 
		else if (StrEqual(cValue, "base")) 
		{
			openBasePropertyMenu(client);
		} 
		else if (StrEqual(cValue, "delete")) 
		{
			char npcUniqueId[128];
			GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
			
			char removeNpcQuery[512];
			Format(removeNpcQuery, sizeof(removeNpcQuery), "DELETE FROM rp_props WHERE uniqueId = '%s'", npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, removeNpcQuery);
			if (IsValidEntity(g_eNpcEdit[client].nNpcId))
				AcceptEntityInput(g_eNpcEdit[client].nNpcId, "kill");
		} 
		else if (StrEqual(cValue, "name")) 
		{
			g_eNpcEdit[client].nWaitingForName = true;
			PrintToChat(client, "Enter the new Name OR 'abort' to cancel");
		} 
		else if (StrEqual(cValue, "type")) 
		{
			openTypeMenu(client);
		}
	}
	if (action == MenuAction_End) {
		delete menu;
	}
}

public void openPositionMenu(int client) 
{
	Handle menu = CreateMenu(editPositionMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(g_eNpcEdit[client].nNpcId, entityName, sizeof(entityName));
	Format(menuTitle, sizeof(menuTitle), "Edit Position of %s", entityName);
	SetMenuTitle(menu, menuTitle);
	AddMenuItem(menu, "up", "Move Up");
	AddMenuItem(menu, "down", "Move Down");
	AddMenuItem(menu, "xPlus", "Move X Plus");
	AddMenuItem(menu, "xMinus", "Move X Minus");
	AddMenuItem(menu, "yPlus", "Move Y Plus");
	AddMenuItem(menu, "yMinus", "Move Y Minus");
	AddMenuItem(menu, "ground", "Put on Ground");
	AddMenuItem(menu, "tpYourself", "Teleport to yourself");
	DisplayMenu(menu, client, 60);
}

public int editPositionMenuHandler(Menu menu, MenuAction action, int client, int param) 
{
	if (action == MenuAction_Select) 
	{
		char cValue[32];
		float pos[3];
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		menu.GetItem(param, STRING(cValue));
		if (StrEqual(cValue, "up")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[2] += 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_props SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "down")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[2] -= 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_props SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "ground")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[2] -= GetClientDistanceToGround(client);
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_props SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "tpYourself")) 
		{
			float selfPos[3];
			GetClientAbsOrigin(client, selfPos);
			TeleportEntity(g_eNpcEdit[client].nNpcId, selfPos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_props SET pos_x = '%.2f' WHERE uniqueId = '%s'", selfPos[0], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updatePositionQuery);
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_props SET pos_y = '%.2f' WHERE uniqueId = '%s'", selfPos[1], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updatePositionQuery);
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_props SET pos_z = '%.2f' WHERE uniqueId = '%s'", selfPos[2], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "xPlus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[0] += 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_props SET pos_x = '%.2f' WHERE uniqueId = '%s'", pos[0], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "xMinus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[0] -= 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_props SET pos_x = '%.2f' WHERE uniqueId = '%s'", pos[0], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "yPlus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[1] += 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_props SET pos_y = '%.2f' WHERE uniqueId = '%s'", pos[1], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updatePositionQuery);
		} 
		else if (StrEqual(cValue, "yMinus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[1] -= 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_props SET pos_y = '%.2f' WHERE uniqueId = '%s'", pos[1], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updatePositionQuery);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public void openAnglesMenu(int client) 
{
	Handle menu = CreateMenu(editAnglesMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(g_eNpcEdit[client].nNpcId, entityName, sizeof(entityName));
	Format(menuTitle, sizeof(menuTitle), "Edit Angles of %s", entityName);
	SetMenuTitle(menu, menuTitle);
	AddMenuItem(menu, "yourself", "Set Your Angles");
	AddMenuItem(menu, "yourselfInverted", "Set Your Inverted Angles");
	AddMenuItem(menu, "minus", "Add Angles");
	AddMenuItem(menu, "plus", "Move Down");
	DisplayMenu(menu, client, 60);
}

public int editAnglesMenuHandler(Menu menu, MenuAction action, int client, int param) 
{
	if (action == MenuAction_Select) 
	{
		char cValue[32];
		float angles[3];
		char npcUniqueId[128];
		if (g_eNpcEdit[client].nNpcId == -1)
			return;
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		menu.GetItem(param, STRING(cValue));
		if (StrEqual(cValue, "plus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_angRotation", angles);
			angles[1] += 5;
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, angles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_props SET angle_y = '%.2f' WHERE uniqueId = '%s'", angles[1], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updateAnglesQuery);
		} 
		else if (StrEqual(cValue, "minus")) 
		{
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_angRotation", angles);
			angles[1] -= 5;
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, angles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_props SET angle_y = '%.2f' WHERE uniqueId = '%s'", angles[1], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updateAnglesQuery);
		} 
		else if (StrEqual(cValue, "yourself")) 
		{
			float selfAngles[3];
			GetClientAbsAngles(client, selfAngles);
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, selfAngles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_props SET angle_x = '%.2f' WHERE uniqueId = '%s'", selfAngles[0], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_props SET angle_y = '%.2f' WHERE uniqueId = '%s'", selfAngles[1], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_props SET angle_z = '%.2f' WHERE uniqueId = '%s'", selfAngles[2], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updateAnglesQuery);
		} 
		else if (StrEqual(cValue, "yourselfInverted")) 
		{
			float selfAngles[3];
			GetClientAbsAngles(client, selfAngles);
			selfAngles[1] = 180 - selfAngles[1];
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, selfAngles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_props SET angle_x = '%.2f' WHERE uniqueId = '%s'", selfAngles[0], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_props SET angle_y = '%.2f' WHERE uniqueId = '%s'", selfAngles[1], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_props SET angle_z = '%.2f' WHERE uniqueId = '%s'", selfAngles[2], npcUniqueId);
			rp_GetDatabase().Query(SQLErrorCheckCallback, updateAnglesQuery);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public void openBasePropertyMenu(int client) 
{
	Handle menu = CreateMenu(editBasePropertyMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(g_eNpcEdit[client].nNpcId, entityName, sizeof(entityName));
	Format(menuTitle, sizeof(menuTitle), "Edit Base Properties of %s", entityName);
	SetMenuTitle(menu, menuTitle);
	AddMenuItem(menu, "solid", "Make NPC solid");
	AddMenuItem(menu, "nonsolid", "Make NPC non-solid");
	DisplayMenu(menu, client, 60);
}

public int editBasePropertyMenuHandler(Menu menu, MenuAction action, int client, int param) 
{
	if (action == MenuAction_Select) 
	{
		char cValue[32];
		menu.GetItem(param, STRING(cValue));
		if (StrEqual(cValue, "solid")) 
		{
			SetEntProp(g_eNpcEdit[client].nNpcId, Prop_Send, "m_nSolidType", 6);
			openBasePropertyMenu(client);
		} 
		else if (StrEqual(cValue, "nonsolid")) 
		{
			SetEntProp(g_eNpcEdit[client].nNpcId, Prop_Send, "m_nSolidType", 0);
			openBasePropertyMenu(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public Action cmdSpawnNpc(int client, int args) 
{
	int npc = CreateEntityByName("prop_dynamic");
	if (npc == -1) 
	{
		PrintToChat(client, "[-T-] Can not spawn Npc - report this?");
		return Plugin_Handled;
	}
	
	g_iNpcList[g_iNpcId].gRefId = EntIndexToEntRef(npc);
	float pos[3];
	GetClientAbsOrigin(client, pos);
	float angles[3];
	GetClientAbsAngles(client, angles);
	/*PrecacheModel("models/characters/hostage_01.mdl", true);
	SetEntityModel(npc, "models/characters/hostage_01.mdl");
	DispatchKeyValue(npc, "Solid", "6");
	SetEntProp(npc, Prop_Send, "m_nSolidType", 6);
	DispatchSpawn(npc);
	TeleportEntity(npc, pos, angles, NULL_VECTOR);
	Entity_SetGlobalName(npc, "npc_%i", g_iNpcId++);
	
	SetVariantString("idle_subtle");
	AcceptEntityInput(npc, "SetAnimation");*/
	
	char uniqueId[128];
	int uniqueIdTime = GetTime();
	IntToString(uniqueIdTime, uniqueId, sizeof(uniqueId));
	strcopy(g_iNpcList[g_iNpcId].gUniqueId, 128, uniqueId);
	
	char mapName[128];
	rp_GetCurrentMap(mapName);
	
	char playerid[20];
	GetClientAuthId(client, AuthId_Steam2, playerid, sizeof(playerid));
	
	char createdBy[128];
	Format(createdBy, sizeof(createdBy), "%s %N", playerid, client);
	
	char insertNpcQuery[4096];
	Format(insertNpcQuery, sizeof(insertNpcQuery), "INSERT INTO `rp_props` (`id`, `uniqueId`, `name`, `map`, `model`, `idle_animation`, `second_animation`, `third_animation`, `pos_x`, `pos_y`, `pos_z`, `angle_x`, `angle_y`, `angle_z`, `type`, `flags`, `special_flags`, `enabled`, `created_by`, `timestamp`) VALUES (NULL, '%s', '', '%s', 'models/characters/hostage_01.mdl', 'idle_subtle', '', '', '%.2f', '%.2f', '%.2f', '%.2f', '%.2f', '%.2f', 'normal', '', '', '1', '%s', CURRENT_TIMESTAMP);", uniqueId, mapName, pos[0], pos[1], pos[2], angles[0], angles[1], angles[2], createdBy);
	rp_GetDatabase().Query(SQLErrorCheckCallback, insertNpcQuery);
	
	
	CreateNpc(uniqueId, "", "models/characters/hostage_01.mdl", "idle_subtle", "Wave", "", pos, angles, "normal", "", "", true);
	
	//g_iNpcId++;
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon, int &tickcount)
{
	if (IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		if (!(g_iPlayerPrevButtons[client] & IN_USE) && iButtons & IN_USE) 
		{
			int TargetObject = GetTargetBlock(client);
			if (TargetObject == -1)
				return;
			float clientPos[3];
			GetClientAbsOrigin(client, clientPos);
			float npcPos[3];
			GetEntPropVector(TargetObject, Prop_Data, "m_vecOrigin", npcPos);
			if (GetVectorDistance(clientPos, npcPos) > 75.0)
				return;
			
			char npcUniqueId[128];
			GetEntPropString(TargetObject, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
			onNpcInteract(client, npcUniqueId, TargetObject);
		}
		g_iPlayerPrevButtons[client] = iButtons;
	}
	
}

stock int GetTargetBlock(int client) 
{
	int entity = GetClientAimTarget(client, false);
	if (IsValidEntity(entity)) {
		char classname[32];
		GetEdictClassname(entity, classname, 32);
		
		if (StrContains(classname, "prop_dynamic") != -1)
			return entity;
	}
	return -1;
}

public Action RP_OnPlayerSay(int client, const char[] arg)
{
	if (g_eNpcEdit[client].nWaitingForModelName && StrContains(arg, "abort") == -1) 
	{
		PrecacheModel(arg, true);
		SetEntityModel(g_eNpcEdit[client].nNpcId, arg);
		char entityName[256];
		Entity_GetGlobalName(g_eNpcEdit[client].nNpcId, entityName, sizeof(entityName));
		PrintToChat(client, "Set Model of %s TO %s", entityName, arg);
		g_eNpcEdit[client].nWaitingForModelName = false;
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		char updateModelQuery[512];
		Format(updateModelQuery, sizeof(updateModelQuery), "UPDATE rp_props SET model = '%s' WHERE uniqueId = '%s'", arg, npcUniqueId);
		rp_GetDatabase().Query(SQLErrorCheckCallback, updateModelQuery);
		return Plugin_Handled;
	} 
	else if (g_eNpcEdit[client].nWaitingForIdleAnimationName && StrContains(arg, "abort") == -1) 
	{
		SetVariantString(arg);
		AcceptEntityInput(g_eNpcEdit[client].nNpcId, "SetAnimation");
		strcopy(g_iNpcList[g_iNpcId].gIdleAnimation, 256, arg);
		char entityName[256];
		Entity_GetGlobalName(g_eNpcEdit[client].nNpcId, entityName, sizeof(entityName));
		PrintToChat(client, "Set Idle Animation of %s TO %s", entityName, arg);
		g_eNpcEdit[client].nWaitingForIdleAnimationName = false;
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		char updateAnimationQuery[512];
		Format(updateAnimationQuery, sizeof(updateAnimationQuery), "UPDATE rp_props SET idle_animation = '%s' WHERE uniqueId = '%s'", arg, npcUniqueId);
		rp_GetDatabase().Query(SQLErrorCheckCallback, updateAnimationQuery);
		return Plugin_Handled;
	} 
	else if (g_eNpcEdit[client].nWaitingForName && StrContains(arg, "abort") == -1) 
	{
		SetVariantString(arg);
		char entityName[256];
		Format(entityName, sizeof(entityName), "%s", arg);
		Entity_SetGlobalName(g_eNpcEdit[client].nNpcId, entityName, sizeof(entityName));
		PrintToChat(client, "Set Name of %s TO %s", entityName, arg);
		g_eNpcEdit[client].nWaitingForName = false;
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		char updateNameQuery[512];
		Format(updateNameQuery, sizeof(updateNameQuery), "UPDATE rp_props SET name = '%s' WHERE uniqueId = '%s'", arg, npcUniqueId);
		rp_GetDatabase().Query(SQLErrorCheckCallback, updateNameQuery);
		strcopy(g_iNpcList[g_iNpcId].gName, 128, arg);
		return Plugin_Handled;
	} 
	else if ((g_eNpcEdit[client].nWaitingForModelName || g_eNpcEdit[client].nWaitingForIdleAnimationName || g_eNpcEdit[client].nWaitingForName) && StrContains(arg, "abort") != -1) 
	{
		g_eNpcEdit[client].nWaitingForModelName = false;
		g_eNpcEdit[client].nWaitingForIdleAnimationName = false;
		g_eNpcEdit[client].nWaitingForName = false;
		PrintToChat(client, "Aborted.");
		return Plugin_Handled;
	}
	
	
	return Plugin_Continue;
}

public float GetClientDistanceToGround(int client) 
{	
	float fOrigin[3];
	float fGround[3];
	GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", fOrigin);
	
	fOrigin[2] += 10.0;
	float anglePos[3];
	anglePos[0] = 90.0;
	anglePos[1] = 0.0;
	anglePos[2] = 0.0;
	
	TR_TraceRayFilter(fOrigin, anglePos, MASK_PLAYERSOLID, RayType_Infinite, TraceRayNoPlayers, client);
	if (TR_DidHit()) 
	{
		TR_GetEndPosition(fGround);
		fOrigin[2] -= 10.0;
		return GetVectorDistance(fOrigin, fGround);
	}
	return 0.0;
}

public bool TraceRayNoPlayers(int entity, int mask, any data)
{
	if (entity == data || (entity >= 1 && entity <= MaxClients)) 
	{
		return false;
	}
	return true;
}

public void onRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	g_iNpcId = 0;
	loadNpcs();
}

public void loadNpcs() 
{
	char mapName[128];
	rp_GetCurrentMap(mapName);
	
	char loadNpcsQuery[1024];
	Format(loadNpcsQuery, sizeof(loadNpcsQuery), "SELECT * FROM rp_props WHERE map = '%s';", mapName);
	rp_GetDatabase().Query(loadNpcsQueryCallback, loadNpcsQuery);
}

public void loadNpcsQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	while (Results.FetchRow()) 
	{
		char uniqueId[128];
		char name[64];
		char model[256];
		char idle_animation[256];
		char second_animation[256];
		char third_animation[256];
		float pos[3];
		float angles[3];
		char type[256];
		char flags[256];
		char special_flags[256];
		bool enabled;
		SQL_FetchStringByName(Results, "uniqueId", STRING(uniqueId));
		SQL_FetchStringByName(Results, "name", STRING(name));
		SQL_FetchStringByName(Results, "model", STRING(model));
		SQL_FetchStringByName(Results, "idle_animation", STRING(idle_animation));
		SQL_FetchStringByName(Results, "second_animation", STRING(second_animation));
		SQL_FetchStringByName(Results, "third_animation", STRING(third_animation));
		pos[0] = SQL_FetchFloatByName(Results, "pos_x");
		pos[1] = SQL_FetchFloatByName(Results, "pos_y");
		pos[2] = SQL_FetchFloatByName(Results, "pos_z");
		angles[0] = SQL_FetchFloatByName(Results, "angle_x");
		angles[1] = SQL_FetchFloatByName(Results, "angle_y");
		angles[2] = SQL_FetchFloatByName(Results, "angle_z");
		SQL_FetchStringByName(Results, "type", STRING(type));
		SQL_FetchStringByName(Results, "flags", STRING(flags));
		SQL_FetchStringByName(Results, "special_flags", STRING(special_flags));
		enabled = SQL_FetchIntByName(Results, "enabled") == 1;
		
		CreateNpc(uniqueId, name, model, idle_animation, second_animation, third_animation, pos, angles, type, flags, special_flags, enabled);
	}
}

public void CreateNpc(char uniqueId[128], char name[64], char model[256], char idle_animation[256], char second_animation[256], char third_animation[256], float pos[3], float angles[3], char type[256], char flags[256], char special_flags[256], bool enabled) 
{
	if (!enabled)
		return;
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
	
	SetEntPropString(npc, Prop_Data, "m_iName", uniqueId);
	
	TeleportEntity(npc, pos, angles, NULL_VECTOR);
	
	strcopy(g_iNpcList[g_iNpcId].gUniqueId, 128, uniqueId);
	strcopy(g_iNpcList[g_iNpcId].gName, 128, name);
	strcopy(g_iNpcList[g_iNpcId].gType, 128, type);
	strcopy(g_iNpcList[g_iNpcId].gIdleAnimation, 256, idle_animation);
	strcopy(g_iNpcList[g_iNpcId].gSecondAnimation, 256, second_animation);
	strcopy(g_iNpcList[g_iNpcId].gThirdAnimation, 256, third_animation);
	
	char entityName[128];
	if (StrEqual(name, ""))
		Format(entityName, sizeof(entityName), "%i", g_iNpcId);
	else
		Format(entityName, sizeof(entityName), "%s", name);
	Entity_SetGlobalName(npc, entityName);
	g_iNpcId++;
	
	SetVariantString(idle_animation);
	AcceptEntityInput(npc, "SetAnimation");
}

public void openTypeMenu(int client) 
{
	Handle menu = CreateMenu(typeChooserHandler);
	SetMenuTitle(menu, "Set Type for this Npc");
	for (int i = 0; i < g_iLoadedTypes; i++) 
	{
		char typeName[128];
		strcopy(typeName, sizeof(typeName), g_cNpcTypes[i]);
		AddMenuItem(menu, typeName, typeName);
	}
	DisplayMenu(menu, client, 60);
}

public int typeChooserHandler(Handle menu, MenuAction action, int client, int item) 
{
	if (action == MenuAction_Select) 
	{
		char cValue[128];
		GetMenuItem(menu, item, cValue, sizeof(cValue));
		
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		int id;
		if ((id = getNpcLoadedIdFromUniqueId(npcUniqueId)) == -1)
			return;
		
		strcopy(g_iNpcList[id].gType, 128, cValue);
		char updateTypeQuery[512];
		Format(updateTypeQuery, sizeof(updateTypeQuery), "UPDATE rp_props SET type = '%s' WHERE uniqueId = '%s'", cValue, g_iNpcList[id].gUniqueId);
		rp_GetDatabase().Query(SQLErrorCheckCallback, updateTypeQuery);
	}
	if (action == MenuAction_End) 
	{
		delete menu;
	}
}

public void onNpcInteract(int client, char uniqueId[128], int entIndex) 
{
	int id;
	if ((id = getNpcLoadedIdFromUniqueId(uniqueId)) == -1)
		return;
	
	char name[64];
	Entity_GetGlobalName(entIndex, STRING(name));
	
	if (!StrEqual(g_iNpcList[id].gSecondAnimation, "") && !g_iNpcList[id].gInAnimation) 
	{
		SetVariantString(g_iNpcList[id].gSecondAnimation);
		AcceptEntityInput(entIndex, "SetAnimation");
		CreateTimer(2.0, setIdleAnimation, EntIndexToEntRef(entIndex));
		g_iNpcList[id].gInAnimation = true;
	}
}

public Action setIdleAnimation(Handle Timer, int entRef) 
{
	int ent = EntRefToEntIndex(entRef);
	int id;
	if ((id = getNpcLoadedIdFromRef(entRef)) == -1)
		return;
	SetVariantString(g_iNpcList[id].gIdleAnimation);
	AcceptEntityInput(ent, "SetAnimation");
	g_iNpcList[id].gInAnimation = false;
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