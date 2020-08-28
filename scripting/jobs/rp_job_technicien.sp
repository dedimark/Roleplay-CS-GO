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

							P L U G I N  -  D E F I N E S

***************************************************************************************/
#define MAXENTITIES 2048

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
char dbconfig[] = "roleplay";

Database g_DB;

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
	if(rp_licensing_isValid())
	{
		GameCheck();		
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_technicien.log");
		Database.Connect(GotDatabase, dbconfig);
		
		rewardTased = CreateConVar("rp_tase_imprimante", "500", "Recompense lors d'un tase imprimante");	
		ImprimanteTimer = CreateConVar("rp_imprimante_timer", "10.0", "Temps  avant la recompense de l'argent");
		ImprimanteCash = CreateConVar("rp_imprimante_cash", "3", "Montant de la recompense sans mise à jour");
		ImprimanteCashv2 = CreateConVar("rp_imprimante_cash_v2", "5", "Montant de la recompense mise à jour v2.0");
		ImprimanteCashv3 = CreateConVar("rp_imprimante_cash_v3", "10", "Montant de la recompense mise à jour v3.0");
		ImprimanteCashMax = CreateConVar("rp_imprimante_cash_max", "500", "Montant max de la liasse sans compte en suisse");
		AutoExecConfig(true, "rp_job_technicien");
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
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_technicien` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `blindage` int(100) NOT NULL, \
		  `recharge` int(100) NOT NULL, \
		  `ameliorationv1` int(100) NOT NULL, \
		  `ameliorationv2` int(100) NOT NULL, \
		  `imprimantes` int(100) NOT NULL, \
		  `rechargebionique` int(100) NOT NULL, \
		  `mines` int(100) NOT NULL, \
		  `propulseur` int(100) NOT NULL, \
		  `gestionnaire` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void OnClientDisconnect(int client)
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
	SQL_EscapeString(g_DB, playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_technicien` (`Id`, `steamid`, `playername`, `blindage`, `recharge`, `ameliorationv1`, `ameliorationv2`, `imprimantes`, `rechargebionique`, `mines`, `propulseur`, `gestionnaire`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadTech(client);
}

public void SQLCALLBACK_LoadTech(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_technicien WHERE steamid = '%s';", steamID[client]);
	g_DB.Query(SQLLoadTechQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadTechQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientItem(client, i_blindage, SQL_FetchIntByName(Results, "blindage"));
		rp_SetClientItem(client, i_recharge, SQL_FetchIntByName(Results, "recharge"));
		rp_SetClientItem(client, i_ameliorationv1, SQL_FetchIntByName(Results, "ameliorationv1"));
		rp_SetClientItem(client, i_ameliorationv2, SQL_FetchIntByName(Results, "ameliorationv2"));
		rp_SetClientItem(client, i_imprimantes, SQL_FetchIntByName(Results, "imprimantes"));
		rp_SetClientItem(client, i_rechargebionique, SQL_FetchIntByName(Results, "rechargebionique"));
		rp_SetClientItem(client, i_mines, SQL_FetchIntByName(Results, "mines"));
		rp_SetClientItem(client, i_propulseur, SQL_FetchIntByName(Results, "propulseur"));
		rp_SetClientItem(client, i_gestionnaire, SQL_FetchIntByName(Results, "gestionnaire"));
	}
} 

public void rp_OnClientDeath(int attacker, int victim, const char[] weapon, bool headshot)
{
	ClientCommand(victim, "r_screenoverlay 0");	

	rp_SetClientBool(victim, b_doubleImprimante, false);
	rp_SetClientBool(victim, b_regenerationbionique, false);
}	

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if(StrEqual(entModel, "models/freeman/compact_printer.mdl") && Distance(client, aim) <= 80.0)
	{
		if (StrContains(entName, steamID[client]) != -1)
			MenuImprimante(client, aim);
		else 
			PrintHintText(client, "(?) Avez-vous essayé de pirater cette imprimante ?");			
	}	
	else if(StrEqual(entName, "Technicien") && Distance(client, aim) <= 80.0)
	{
		int nbTech;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				if(rp_GetClientInt(i, i_Job) == 10 && !rp_GetClientBool(i, b_isAfk))
					nbTech++;
			}
		}
		if(nbTech == 0 || nbTech == 1 && rp_GetClientInt(client, i_Job) == 10 || rp_GetClientInt(client, i_Job) == 10 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un technicien.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un technicien.");
		}
	}
	else if(StrEqual(entModel, "models/props/cs_assault/money.mdl") && Distance(client, aim) <= 80.0)
	{
		char buff4[2][64];
		ExplodeString(entName, "|", buff4, 2, 64);
		// buff4[0] : nom proprio
		int montant = StringToInt(buff4[1]);
		if(montant <= 0) montant = 10;
	
		if(StrContains(buff4[0], "braquage", false) == -1)
		{
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + montant);
			SetSQL_Int(g_DB, "rp_economy", "money", rp_GetClientInt(client, i_Money), steamID[client]);
			rp_SetJobCapital(5, rp_GetJobCapital(5) - montant);
			EmitCashSound(client, montant);
			
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientValid(i))
				{
					if(entBillet[i][0] == aim)
					{
						entBillet[i][0] = -1;
						char pseudo[32];
						GetClientName(i, pseudo, sizeof(pseudo));
						if(!StrEqual(buff4[0], pseudo))
							CPrintToChat(i, "Les billets de votre imprimante à faux billet ont été volés !");
						CPrintToChat(client, "%s Vous avez récupéré %i$.", TEAM, montant);
						break;
					}
					if(entBillet[i][1] == aim)
					{
						entBillet[i][1] = -1;
						char pseudo[32];
						GetClientName(i, pseudo, sizeof(pseudo));
						if(!StrEqual(buff4[0], pseudo))
							CPrintToChat(i, "Les billets de votre imprimante à faux billet ont été volés !");
						CPrintToChat(client, "%s Vous avez récupéré %i$.", TEAM, montant);
						break;
					}
				}
			}
		}
		else
		{
			if(rp_GetClientInt(client, i_Job) == 1)
			{
				rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + 100);
				SetSQL_Int(g_DB, "rp_economy", "money", rp_GetClientInt(client, i_Money), steamID[client]);
				rp_SetJobCapital(5, rp_GetJobCapital(5) - 100);
				EmitCashSound(client, 100);
			}
			else if(rp_GetClientInt(client, i_Job) == 2)
			{
				rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + montant / 2);
				SetSQL_Int(g_DB, "rp_economy", "money", rp_GetClientInt(client, i_Money), steamID[client]);
				rp_SetJobCapital(3, rp_GetJobCapital(3) + montant / 2);
				rp_SetJobCapital(5, rp_GetJobCapital(5) - montant);
				EmitCashSound(client, montant / 2);
			}
		}
		if(IsValidEdict(aim))
			RemoveEdict(aim);
	}
}	

public Action rp_OnTasedItem(int client, int aim, int reward, const char[] entName, const char[] entModel, const char[] entClassName)
{
	char buffer[2][64];
	ExplodeString(entName, "|", buffer, 2, 64);
	
	if(StrEqual(entModel, "models/freeman/compact_printer.mdl") && Distance(client, aim) <= 180)
	{
		CPrintToChat(client, "%s Vous avez saisi un appareil de contrebande.", TEAM);
		int joueur = Client_FindBySteamId(buffer[0]);
					
		reward = GetConVarInt(rewardTased);
		CPrintToChat(client, "%s Le Commadant vous reverse une prime de 500$ pour cette saisie.", TEAM);
					
		CreateTimer(0.1, ExplodeImprimante, aim);
		RemoveEdict(aim);
		
		entBillet[joueur][StringToInt(buffer[1])] = -1;
		entMachine[joueur][StringToInt(buffer[1])] = -1;
					
		if(IsClientValid(joueur))
			CPrintToChat(joueur, "%s Votre imprimante à faux billet à été saisie par le {lightred}service de Police{default}.", TEAM);	
	}
}	

public Action rp_MenuBuild(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_Job) == 10)
	{
		menu.SetTitle("Build - Technicien");
		menu.AddItem("imprimante", "Installer une imprimante");
	}	
}	

public Action rp_OnWeaponFire(int client, int aim, const char[] weaponName)
{
	char entModel[64];
	Entity_GetModel(aim, entModel, sizeof(entModel));
	if(StrEqual(entModel, "models/freeman/compact_printer.mdl"))
	{
		float position[3];
		if(healthEnt[aim] - 11 > 0)
		{
			healthEnt[aim] -= 11;
			PointVision(client, position);
			float dir[3] = {0.0, 0.0, 1.0};
			TE_SetupMetalSparks(position, dir);
			TE_SendToAll();
		}
		else if(healthEnt[aim] != 0)
		{
			GetEntPropVector(aim, Prop_Send, "m_vecOrigin", position);
			position[2] += 4;
			rp_CreateFire(position, 4.5);
			CreateTimer(5.0, ExplodeImprimante, aim);
		}
	}	
}	

public int rp_HandlerMenuBuild(int client, const char[] info)
{
	if(StrEqual(info, "imprimante"))
	{
		if(rp_GetClientInt(client, i_ByteZone) == 777)
		{
			if (entMachine[client][0] != -1 && !rp_GetClientBool(client, b_doubleImprimante))
				CPrintToChat(client, "%s Vous n'avez pas les compétences d'installer plusieurs imprimantes.", TEAM);
			else if (rp_GetClientBool(client, b_doubleImprimante) && entMachine[client][0] != -1 && entMachine[client][1] != -1)
				CPrintToChat(client, "%s Vous avez déjà posé 2 imprimantes.", TEAM);
			else
			{
				PrecacheModel("models/freeman/compact_printer.mdl");
				int ent = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(ent, "solid", "6");
				DispatchKeyValue(ent, "model", "models/freeman/compact_printer.mdl");
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

public Action rp_MenuInventory(int client, Menu menu)
{
	char amount[64];
	
	//menu.AddItem("", "⁂ Electroniques ⁂", ITEMDRAW_DISABLED);
	
	if(rp_GetClientItem(client, i_blindage) >= 1)
	{
		Format(STRING(amount), "Blindage [%i]", rp_GetClientItem(client, i_blindage));
		menu.AddItem("blindage", amount, ITEMDRAW_DISABLED);
	}

	if(rp_GetClientItem(client, i_recharge) >= 1)
	{
		Format(STRING(amount), "Recharge Imprimante [%i]", rp_GetClientItem(client, i_recharge));
		menu.AddItem("recharge", amount, ITEMDRAW_DISABLED);
	}
	
	if(rp_GetClientItem(client, i_ameliorationv1) >= 1)
	{
		Format(STRING(amount), "Amelioration v1 [%i]", rp_GetClientItem(client, i_ameliorationv1));
		menu.AddItem("ameliorationv1", amount, ITEMDRAW_DISABLED);
	}
	
	if(rp_GetClientItem(client, i_ameliorationv2) >= 1)
	{
		Format(STRING(amount), "Amelioration v2 [%i]", rp_GetClientItem(client, i_ameliorationv2));
		menu.AddItem("ameliorationv2", amount, ITEMDRAW_DISABLED);
	}
	
	if(rp_GetClientItem(client, i_imprimantes) >= 1)
	{
		Format(STRING(amount), "Imprimantes [%i]", rp_GetClientItem(client, i_imprimantes));
		menu.AddItem("imprimantes", amount);
	}
	
	if(rp_GetClientItem(client, i_rechargebionique) >= 1)
	{
		Format(STRING(amount), "Recharge bionique [%i]", rp_GetClientItem(client, i_rechargebionique));
		menu.AddItem("rechargebionique", amount);
	}
	
	if(rp_GetClientItem(client, i_mines) >= 1)
	{
		Format(STRING(amount), "Mines [%i]", rp_GetClientItem(client, i_mines));
		menu.AddItem("mines", amount);
	}
	
	if(rp_GetClientItem(client, i_propulseur) >= 1)
	{
		Format(STRING(amount), "Propulseur [%i]", rp_GetClientItem(client, i_propulseur));
		menu.AddItem("propulseur", amount);
	}
}	
	
public int rp_HandlerMenuInventory(int client, char[] info)
{
	if(StrEqual(info, "imprimantes") && IsPlayerAlive(client))
	{
		if(rp_GetClientInt(client, i_ByteZone) == 777)
		{
			if (entMachine[client][0] != -1 && !rp_GetClientBool(client, b_doubleImprimante))
				CPrintToChat(client, "%s Vous n'avez pas les compétences d'installer plusieurs imprimantes.", TEAM);
			else if (rp_GetClientBool(client, b_doubleImprimante) && entMachine[client][0] != -1 && entMachine[client][1] != -1)
				CPrintToChat(client, "%s Vous avez déjà posé 2 imprimantes.", TEAM);
			else
			{
				rp_SetClientItem(client, i_imprimantes, rp_GetClientItem(client, i_imprimantes) - 1);
				SetSQL_Int(g_DB, "rp_technicien", "imprimantes", rp_GetClientItem(client, i_imprimantes), steamID[client]);
				
				PrecacheModel("models/freeman/compact_printer.mdl");
				int ent = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(ent, "solid", "6");
				DispatchKeyValue(ent, "model", "models/freeman/compact_printer.mdl");
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
	else if(StrEqual(info, "rechargebionique") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, i_rechargebionique, rp_GetClientItem(client, i_rechargebionique) - 1);
		SetSQL_Int(g_DB, "rp_technicien", "rechargebionique", rp_GetClientItem(client, i_rechargebionique), steamID[client]);
	}
	else if(StrEqual(info, "mines") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_C4) == -1)
		{
			rp_SetClientItem(client, i_mines, rp_GetClientItem(client, i_mines) - 1);
			SetSQL_Int(g_DB, "rp_technicien", "mines", rp_GetClientItem(client, i_mines), steamID[client]);
				
			GivePlayerItem(client, "weapon_bumpmine");
			
			CPrintToChat(client, "%s Vous utilisez des mines.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise des mines.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà des mines.", TEAM);
	}
	else if(StrEqual(info, "propulseur") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_C4) == -1)
		{
			rp_SetClientItem(client, i_propulseur, rp_GetClientItem(client, i_propulseur) - 1);
			SetSQL_Int(g_DB, "rp_technicien", "propulseur", rp_GetClientItem(client, i_propulseur), steamID[client]);
				
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
					PrecacheModel("models/props/cs_assault/money.mdl");
					int ent = CreateEntityByName("prop_dynamic_override");
					DispatchKeyValue(ent, "solid", "6");
					DispatchKeyValue(ent, "model", "models/props/cs_assault/money.mdl");
					DispatchSpawn(ent);
					
					if (ameliorationImprimante[client][i] == 0)
						Format(STRING(strFormat), "%N|1", client);
					else if (ameliorationImprimante[client][i] == 1)
						Format(STRING(strFormat), "%N|2", client);
					else if (ameliorationImprimante[client][i] == 2)
						Format(STRING(strFormat), "%N|3", client);
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
				rp_SetClientItem(client, i_recharge, rp_GetClientItem(client, i_recharge) - 1);
				SetSQL_Int(g_DB, "rp_technicien", "imprimantes", rp_GetClientItem(client, i_recharge), steamID[client]);
				
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
				
				rp_SetClientItem(client, i_imprimantes, rp_GetClientItem(client, i_imprimantes) + 1);
				SetSQL_Int(g_DB, "rp_technicien", "imprimantes", rp_GetClientItem(client, i_imprimantes), steamID[client]);
				
				CPrintToChat(client, "%s Vous avez rangé votre imprimante à faux billets dans votre inventaire.", TEAM);
			}
			else if (StrEqual(buffer[0], "1.0"))
			{
				ameliorationImprimante[client][num] = 1;
				
				rp_SetClientItem(client, i_ameliorationv1, rp_GetClientItem(client, i_ameliorationv1) - 1);
				SetSQL_Int(g_DB, "rp_technicien", "ameliorationv1", rp_GetClientItem(client, i_ameliorationv1), steamID[client]);
				
				CPrintToChat(client, "%s L'imprimante a été mis à jour (1.0).", TEAM);
			}
			else if (StrEqual(buffer[0], "2.0"))
			{
				ameliorationImprimante[client][num] = 2;
				
				rp_SetClientItem(client, i_ameliorationv2, rp_GetClientItem(client, i_ameliorationv2) - 1);
				SetSQL_Int(g_DB, "rp_technicien", "ameliorationv2", rp_GetClientItem(client, i_ameliorationv2), steamID[client]);
				
				CPrintToChat(client, "%s L'imprimante a été mis à jour (2.0).", TEAM);
			}
			else if (StrEqual(buffer[0], "blinder"))
			{
				blindageImprimante[client][num] = true;
				healthEnt[entMachine[client][num]] = 1000;
				
				rp_SetClientItem(client, i_blindage, rp_GetClientItem(client, i_blindage) - 1);
				SetSQL_Int(g_DB, "rp_technicien", "blindage", rp_GetClientItem(client, i_blindage), steamID[client]);
				
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
	menu.AddItem("tech", "Electronique");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "tech"))
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

public Action rp_MenuVendre(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 10)
	{
		menu.AddItem("tech", "Electronique");
	}
}	

public int rp_HandleMenuVendre(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "tech"))
		SellTech(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellTech(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Electroniques Disponibles");

	prix = rp_GetPrice("blindage");
	Format(STRING(strFormat), "%i|%i|blindage", target, prix);
	Format(STRING(strMenu), "Blindage (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("recharge");
	Format(STRING(strFormat), "%i|%i|recharge", target, prix);
	Format(STRING(strMenu), "Recharge (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("ameliorationv1");
	Format(STRING(strFormat), "%i|%i|ameliorationv1", target, prix);
	Format(STRING(strMenu), "Amélioration v1 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("ameliorationv2");
	Format(STRING(strFormat), "%i|%i|ameliorationv2", target, prix);
	Format(STRING(strMenu), "Amélioration v2 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("imprimantes");
	Format(STRING(strFormat), "%i|%i|imprimantes", target, prix);
	Format(STRING(strMenu), "Imprimante (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("rechargebionique");
	Format(STRING(strFormat), "%i|%i|rechargebionique", target, prix);
	Format(STRING(strMenu), "Recharge bionique (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("mines");
	Format(STRING(strFormat), "%i|%i|mines", target, prix);
	Format(STRING(strMenu), "Mines propulsives (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("propulseur");
	Format(STRING(strFormat), "%i|%i|propulseur", target, prix);
	Format(STRING(strMenu), "Propulseur (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}			

public int DoSell(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32], buffer[3][64], strQuantite[128], strFormat[64], strAppart[2][32];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		
		ExplodeString(info, "|", buffer, 3, 64);
		ExplodeString(buffer[2], "_", strAppart, 2, 32);
			
		int target = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[1]);

		/* MENU QUANTITE */
		
		Menu quantity = new Menu(DoMenuQuantity);
		quantity.SetTitle("Choisissez la quantité");
			
		for(int i = 1; i <= 10; i++)
		{			
			Format(STRING(strQuantite), "%i|%i|%s|%i", target, prix, buffer[2], i);
			Format(STRING(strFormat), "%i", i);
			quantity.AddItem(strQuantite, strFormat);
		}	
		Format(STRING(strQuantite), "%i|%i|%s|25", target, prix, buffer[2]);
		quantity.AddItem(strQuantite, "25");
		Format(STRING(strQuantite), "%i|%i|%s|50", target, prix, buffer[2]);
		quantity.AddItem(strQuantite, "50");
		Format(STRING(strQuantite), "%i|%i|%s|100", target, prix, buffer[2]);
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
		int quantity = StringToInt(buffer[3]);
		int prix = StringToInt(buffer[1]) * quantity;
		
		rp_SetClientBool(target, b_menuOpen, true);
		Menu request = new Menu(FinalMenu);
		
		if(target != client)
			request.SetTitle("%N vous propose %i %s pour %i$, acheter ?", client, quantity, buffer[2], prix);	
		else
			request.SetTitle("Acheter %i %s pour %i$ ?", quantity, buffer[2], prix);				
				
		
		Format(STRING(response), "%i|%i|%s|%i|oui", client, quantity, buffer[2], prix);		
		request.AddItem(response, "Payer en liquide.");
		
		if(rp_GetClientBool(target, b_asCb))
		{
			Format(STRING(response), "%i|%i|%s|%i|cb", client, quantity, buffer[2], prix);			
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
		bool payCB;
		
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
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, buffer[2], prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, buffer[2], prix);
					}
					else
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, buffer[2], vendeur, prix);
						CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, buffer[2], client, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, buffer[2], prix, client);
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
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, buffer[2], prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, buffer[2], prix);
					}
					else
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, buffer[2], vendeur, prix);
						CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, buffer[2], client, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, buffer[2], prix, client);
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
			
			if(StrEqual(buffer[2], "blindage"))
			{
				rp_SetClientItem(client, i_blindage, rp_GetClientItem(client, i_blindage) + quantity);	
				SetSQL_Int(g_DB, "rp_technicien", buffer[2], rp_GetClientItem(client, i_blindage), steamID[client]);
			}
			else if(StrEqual(buffer[2], "recharge"))
			{
				rp_SetClientItem(client, i_recharge, rp_GetClientItem(client, i_recharge) + quantity);	
				SetSQL_Int(g_DB, "rp_technicien", buffer[2], rp_GetClientItem(client, i_recharge), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ameliorationv1"))
			{
				rp_SetClientItem(client, i_ameliorationv1, rp_GetClientItem(client, i_ameliorationv1) + quantity);	
				SetSQL_Int(g_DB, "rp_technicien", buffer[2], rp_GetClientItem(client, i_ameliorationv1), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ameliorationv1"))
			{
				rp_SetClientItem(client, i_ameliorationv2, rp_GetClientItem(client, i_ameliorationv2) + quantity);	
				SetSQL_Int(g_DB, "rp_technicien", buffer[2], rp_GetClientItem(client, i_ameliorationv2), steamID[client]);
			}	
			else if(StrEqual(buffer[2], "imprimantes"))
			{
				rp_SetClientItem(client, i_imprimantes, rp_GetClientItem(client, i_imprimantes) + quantity);	
				SetSQL_Int(g_DB, "rp_technicien", buffer[2], rp_GetClientItem(client, i_imprimantes), steamID[client]);
			}
			else if(StrEqual(buffer[2], "rechargebionique"))
			{
				rp_SetClientItem(client, i_rechargebionique, rp_GetClientItem(client, i_rechargebionique) + quantity);	
				SetSQL_Int(g_DB, "rp_technicien", buffer[2], rp_GetClientItem(client, i_rechargebionique), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mines"))
			{
				rp_SetClientItem(client, i_mines, rp_GetClientItem(client, i_mines) + quantity);	
				SetSQL_Int(g_DB, "rp_technicien", buffer[2], rp_GetClientItem(client, i_mines), steamID[client]);
			}
			else if(StrEqual(buffer[2], "propulseur"))
			{
				rp_SetClientItem(client, i_propulseur, rp_GetClientItem(client, i_propulseur) + quantity);	
				SetSQL_Int(g_DB, "rp_technicien", buffer[2], rp_GetClientItem(client, i_propulseur), steamID[client]);
			}	
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