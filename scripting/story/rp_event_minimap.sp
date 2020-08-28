/*
							T-RP
   			Copyright (C) 2017 Christian Ziegler
   				 
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <multicolors>
#include <roleplay>

#define MAX_PROPS 512
#define MaxEntities 2048
#define NAME "{red}[{lightblue}Roleplay{red}]{default}"

#pragma newdecls required

char dbconfig[] = "roleplay";
Database g_DB;

char eventNameDB[64];

enum struct GlobalNpcProperties {
	int gRefId;
	char gUniqueId[128];
	char gName[256];
}

int g_iNpcId = 0;
GlobalNpcProperties g_iNpcList[MAX_PROPS];

enum struct NpcEdit {
	int nNpcId;
	bool nWaitingForModelName;
	bool nWaitingForIdleAnimationName;
	bool nWaitingForName;
}

NpcEdit g_eNpcEdit[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[Roleplay] Minimap", 
	author = "Benito", 
	description = "Spawn une minimap préconfigurée selon l'event", 
	version = VERSION,
	url = "www.revolution-team.be"
};

public void OnPluginStart()
{
	RegConsoleCmd("rp_minimap", Cmd_SpawnProp);
	RegConsoleCmd("rp_editminimap", Cmd_EditProp);
	
	RegConsoleCmd("say", chatHook);
	
	HookEvent("round_start", onRoundStart);
	
	Database.Connect(GotDatabase, dbconfig);
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
		  "CREATE TABLE IF NOT EXISTS `rp_minimap` ( \
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
		  `created_by` varchar(128) COLLATE utf8_bin NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`id`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		
		g_DB.Query(SQLErrorCheckCallback, createTableQuery);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("rp_InitEventMinimap", InitEventMinimap);
}

public int InitEventMinimap(Handle plugin, int numParams) 
{
	char eventtype[64];
	GetNativeString(1, eventtype, sizeof(eventtype));
	
	LoadProps(eventtype);
}

public void LoadProps(char eventName[64]) {
	char mapName[128], mapPart[3][64];
	GetCurrentMap(mapName, sizeof(mapName));
	ExplodeString(mapName, "/", mapPart, 3, 64);
	
	char LoadPropsQuery[1024];
	Format(LoadPropsQuery, sizeof(LoadPropsQuery), "SELECT * FROM rp_minimap WHERE map = '%s' AND name = '%s';", mapPart[2], eventName);
	g_DB.Query(LoadPropsQueryCallback, LoadPropsQuery);
}


public void LoadPropsQueryCallback(Database db, DBResultSet Results, const char[] error, any data) {
	while (Results.FetchRow()) {
		char name[64];
		SQL_FetchStringByName(Results, "name", name, sizeof(name));
		
		char model[256];
		SQL_FetchStringByName(Results, "model", model, sizeof(model));
		
		char uniqueId[128];
		SQL_FetchStringByName(Results, "uniqueId", uniqueId, sizeof(uniqueId));
		
		float pos[3];
		pos[0] = SQL_FetchFloatByName(Results, "pos_x");
		pos[1] = SQL_FetchFloatByName(Results, "pos_y");
		pos[2] = SQL_FetchFloatByName(Results, "pos_z");
		
		float angles[3];
		angles[0] = SQL_FetchFloatByName(Results, "angle_x");
		angles[1] = SQL_FetchFloatByName(Results, "angle_y");
		angles[2] = SQL_FetchFloatByName(Results, "angle_z");
		
		CreateNpc(uniqueId, name, model, pos, angles);
	}
}

public void resetNpcEdit(int client) {
	g_eNpcEdit[client].nNpcId = -1;
}

public Action Cmd_EditProp(int client, int args) {
	int TargetObject = GetTargetBlock(client);
	if (TargetObject == -1) {
		ReplyToCommand(client, "Invalid target");
		return Plugin_Handled;
	}
	
	g_eNpcEdit[client].nNpcId = TargetObject;
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(editMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(TargetObject, entityName, sizeof(entityName));
	Format(menuTitle, sizeof(menuTitle), "Modification en cours (%s)", entityName);
	menu.SetTitle(menuTitle);
	menu.AddItem("position", "Modifier la position");
	menu.AddItem("angles", "Modifier les angles");
	menu.AddItem("name", "Modifier le nom");
	menu.AddItem("base", "Modifier les propriétés");
	menu.AddItem("save", "Sauvegarder le prop dans la BDD");
	menu.AddItem("delete", "Supprimer le prop");
	menu.Display(client, 60);
	
	
	return Plugin_Handled;
}

public int editMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char cValue[32];
		menu.GetItem(item, cValue, sizeof(cValue));
		if (StrEqual(cValue, "position")) {
			openPositionMenu(client);
		} else if (StrEqual(cValue, "angles")) {
			openAnglesMenu(client);
		} else if (StrEqual(cValue, "base")) {
			openBasePropertyMenu(client);
		} else if (StrEqual(cValue, "delete")) {
			char npcUniqueId[128];
			GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
			
			char removeNpcQuery[512];
			Format(removeNpcQuery, sizeof(removeNpcQuery), "DELETE FROM rp_minimap WHERE uniqueId = '%s'", npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, removeNpcQuery);
			if (IsValidEntity(g_eNpcEdit[client].nNpcId))
				AcceptEntityInput(g_eNpcEdit[client].nNpcId, "kill");
		} else if (StrEqual(cValue, "name")) {
			g_eNpcEdit[client].nWaitingForName = true;
			PrintToChat(client, "Enter the new Name OR 'abort' to cancel");
		} 
		else if (StrEqual(cValue, "save")) 
		{
			for (int i = MaxClients; i <= MaxEntities; i++)
			{
				if (IsValidEntity(i))
				{
					char entName[64];
					Entity_GetName(i, entName, sizeof(entName));
					
					if(StrContains(entName, "prop;") != -1)
					{
						char modelName[256];
						GetEntPropString(i, Prop_Data, "m_ModelName", modelName, 256);
						
						int npc = CreateEntityByName("prop_dynamic_override");
			
						g_iNpcList[g_iNpcId].gRefId = EntIndexToEntRef(npc);
						
						float pos[3];
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
						
						float angles[3];
						GetEntPropVector(i, Prop_Data, "m_angRotation", angles); 
						
						char uniqueId[128];
						int uniqueIdTime = GetTime();
						IntToString(GetRandomInt(1, MaxEntities), uniqueId, sizeof(uniqueId));
						
						char mapName[128], mapPart[3][64];
						GetCurrentMap(mapName, sizeof(mapName));
						ExplodeString(mapName, "/", mapPart, 3, 64);
						
						char playerid[20];
						GetClientAuthId(client, AuthId_Steam2, playerid, sizeof(playerid));
						
						char createdBy[128];
						Format(createdBy, sizeof(createdBy), "%s %N", playerid, client);
						
						char insertNpcQuery[4096];
						Format(insertNpcQuery, sizeof(insertNpcQuery), "INSERT INTO `rp_minimap` (`id`, `uniqueId`, `name`, `map`, `model`, `pos_x`, `pos_y`, `pos_z`, `angle_x`, `angle_y`, `angle_z`, `created_by`, `timestamp`) VALUES (NULL, '%s', '%s', '%s', '%s', '%.2f', '%.2f', '%.2f', '%.2f', '%.2f', '%.2f', '%s', CURRENT_TIMESTAMP);", entName, eventNameDB, mapPart[2], modelName, pos[0], pos[1], pos[2], angles[0], angles[1], angles[2], createdBy);
						PrintToServer(insertNpcQuery);
						CPrintToChat(client, insertNpcQuery);
						g_DB.Query(SQLErrorCheckCallback, insertNpcQuery);
					}	
				}	
			}	
		}
	}
	if (action == MenuAction_End) {
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

public void openPositionMenu(int client) {
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(editPositionMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(g_eNpcEdit[client].nNpcId, entityName, sizeof(entityName));
	Format(menuTitle, sizeof(menuTitle), "Edit Position of %s", entityName);
	menu.SetTitle(menuTitle);
	menu.AddItem("up", "Move Up");
	menu.AddItem("down", "Move Down");
	menu.AddItem("xPlus", "Move X Plus");
	menu.AddItem("xMinus", "Move X Minus");
	menu.AddItem("yPlus", "Move Y Plus");
	menu.AddItem("yMinus", "Move Y Minus");
	menu.AddItem("ground", "Put on Ground");
	menu.AddItem("tpYourself", "Teleport to yourself");
	menu.Display(client, 60);
}

public int editPositionMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char cValue[32];
		float pos[3];
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		menu.GetItem(item, cValue, sizeof(cValue));
		if (StrEqual(cValue, "up")) {
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[2] += 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_minimap SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "down")) {
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[2] -= 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_minimap SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "ground")) {
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[2] -= GetClientDistanceToGround(client);
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_minimap SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "tpYourself")) {
			float selfPos[3];
			GetClientAbsOrigin(client, selfPos);
			TeleportEntity(g_eNpcEdit[client].nNpcId, selfPos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_minimap SET pos_x = '%.2f' WHERE uniqueId = '%s'", selfPos[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_minimap SET pos_y = '%.2f' WHERE uniqueId = '%s'", selfPos[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_minimap SET pos_z = '%.2f' WHERE uniqueId = '%s'", selfPos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "xPlus")) {
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[0] += 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_minimap SET pos_x = '%.2f' WHERE uniqueId = '%s'", pos[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "xMinus")) {
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[0] -= 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_minimap SET pos_x = '%.2f' WHERE uniqueId = '%s'", pos[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "yPlus")) {
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[1] += 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_minimap SET pos_y = '%.2f' WHERE uniqueId = '%s'", pos[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "yMinus")) {
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_vecOrigin", pos);
			pos[1] -= 10;
			TeleportEntity(g_eNpcEdit[client].nNpcId, pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_minimap SET pos_y = '%.2f' WHERE uniqueId = '%s'", pos[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		}
	}
	if (action == MenuAction_End) {
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

public void openAnglesMenu(int client) {
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(editAnglesMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(g_eNpcEdit[client].nNpcId, entityName, sizeof(entityName));
	Format(menuTitle, sizeof(menuTitle), "Editer les angles de %s", entityName);
	menu.SetTitle(menuTitle);
	menu.AddItem("yourself", "Définir votre angle");
	menu.AddItem("yourselfInverted", "Définir votre angle contraire");
	menu.AddItem("minus", "Rajouter de l'angle");
	menu.AddItem("plus", "Retirer de l'angle");
	menu.Display(client, 60);
}

public int editAnglesMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char cValue[32];
		float angles[3];
		char npcUniqueId[128];
		if (g_eNpcEdit[client].nNpcId == -1)
			return;
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		menu.GetItem(item, cValue, sizeof(cValue));
		if (StrEqual(cValue, "plus")) {
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_angRotation", angles);
			angles[1] += 5;
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, angles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_minimap SET angle_y = '%.2f' WHERE uniqueId = '%s'", angles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		} else if (StrEqual(cValue, "minus")) {
			GetEntPropVector(g_eNpcEdit[client].nNpcId, Prop_Data, "m_angRotation", angles);
			angles[1] -= 5;
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, angles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_minimap SET angle_y = '%.2f' WHERE uniqueId = '%s'", angles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		} else if (StrEqual(cValue, "yourself")) {
			float selfAngles[3];
			GetClientAbsAngles(client, selfAngles);
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, selfAngles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_minimap SET angle_x = '%.2f' WHERE uniqueId = '%s'", selfAngles[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_minimap SET angle_y = '%.2f' WHERE uniqueId = '%s'", selfAngles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_minimap SET angle_z = '%.2f' WHERE uniqueId = '%s'", selfAngles[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		} else if (StrEqual(cValue, "yourselfInverted")) {
			float selfAngles[3];
			GetClientAbsAngles(client, selfAngles);
			selfAngles[1] = 180 - selfAngles[1];
			TeleportEntity(g_eNpcEdit[client].nNpcId, NULL_VECTOR, selfAngles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_minimap SET angle_x = '%.2f' WHERE uniqueId = '%s'", selfAngles[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_minimap SET angle_y = '%.2f' WHERE uniqueId = '%s'", selfAngles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_minimap SET angle_z = '%.2f' WHERE uniqueId = '%s'", selfAngles[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		}
	}
	if (action == MenuAction_End) {
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

public void openBasePropertyMenu(int client) {
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(editBasePropertyMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(g_eNpcEdit[client].nNpcId, entityName, sizeof(entityName));
	Format(menuTitle, sizeof(menuTitle), "Edit Base Properties of %s", entityName);
	menu.SetTitle(menuTitle);
	menu.AddItem("solid", "Make NPC solid");
	menu.AddItem("nonsolid", "Make NPC non-solid");
	menu.Display(client, 60);
}

public int editBasePropertyMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char cValue[32];
		menu.GetItem(item, cValue, sizeof(cValue));
		if (StrEqual(cValue, "solid")) {
			SetEntProp(g_eNpcEdit[client].nNpcId, Prop_Send, "m_nSolidType", 6);
			openBasePropertyMenu(client);
		} else if (StrEqual(cValue, "nonsolid")) {
			SetEntProp(g_eNpcEdit[client].nNpcId, Prop_Send, "m_nSolidType", 0);
			openBasePropertyMenu(client);
		}
	}
	if (action == MenuAction_End) {
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

public Action Cmd_SpawnProp(int client, int args) 
{
	if(rp_GetClientInt(client, i_AdminLevel) > 2)
	{
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
		return Plugin_Handled;
	}
		
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu prop = new Menu(DoSpawnProp);	
	prop.SetTitle("Roleplay - MiniMap");	
	
	prop.AddItem("models/props/house.mdl", "Maison V1");
	prop.AddItem("models/props/guard_booth.mdl", "Maison V2");
	prop.AddItem("models/auditor/re4/house_re4.mdl", "Maison V3");
	prop.AddItem("models/housepack21/house19.mdl", "Maison V4");
	prop.AddItem("models/housepack21/house16.mdl", "Maison V5");
	prop.AddItem("models/housepack21/house14.mdl", "Maison V6");
	prop.AddItem("models/housepack21/house09.mdl", "Maison V7");
	prop.AddItem("models/props/buildings/hut.mdl", "Batiment V1");
	prop.AddItem("models/props/fences/brick_fence.mdl", "Murret en brique V1");
	//prop.AddItem("models/props/fences/part_of_the_fence.mdl", "Murret en brique V2");
	prop.AddItem("models/props/huts/hut_01.mdl", "Cabane V1");
	prop.AddItem("models/props/huts/hut_02.mdl", "Cabane V2");
	prop.AddItem("models/props/medium_bridge.mdl", "Pont");
	prop.AddItem("models/trees/pi_tree1.mdl", "Arbre V1");
	prop.AddItem("models/trees/pi_tree4.mdl", "Arbre V2");
	prop.AddItem("models/trees/pi_tree5.mdl", "Arbre V3");
	prop.AddItem("models/props_foliage/urban_tree_giant01_a.mdl", "Arbre V4");
	prop.AddItem("models/props_foliage/tree_pine_large.mdl", "Sapin");
	
	prop.ExitButton = true;
	prop.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int DoSpawnProp(Menu menu, MenuAction action, int client, int param) 
{
	if (action == MenuAction_Select)
	{
		char info[256];
		menu.GetItem(param, info, sizeof(info));
		
		FakeClientCommand(client, "rp_editminimap");
		int npc = CreateEntityByName("prop_dynamic_override");
	
		g_iNpcList[g_iNpcId].gRefId = EntIndexToEntRef(npc);
		float pos[3];
		GetClientAbsOrigin(client, pos);
		
		float angles[3];
		GetClientAbsAngles(client, angles);
		
		char uniqueId[128];
		int uniqueIdTime = GetTime();
		IntToString(uniqueIdTime, uniqueId, sizeof(uniqueId));
		strcopy(g_iNpcList[g_iNpcId].gUniqueId, 128, uniqueId);
		
		char mapName[128], mapPart[3][64];
		GetCurrentMap(mapName, sizeof(mapName));
		ExplodeString(mapName, "/", mapPart, 3, 64);
		
		char playerid[20];
		GetClientAuthId(client, AuthId_Steam2, playerid, sizeof(playerid));
		
		char createdBy[128];
		Format(createdBy, sizeof(createdBy), "%s %N", playerid, client);
		
		char insertNpcQuery[4096];
		Format(insertNpcQuery, sizeof(insertNpcQuery), "INSERT INTO `rp_minimap` (`id`, `uniqueId`, `name`, `map`, `model`, `pos_x`, `pos_y`, `pos_z`, `angle_x`, `angle_y`, `angle_z`, `created_by`, `timestamp`) VALUES (NULL, '%s', '', '%s', '%s', '%.2f', '%.2f', '%.2f', '%.2f', '%.2f', '%.2f', '%s', CURRENT_TIMESTAMP);", uniqueId, mapPart[2], info, pos[0], pos[1], pos[2], angles[0], angles[1], angles[2], createdBy);
		g_DB.Query(SQLErrorCheckCallback, insertNpcQuery);		
		
		CreateNpc(uniqueId, "", info, pos, angles);
	}
	if (action == MenuAction_End) 
	{
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

stock int GetTargetBlock(int client) {
	int entity = GetClientAimTarget(client, false);
	if (IsValidEntity(entity)) {
		char classname[32];
		GetEdictClassname(entity, classname, 32);
		
		if (StrContains(classname, "prop_dynamic") != -1)
			return entity;
	}
	return -1;
}

public Action chatHook(int client, int args) {
	char text[1024];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	
	if (g_eNpcEdit[client].nWaitingForName && StrContains(text, "abort") == -1) 
	{
		SetVariantString(text);
		char entityName[256];
		Format(entityName, sizeof(entityName), "%s", text);
		Entity_SetGlobalName(g_eNpcEdit[client].nNpcId, entityName, sizeof(entityName));
		Format(eventNameDB, sizeof(eventNameDB), "%s", text);
		PrintToChat(client, "Nom de %s défini en %s", entityName, eventNameDB);
		g_eNpcEdit[client].nWaitingForName = false;
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client].nNpcId, Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		char updateNameQuery[512];
		Format(updateNameQuery, sizeof(updateNameQuery), "UPDATE rp_props SET name = '%s' WHERE uniqueId = '%s'", text, npcUniqueId);
		g_DB.Query(SQLErrorCheckCallback, updateNameQuery);
		strcopy(g_iNpcList[g_iNpcId].gName, 128, text);
		return Plugin_Handled;
	} else if ((g_eNpcEdit[client].nWaitingForName) && StrContains(text, "abort") != -1) {
		g_eNpcEdit[client].nWaitingForName = false;
		PrintToChat(client, "Aborted.");
		return Plugin_Handled;
	}
	
	
	return Plugin_Continue;
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
}	

public void onRoundStart(Event event, const char[] name, bool dontBroadcast) {
	g_iNpcId = 0;
}

public void CreateNpc(char uniqueId[128], char name[64], char model[256], float pos[3], float angles[3]) 
{
	PrecacheModel(model, true);
	
	int npc = CreateEntityByName("prop_dynamic_override");
	if (npc == -1)
		return;
	
	g_iNpcList[g_iNpcId].gRefId = EntIndexToEntRef(npc);
	
	DispatchKeyValue(npc, "disablebonefollowers", "1");
	if (!DispatchKeyValue(npc, "solid", "2"))PrintToChatAll("Box Failed");
	DispatchKeyValue(npc, "model", model);
	
	SetEntProp(npc, Prop_Send, "m_nSolidType", SOLID_VPHYSICS);
	
	DispatchSpawn(npc);
	
	SetEntPropString(npc, Prop_Data, "m_iName", uniqueId);
	
	TeleportEntity(npc, pos, angles, NULL_VECTOR);
	
	strcopy(g_iNpcList[g_iNpcId].gUniqueId, 128, uniqueId);
	strcopy(g_iNpcList[g_iNpcId].gName, 128, name);
	
	char entityName[128];
	if (StrEqual(name, ""))
		Format(entityName, sizeof(entityName), "%i", g_iNpcId);
	else
		Format(entityName, sizeof(entityName), "%s", name);
	Entity_SetGlobalName(npc, entityName);
	g_iNpcId++;
}

stock int getNpcLoadedIdFromUniqueId(char uniqueId[128]) {
	for (int i = 0; i < g_iNpcId; i++) {
		if (StrEqual(g_iNpcList[i][gUniqueId], uniqueId))
			return i;
	}
	return -1;
}

stock int getNpcLoadedIdFromRef(int entRef) {
	for (int i = 0; i < g_iNpcId; i++) {
		if (g_iNpcList[i][gRefId] == entRef)
			return i;
	}
	return -1;
}

public void SQLErrorCheckCallback(Database db, DBResultSet Results, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}

