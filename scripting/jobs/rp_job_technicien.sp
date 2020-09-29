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
#include <emitsoundany>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
int entMachine[MAXPLAYERS + 1][2];
int entBillet[MAXPLAYERS + 1][2];
int healthEnt[MAXENTITIES + 1];
int needPapier[MAXPLAYERS + 1][2];
int ameliorationImprimante[MAXPLAYERS + 1][2];

bool blindageImprimante[MAXPLAYERS + 1][2];

Handle timerMachine1Papier[MAXPLAYERS + 1] =  { null, ... };
Handle timerMachine2Papier[MAXPLAYERS + 1] =  { null, ... };

char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];

ConVar rewardTased;
ConVar ImprimanteTimer; 
ConVar ImprimanteCash;
ConVar ImprimanteCashv2;
ConVar ImprimanteCashv3;
ConVar ImprimanteCashMax;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Technicien", 
	author = "Benito", 
	description = "Métier Technicien", 
	version = VERSION, 
	url = URL
};

/***************************************************************************************

							P L U G I N  -  E V E N T S

***************************************************************************************/
public void OnPluginStart()
{
	GameCheck();	
	rp_LoadTranslation();
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_technicien.log");
	
	rewardTased = CreateConVar("rp_tase_imprimante", "500", "Recompense lors d'un tase imprimante");	
	ImprimanteTimer = CreateConVar("rp_imprimante_timer", "10.0", "Temps  avant la recompense de l'argent");
	ImprimanteCash = CreateConVar("rp_imprimante_cash", "3", "Montant de la recompense sans mise à jour");
	ImprimanteCashv2 = CreateConVar("rp_imprimante_cash_v2", "5", "Montant de la recompense mise à jour v2.0");
	ImprimanteCashv3 = CreateConVar("rp_imprimante_cash_v3", "10", "Montant de la recompense mise à jour v3.0");
	ImprimanteCashMax = CreateConVar("rp_imprimante_cash_max", "500", "Montant max de la liasse sans compte en suisse");
	AutoExecConfig(true, "rp_job_technicien");
	RegConsoleCmd("firework", Cmd_ItemFireWork);
}

public Action Cmd_ItemFireWork(int client, int args) 
{	
	CreateTimer(0.1, Fire_Spriteworks01, client);
	CreateTimer(0.6, Fire_Spriteworks02, client);
}

public Action Fire_Spriteworks01(Handle timer, any client) 
{
	int g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	float vec[3], vec2[3];
	GetClientAbsOrigin(client, vec);
	vec2 = vec; // <-- CA CAY PRATIQUE
	vec2[2] = vec[2] + 400.0;

	
	// TODO <-- Couleur de ligne différente ?
	TE_SetupBeamPoints( vec, vec2, g_cBeam, 0, 0, 0, 0.8, 2.0, 1.0, 1, 0.0, {255,255,255,50}, 10);
	TE_SendToAll();
}

public Action Fire_Spriteworks02(Handle timer, any client) 
{
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 400.0;
	
	char sound[128];
	PrecacheSound("weapons/hegrenade/explode%i.wav");
	Format(sound, sizeof(sound), "weapons/hegrenade/explode%i.wav", Math_GetRandomInt(3, 5));
	EmitSoundToAllAny(sound, SOUND_FROM_WORLD, _, _, _, _, _, _, vec);
	
	/*float vecAngle[3]; 
	rp_Effect_ParticlePath(client, "firework_crate_explosion_01", vec, vecAngle, vec);
	rp_Effect_ParticlePath(client, "firework_crate_explosion_02", vec, vecAngle, vec);
	rp_Effect_ParticlePath(client, "firework_crate_ground_sparks_01", vec, vecAngle, vec);*/
	
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_technicien` ( \
	  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `7` int(100) NOT NULL, \
	  `8` int(100) NOT NULL, \
	  `9` int(100) NOT NULL, \
	  `10` int(100) NOT NULL, \
	  `11` int(100) NOT NULL, \
	  `12` int(100) NOT NULL, \
	  `13` int(100) NOT NULL, \
	  `14` int(100) NOT NULL, \
	  `15` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

public void OnMapEnd()
{
	for(int i = MaxClients; i <= MAXENTITIES; i++)
	{
		if(IsValidEntity(i))
		{
			char entModel[128];
			Entity_GetModel(i, STRING(entModel));
			if(StrEqual(entModel, IMPRIMANTE))
			{
				char entName[64];
				Entity_GetName(i, STRING(entName));
				
				char buffer[2][64];
				ExplodeString(entName, "|", buffer, 2, 64);
				
				int player = StringToInt(buffer[0]);
				
				if(IsClientValid(player))
					rp_ClientGiveItem(player, i_imprimantes, rp_GetClientItem(player, i_imprimantes) + 1);
			}	
		}
	}
}	

public void RP_OnPlayerDisconnect(int client)
{
	if(!IsClientInGame(client))
		return;
	
	if(IsValidEntity(entMachine[client][0]))
	{
		RemoveEdict(entMachine[client][0]);
		entMachine[client][0] = -1;
	}
	
	if(IsValidEntity(entMachine[client][1]))
	{
		RemoveEdict(entMachine[client][1]);
		entMachine[client][1] = -1;
	}
	
	if(IsValidEntity(entBillet[client][0]))
	{
		RemoveEdict(entBillet[client][0]);
		entBillet[client][0] = -1;
	}
	
	if(IsValidEntity(entBillet[client][1]))
	{
		RemoveEdict(entBillet[client][1]);
		entBillet[client][1] = -1;
	}
		
	blindageImprimante[client][0] = false;
	blindageImprimante[client][1] = false;
	ameliorationImprimante[client][0] = 0;
	ameliorationImprimante[client][1] = 0;
	
	if(timerMachine1Papier[client] != null)
	{
		TrashTimer(timerMachine1Papier[client], true);
		timerMachine1Papier[client] = null;
	}
	if(timerMachine2Papier[client] != null)
	{
		TrashTimer(timerMachine2Papier[client], true);
		timerMachine2Papier[client] = null;
	}
	
	rp_SetClientBool(client, b_doubleImprimante, false);
	rp_SetClientBool(client, b_regenerationbionique, false);
}

public void OnClientPutInServer(int client)
{	
	ameliorationImprimante[client][0] = 0;
	ameliorationImprimante[client][1] = 0;
	blindageImprimante[client][0] = false;
	blindageImprimante[client][1] = false;
	entBillet[client][0] = -1;
	entBillet[client][1] = -1;	
	entMachine[client][0] = -1;	
	entMachine[client][1] = -1;	
	rp_SetClientBool(client, b_doubleImprimante, false);
	rp_SetClientBool(client, b_regenerationbionique, false);
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPostAdminCheck(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(rp_GetDatabase(), playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_technicien` (`Id`, `steamid`, `playername`, `7`, `8`, `9`, `10`, `11`, `12`, `13`, `14`, `15`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
}

public void LoadSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_technicien WHERE steamid = '%s';", steamID[client]);
	rp_GetDatabase().Query(QueryCallback, buffer, GetClientUserId(client));
}

public void QueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		for (int i = 0; i <= MAXITEMS; i++)
		{
			char item_jobid[64];
			rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
			
			if(StrEqual(item_jobid, "10"))
			{
				char item_string[10];
				IntToString(i, STRING(item_string));
				
				rp_ClientGiveItem(client, i, SQL_FetchIntByName(Results, item_string));
			}	
		}	
	}
} 

public void RP_OnPlayerDeath(int attacker, int victim, int respawnTime)
{
	ClientCommand(victim, "r_screenoverlay 0");	

	//rp_SetClientBool(victim, b_doubleImprimante, false);
	rp_SetClientBool(victim, b_regenerationbionique, false);
}	

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	
	if(StrEqual(model, IMPRIMANTE) && Distance(client, target) <= 80.0)
	{
		if (StrContains(name, steamID[client]) != -1)
			MenuImprimante(client, target);
		else 
			PrintHintText(client, "(?) Avez-vous essayé de pirater cette imprimante ?");			
	}	
	else if(StrEqual(entityName, "Technicien") && Distance(client, target) <= 80.0)
	{
		int nbTech;
		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Job) == 10 && !rp_GetClientBool(i, b_isAfk))
				nbTech++;
		}
		if(nbTech == 0 || nbTech == 1 && rp_GetClientInt(client, i_Job) == 10 || rp_GetClientInt(client, i_Job) == 10 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un technicien.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un technicien.");
		}
	}
	else if(StrEqual(model, MONEY_MDL) && Distance(client, target) <= 80.0)
	{
		char buff4[2][64];
		ExplodeString(name, "|", buff4, 2, 64);
		// buff4[0] : nom proprio
		int montant = StringToInt(buff4[1]);
		if(montant <= 0) montant = 10;
	
		rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + montant);
		SetSQL_Int(rp_GetDatabase(), "rp_economy", "money", rp_GetClientInt(client, i_Money), steamID[client]);
		rp_SetJobCapital(5, rp_GetJobCapital(5) - montant);
		EmitCashSound(client, montant);
		RemoveEdict(target);
		
		int owner = Client_FindBySteamId(buff4[0]);
		
		if(entBillet[owner][0] == target)
		{
			entBillet[owner][0] = -1;
			if(!StrEqual(buff4[0], steamID[client]))
				CPrintToChat(owner, "%s Les billets de votre imprimante à faux billet ont été volés !", TEAM);
			CPrintToChat(client, "%s Vous avez récupéré %i$.", TEAM, montant);
		}
		if(entBillet[owner][1] == target)
		{
			entBillet[owner][1] = -1;
			if(!StrEqual(buff4[0], steamID[client]))
				CPrintToChat(owner, "%s Les billets de votre imprimante à faux billet ont été volés !", TEAM);
			CPrintToChat(client, "%s Vous avez récupéré %i$.", TEAM, montant);
		}	
		
		if(rp_GetClientInt(client, i_Job) == 1)
		{
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 100);
			rp_SetJobCapital(5, rp_GetJobCapital(5) - 100);
			EmitCashSound(client, 100);
		}
		else if(rp_GetClientInt(client, i_Job) == 2)
		{
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + montant / 2);
			rp_SetJobCapital(3, rp_GetJobCapital(3) + montant / 2);
			rp_SetJobCapital(5, rp_GetJobCapital(5) - montant);
			EmitCashSound(client, montant / 2);
		}
	}
}	

public Action RP_OnPlayerTase(int client, int target, int reward, const char[] class, const char[] model, const char[] name)
{
	char buffer[2][64];
	ExplodeString(name, "|", buffer, 2, 64);
	
	if(StrEqual(model, IMPRIMANTE) && Distance(client, target) <= 180)
	{
		CPrintToChat(client, "%s Vous avez saisi un appareil de contrebande.", TEAM);
		int joueur = Client_FindBySteamId(buffer[0]);
					
		reward = GetConVarInt(rewardTased);
		CPrintToChat(client, "%s Le Commadant vous reverse une prime de %i$ pour cette saisie.", TEAM, reward);
					
		CreateTimer(0.1, ExplodeImprimante, target);
		RemoveEdict(target);
		
		entBillet[joueur][StringToInt(buffer[1])] = -1;
		entMachine[joueur][StringToInt(buffer[1])] = -1;
					
		if(IsClientValid(joueur))
			CPrintToChat(joueur, "%s Votre imprimante à faux billet à été saisie par le {lightred}service de Police{default}.", TEAM);	
	}
}	


public Action RP_OnPlayerFire(int client, int target, const char[] weapon)
{
	char entModel[64];
	Entity_GetModel(target, entModel, sizeof(entModel));
	if(StrEqual(entModel, IMPRIMANTE))
	{
		float position[3];
		if(healthEnt[target] - 11 > 0)
		{
			healthEnt[target] -= 11;
			PointVision(client, position);
			float dir[3] = {0.0, 0.0, 1.0};
			TE_SetupMetalSparks(position, dir);
			TE_SendToAll();
		}
		else if(healthEnt[target] != 0)
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", position);
			position[2] += 4;
			rp_CreateFire(position, 4.5);
			CreateTimer(5.0, ExplodeImprimante, target);
		}
	}	
}	

public Action RP_OnPlayerBuild(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_Job) == 10)
	{
		menu.SetTitle("Build - Technicien");
		menu.AddItem("imprimante", "Installer une imprimante");
	}	
}	

public int RP_OnPlayerBuildHandle(int client, const char[] info)
{
	if(StrEqual(info, "imprimante"))
	{
		if(rp_GetClientInt(client, i_ByteZone) != 777)
		{
			if (entMachine[client][0] != -1 && !rp_GetClientBool(client, b_doubleImprimante))
				CPrintToChat(client, "%s Vous n'avez pas les compétences d'installer plusieurs imprimantes.", TEAM);
			else if (rp_GetClientBool(client, b_doubleImprimante) && entMachine[client][0] != -1 && entMachine[client][1] != -1)
				CPrintToChat(client, "%s Vous avez déjà posé 2 imprimantes.", TEAM);
			else
			{
				PrecacheModel(IMPRIMANTE);
				int ent = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(ent, "solid", "6");
				DispatchKeyValue(ent, "model", IMPRIMANTE);
				DispatchSpawn(ent);
				char strFormat[128];
				if (entMachine[client][0] == -1)
				{
					entMachine[client][0] = ent;
					Format(STRING(strFormat), "%s|0", steamID[client]);
				}
				else
				{
					entMachine[client][1] = ent;
					Format(STRING(strFormat), "%s|1", steamID[client]);
				}
				Entity_SetName(ent, strFormat);
							
				float origin[3];
				GetClientAbsOrigin(client, origin);
				TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
				origin[2] += 20;
				TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
							
				healthEnt[ent] = 100;
				CreateTimer(GetConVarFloat(ImprimanteTimer), DoMachine, client);
				if (entMachine[client][0] != -1)
				{
					needPapier[client][0] = false;
					timerMachine1Papier[client] = CreateTimer(3600.0, TimerMachinePapier, client);
				}
				else
				{
					needPapier[client][1] = false;
					timerMachine2Papier[client] = CreateTimer(3600.0, TimerMachinePapier, client);
				}
			}	
		}
		else 
			CPrintToChat(client, "%s Interdit de poser une imprimante en zone P.V.P", TEAM);
	}						
}	

public Action RP_OnPlayerInventory(int client, Menu menu)
{
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "10"))
		{
			if(rp_GetClientItem(client, i) >= 1)
			{
				char item_name[64], item_handle[64];
				rp_GetItemData(i, item_type_name, STRING(item_name));
				Format(STRING(item_name), "%s [%i]", item_name, rp_GetClientItem(client, i));
				Format(STRING(item_handle), "%i", i);
				menu.AddItem(item_handle, item_name);
			}
		}
	}
}	
	
public int RP_OnPlayerInventoryHandle(int client, char[] info)
{
	if(StrEqual(info, "11") && IsPlayerAlive(client))
	{
		if(rp_GetClientInt(client, i_ByteZone) != 777)
		{
			if (entMachine[client][0] != -1 && !rp_GetClientBool(client, b_doubleImprimante))
				CPrintToChat(client, "%s Vous n'avez pas les compétences d'installer plusieurs imprimantes.", TEAM);
			else if (rp_GetClientBool(client, b_doubleImprimante) && entMachine[client][0] != -1 && entMachine[client][1] != -1)
				CPrintToChat(client, "%s Vous avez déjà posé 2 imprimantes.", TEAM);
			else
			{
				int itemID = StringToInt(info);
				rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_technicien` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
				
				PrecacheModel(IMPRIMANTE);
				int ent = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(ent, "solid", "6");
				DispatchKeyValue(ent, "model", IMPRIMANTE);
				DispatchSpawn(ent);
				char strFormat[128];
				if (entMachine[client][0] == -1)
				{
					entMachine[client][0] = ent;
					Format(STRING(strFormat), "%s|0", steamID[client]);
				}
				else
				{
					entMachine[client][1] = ent;
					Format(STRING(strFormat), "%s|1", steamID[client]);
				}
				Entity_SetName(ent, strFormat);
							
				float origin[3];
				GetClientAbsOrigin(client, origin);
				TeleportEntity(ent, origin, NULL_VECTOR, NULL_VECTOR);
				origin[2] += 20;
				TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
							
				healthEnt[ent] = 100;
				CreateTimer(GetConVarFloat(ImprimanteTimer), DoMachine, client);
				if (entMachine[client][0] != -1)
				{
					needPapier[client][0] = false;
					timerMachine1Papier[client] = CreateTimer(3600.0, TimerMachinePapier, client);
				}
				else
				{
					needPapier[client][1] = false;
					timerMachine2Papier[client] = CreateTimer(3600.0, TimerMachinePapier, client);
				}
			}	
		}
		else 
			CPrintToChat(client, "%s Interdit de poser une imprimante en zone P.V.P", TEAM);
	}
	else if(StrEqual(info, "12") && IsPlayerAlive(client))
	{
		int itemID = StringToInt(info);
		rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
		UpdateSQL(rp_GetDatabase(), "UPDATE `rp_technicien` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
	}
	else if(StrEqual(info, "13") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_C4) == -1)
		{
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_technicien` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
				
			GivePlayerItem(client, "weapon_bumpmine");
			
			CPrintToChat(client, "%s Vous utilisez des mines.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise des mines.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà des mines.", TEAM);
	}
	else if(StrEqual(info, "14") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_C4) == -1)
		{
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_technicien` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
				
			GivePlayerItem(client, "prop_weapon_upgrade_exojump");
			
			CPrintToChat(client, "%s Vous utilisez un propulseur.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un propulseur.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà un propulseur.", TEAM);
	}
	
	FakeClientCommand(client, "rp");
}		

public Action ExplodeImprimante(Handle timer, any ent)
{
	if (IsValidEntity(ent))
	{
		float position[3];
		char sound[64], entName[64], buffer[2][64];
		Entity_GetName(ent, STRING(entName));
		ExplodeString(entName, "|", buffer, 2, 64);
		int num = StringToInt(buffer[1]);
		
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		TE_SetupExplosion(position, -1, 1.0, 1, 0, 200, 200);
		TE_SendToAll();
		
		switch (GetRandomInt(1, 3))
		{
			case 1:strcopy(STRING(sound), "weapons/hegrenade/explode3.wav");
			case 2:strcopy(STRING(sound), "weapons/hegrenade/explode4.wav");
			case 3:strcopy(STRING(sound), "weapons/hegrenade/explode5.wav");
		}
		PrecacheSoundAny(sound);
		EmitSoundToAllAny(sound, ent, _, _, _, 1.0, _, _, position);
		
		LoopClients(i)
		{
			if (IsClientValid(i))
			{
				if (entMachine[i][num] == ent)
				{
					entMachine[i][num] = -1;
					if (IsValidEntity(entBillet[i][num]))
						RemoveEdict(entBillet[i][num]);
					entBillet[i][num] = -1;
					CPrintToChat(i, "%s Votre imprimante à faux billets à été détruite.", TEAM);
					
					ameliorationImprimante[i][num] = 0;
					blindageImprimante[i][num] = false;
					
					if (num == 0)
					{
						if (timerMachine1Papier[i] != INVALID_HANDLE)
						{
							KillTimer(timerMachine1Papier[i]);
							timerMachine1Papier[i] = INVALID_HANDLE;
						}
					}
					if (num == 1)
					{
						if (timerMachine2Papier[i] != INVALID_HANDLE)
						{
							KillTimer(timerMachine2Papier[i]);
							timerMachine2Papier[i] = INVALID_HANDLE;
						}
					}
				}
				
				float origin[3];
				GetClientAbsOrigin(i, origin);
				if (GetVectorDistance(position, origin) < 80.0)
				{
					int vie = GetClientHealth(i);
					if (vie - 4 > 0)
						SetEntityHealth(i, vie - 4);
					else
						ForcePlayerSuicide(i);
						
					LogToFile(logFile, "Le joueur %N est mort tué par une explosion d'imprimante.", i);
				}
			}
		}
		RemoveEdict(ent);
	}
}

public Action DoMachine(Handle timer, any client)
{
	if (IsClientValid(client))
	{
		if (IsValidEntity(entMachine[client][0]) || IsValidEntity(entMachine[client][1]))
		{
			CreateTimer(GetConVarFloat(ImprimanteTimer), DoMachine, client);
			
			for (int i; i <= 1; i++)
			{
				if (!IsValidEntity(entMachine[client][i]))
					return Plugin_Handled;
				
				float position[3];
				GetEntPropVector(entMachine[client][i], Prop_Send, "m_vecOrigin", position);
				
				if (needPapier[client][i])
				{
					PrecacheSoundAny("ui/beep22.wav");
					EmitSoundToAllAny("ui/beep22.wav", entMachine[client][i], _, _, _, 1.0, _, _, position);
					if (GetRandomInt(1, 10) == 5)
					{
						PrintHintText(client ,"Imprimante à court d'encre et de papier.");

						PrecacheSoundAny("ui/weapon_cant_buy.wav");
						EmitSoundToClientAny(client, "ui/weapon_cant_buy.wav", client, _, _, _, 0.8);
					}
					return Plugin_Handled;
				}
				
				int sound = true;
				char strFormat[64];
				if (rp_GetClientBool(client, b_compteSuisse))
				{
					if (rp_GetClientInt(client, i_timeJail) == 0 && !rp_GetClientBool(client, b_isAfk))
					{
						if (ameliorationImprimante[client][i] == 0)
							rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) +  GetConVarInt(ImprimanteCash));
						else if (ameliorationImprimante[client][i] == 1)
							rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) +  GetConVarInt(ImprimanteCashv2));
						else if (ameliorationImprimante[client][i] == 2)
							rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) +  GetConVarInt(ImprimanteCashv3));
					}
				}
				else if (entBillet[client][i] == -1)
				{
					PrecacheModel(MONEY_MDL);
					int ent = CreateEntityByName("prop_dynamic_override");
					DispatchKeyValue(ent, "solid", "6");
					DispatchKeyValue(ent, "model", MONEY_MDL);
					DispatchSpawn(ent);
					
					if (ameliorationImprimante[client][i] == 0)
						Format(STRING(strFormat), "%s|1", steamID[client]);
					else if (ameliorationImprimante[client][i] == 1)
						Format(STRING(strFormat), "%s|2", steamID[client]);
					else if (ameliorationImprimante[client][i] == 2)
						Format(STRING(strFormat), "%s|3", steamID[client]);
					Entity_SetName(ent, strFormat);
					
					position[1] -= 10;
					position[2] += 16;
					TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
					
					entBillet[client][i] = ent;
				}
				else if (IsValidEntity(entBillet[client][i]))
				{
					char entName[64], buffer[2][64];
					Entity_GetName(entBillet[client][i], entName, sizeof(entName));
					int len = ExplodeString(entName, "|", buffer, 2, 64);
					if (len > 0)
					{
						// buffer[0] : pseudo client
						int montant = StringToInt(buffer[1]);
						
						int valeur;
						if (ameliorationImprimante[client][i] == 0)
							valeur = GetConVarInt(ImprimanteCash);
						else if (ameliorationImprimante[client][i] == 1)
							valeur = GetConVarInt(ImprimanteCashv2);
						else if (ameliorationImprimante[client][i] == 2)
							valeur = GetConVarInt(ImprimanteCashv3);
						
						if (montant <= GetConVarInt(ImprimanteCashMax))
						{
							if (rp_GetClientInt(client, i_timeJail) == 0 && !rp_GetClientBool(client, b_isAfk))
							{
								Format(STRING(strFormat), "%s|%i", buffer[0], montant + valeur);
								Entity_SetName(entBillet[client][i], strFormat);
							}
						}
						else
						{
							sound = false;
							switch (GetRandomInt(1, 10))
							{
								case 5:CPrintToChat(client, "%s Votre imprimante à faux billets déborde !", TEAM);
								case 10:
								{
									PrintHintText(client ,"Votre imprimante à faux billets déborde !");
								}	
							}
						}
					}
					else
					{
						Format(STRING(strFormat), "%s|10", entName);
						Entity_SetName(entBillet[client][i], strFormat);
					}
				}
				if (sound)
				{
					PrecacheSoundAny("revolution-team/Dollar.mp3");
					EmitSoundToAllAny("revolution-team/Dollar.mp3", entBillet[client][i], _, _, _, 0.1, _, _, position);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action TimerMachinePapier(Handle timer, any client)
{
	if (IsClientValid(client))
	{
		if(!needPapier[client][0])
			needPapier[client][0] = true;
		else if(!needPapier[client][1])
			needPapier[client][1] = true;
			
		CPrintToChat(client, "%s Votre imprimante à faux billets a besoin d'encre et de papier pour continuer à imprimer !", TEAM);
		PrintCenterText(client, "Votre imprimante à faux billets a besoin d'encre et de papier !");	
	}
}

Menu MenuImprimante(int client, int aim)
{
	if (IsValidEntity(aim))
	{
		char strFormat[64], entName[64], buffer[2][64];
		Entity_GetName(aim, entName, sizeof(entName));
		ExplodeString(entName, "|", buffer, 2, 64);

		rp_SetClientBool(client, b_menuOpen, true);
		
		Menu menu = new Menu(DoMenuImprimante);
		int num = StringToInt(buffer[1]);
		
		if (needPapier[client][num] && healthEnt[aim] > 0)
		{
			menu.SetTitle("Imprimante à court de papier et d'encre :");
			if (rp_GetClientItem(client, i_recharge) == 0)
				menu.AddItem("", "Vous devez acheter une recharge pour imprimante.", ITEMDRAW_DISABLED);
			else
			{
				Format(STRING(strFormat), "recharger|%i", aim);
				menu.AddItem(strFormat, "Recharger l'imprimante.");
			}
			Format(STRING(strFormat), "detruire|%i", aim);
			menu.AddItem(strFormat, "Détruire l'imprimante.");
		}
		else if (healthEnt[aim] > 0)
		{
			menu.SetTitle("Voulez-vous récupérer votre imprimante ?");
			if (rp_GetClientInt(client, i_Job) == 10 && rp_GetClientInt(client, i_Grade) > 4)
			{
				Format(STRING(strFormat), "oui|%i", aim);
				menu.AddItem(strFormat, "Oui, la ranger dans mon inventaire.");
				menu.AddItem("", "Non.");
			}
			else
				menu.AddItem("", "Vous n'avez pas le droit de ranger cette machine.", ITEMDRAW_DISABLED);
		}
		else if (healthEnt[aim] < 100 && rp_GetClientInt(client, i_Job) == 10)
		{
			Format(STRING(strFormat), "reparer|%i", aim);
			menu.AddItem(strFormat, "Réparer l'imprimante.");
		}
		
		if (rp_GetClientItem(client, i_ameliorationv1) > 0 && ameliorationImprimante[client][num] == 0)
		{
			Format(STRING(strFormat), "1.0|%i", aim);
			menu.AddItem(strFormat, "Lancer la mise à jour v1.0.");
		}
		else if (ameliorationImprimante[client][num] == 1)
			menu.AddItem("", "Mise à jour 1.0 installée.", ITEMDRAW_DISABLED);
			
		if (rp_GetClientItem(client, i_ameliorationv2) > 0 && ameliorationImprimante[client][num] < 2)
		{
			Format(STRING(strFormat), "2.0|%i", aim);
			menu.AddItem(strFormat, "Lancer la mise à jour v2.0");
		}
		else if (ameliorationImprimante[client][num] == 2)
			menu.AddItem("", "Mise à jour 2.0 installée.", ITEMDRAW_DISABLED);
			
		if (rp_GetClientItem(client, i_blindage) > 0 && !blindageImprimante[client][num])
		{
			Format(STRING(strFormat), "blinder|%i", aim);
			menu.AddItem(strFormat, "Blinder l'imprimante.");
		}
		else if (blindageImprimante[client][num])
			menu.AddItem("", "Imprimante blindée.", ITEMDRAW_DISABLED);
			
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
		CPrintToChat(client, "%s Un menu plus important est ouvert.", TEAM);
}

public int DoMenuImprimante(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64], buffer[2][64], buffer2[2][64], entName[64];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 2, 64);
		// buffer[0] : info
		int aim = StringToInt(buffer[1]);
		Entity_GetName(aim, entName, sizeof(entName));
		ExplodeString(entName, "|", buffer2, 2, 64);
		int num = StringToInt(buffer2[1]);
		
		if (needPapier[client][num])
		{
			if (StrEqual(buffer[0], "recharger"))
			{
				rp_ClientGiveItem(client, i_recharge, rp_GetClientItem(client, i_recharge) - 1);
				SetSQL_Int(rp_GetDatabase(), "rp_technicien", "imprimantes", rp_GetClientItem(client, i_recharge), steamID[client]);
				
				needPapier[client][num] = false;
				
				CPrintToChat(client, "%s Vous avez rechargé votre imprimante, elle est maintenant opérationnelle.", TEAM);
				
				PrintHintText(client, "Imprimante rechargée.\n-1 recharge d'imprimante (papier et encre)");
				
				switch (num)
				{
					case 0:timerMachine1Papier[client] = CreateTimer(GetRandomFloat(1800.0, 3600.0), TimerMachinePapier, client);
					case 1:timerMachine2Papier[client] = CreateTimer(GetRandomFloat(1800.0, 3600.0), TimerMachinePapier, client);
				}
			}
			else if (StrEqual(buffer[0], "detruire"))
				CreateTimer(0.1, ExplodeImprimante, entMachine[client][num]);
		}
		else
		{
			if (StrEqual(buffer[0], "oui"))
			{
				PrecacheSoundAny("weapons/movement3.wav");
				EmitSoundToAllAny("weapons/movement3.wav", client, _, _, _, 1.0);
				
				if (timerMachine1Papier[client] != INVALID_HANDLE)
				{
					KillTimer(timerMachine1Papier[client]);
					timerMachine1Papier[client] = INVALID_HANDLE;
				}
				if (timerMachine2Papier[client] != INVALID_HANDLE)
				{
					KillTimer(timerMachine2Papier[client]);
					timerMachine2Papier[client] = INVALID_HANDLE;
				}
				
				if (IsValidEntity(entMachine[client][num]))
					DisolveEntity(entMachine[client][num]);
				if (IsValidEntity(entBillet[client][num]))
					DisolveEntity(entBillet[client][num]);
				
				entMachine[client][num] = -1;
				entBillet[client][num] = -1;
				CreateTimer(0.1, ExplodeImprimante, aim);
				
				rp_ClientGiveItem(client, i_imprimantes, rp_GetClientItem(client, i_imprimantes) + 1);
				SetSQL_Int(rp_GetDatabase(), "rp_technicien", "imprimantes", rp_GetClientItem(client, i_imprimantes), steamID[client]);
				
				CPrintToChat(client, "%s Vous avez rangé votre imprimante à faux billets dans votre inventaire.", TEAM);
			}
			else if (StrEqual(buffer[0], "1.0"))
			{
				ameliorationImprimante[client][num] = 1;
				
				rp_ClientGiveItem(client, i_ameliorationv1, rp_GetClientItem(client, i_ameliorationv1) - 1);
				SetSQL_Int(rp_GetDatabase(), "rp_technicien", "ameliorationv1", rp_GetClientItem(client, i_ameliorationv1), steamID[client]);
				
				CPrintToChat(client, "%s L'imprimante a été mis à jour (1.0).", TEAM);
			}
			else if (StrEqual(buffer[0], "2.0"))
			{
				ameliorationImprimante[client][num] = 2;
				
				rp_ClientGiveItem(client, i_ameliorationv2, rp_GetClientItem(client, i_ameliorationv2) - 1);
				SetSQL_Int(rp_GetDatabase(), "rp_technicien", "ameliorationv2", rp_GetClientItem(client, i_ameliorationv2), steamID[client]);
				
				CPrintToChat(client, "%s L'imprimante a été mis à jour (2.0).", TEAM);
			}
			else if (StrEqual(buffer[0], "blinder"))
			{
				blindageImprimante[client][num] = true;
				healthEnt[entMachine[client][num]] = 1000;
				
				rp_ClientGiveItem(client, i_blindage, rp_GetClientItem(client, i_blindage) - 1);
				SetSQL_Int(rp_GetDatabase(), "rp_technicien", "blindage", rp_GetClientItem(client, i_blindage), steamID[client]);
				
				CPrintToChat(client, "%s L'imprimante a été blindée.", TEAM);
			}
		}
		rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}


/***************** NPC SYSTEM *****************/

int NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Technicien");
	menu.AddItem("item", "Acheter un objet");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "item"))
			SellTech(client, client);	
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}
	
/************************************************/
/***************** Global Forwards *****************/

public Action RP_OnPlayerSell(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 10)
	{
		menu.AddItem("item", "Vendre un objet");
	}
}	

public int RP_OnPlayerSellHandle(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "item"))
		SellTech(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellTech(int client, int target)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Items Disponibles");
	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "10"))
		{
			char item_name[64], item_handle[64], item_price[32];
			rp_GetItemData(i, item_type_name, STRING(item_name));
			rp_GetItemData(i, item_type_prix, STRING(item_price));
			Format(STRING(item_name), "%s [%s$]", item_name, item_price);
			Format(STRING(item_handle), "%i|%i|%i", target, StringToInt(item_price), i);
			menu.AddItem(item_handle, item_name);
		}
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}			

public int DoSell(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64], buffer[3][64], strQuantite[128], strFormat[64];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		
		ExplodeString(info, "|", buffer, 3, 64);
			
		int target = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[1]);
		int itemID = StringToInt(buffer[2]);

		/* MENU QUANTITE */
		
		Menu quantity = new Menu(DoMenuQuantity);
		quantity.SetTitle("Choisissez la quantité");
			
		for(int i = 1; i <= 10; i++)
		{			
			Format(STRING(strQuantite), "%i|%i|%i|%i", target, prix, itemID, i);
			Format(STRING(strFormat), "%i", i);
			quantity.AddItem(strQuantite, strFormat);
		}	
		Format(STRING(strQuantite), "%i|%i|%i|25", target, prix, itemID);
		quantity.AddItem(strQuantite, "25");
		Format(STRING(strQuantite), "%i|%i|%i|50", target, prix, itemID);
		quantity.AddItem(strQuantite, "50");
		Format(STRING(strQuantite), "%i|%i|%i|100", target, prix, itemID);
		quantity.AddItem(strQuantite, "100");

		quantity.ExitButton = true;
		quantity.Display(client, MENU_TIME_FOREVER);
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuQuantity(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], buffer[4][64], response[128];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 4, 64);
			
		int target = StringToInt(buffer[0]);
		int itemID = StringToInt(buffer[2]);
		int quantity = StringToInt(buffer[3]);
		int prix = StringToInt(buffer[1]) * quantity;
		
		char item_name[32];
		rp_GetItemData(itemID, item_type_name, STRING(item_name));
		
		rp_SetClientBool(target, b_menuOpen, true);
		Menu request = new Menu(FinalMenu);
		
		if(target != client)
			request.SetTitle("%N vous propose %i %s pour %i$, acheter ?", client, quantity, item_name, prix);	
		else
			request.SetTitle("Acheter %i %s pour %i$ ?", quantity, item_name, prix);				
				
		
		Format(STRING(response), "%i|%i|%i|%i|oui", client, quantity, itemID, prix);		
		request.AddItem(response, "Payer en liquide.");
		
		if(rp_GetClientBool(target, b_asCb))
		{
			Format(STRING(response), "%i|%i|%i|%i|cb", client, quantity, itemID, prix);			
			request.AddItem(response, "Payer avec ma carte bleue.");
		}
		
		request.AddItem("non", "Refuser l'achat.");
		
		request.ExitButton = false;
		request.Display(target, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else
	{
		if(action == MenuAction_End)
			delete menu;
	}
}	

public int FinalMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], buffer[5][128], strAppart[2][32];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 5, 128);
		ExplodeString(buffer[2], "_", strAppart, 2, 32);
			
		int vendeur = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[3]);
		int quantity = StringToInt(buffer[1]);
		int itemID = StringToInt(buffer[2]);
		bool payCB;
		
		char item_name[32];
		rp_GetItemData(itemID, item_type_name, STRING(item_name));
		
		if(StrEqual(buffer[4], "cb"))
			payCB = true;
			
		if(!StrEqual(buffer[4], "non"))
		{
			if(payCB)
			{
				if(rp_GetClientInt(client, i_Bank) >= prix)
				{
					rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - prix);
					
					if(vendeur == client)
					{
						rp_SetJobCapital(10, rp_GetJobCapital(10) + prix / 2);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);
					
					if(vendeur == client)
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, item_name, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, item_name, prix);
					}
					else
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, item_name, vendeur, prix);
						CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, item_name, client, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, item_name, prix, client);
					}
					
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
				}
				else
				{
					if(client != vendeur)
						CPrintToChat(vendeur, "%s %N n'a pas assez d'argent en banque.", TEAM, client);
					CPrintToChat(client, "%s Vous n'avez pas assez d'argent en banque.", TEAM);
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
					return;
				}	
			}
			else
			{
				if(rp_GetClientInt(client, i_Money) >= prix)
				{
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - prix);
					
					if(vendeur == client)
					{
						rp_SetJobCapital(10, rp_GetJobCapital(10) + prix / 2);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);					
					
					if(vendeur == client)
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, item_name, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, item_name, prix);
					}
					else
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, item_name, vendeur, prix);
						CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, item_name, client, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, item_name, prix, client);
					}
					
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
				}
				else
				{
					if(client != vendeur)
						CPrintToChat(vendeur, "%s %N n'a pas assez d'argent en liquide.", TEAM, client);
					CPrintToChat(client, "%s Vous n'avez pas assez d'argent en liquide.", TEAM);
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
					return;
				}
			}
			
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) + quantity);
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_technicien` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		}
		else if(StrEqual(buffer[4], "non"))
		{
			if(client != vendeur)
			{
				CPrintToChat(vendeur, "%s %N a refusé votre offre.", TEAM, client);
				CPrintToChat(client, "%s Vous avez refusé la vente de %N.", TEAM, vendeur);
				
				rp_SetClientBool(vendeur, b_menuOpen, false);
				rp_SetClientBool(client, b_menuOpen, false);
			}
			else CPrintToChat(client, "%s Vous avez refusé le paiement.", TEAM);
		}
		if(!StrEqual(buffer[4], "non"))
		{
			rp_SetupRingPoint(client, vendeur);
		}		
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else
	{
		if(action == MenuAction_End)
			delete menu;
	}
}
/************************************************/