#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <multicolors>
#include <roleplay>
#include <rp_npc_core>

#define MAX_NPCS 512
#define MAX_TYPES 64
#define _PREFIX_	"{red}[{green}Revolution{red}]{default}"

#pragma newdecls required

char dbconfig[] = "roleplay";
Database g_DB;

int g_iPlayerPrevButtons[MAXPLAYERS + 1];

int g_iLoadedTypes = 0;
char g_cNpcTypes[MAX_TYPES][128];

enum GlobalNpcProperties {
	gRefId, 
	String:gUniqueId[128], 
	String:gName[256], 
	String:gType[128], 
	String:gIdleAnimation[256], 
	String:gSecondAnimation[256], 
	String:gThirdAnimation[256], 
	bool:gEnabled, 
	bool:gInAnimation
}

int g_iNpcId = 0;
int g_iNpcList[MAX_NPCS][GlobalNpcProperties];

enum NpcEdit {
	nNpcId, 
	bool:nWaitingForModelName, 
	bool:nWaitingForIdleAnimationName, 
	bool:nWaitingForName
}

int g_eNpcEdit[MAXPLAYERS + 1][NpcEdit];

Handle g_hOnNpcInteract;

public Plugin myinfo = 
{
	name = "[Roleplay] Système PNJ", 
	author = "Benito", 
	description = "Spawn les PNJ Configuré en jeu après redemarrage du serveur", 
	version = "1.0",
	url = "www.revolution-asso.eu"
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		RegConsoleCmd("sm_npc", cmdSpawnNpc, "Spawn a NPC");
		RegConsoleCmd("sm_editnpc", cmdEditNpc, "Edits an NPC");	
		RegConsoleCmd("say", chatHook);	
		NpcTypesJobs();
		HookEvent("round_start", onRoundStart);	
		Database.Connect(GotDatabase, dbconfig);
	}	
	else
		UnloadPlugin();
}

void NpcTypesJobs()
{
	npc_registerNpcType("Police");
	npc_registerNpcType("Armurerie");
	npc_registerNpcType("Tabac");
	npc_registerNpcType("Hôpital");
	npc_registerNpcType("Marché Noir");
	npc_registerNpcType("Banque");
	npc_registerNpcType("Tabac-Skin");
	npc_registerNpcType("Concessionnaire");
	npc_registerNpcType("Technicien");
	npc_registerNpcType("Pôle Emploi");
	npc_registerNpcType("MacDonald's");
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
		Format(createTableQuery, sizeof(createTableQuery), 
		  "CREATE TABLE IF NOT EXISTS `rp_npcs` ( \
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
		
		g_DB.Query(SQLErrorCheckCallback, createTableQuery);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	/*
		Registers a new Npc Type
		
		@Param1 -> char NpcType[128]
		
		@return loaded Slot
	*/
	CreateNative("npc_registerNpcType", Native_RegisterNpcType);
	
	/*
		Forward when a Client interacted with an NPC
		
		@Param1 -> int client
		@Param2 -> char NpcType[64]
		@Param3 -> char UniqueId[128]
		@Param4 -> int Ent index
		
		@return -
	*/
	g_hOnNpcInteract = CreateGlobalForward("OnNpcInteract", ET_Ignore, Param_Cell, Param_String, Param_String, Param_Cell);
}

public int Native_RegisterNpcType(Handle plugin, int numParams) {
	if (g_iLoadedTypes > MAX_TYPES)
		return -1;
	
	char temptype[128];
	GetNativeString(1, temptype, 128);
	if (typeExists(temptype))
		return -1;
	strcopy(g_cNpcTypes[g_iLoadedTypes], 128, temptype);
	g_iLoadedTypes++;
	return (g_iLoadedTypes - 1);
}

public bool typeExists(char type[128]) {
	for (int i = 0; i < g_iLoadedTypes; i++)
	if (StrEqual(g_cNpcTypes[i], type))
		return true;
	return false;
}

public void resetNpcEdit(int client) {
	g_eNpcEdit[client][nNpcId] = -1;
	g_eNpcEdit[client][nWaitingForModelName] = false;
}

public Action cmdEditNpc(int client, int args) {
	int TargetObject = GetTargetBlock(client);
	if (TargetObject == -1) {
		ReplyToCommand(client, "Invalid target");
		return Plugin_Handled;
	}
	
	g_eNpcEdit[client][nNpcId] = TargetObject;
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(editMenuHandler);
	char menuTitle[255];
	char entityName[256];
	Entity_GetGlobalName(TargetObject, entityName, sizeof(entityName));
	Format(menuTitle, sizeof(menuTitle), "Modification en cours (%s)", entityName);
	menu.SetTitle(menuTitle);
	menu.AddItem("model", "Modifier le modèle");
	menu.AddItem("idleAnimation", "Modifier l'animation de standby");
	menu.AddItem("position", "Modifier la position");
	menu.AddItem("angles", "Modifier les angles");
	menu.AddItem("name", "Modifier le nom");
	menu.AddItem("type", "Paramétrage JOB");
	menu.AddItem("base", "Modifier les propriétés");
	menu.AddItem("delete", "Supprimer le P.N.J");
	menu.Display(client, 60);
	
	
	return Plugin_Handled;
}

public int editMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char cValue[32];
		menu.GetItem(item, cValue, sizeof(cValue));
		if (StrEqual(cValue, "model")) {
			g_eNpcEdit[client][nWaitingForModelName] = true;
			PrintToChat(client, "Enter the new Model Name OR 'abort' to cancel");
		} else if (StrEqual(cValue, "idleAnimation")) {
			g_eNpcEdit[client][nWaitingForIdleAnimationName] = true;
			PrintToChat(client, "Enter the new Idle Animation Name OR 'abort' to cancel");
		} else if (StrEqual(cValue, "position")) {
			openPositionMenu(client);
		} else if (StrEqual(cValue, "angles")) {
			openAnglesMenu(client);
		} else if (StrEqual(cValue, "base")) {
			openBasePropertyMenu(client);
		} else if (StrEqual(cValue, "delete")) {
			char npcUniqueId[128];
			GetEntPropString(g_eNpcEdit[client][nNpcId], Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
			
			char removeNpcQuery[512];
			Format(removeNpcQuery, sizeof(removeNpcQuery), "DELETE FROM rp_npcs WHERE uniqueId = '%s'", npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, removeNpcQuery);
			if (IsValidEntity(g_eNpcEdit[client][nNpcId]))
				AcceptEntityInput(g_eNpcEdit[client][nNpcId], "kill");
		} else if (StrEqual(cValue, "name")) {
			g_eNpcEdit[client][nWaitingForName] = true;
			PrintToChat(client, "Enter the new Name OR 'abort' to cancel");
		} else if (StrEqual(cValue, "type")) {
			openTypeMenu(client);
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
	Entity_GetGlobalName(g_eNpcEdit[client][nNpcId], entityName, sizeof(entityName));
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
		GetEntPropString(g_eNpcEdit[client][nNpcId], Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		menu.GetItem(item, cValue, sizeof(cValue));
		if (StrEqual(cValue, "up")) {
			GetEntPropVector(g_eNpcEdit[client][nNpcId], Prop_Data, "m_vecOrigin", pos);
			pos[2] += 10;
			TeleportEntity(g_eNpcEdit[client][nNpcId], pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_npcs SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "down")) {
			GetEntPropVector(g_eNpcEdit[client][nNpcId], Prop_Data, "m_vecOrigin", pos);
			pos[2] -= 10;
			TeleportEntity(g_eNpcEdit[client][nNpcId], pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_npcs SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "ground")) {
			GetEntPropVector(g_eNpcEdit[client][nNpcId], Prop_Data, "m_vecOrigin", pos);
			pos[2] -= GetClientDistanceToGround(client);
			TeleportEntity(g_eNpcEdit[client][nNpcId], pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_npcs SET pos_z = '%.2f' WHERE uniqueId = '%s'", pos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "tpYourself")) {
			float selfPos[3];
			GetClientAbsOrigin(client, selfPos);
			TeleportEntity(g_eNpcEdit[client][nNpcId], selfPos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_npcs SET pos_x = '%.2f' WHERE uniqueId = '%s'", selfPos[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_npcs SET pos_y = '%.2f' WHERE uniqueId = '%s'", selfPos[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_npcs SET pos_z = '%.2f' WHERE uniqueId = '%s'", selfPos[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "xPlus")) {
			GetEntPropVector(g_eNpcEdit[client][nNpcId], Prop_Data, "m_vecOrigin", pos);
			pos[0] += 10;
			TeleportEntity(g_eNpcEdit[client][nNpcId], pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_npcs SET pos_x = '%.2f' WHERE uniqueId = '%s'", pos[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "xMinus")) {
			GetEntPropVector(g_eNpcEdit[client][nNpcId], Prop_Data, "m_vecOrigin", pos);
			pos[0] -= 10;
			TeleportEntity(g_eNpcEdit[client][nNpcId], pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_npcs SET pos_x = '%.2f' WHERE uniqueId = '%s'", pos[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "yPlus")) {
			GetEntPropVector(g_eNpcEdit[client][nNpcId], Prop_Data, "m_vecOrigin", pos);
			pos[1] += 10;
			TeleportEntity(g_eNpcEdit[client][nNpcId], pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_npcs SET pos_y = '%.2f' WHERE uniqueId = '%s'", pos[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updatePositionQuery);
		} else if (StrEqual(cValue, "yMinus")) {
			GetEntPropVector(g_eNpcEdit[client][nNpcId], Prop_Data, "m_vecOrigin", pos);
			pos[1] -= 10;
			TeleportEntity(g_eNpcEdit[client][nNpcId], pos, NULL_VECTOR, NULL_VECTOR);
			openPositionMenu(client);
			char updatePositionQuery[512];
			Format(updatePositionQuery, sizeof(updatePositionQuery), "UPDATE rp_npcs SET pos_y = '%.2f' WHERE uniqueId = '%s'", pos[1], npcUniqueId);
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
	Entity_GetGlobalName(g_eNpcEdit[client][nNpcId], entityName, sizeof(entityName));
	Format(menuTitle, sizeof(menuTitle), "Edit Angles of %s", entityName);
	menu.SetTitle(menuTitle);
	menu.AddItem("yourself", "Set Your Angles");
	menu.AddItem("yourselfInverted", "Set Your Inverted Angles");
	menu.AddItem("minus", "Add Angles");
	menu.AddItem("plus", "Move Down");
	menu.Display(client, 60);
}

public int editAnglesMenuHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char cValue[32];
		float angles[3];
		char npcUniqueId[128];
		if (g_eNpcEdit[client][nNpcId] == -1)
			return;
		GetEntPropString(g_eNpcEdit[client][nNpcId], Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		menu.GetItem(item, cValue, sizeof(cValue));
		if (StrEqual(cValue, "plus")) {
			GetEntPropVector(g_eNpcEdit[client][nNpcId], Prop_Data, "m_angRotation", angles);
			angles[1] += 5;
			TeleportEntity(g_eNpcEdit[client][nNpcId], NULL_VECTOR, angles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_npcs SET angle_y = '%.2f' WHERE uniqueId = '%s'", angles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		} else if (StrEqual(cValue, "minus")) {
			GetEntPropVector(g_eNpcEdit[client][nNpcId], Prop_Data, "m_angRotation", angles);
			angles[1] -= 5;
			TeleportEntity(g_eNpcEdit[client][nNpcId], NULL_VECTOR, angles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_npcs SET angle_y = '%.2f' WHERE uniqueId = '%s'", angles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		} else if (StrEqual(cValue, "yourself")) {
			float selfAngles[3];
			GetClientAbsAngles(client, selfAngles);
			TeleportEntity(g_eNpcEdit[client][nNpcId], NULL_VECTOR, selfAngles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_npcs SET angle_x = '%.2f' WHERE uniqueId = '%s'", selfAngles[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_npcs SET angle_y = '%.2f' WHERE uniqueId = '%s'", selfAngles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_npcs SET angle_z = '%.2f' WHERE uniqueId = '%s'", selfAngles[2], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
		} else if (StrEqual(cValue, "yourselfInverted")) {
			float selfAngles[3];
			GetClientAbsAngles(client, selfAngles);
			selfAngles[1] = 180 - selfAngles[1];
			TeleportEntity(g_eNpcEdit[client][nNpcId], NULL_VECTOR, selfAngles, NULL_VECTOR);
			openAnglesMenu(client);
			char updateAnglesQuery[512];
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_npcs SET angle_x = '%.2f' WHERE uniqueId = '%s'", selfAngles[0], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_npcs SET angle_y = '%.2f' WHERE uniqueId = '%s'", selfAngles[1], npcUniqueId);
			g_DB.Query(SQLErrorCheckCallback, updateAnglesQuery);
			Format(updateAnglesQuery, sizeof(updateAnglesQuery), "UPDATE rp_npcs SET angle_z = '%.2f' WHERE uniqueId = '%s'", selfAngles[2], npcUniqueId);
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
	Entity_GetGlobalName(g_eNpcEdit[client][nNpcId], entityName, sizeof(entityName));
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
			SetEntProp(g_eNpcEdit[client][nNpcId], Prop_Send, "m_nSolidType", 6);
			openBasePropertyMenu(client);
		} else if (StrEqual(cValue, "nonsolid")) {
			SetEntProp(g_eNpcEdit[client][nNpcId], Prop_Send, "m_nSolidType", 0);
			openBasePropertyMenu(client);
		}
	}
	if (action == MenuAction_End) {
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}
}

public Action cmdSpawnNpc(int client, int args) {
	int npc = CreateEntityByName("prop_dynamic");
	if (npc == -1) {
		PrintToChat(client, "[-T-] Can not spawn Npc - report this?");
		return Plugin_Handled;
	}
	
	g_iNpcList[g_iNpcId][gRefId] = EntIndexToEntRef(npc);
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
	strcopy(g_iNpcList[g_iNpcId][gUniqueId], 128, uniqueId);
	
	char mapName[128];
	GetCurrentMap(mapName, sizeof(mapName));
	
	char playerid[20];
	GetClientAuthId(client, AuthId_Steam2, playerid, sizeof(playerid));
	
	char createdBy[128];
	Format(createdBy, sizeof(createdBy), "%s %N", playerid, client);
	
	char insertNpcQuery[4096];
	Format(insertNpcQuery, sizeof(insertNpcQuery), "INSERT INTO `rp_npcs` (`id`, `uniqueId`, `name`, `map`, `model`, `idle_animation`, `second_animation`, `third_animation`, `pos_x`, `pos_y`, `pos_z`, `angle_x`, `angle_y`, `angle_z`, `type`, `flags`, `special_flags`, `enabled`, `created_by`, `timestamp`) VALUES (NULL, '%s', '', '%s', 'models/characters/hostage_01.mdl', 'idle_subtle', '', '', '%.2f', '%.2f', '%.2f', '%.2f', '%.2f', '%.2f', 'normal', '', '', '1', '%s', CURRENT_TIMESTAMP);", uniqueId, mapName, pos[0], pos[1], pos[2], angles[0], angles[1], angles[2], createdBy);
	g_DB.Query(SQLErrorCheckCallback, insertNpcQuery);
	
	
	CreateNpc(uniqueId, "", "models/characters/hostage_01.mdl", "idle_subtle", "Wave", "", pos, angles, "normal", "", "", true);
	
	//g_iNpcId++;
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon, int &tickcount)
{
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		if (!(g_iPlayerPrevButtons[client] & IN_USE) && iButtons & IN_USE) {
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
	
	if (g_eNpcEdit[client][nWaitingForModelName] && StrContains(text, "abort") == -1) {
		PrecacheModel(text, true);
		SetEntityModel(g_eNpcEdit[client][nNpcId], text);
		char entityName[256];
		Entity_GetGlobalName(g_eNpcEdit[client][nNpcId], entityName, sizeof(entityName));
		PrintToChat(client, "Set Model of %s TO %s", entityName, text);
		g_eNpcEdit[client][nWaitingForModelName] = false;
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client][nNpcId], Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		char updateModelQuery[512];
		Format(updateModelQuery, sizeof(updateModelQuery), "UPDATE rp_npcs SET model = '%s' WHERE uniqueId = '%s'", text, npcUniqueId);
		g_DB.Query(SQLErrorCheckCallback, updateModelQuery);
		return Plugin_Handled;
	} else if (g_eNpcEdit[client][nWaitingForIdleAnimationName] && StrContains(text, "abort") == -1) {
		SetVariantString(text);
		AcceptEntityInput(g_eNpcEdit[client][nNpcId], "SetAnimation");
		strcopy(g_iNpcList[g_iNpcId][gIdleAnimation], 256, text);
		char entityName[256];
		Entity_GetGlobalName(g_eNpcEdit[client][nNpcId], entityName, sizeof(entityName));
		PrintToChat(client, "Set Idle Animation of %s TO %s", entityName, text);
		g_eNpcEdit[client][nWaitingForIdleAnimationName] = false;
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client][nNpcId], Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		char updateAnimationQuery[512];
		Format(updateAnimationQuery, sizeof(updateAnimationQuery), "UPDATE rp_npcs SET idle_animation = '%s' WHERE uniqueId = '%s'", text, npcUniqueId);
		g_DB.Query(SQLErrorCheckCallback, updateAnimationQuery);
		return Plugin_Handled;
	} else if (g_eNpcEdit[client][nWaitingForName] && StrContains(text, "abort") == -1) {
		SetVariantString(text);
		char entityName[256];
		Format(entityName, sizeof(entityName), "%s", text);
		Entity_SetGlobalName(g_eNpcEdit[client][nNpcId], entityName, sizeof(entityName));
		PrintToChat(client, "Set Name of %s TO %s", entityName, text);
		g_eNpcEdit[client][nWaitingForName] = false;
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client][nNpcId], Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		char updateNameQuery[512];
		Format(updateNameQuery, sizeof(updateNameQuery), "UPDATE rp_npcs SET name = '%s' WHERE uniqueId = '%s'", text, npcUniqueId);
		g_DB.Query(SQLErrorCheckCallback, updateNameQuery);
		strcopy(g_iNpcList[nNpcId][gName], 128, text);
		return Plugin_Handled;
	} else if ((g_eNpcEdit[client][nWaitingForModelName] || g_eNpcEdit[client][nWaitingForIdleAnimationName] || g_eNpcEdit[client][nWaitingForName]) && StrContains(text, "abort") != -1) {
		g_eNpcEdit[client][nWaitingForModelName] = false;
		g_eNpcEdit[client][nWaitingForIdleAnimationName] = false;
		g_eNpcEdit[client][nWaitingForName] = false;
		PrintToChat(client, "Aborted.");
		return Plugin_Handled;
	}
	
	
	return Plugin_Continue;
}

public float GetClientDistanceToGround(int client) {
	
	float fOrigin[3];
	float fGround[3];
	GetEntPropVector(g_eNpcEdit[client][nNpcId], Prop_Data, "m_vecOrigin", fOrigin);
	
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
	loadNpcs();
}	

public void onRoundStart(Event event, const char[] name, bool dontBroadcast) {
	g_iNpcId = 0;
	loadNpcs();
}

public void loadNpcs() {
	char mapName[128];
	GetCurrentMap(mapName, sizeof(mapName));
	
	char loadNpcsQuery[1024];
	Format(loadNpcsQuery, sizeof(loadNpcsQuery), "SELECT * FROM rp_npcs WHERE map = '%s';", mapName);
	g_DB.Query(loadNpcsQueryCallback, loadNpcsQuery);
}


public void loadNpcsQueryCallback(Database db, DBResultSet Results, const char[] error, any data) {
	while (Results.FetchRow()) {
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
		SQL_FetchStringByName(Results, "uniqueId", uniqueId, sizeof(uniqueId));
		SQL_FetchStringByName(Results, "name", name, sizeof(name));
		SQL_FetchStringByName(Results, "model", model, sizeof(model));
		SQL_FetchStringByName(Results, "idle_animation", idle_animation, sizeof(idle_animation));
		SQL_FetchStringByName(Results, "second_animation", second_animation, sizeof(second_animation));
		SQL_FetchStringByName(Results, "third_animation", third_animation, sizeof(third_animation));
		pos[0] = SQL_FetchFloatByName(Results, "pos_x");
		pos[1] = SQL_FetchFloatByName(Results, "pos_y");
		pos[2] = SQL_FetchFloatByName(Results, "pos_z");
		angles[0] = SQL_FetchFloatByName(Results, "angle_x");
		angles[1] = SQL_FetchFloatByName(Results, "angle_y");
		angles[2] = SQL_FetchFloatByName(Results, "angle_z");
		SQL_FetchStringByName(Results, "type", type, sizeof(type));
		SQL_FetchStringByName(Results, "flags", flags, sizeof(flags));
		SQL_FetchStringByName(Results, "special_flags", special_flags, sizeof(special_flags));
		enabled = SQL_FetchIntByName(Results, "enabled") == 1;
		
		CreateNpc(uniqueId, name, model, idle_animation, second_animation, third_animation, pos, angles, type, flags, special_flags, enabled);
	}
}

public void CreateNpc(char uniqueId[128], char name[64], char model[256], char idle_animation[256], char second_animation[256], char third_animation[256], float pos[3], float angles[3], char type[256], char flags[256], char special_flags[256], bool enabled) {
	if (!enabled)
		return;
	PrecacheModel(model, true);
	
	int npc = CreateEntityByName("prop_dynamic");
	if (npc == -1)
		return;
	
	g_iNpcList[g_iNpcId][gRefId] = EntIndexToEntRef(npc);
	
	DispatchKeyValue(npc, "disablebonefollowers", "1");
	if (!DispatchKeyValue(npc, "solid", "2"))PrintToChatAll("Box Failed");
	DispatchKeyValue(npc, "model", model);
	
	SetEntProp(npc, Prop_Send, "m_nSolidType", 2);
	SetEntProp(npc, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
	//SetEntPropFloat(npc, Prop_Send, "m_flModelScale", 3.0);
	
	DispatchSpawn(npc);
	
	SetEntPropString(npc, Prop_Data, "m_iName", uniqueId);
	
	TeleportEntity(npc, pos, angles, NULL_VECTOR);
	
	strcopy(g_iNpcList[g_iNpcId][gUniqueId], 128, uniqueId);
	strcopy(g_iNpcList[g_iNpcId][gName], 128, name);
	strcopy(g_iNpcList[g_iNpcId][gType], 128, type);
	strcopy(g_iNpcList[g_iNpcId][gIdleAnimation], 256, idle_animation);
	strcopy(g_iNpcList[g_iNpcId][gSecondAnimation], 256, second_animation);
	strcopy(g_iNpcList[g_iNpcId][gThirdAnimation], 256, third_animation);
	
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

public void openTypeMenu(int client) {
	Menu menu = new Menu(typeChooserHandler);
	menu.SetTitle("Set Type for this Npc");
	for (int i = 0; i < g_iLoadedTypes; i++) {
		char typeName[128];
		strcopy(typeName, sizeof(typeName), g_cNpcTypes[i]);
		menu.AddItem(typeName, typeName);
	}
	menu.Display(client, 60);
}

public int typeChooserHandler(Menu menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char cValue[128];
		menu.GetItem(item, cValue, sizeof(cValue));
		
		char npcUniqueId[128];
		GetEntPropString(g_eNpcEdit[client][nNpcId], Prop_Data, "m_iName", npcUniqueId, sizeof(npcUniqueId));
		int id;
		if ((id = getNpcLoadedIdFromUniqueId(npcUniqueId)) == -1)
			return;
		
		strcopy(g_iNpcList[id][gType], 128, cValue);
		char updateTypeQuery[512];
		Format(updateTypeQuery, sizeof(updateTypeQuery), "UPDATE rp_npcs SET type = '%s' WHERE uniqueId = '%s'", cValue, g_iNpcList[id][gUniqueId]);
		g_DB.Query(SQLErrorCheckCallback, updateTypeQuery);
	}
	if (action == MenuAction_End) {
		delete menu;
	}
}

public void onNpcInteract(int client, char uniqueId[128], int entIndex) {
	int id;
	if ((id = getNpcLoadedIdFromUniqueId(uniqueId)) == -1)
		return;
	
	char name[64], playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, playername, sizeof(playername));
	Entity_GetGlobalName(entIndex, name, sizeof(name));
	if (!StrEqual(g_iNpcList[id][gType], "") && !StrEqual(g_iNpcList[id][gType], "normal"))
		CPrintToChat(client, "%s {orange}Salut %s ! {green}Bienvenu{purple}(%s){green}.", _PREFIX_, playername, g_iNpcList[id][gType]);
	else {
		CPrintToChat(client, "%s l'npc %s... n'as pas été configuré (Npc: %i)", _PREFIX_, name, id);
		if (CheckCommandAccess(client, "sm_pedo", ADMFLAG_ROOT, true))
			cmdEditNpc(client, 0);
	}
	
	if (!StrEqual(g_iNpcList[id][gSecondAnimation], "") && !g_iNpcList[id][gInAnimation]) {
		SetVariantString(g_iNpcList[id][gSecondAnimation]);
		AcceptEntityInput(entIndex, "SetAnimation");
		CreateTimer(2.0, setIdleAnimation, EntIndexToEntRef(entIndex));
		g_iNpcList[id][gInAnimation] = true;
	}
	
	Call_StartForward(g_hOnNpcInteract);
	Call_PushCell(client);
	Call_PushString(g_iNpcList[id][gType]);
	Call_PushString(g_iNpcList[id][gUniqueId]);
	Call_PushCell(entIndex);
	Call_Finish();
}

public Action setIdleAnimation(Handle Timer, int entRef) {
	int ent = EntRefToEntIndex(entRef);
	int id;
	if ((id = getNpcLoadedIdFromRef(entRef)) == -1)
		return;
	SetVariantString(g_iNpcList[id][gIdleAnimation]);
	AcceptEntityInput(ent, "SetAnimation");
	g_iNpcList[id][gInAnimation] = false;
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

