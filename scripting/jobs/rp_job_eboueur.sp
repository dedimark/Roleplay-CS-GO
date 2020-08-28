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
#include <sdktools>
#include <smlib>
#include <cstrike>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/***************************************************************************************

							P L U G I N  -  D E F I N E S

***************************************************************************************/
#define MAX_GARBAGE 1024
#define MAX_IN_GARBAGE 5

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
char logFile[PLATFORM_MAX_PATH];
char dbconfig[] = "roleplay";
char g_cTrash[3][64];
Database g_DB;
int g_iSpeedTimeLeft[MAXPLAYERS + 1];

enum garbage {
	Float:gXPos, 
	Float:gYPos, 
	Float:gZPos, 
	bool:gIsActive
}

int g_eGarbageSpawnPoints[MAX_GARBAGE][garbage];
int g_iLoadedGarbage = 0;
int g_iActiveGarbage = 0;
int g_iBlueGlow;

int g_iBaseGarbageSpawns = 10;
int g_iMaxGarbageSpawns = 20;

ArrayList randomNumbers;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Eboueur", 
	author = "Benito", 
	description = "Métier Eboueur", 
	version = VERSION, 
	url = URL
};

/***************************************************************************************

							P L U G I N  -  E V E N T S

***************************************************************************************/
public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		GameCheck();
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_eboueur.log");
		Database.Connect(GotDatabase, dbconfig);
		
		RegConsoleCmd("rp_poubelles", addSpawnPoints);
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
	PrecacheModel("models/props_junk/trashcluster01a_corner.mdl", true);
	PrecacheModel("models/props/de_train/hr_t/trash_c/hr_clothes_pile.mdl", true);
	PrecacheModel("models/props/de_train/hr_t/trash_b/hr_food_pile_02.mdl", true);
	
	CreateTimer(1.0, refreshTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	strcopy(g_cTrash[0], 64, "models/props_junk/trashcluster01a_corner.mdl");
	strcopy(g_cTrash[1], 64, "models/props/de_train/hr_t/trash_c/hr_clothes_pile.mdl");
	strcopy(g_cTrash[2], 64, "models/props/de_train/hr_t/trash_b/hr_food_pile_02.mdl");
	
	for (int i = 0; i < MAX_GARBAGE; i++) {
		g_eGarbageSpawnPoints[g_iLoadedGarbage][gXPos] = -1.0;
		g_eGarbageSpawnPoints[g_iLoadedGarbage][gYPos] = -1.0;
		g_eGarbageSpawnPoints[g_iLoadedGarbage][gZPos] = -1.0;
		g_eGarbageSpawnPoints[g_iLoadedGarbage][gIsActive] = false;
	}
	g_iLoadedGarbage = 0;
	g_iBlueGlow = PrecacheModel("sprites/blueglow1.vmt");
	loadGarbageSpawnPoints();
	InitPoubelles();
}	

public void InitPoubelles() {
	for (int i = 0; i < MAX_GARBAGE; i++) {
		g_eGarbageSpawnPoints[i][gIsActive] = false;
	}
	
	randomNumbers = CreateArray(g_iBaseGarbageSpawns, g_iBaseGarbageSpawns);
	ClearArray(randomNumbers);
	for (int i = 0; i < g_iLoadedGarbage; i++) {
		PushArrayCell(randomNumbers, i);
	}
	
	for (int i = 0; i < MAX_GARBAGE; i++) {
		int index1 = GetRandomInt(0, (g_iLoadedGarbage - 1));
		int index2 = GetRandomInt(0, (g_iLoadedGarbage - 1));
		if (GetArraySize(randomNumbers) > 0)
			SwapArrayItems(randomNumbers, index1, index2);
	}
	
	int spawns = 0;
	if (g_iBaseGarbageSpawns > g_iLoadedGarbage)
		spawns = g_iLoadedGarbage;
	else
		spawns = g_iBaseGarbageSpawns;
	for (int i = 0; i < spawns; i++) {
		int spawnId = GetArrayCell(randomNumbers, 0);
		RemoveFromArray(randomNumbers, 0);
		spawnGarbage(spawnId);
	}
}

public void spawnGarbage(int id) {
	int trashEnt = CreateEntityByName("prop_dynamic_override");
	if (trashEnt == -1)
		return;
	char modelPath[128];
	Format(modelPath, sizeof(modelPath), g_cTrash[GetRandomInt(0, 2)]);
	SetEntityModel(trashEnt, modelPath);
	DispatchKeyValue(trashEnt, "Solid", "2");
	SetEntProp(trashEnt, Prop_Send, "m_nSolidType", 2);
	SetEntProp(trashEnt, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_NONE);
	char cId[8];
	IntToString(id, cId, sizeof(cId));
	SetEntPropString(trashEnt, Prop_Data, "m_iName", cId);
	DispatchSpawn(trashEnt);
	float pos[3];
	pos[0] = g_eGarbageSpawnPoints[id][gXPos];
	pos[1] = g_eGarbageSpawnPoints[id][gYPos];
	pos[2] = g_eGarbageSpawnPoints[id][gZPos];
	TeleportEntity(trashEnt, pos, NULL_VECTOR, NULL_VECTOR);
	Entity_SetGlobalName(trashEnt, "Garbage");
	
	g_eGarbageSpawnPoints[id][gIsActive] = true;
	g_iActiveGarbage++;
}

public Action refreshTimer(Handle Timer) {
	for (int i = 1; i < MAXPLAYERS; i++) {
		if (g_iSpeedTimeLeft[i] > 0)
			g_iSpeedTimeLeft[i]--;
		else if (g_iSpeedTimeLeft[i] == 0) {
			g_iSpeedTimeLeft[i] = -1;
			removeSpeed(i);
		}
	}
	
	if (randomNumbers == INVALID_HANDLE)
		return;
	int active = getActiveGarbage();
	if (active == g_iLoadedGarbage)
		return;
	if (active >= g_iMaxGarbageSpawns)
		return;
	if (active < g_iBaseGarbageSpawns) {
		if (GetArraySize(randomNumbers) > 0) {
			int spawnId = GetArrayCell(randomNumbers, 0);
			RemoveFromArray(randomNumbers, 0);
			spawnGarbage(spawnId);
			return;
		}
	}
	if (active >= g_iBaseGarbageSpawns && active < g_iMaxGarbageSpawns) {
		if (GetArraySize(randomNumbers) > 0) {
			if (GetRandomInt(0, 20) == 7) {
				int spawnId = GetArrayCell(randomNumbers, 0);
				RemoveFromArray(randomNumbers, 0);
				spawnGarbage(spawnId);
			}
		}
	}
}

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName) 
{
	if(rp_GetClientInt(client, i_Job) == 19)
	{
		if (StrEqual(entModel, g_cTrash[0])
		|| StrEqual(entModel, g_cTrash[1])
		|| StrEqual(entModel, g_cTrash[2])) 
		{
			if(rp_GetClientInt(client, i_poubelles) != MAX_IN_GARBAGE)
			{
				rp_SetClientInt(client, i_poubelles, rp_GetClientInt(client, i_poubelles) + 1);
				PoubellesGift(client);
				LoadingBar("Poubelles", 1, 1.0);
				RemoveEdict(aim);
				CPrintToChat(client, "%s Vous avez ramassé une poubelle (%i / %i).", TEAM, rp_GetClientInt(client, i_poubelles), MAX_IN_GARBAGE);
			}
			else
				CPrintToChat(client, "%s Vous avez atteint la limite de poubelles sur vous.", TEAM);
		}
	}
}

public void PoubellesGift(int client)
{
	int id = GetRandomInt(0, 7);
	
	if(id == 3)
	{
		int reward = GetRandomInt(50, 346);
		CPrintToChat(client, "%s Vous avez trouvé %i$ dans les déchets.", TEAM, reward);
		rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + reward);
	}
	else if(id == 5)
	{
		GivePlayerItem(client, "weapon_glock18");
		CPrintToChat(client, "%s Vous avez trouvé une arme de crime.", TEAM);	
	}	
}

public void removeSpeed(int client) 
{
	if (!IsClientValid(client))
		return;
	if (GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") <= 1.0)
		return;
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
}

public void loadGarbageSpawnPoints()
{
	char map[128];
	GetCurrentMap(STRING(map));
	if (StrContains(map, "workshop") != -1) 
	{
		char mapPart[3][64];
		ExplodeString(map, "/", mapPart, 3, 64);
		strcopy(STRING(map), mapPart[2]);
	}
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/roleplay/%s/poubelles.cfg", map);
	
	Handle hFile = OpenFile(sPath, "r");
	
	char sBuffer[512];
	char sDatas[3][32];
	
	if (hFile != INVALID_HANDLE)
	{
		while (ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
		{
			ExplodeString(sBuffer, ";", sDatas, 3, 32);
			
			g_eGarbageSpawnPoints[g_iLoadedGarbage][gXPos] = StringToFloat(sDatas[0]);
			g_eGarbageSpawnPoints[g_iLoadedGarbage][gYPos] = StringToFloat(sDatas[1]);
			g_eGarbageSpawnPoints[g_iLoadedGarbage][gZPos] = StringToFloat(sDatas[2]);
			
			g_iLoadedGarbage++;
		}
		
		delete hFile;
	}
	PrintToServer("Chargement de %i spawn de poubelles", g_iLoadedGarbage);
}

public void saveGarbageSpawnPoints()
{
	char map[128];
	rp_GetCurrentMap(map);
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/roleplay/%s/poubelles.cfg", map);
	
	Handle hFile = OpenFile(sPath, "w");
	
	if (hFile != INVALID_HANDLE)
	{
		for (int i = 0; i < g_iLoadedGarbage; i++) {
			WriteFileLine(hFile, "%.2f;%.2f;%.2f;", g_eGarbageSpawnPoints[i][gXPos], g_eGarbageSpawnPoints[i][gYPos], g_eGarbageSpawnPoints[i][gZPos]);
		}
		
		delete hFile;
	}
	
	if (!FileExists(sPath))
		LogError("Couldn't save item spawns to  file: \"%s\".", sPath);
}

public void AddLootSpawn(int client)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	TE_SetupGlowSprite(pos, g_iBlueGlow, 10.0, 1.0, 235);
	TE_SendToAll();
	
	g_eGarbageSpawnPoints[g_iLoadedGarbage][gXPos] = pos[0];
	g_eGarbageSpawnPoints[g_iLoadedGarbage][gYPos] = pos[1];
	g_eGarbageSpawnPoints[g_iLoadedGarbage][gZPos] = pos[2];
	g_iLoadedGarbage++;
	
	CPrintToChat(client, "Ajout d'une poubelle à la position %.2f:%.2f:%.2f", TEAM, pos[0], pos[1], pos[2]);
	saveGarbageSpawnPoints();
}


public Action addSpawnPoints(int client, int args) 
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu");
		return Plugin_Handled;
	}
	else if(rp_GetClientInt(client, i_AdminLevel) == 0)
	{
		CPrintToServer("Vous n'avez pas accès à cette commande.", TEAM);
		return Plugin_Handled;
	}
	
	addSpawnPointsMenu(client, args);
	return Plugin_Handled;
}

public Action addSpawnPointsMenu(int client, int args)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(HandlePoubelleSpawn);
	menu.SetTitle("Spawn: Poubelles (Total: %i)", g_iLoadedGarbage);
	menu.AddItem("add", "Ajouter un spawn");
	menu.AddItem("show", "Afficher les spawn");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int HandlePoubelleSpawn(Menu menu, MenuAction action, int client, int param) 
{
	if (action == MenuAction_Select) 
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if (StrEqual(info, "add")) 
		{
			AddLootSpawn(client);
			addSpawnPointsMenu(client, 0);
		} 
		else if (StrEqual(info, "show")) 
		{
			ShowSpawns();
			addSpawnPointsMenu(client, 0);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public void ShowSpawns() {
	for (int i = 0; i < g_iLoadedGarbage; i++) {
		float pos[3];
		pos[0] = g_eGarbageSpawnPoints[i][gXPos];
		pos[1] = g_eGarbageSpawnPoints[i][gYPos];
		pos[2] = g_eGarbageSpawnPoints[i][gZPos];
		TE_SetupGlowSprite(pos, g_iBlueGlow, 10.0, 1.0, 235);
		TE_SendToAll();
	}
}

public int getActiveGarbage() {
	int count = 0;
	for (int i = 0; i < g_iLoadedGarbage; i++) {
		if (g_eGarbageSpawnPoints[i][gIsActive])
			count++;
	}
	return count;
}

public void OnClientPostAdminCheck(int client) {
	resetAmountVars();
	g_iSpeedTimeLeft[client] = -1;
}

public void resetAmountVars() {
	int amount;
	if ((amount = GetRealClientCount()) != 0) {
		g_iMaxGarbageSpawns = amount;
		amount /= 3;
		g_iBaseGarbageSpawns = amount <= 3 ? 3:amount;
	} else {
		g_iBaseGarbageSpawns = 1;
		g_iMaxGarbageSpawns = 5;
	}
}

public int GetRealClientCount() {
	int total = 0;
	LoopClients(i)
		if (IsClientConnected(i) && !IsFakeClient(i))
			total++;
	return total;
} 