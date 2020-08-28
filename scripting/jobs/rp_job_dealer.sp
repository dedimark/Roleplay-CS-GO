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
#include <cstrike>
#include <sdkhooks>
#include <smlib>
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
#define COLOR_TASER			{15, 15, 255, 225}
#define MAX_DRYING			3
#define MAXENTITIES 		2048

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
int ColorEcstazy[4]	 			     = {220, 22, 226, 255};
int ColorCocaine[4]				     = {11, 234, 22, 255};
int ColorHeroine[4]				     = {239, 11, 46, 255};
int ColorShit[4]				     = {239, 239, 23, 255};
int ColorWeed[4]				     = {41, 19, 239, 255};
int ColorAmphetamine[4]		     	 = {66, 248, 255, 255};
int plante[5];
int g_BeamSpriteFollow;
int g_Glow;

int EntPlante[MAXPLAYERS + 1][2];
int planteCannabis[5];
int grammeCannabis;

enum drying_drugs {
	bool:COCAINE,
	bool:AMPHETAMINE,
	bool:HEROINE,
	bool:ECSTASY
};

int drying_drug_type[MAXENTITIES + 1][drying_drugs];
bool canUseDrying[MAXENTITIES + 1] = true;
int drying_timestamp[MAXENTITIES + 1];
int drying[MAXPLAYERS + 1];

char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];
char dbconfig[] = "roleplay";

Database g_DB;

Handle TimerRPT[MAXPLAYERS + 1] = { null, ... };

float g_fDiscoRotation[3] = 
{
	1093926912.0, ...
};

int g_iDefaultColors_c[6][3] = 
{
	{
		255, 0, 0
	}, 
	{
		0, 255, 0
	}, 
	{
		0, 0, 255
	}, 
	{
		255, 255, 0
	}, 
	{
		0, 255, 255
	}, 
	{
		255, 0, 255
	}
};

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Dealer", 
	author = "Benito", 
	description = "Métier Dealer", 
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
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_dealer.log");
		Database.Connect(GotDatabase, dbconfig);
		//AddFileToDownloadsTable("models/craphead_scripts/the_cocaine_factory/utility/cocaine_pack.mdl");
		//AddFileToDownloadsTable("models/craphead_scripts/the_cocaine_factory/utility/leaves.mdl");
		//AddFileToDownloadsTable("models/craphead_scripts/the_cocaine_factory/utility/soda.mdl");
		//AddFileToDownloadsTable("models/craphead_scripts/the_cocaine_factory/utility/stove_upgrade.mdl");
		//AddFileToDownloadsTable("models/craphead_scripts/the_cocaine_factory/drying_rack/drying_rack.mdl");
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
		"CREATE TABLE IF NOT EXISTS `rp_dealer` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `joint` int(100) NOT NULL, \
		  `shit` int(100) NOT NULL, \
		  `amphetamine` int(100) NOT NULL, \
		  `heroine` int(100) NOT NULL, \
		  `cocaine` int(100) NOT NULL, \
		  `ecstasy` int(100) NOT NULL, \
		  `plante` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void OnMapStart() 
{
	g_BeamSpriteFollow = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_Glow = PrecacheModel("materials/sprites/glow1.vmt", true);
	
	for(int i = MaxClients; i <= MAXENTITIES; i++)
		canUseDrying[i] = true;
}

public void OnClientDisconnect(int client)
{
	if(!IsClientInGame(client))
		return;
	
	rp_SetClientBool(client, b_isJoint, false);
	rp_SetClientBool(client, b_isShit, false);
	rp_SetClientBool(client, b_isAmphetamine, false);	
	rp_SetClientBool(client, b_isHeroine, false);
	rp_SetClientBool(client, b_isCocaine, false);	
	rp_SetClientBool(client, b_isEcstasy, false);	
	
	if(IsValidEntity(EntPlante[client][0]))
	{
		RemoveEdict(EntPlante[client][0]);
		EntPlante[client][0] = -1;
	}
	
	if(IsValidEntity(EntPlante[client][1]))
	{
		RemoveEdict(EntPlante[client][1]);
		EntPlante[client][1] = -1;
	}
	
	TrashTimer(TimerRPT[client], true);
}

public void OnClientPutInServer(int client)
{
	rp_SetClientBool(client, b_isJoint, false);
	rp_SetClientBool(client, b_isShit, false);
	rp_SetClientBool(client, b_isAmphetamine, false);	
	rp_SetClientBool(client, b_isHeroine, false);
	rp_SetClientBool(client, b_isCocaine, false);	
	rp_SetClientBool(client, b_isEcstasy, false);
	drying[client] = 0;
	
	EntPlante[client][0] = -1;
	EntPlante[client][1] = -1;
	
	TimerRPT[client] = CreateTimer(1.0, update, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
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
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_dealer` (`Id`, `steamid`, `playername`, `joint`, `shit`, `amphetamine`, `heroine`, `cocaine`, `ecstasy`, `plante`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadDealer(client);
}

public void SQLCALLBACK_LoadDealer(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_dealer WHERE steamid = '%s';", steamID[client]);
	g_DB.Query(SQLLoadDealerQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadDealerQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientItem(client, i_joint, SQL_FetchIntByName(Results, "joint"));
		rp_SetClientItem(client, i_shit, SQL_FetchIntByName(Results, "shit"));
		rp_SetClientItem(client, i_amphetamine, SQL_FetchIntByName(Results, "amphetamine"));
		rp_SetClientItem(client, i_heroine, SQL_FetchIntByName(Results, "heroine"));
		rp_SetClientItem(client, i_cocaine, SQL_FetchIntByName(Results, "cocaine"));
		rp_SetClientItem(client, i_ecstasy, SQL_FetchIntByName(Results, "ecstasy"));
		rp_SetClientItem(client, i_plante, SQL_FetchIntByName(Results, "plante"));
	}
} 

public void rp_OnClientDeath(int attacker, int victim, const char[] weapon, bool headshot)
{
	if(rp_GetClientBool(victim, b_isJoint))
		rp_SetClientBool(victim, b_isJoint, false);
		
	if(rp_GetClientBool(victim, b_isShit))
		rp_SetClientBool(victim, b_isShit, false);
	
	if(rp_GetClientBool(victim, b_isAmphetamine))
		rp_SetClientBool(victim, b_isAmphetamine, false);	
	
	if(rp_GetClientBool(victim, b_isHeroine))
		rp_SetClientBool(victim, b_isHeroine, false);
		
	if(rp_GetClientBool(victim, b_isCocaine))
		rp_SetClientBool(victim, b_isCocaine, false);	
		
	if(rp_GetClientBool(victim, b_isEcstasy))
		rp_SetClientBool(victim, b_isEcstasy, false);		
}

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if(StrEqual(entName, "coffre_dealer"))
		CPrintToChat(client, "%s En developement", TEAM);
	else if(StrEqual(entName, "Trafiquant"))
	{
		int nbDealer;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				if(rp_GetClientInt(i, i_Job) == 8 && !rp_GetClientBool(i, b_isAfk))
					nbDealer++;
			}
		}
		if(nbDealer == 0 && rp_GetClientInt(client, i_Job) != 9)
			NPC_MENU(client);
		else 
		{
			if(rp_GetClientInt(client, i_Job) == 9)
			{				
				PrintHintText(client, "Malheureusement vous ne pouvez pas vous vendre à vous même.\n Aller en fabriquer.");
				CPrintToChat(client, "Malheureusement vous ne pouvez pas vous vendre à vous même.\n Aller en fabriquer.");
			}
			else if(nbDealer > 1)
			{
				PrintHintText(client, "Malheureusement je suis indisponible, contactez un dealer.");
				CPrintToChat(client, "Malheureusement je suis indisponible, contactez un dealer.");
			}
		}
	}	
	else if(StrEqual(entModel, "models/revolution/weed/weedplant_pot_v7.mdl") && Distance(client, aim) <= 80.0 && rp_GetClientInt(client, i_Job) == 9)
	{
		if(IsValidEntity(aim))
		{
			if(IsValidEdict(aim))
				RemoveEdict(aim);
			int nombre = GetRandomInt(0, 15);
			if(nombre <= 2)
			{
				CPrintToChat(client, "%s Cette plante est un mâle, seul les femelles produisent !", TEAM);
				
				char buffer[2][64];
				ExplodeString(entName, "|", buffer, 2, 64);
				
				if(StrEqual(buffer[0], "1") && rp_GetClientInt(client, i_Grade) == 1)
				{
					planteCannabis[0]--;
				}	
				else if(StrEqual(buffer[0], "2") && rp_GetClientInt(client, i_Grade) == 2)
				{
					planteCannabis[1]--;
				}
				else if(StrEqual(buffer[0], "3") && rp_GetClientInt(client, i_Grade) == 3)
				{
					planteCannabis[2]--;
				}
				else if(StrEqual(buffer[0], "4") && rp_GetClientInt(client, i_Grade) == 4)
				{
					planteCannabis[3]--;
				}
				else if(StrEqual(buffer[0], "5") && rp_GetClientInt(client, i_Grade) == 5)
				{
					planteCannabis[4]--;
				}
				else
					CPrintToChat(client, "%s C'est mal de voler ses collègues", TEAM);
			}
			else
			{
				grammeCannabis += nombre;
				
				if(rp_GetClientInt(client, i_Grade) == 1)
				{
					planteCannabis[0]--;
				}	
				else if(rp_GetClientInt(client, i_Grade) == 2)
				{
					planteCannabis[1]--;
				}
				else if(rp_GetClientInt(client, i_Grade) == 3)
				{
					planteCannabis[2]--;
				}
				else if(rp_GetClientInt(client, i_Grade) == 4)
				{
					planteCannabis[3]--;
				}
				else if(rp_GetClientInt(client, i_Grade) == 5)
				{
					planteCannabis[4]--;
				}
				else
					CPrintToChat(client, "%s C'est mal de voler ses collègues", TEAM);
					
				CPrintToChat(client, "%s Vous avez récolté %ig de cannabis.", TEAM, nombre);
			}
		}
	}
	else if(StrContains(entModel, "weedplant_pot_") != -1 && !StrEqual(entModel, "models/revolution/weed/weedplant_pot_v7.mdl") && Distance(client, aim) <= 80.0 && rp_GetClientInt(client, i_Job) == 9)
	{
		CPrintToChat(client, "%s Cette plante n'est pas encore prête pour la recolte.", TEAM);
		PrintHintText(client, "<font color='#5100A2'>Cette plante n'est pas encore prête pour la recolte.</font>");
	}	
	else if(StrEqual(entModel, "models/drugs/drying_rack/drying_rack.mdl") && Distance(client, aim) <= 80.0 && rp_GetClientInt(client, i_Job) == 9)
	{
		DrawDryingDrugBuild(client, aim);
	}
	else if(StrContains(entModel, "cocaine_pack.mdl") != -1 && Distance(client, aim) <= 80.0 && rp_GetClientInt(client, i_Job) == 9)
	{
		if(rp_GetClientInt(client, i_Job) != 9)
			CPrintToChat(client, "%s Vous n'avez pas l'habilité de récolter de la Cocaïne !", TEAM);
		
		if(IsValidEntity(aim))
		{
			if(IsValidEdict(aim))
				RemoveEdict(aim);
			int value = GetRandomInt(1, 3);
			
			rp_SetStock(stock_cocaine, rp_GetStock(stock_cocaine) + value);
			UpdateSQL(g_DB, "UPDATE rp_stocks SET cocaine = %i;", rp_GetStock(stock_cocaine));
			CPrintToChat(client, "%s Vous avez récolté %ig de Cocaïne.", TEAM, value);
		}	
	}
	else if(StrContains(entModel, "leaves.mdl") != -1 && Distance(client, aim) <= 80.0 && rp_GetClientInt(client, i_Job) == 9)
	{
		if(rp_GetClientInt(client, i_Job) != 9)
			CPrintToChat(client, "%s Vous n'avez pas l'habilité de récolter de l'Amphétamine !", TEAM);
		
		if(IsValidEntity(aim))
		{
			if(IsValidEdict(aim))
				RemoveEdict(aim);
			int value = GetRandomInt(1, 3);
			
			rp_SetStock(stock_amphetamine, rp_GetStock(stock_amphetamine) + value);
			UpdateSQL(g_DB, "UPDATE rp_stocks SET cocaine = %i;", rp_GetStock(stock_amphetamine));
			CPrintToChat(client, "%s Vous avez récolté %ig d'Amphétamine.", TEAM, value);
		}	
	}
	else if(StrContains(entModel, "soda.mdl") != -1 && Distance(client, aim) <= 80.0 && rp_GetClientInt(client, i_Job) == 9)
	{
		if(rp_GetClientInt(client, i_Job) != 9)
			CPrintToChat(client, "%s Vous n'avez pas l'habilité de récolter de l'Heroïne !", TEAM);
		
		if(IsValidEntity(aim))
		{
			if(IsValidEdict(aim))
				RemoveEdict(aim);
			int value = GetRandomInt(1, 3);
			
			rp_SetStock(stock_heroine, rp_GetStock(stock_heroine) + value);
			UpdateSQL(g_DB, "UPDATE rp_stocks SET cocaine = %i;", rp_GetStock(stock_heroine));
			CPrintToChat(client, "%s Vous avez récolté %ig d'Heroïne.", TEAM, value);
		}	
	}
	else if(StrContains(entModel, "stove_upgrade.mdl") != -1 && Distance(client, aim) <= 80.0 && rp_GetClientInt(client, i_Job) == 9)
	{
		if(rp_GetClientInt(client, i_Job) != 9)
			CPrintToChat(client, "%s Vous n'avez pas l'habilité de récolter de l'Ecstasy !", TEAM);
		
		if(IsValidEntity(aim))
		{
			if(IsValidEdict(aim))
				RemoveEdict(aim);
			int value = GetRandomInt(1, 3);
			
			rp_SetStock(stock_ecstasy, rp_GetStock(stock_ecstasy) + value);
			UpdateSQL(g_DB, "UPDATE rp_stocks SET cocaine = %i;", rp_GetStock(stock_ecstasy));
			CPrintToChat(client, "%s Vous avez récolté %ig d'Ecstasy.", TEAM, value);
		}	
	}
}	

public Action rp_OnTasedItem(int client, int aim, int reward, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if(StrContains(entModel, "weedplant", false) != -1 && Distance(client, aim) <= 80)
	{
		if(IsValidEdict(aim))
			RemoveEdict(aim);
					
		char buffer[2][64];
		ExplodeString(entName, "|", buffer, 2, 64);
					
		int joueur = Client_FindBySteamId(buffer[1]);
					
		if(StrEqual(buffer[0], "1"))
			plante[0]--;
		else if(StrEqual(buffer[0], "2"))
			plante[1]--;
		else if(StrEqual(buffer[0], "3"))
			plante[2]--;	
		else if(StrEqual(buffer[0], "4"))
			plante[3]--;
		else if(StrEqual(buffer[0], "5"))
			plante[4]--;		
					
		if(IsClientValid(joueur))
			CPrintToChat(joueur, "%s Une plante de cannabis a été saisi par le service de Police.", TEAM);
					
		reward = 100;

		CPrintToChat(client, "%s Vous avez saisi une plante de cannabis.", TEAM);
		CPrintToChat(client, "%s Le Chef Police vous reverse une prime de 100$ pour cette saisie.", TEAM);
	}
	else if(StrContains(entModel, "cocaine_pack.mdl", false) != -1 || StrContains(entModel, "leaves.mdl", false) != -1 
	|| StrContains(entModel, "soda.mdl", false) != -1 || StrContains(entModel, "stove_upgrade.mdl", false) != -1 && Distance(client, aim) <= 80)
	{
		if(IsValidEdict(aim))
			RemoveEdict(aim);
					
		int joueur = Client_FindBySteamId(entName);		
					
		if(IsClientValid(joueur))
			CPrintToChat(joueur, "%s De la drogue vous a été saisi par le service de Police.", TEAM);
					
		reward = 50;

		CPrintToChat(client, "%s Vous avez saisi de la drogue de contre bande.", TEAM);
		CPrintToChat(client, "%s Le Chef Police vous reverse une prime de 50$ pour cette saisie.", TEAM);
	}
	else if(StrContains(entModel, "drying_rack.mdl", false) != -1 && Distance(client, aim) <= 80)
	{
		if(IsValidEdict(aim))
			RemoveEdict(aim);
					
		int joueur = Client_FindBySteamId(entName);		
		drying[joueur]--;
					
		if(IsClientValid(joueur))
			CPrintToChat(joueur, "%s Un étendoir vous a été saisi par le service de Police.", TEAM);
					
		reward = 100;

		CPrintToChat(client, "%s Vous avez saisi un étendoir de contre bande.", TEAM);
		CPrintToChat(client, "%s Le Chef Police vous reverse une prime de 100$ pour cette saisie.", TEAM);
	}
}	

public Action rp_MenuBuild(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_Job) == 9)
	{
		char strFormat[32];
		
		menu.SetTitle("Build - Dealer");
		menu.AddItem("cannabis", "Planter du Cannabis");
		if(drying[client] != MAX_DRYING)
		{
			Format(STRING(strFormat), "Etendoir de drogue (%i/3)", drying[client]);
			menu.AddItem("cocaine", strFormat);
		}	
		else
		{
			Format(STRING(strFormat), "Etendoir de drogue (%i/%i)", drying[client], MAX_DRYING);
			menu.AddItem("cocaine", strFormat, ITEMDRAW_DISABLED);
		}	
		menu.AddItem("dealer", "Gérer le stock");
		if(rp_GetClientInt(client, i_VipTime) != 0)
			menu.AddItem("dj", "Système DJ");
		else
			menu.AddItem("", "Système DJ(VIP)", ITEMDRAW_DISABLED);				
	}	
}	

public int rp_HandlerMenuBuild(int client, const char[] info)
{
	if(StrEqual(info, "cannabis"))
	{
		if(rp_GetClientInt(client, i_ByteZone) != 777)
		{
			char strBuffer[128];
			Format(STRING(strBuffer), "%i|%s", rp_GetClientInt(client, i_Grade), steamID[client]);
						
			if(plante[0] < 20 && rp_GetClientInt(client, i_Grade) == 1)
			{							
				BuildCanabisModel("models/revolution/weed/weedplant_pot_v1.mdl", strBuffer);
				plante[0]++;
					
				CPrintToChat(client, "%s Vous avez planté du cannabis, attendez qu'il pousse pour le récolter. [%i/20]", TEAM, plante[0]);
				LogToFile(logFile, "Le joueur %N a plante du cannabis. [%i/20]", client, plante[0]);
			}
			else if(plante[1] < 20 && rp_GetClientInt(client, i_Grade) == 2)
			{							
				BuildCanabisModel("models/revolution/weed/weedplant_pot_v1.mdl", strBuffer);				
				plante[1]++;
							
				CPrintToChat(client, "%s Vous avez planté du cannabis, attendez qu'il pousse pour le récolter. [%i/20]", TEAM, plante[1]);
				LogToFile(logFile, "Le joueur %N a plante du cannabis. [%i/20]", client, plante[1]);
			}
			else if(plante[2] < 20 && rp_GetClientInt(client, i_Grade) == 3)
			{							
				BuildCanabisModel("models/revolution/weed/weedplant_pot_v1.mdl", strBuffer);
				plante[2]++;
				
				CPrintToChat(client, "%s Vous avez planté du cannabis, attendez qu'il pousse pour le récolter. [%i/20]", TEAM, plante[2]);
				LogToFile(logFile, "Le joueur %N a plante du cannabis. [%i/20]", client, plante[2]);
			}
			else if(plante[3] < 20 && rp_GetClientInt(client, i_Grade) == 4)
			{							
				BuildCanabisModel("models/revolution/weed/weedplant_pot_v1.mdl", strBuffer);
				plante[3]++;
				
				CPrintToChat(client, "%s Vous avez planté du cannabis, attendez qu'il pousse pour le récolter. [%i/20]", TEAM, plante[3]);
				LogToFile(logFile, "Le joueur %N a plante du cannabis. [%i/20]", client, plante[3]);
			}
			else if(plante[4] < 20 && rp_GetClientInt(client, i_Grade) == 5)
			{							
				BuildCanabisModel("models/revolution/weed/weedplant_pot_v1.mdl", strBuffer);
				plante[4]++;
							
				CPrintToChat(client, "%s Vous avez planté du cannabis, attendez qu'il pousse pour le récolter. [%i/20]", TEAM, plante[4]);
				LogToFile(logFile, "Le joueur %N a plante du cannabis. [%i/20]", client, plante[4]);
			}
			else
				CPrintToChat(client, "%s Vous n'avez plus de graine ! [20/20]", TEAM);						
		}
		else 
			CPrintToChat(client, "%s Interdit de poser une plante en zone P.V.P", TEAM);
	}
	else if(StrEqual(info, "cocaine"))
	{
		if(rp_GetClientInt(client, i_ByteZone) != 777)
		{
			drying[client]++;
			
			PrecacheModel("models/drugs/drying_rack/drying_rack.mdl");
			int ent = CreateEntityByName("prop_physics_override");
			DispatchKeyValue(ent, "solid", "1");
			DispatchKeyValue(ent, "model", "models/drugs/drying_rack/drying_rack.mdl");			
			Entity_SetName(ent, steamID[client]);
			DispatchSpawn(ent);			
			
			float position[3];
			GetAimOrigin(client, position);
			TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
			
			CPrintToChat(client, "%s Vous avez installé un étendoir, attendez que les feuilles de cocaine sèchents. [%i/%i]", TEAM, drying[client], MAX_DRYING);		
			LogToFile(logFile, "Le joueur %N a installe du étendoir. [%i/%i]", client, drying[client], MAX_DRYING);	
		}
		else 
			CPrintToChat(client, "%s Interdit d'installer un étendoir en zone P.V.P", TEAM);
	}	
	else if (StrEqual(info, "dealer"))
		MenuDealer(client);
	else if (StrEqual(info, "dj"))
		MenuDJDealer(client);	
}	

int BuildCanabisModel(char[] model, char[] name)
{
	PrecacheModel(model);
	int ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "solid", "1");
	DispatchKeyValue(ent, "model", model);
	Entity_SetName(ent, name);
	DispatchSpawn(ent);
	
	char buffer[2][64];
	ExplodeString(name, "|", buffer, 2, 64);
	
	int client = Client_FindBySteamId(buffer[1]);
	
	float TeleportOrigin[3], JoueurOrigin[3];
	GetClientAbsOrigin(client, JoueurOrigin);
	TeleportOrigin[0] = JoueurOrigin[0];
	TeleportOrigin[1] = JoueurOrigin[1];
	TeleportOrigin[2] = (JoueurOrigin[2]);
	TeleportEntity(ent, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
	JoueurOrigin[2] += 35;
	TeleportEntity(client, JoueurOrigin, NULL_VECTOR, NULL_VECTOR);
	
	CreateTimer(5.0, WeedPousse, ent);
}	

public Action WeedPousse(Handle timer, any ent)
{
	if(IsValidEntity(ent))
	{
		char entModel[64];
		Entity_GetModel(ent, STRING(entModel));
		
		if(StrEqual(entModel, "models/revolution/weed/weedplant_pot_v1.mdl"))
		{
			rp_SetSkin(ent, "models/revolution/weed/weedplant_pot_v2.mdl");
			CreateTimer(GetRandomFloat(20.0, 40.0), WeedPousse, ent);
		}
		else if(StrEqual(entModel, "models/revolution/weed/weedplant_pot_v2.mdl"))
		{
			rp_SetSkin(ent, "models/revolution/weed/weedplant_pot_v3.mdl");
			CreateTimer(GetRandomFloat(20.0, 40.0), WeedPousse, ent);
		}
		else if(StrEqual(entModel, "models/revolution/weed/weedplant_pot_v3.mdl"))
		{
			rp_SetSkin(ent, "models/revolution/weed/weedplant_pot_v4.mdl");
			CreateTimer(GetRandomFloat(20.0, 40.0), WeedPousse, ent);
		}
		else if(StrEqual(entModel, "models/revolution/weed/weedplant_pot_v4.mdl"))
		{
			rp_SetSkin(ent, "models/revolution/weed/weedplant_pot_v5.mdl");
			CreateTimer(GetRandomFloat(20.0, 40.0), WeedPousse, ent);
		}
		else if(StrEqual(entModel, "models/revolution/weed/weedplant_pot_v5.mdl"))
		{
			rp_SetSkin(ent, "models/revolution/weed/weedplant_pot_v6.mdl");
			CreateTimer(GetRandomFloat(20.0, 40.0), WeedPousse, ent);
		}
		else if(StrEqual(entModel, "models/revolution/weed/weedplant_pot_v6.mdl"))
		{
			rp_SetSkin(ent, "models/revolution/weed/weedplant_pot_v7.mdl");
			CreateTimer(GetRandomFloat(20.0, 40.0), WeedPousse, ent);
		}
	}
}

public Action rp_MenuInventory(int client, Menu menu)
{
	char amount[64];
	
	//menu.AddItem("", "⁂ Drogues ⁂", ITEMDRAW_DISABLED);
	
	if(rp_GetClientItem(client, i_joint) >= 1)
	{
		Format(STRING(amount), "Joint [%i]", rp_GetClientItem(client, i_joint));
		menu.AddItem("joint", amount);
	}

	if(rp_GetClientItem(client, i_shit) >= 1)
	{
		Format(STRING(amount), "Shit [%i]", rp_GetClientItem(client, i_shit));
		menu.AddItem("shit", amount);
	}
	
	if(rp_GetClientItem(client, i_amphetamine) >= 1)
	{
		Format(STRING(amount), "Amphétamine [%i]", rp_GetClientItem(client, i_amphetamine));
		menu.AddItem("amphetamine", amount);
	}
	
	if(rp_GetClientItem(client, i_heroine) >= 1)
	{
		Format(STRING(amount), "Héroïne [%i]", rp_GetClientItem(client, i_heroine));
		menu.AddItem("heroine", amount);
	}
	
	if(rp_GetClientItem(client, i_cocaine) >= 1)
	{
		Format(STRING(amount), "Cocaine [%i]", rp_GetClientItem(client, i_cocaine));
		menu.AddItem("cocaine", amount);
	}
	
	if(rp_GetClientItem(client, i_ecstasy) >= 1)
	{
		Format(STRING(amount), "Ecstasy [%i]", rp_GetClientItem(client, i_ecstasy));
		menu.AddItem("ecstasy", amount);
	}
	
	if(rp_GetClientItem(client, i_plante) >= 1)
	{
		Format(STRING(amount), "Plante de cannabis [%i]", rp_GetClientItem(client, i_plante));
		menu.AddItem("plante", amount);
	}
}	
	
public int rp_HandlerMenuInventory(int client, char[] info)
{
	if(StrEqual(info, "joint") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, i_joint, rp_GetClientItem(client, i_joint) - 1);
		SetSQL_Int(g_DB, "rp_dealer", "joint", rp_GetClientItem(client, i_joint), steamID[client]);
		
		rp_SetClientInt(client, i_countDrogue, rp_GetClientInt(client, i_countDrogue) + 1);
		rp_SetClientBool(client, b_isJoint, true);
		
		int playsoundInt = GetRandomInt(0, 3);		
		if(playsoundInt == 2)
		{	
			PrecacheSoundAny("roleplay/drogue.mp3");
			EmitSoundToAllAny("roleplay/drogue.mp3", client, _, _, _, 1.0);
		}	
		
		ClientCommand(client, "r_screenoverlay revolution/overlays/effect_weed.vmt");
		CreateTimer(30.0, CountDrogueMinus, client, TIMER_FLAG_NO_MAPCHANGE);
		
		TE_SetupBeamFollow(client, g_BeamSpriteFollow, 0, 30.0, 5.0, 50.0, 3, ColorWeed);
		TE_SendToAll();
			
		CPrintToChat(client, "%s Vous avez fumé un joint de cannabis.", TEAM);
		PrintHintText(client, "VOUS ÊTES DEFONCÉ");
		LogToFile(logFile, "Le joueur %N a fume un joint de cannabis.", client);
	}
	else if(StrEqual(info, "shit") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, i_shit, rp_GetClientItem(client, i_shit) - 1);
		SetSQL_Int(g_DB, "rp_dealer", "shit", rp_GetClientItem(client, i_shit), steamID[client]);
		
		rp_SetClientInt(client, i_countDrogue, rp_GetClientInt(client, i_countDrogue) + 1);
		rp_SetClientBool(client, b_isShit, true);
		
		int playsoundInt = GetRandomInt(0, 3);		
		if(playsoundInt == 2)
		{	
			PrecacheSoundAny("roleplay/drogue.mp3");
			EmitSoundToAllAny("roleplay/drogue.mp3", client, _, _, _, 1.0);
		}	
		
		ClientCommand(client, "r_screenoverlay revolution/overlays/effect_weed.vmt");
		CreateTimer(30.0, CountDrogueMinus, client, TIMER_FLAG_NO_MAPCHANGE);		
		
		TE_SetupBeamFollow(client, g_BeamSpriteFollow, 0, 30.0, 5.0, 50.0, 3, ColorShit);
		TE_SendToAll();
		
		CPrintToChat(client, "%s Vous avez fumé un joint de shit.", TEAM);
		PrintHintText(client, "VOUS ÊTES DEFONCÉ");
		LogToFile(logFile, "Le joueur %N a fume un joint de shit.", client);
	}
	else if(StrEqual(info, "amphetamine") && IsPlayerAlive(client))
	{
		if(!rp_GetClientBool(client, b_isAmphetamine) && rp_GetClientInt(client, i_Faim) != 100)
		{
			rp_SetClientItem(client, i_amphetamine, rp_GetClientItem(client, i_amphetamine) - 1);
			SetSQL_Int(g_DB, "rp_dealer", "amphetamine", rp_GetClientItem(client, i_amphetamine), steamID[client]);
			
			rp_SetClientInt(client, i_countDrogue, rp_GetClientInt(client, i_countDrogue) + 1);
			rp_SetClientBool(client, b_isAmphetamine, true);
			
			rp_SetClientInt(client, i_Faim, 100);
			
			ClientCommand(client, "r_screenoverlay revolution/overlays/effect_weed.vmt");
			CreateTimer(30.0, CountDrogueMinus, client, TIMER_FLAG_NO_MAPCHANGE);
			
			TE_SetupBeamFollow(client, g_BeamSpriteFollow, 0, 30.0, 5.0, 50.0, 3, ColorAmphetamine);
			TE_SendToAll();
			
			int playsoundInt = GetRandomInt(0, 3);		
			if(playsoundInt == 2)
			{	
				PrecacheSoundAny("roleplay/drogue.mp3");
				EmitSoundToAllAny("roleplay/drogue.mp3", client, _, _, _, 1.0);
			}	
			
			CPrintToChat(client, "%s Vous avez consommé une dose de amphetamine.", TEAM);
			PrintHintText(client, "VOUS ÊTES DEFONCÉ");
			LogToFile(logFile, "Le joueur %N a consomme une dose de amphetamine.", client);
		}
		else
		{
			if(rp_GetClientBool(client, b_isAmphetamine))
				CPrintToChat(client, "%s Vous êtes déjà sous l'effet de la amphetamine.", TEAM);
			else if(rp_GetClientInt(client, i_Faim) == 100)
				CPrintToChat(client, "%s Votre barre de faim est déjà au max.", TEAM);	
		}		
	}
	else if(StrEqual(info, "heroine") && IsPlayerAlive(client))
	{
		if(!rp_GetClientBool(client, b_isHeroine))
		{
			rp_SetClientItem(client, i_heroine, rp_GetClientItem(client, i_heroine) - 1);
			SetSQL_Int(g_DB, "rp_dealer", "heroine", rp_GetClientItem(client, i_heroine), steamID[client]);
			
			rp_SetClientInt(client, i_countDrogue, rp_GetClientInt(client, i_countDrogue) + 1);
			rp_SetClientBool(client, b_isHeroine, true);
			
			ClientCommand(client, "r_screenoverlay revolution/overlays/effect_heroine.vmt");
			CreateTimer(30.0, CountDrogueMinus, client, TIMER_FLAG_NO_MAPCHANGE);
			
			TE_SetupBeamFollow(client, g_BeamSpriteFollow, 0, 30.0, 5.0, 50.0, 3, ColorHeroine);
			TE_SendToAll();

			int vie = GetClientHealth(client);
			if(vie + 100 < 500)
				SetEntityHealth(client, vie + 100);
			else SetEntityHealth(client, 500);
			
			int playsoundInt = GetRandomInt(0, 3);		
			if(playsoundInt == 2)
			{	
				PrecacheSoundAny("roleplay/drogue.mp3");
				EmitSoundToAllAny("roleplay/drogue.mp3", client, _, _, _, 1.0);
			}	
			
			PrintHintText(client, "VOUS ÊTES DEFONCÉ");
			CPrintToChat(client, "%s Vous avez consommé une dose d'héroïne.", TEAM);
			LogToFile(logFile, "Le joueur %N a consomme une dose d'heroine.", client);
		}
		else
			CPrintToChat(client, "%s Vous êtes déjà sous l'effet de l'héroïne.", TEAM);
	}
	else if(StrEqual(info, "cocaine") && IsPlayerAlive(client))
	{
		if(!rp_GetClientBool(client, b_isCocaine))
		{
			rp_SetClientItem(client, i_cocaine, rp_GetClientItem(client, i_cocaine) - 1);
			SetSQL_Int(g_DB, "rp_dealer", "cocaine", rp_GetClientItem(client, i_cocaine), steamID[client]);
			
			rp_SetClientInt(client, i_countDrogue, rp_GetClientInt(client, i_countDrogue) + 1);
			rp_SetClientBool(client, b_isCocaine, true);
			
			ClientCommand(client, "r_screenoverlay revolution/overlays/effect_cocaine.vmt");
			CreateTimer(30.0, CountDrogueMinus, client, TIMER_FLAG_NO_MAPCHANGE);
			
			TE_SetupBeamFollow(client, g_BeamSpriteFollow, 0, 30.0, 5.0, 50.0, 3, ColorCocaine);
			TE_SendToAll();
			
			int vie = GetClientHealth(client);
			if(vie + 50 < 500)
				SetEntityHealth(client, vie + 50);
			else SetEntityHealth(client, 500);
			
			int playsoundInt = GetRandomInt(0, 3);		
			if(playsoundInt == 2)
			{	
				PrecacheSoundAny("roleplay/drogue.mp3");
				EmitSoundToAllAny("roleplay/drogue.mp3", client, _, _, _, 1.0);
			}	
			
			PrintHintText(client, "VOUS ÊTES DEFONCÉ");
			CPrintToChat(client, "%s Vous avez consommé une dose de cocaïne.", TEAM);
			LogToFile(logFile, "Le joueur %N a consomme une dose de cocaine.", client);
		}
		else
			CPrintToChat(client, "%s Vous êtes déjà sous l'effet de la cocaïne.", TEAM);
	}
	else if(StrEqual(info, "ecstasy") && IsPlayerAlive(client))
	{
		if(!rp_GetClientBool(client, b_isEcstasy))
		{
			rp_SetClientItem(client, i_ecstasy, rp_GetClientItem(client, i_ecstasy) - 1);
			SetSQL_Int(g_DB, "rp_dealer", "ecstasy", rp_GetClientItem(client, i_ecstasy), steamID[client]);
			
			rp_SetClientInt(client, i_countDrogue, rp_GetClientInt(client, i_countDrogue) + 1);
			rp_SetClientBool(client, b_isEcstasy, true);
			
			ClientCommand(client, "r_screenoverlay revolution/overlays/effect_ecstasy.vmt");
			CreateTimer(30.0, CountDrogueMinus, client, TIMER_FLAG_NO_MAPCHANGE);
			
			TE_SetupBeamFollow(client, g_BeamSpriteFollow, 0, 30.0, 5.0, 50.0, 3, ColorEcstazy);
			TE_SendToAll();
			
			int vie = GetClientHealth(client);
			if(vie + 50 < 500)
				SetEntityHealth(client, vie + 50);
			else SetEntityHealth(client, 500);
			
			int playsoundInt = GetRandomInt(0, 3);		
			if(playsoundInt == 2)
			{	
				PrecacheSoundAny("roleplay/drogue.mp3");
				EmitSoundToAllAny("roleplay/drogue.mp3", client, _, _, _, 1.0);
			}	
			
			CPrintToChat(client, "%s Vous avez consommé une dose d'ecstasy.", TEAM);
			LogToFile(logFile, "Le joueur %N a consomme une dose d'ecstasy.", client);
		}
		else
			CPrintToChat(client, "%s Vous êtes déjà sous l'effet de l'ecstasy.", TEAM);
	}
	else if(StrEqual(info, "plante") && IsPlayerAlive(client))
	{
		if(EntPlante[client][0] == -1 || EntPlante[client][1] == -1)
		{
			rp_SetClientItem(client, i_plante, rp_GetClientItem(client, i_plante) - 1);
			SetSQL_Int(g_DB, "rp_dealer", "plante", rp_GetClientItem(client, i_plante), steamID[client]);
			
			PrecacheModel("models/revolution/weed/weedplant_pot_v1.mdl");
			int ent = CreateEntityByName("prop_physics_override");
			DispatchKeyValue(ent, "solid", "1");
			DispatchKeyValue(ent, "model", "models/revolution/weed/weedplant_pot_v1.mdl");
			char strFormat[128];
			if (EntPlante[client][0] == -1)
			{
				EntPlante[client][0] = ent;
				Format(STRING(strFormat), "%s|plante0", steamID[client]);
			}
			else
			{
				EntPlante[client][1] = ent;
				Format(STRING(strFormat), "%s|plante1", steamID[client]);
			}
			DispatchSpawn(ent);
			
			float TeleportOrigin[3], JoueurOrigin[3];
			GetClientAbsOrigin(client, JoueurOrigin);
			TeleportOrigin[0] = JoueurOrigin[0];
			TeleportOrigin[1] = JoueurOrigin[1];
			TeleportOrigin[2] = (JoueurOrigin[2]);
			TeleportEntity(ent, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
			JoueurOrigin[2] += 35;
			TeleportEntity(client, JoueurOrigin, NULL_VECTOR, NULL_VECTOR);
			
			CreateTimer(5.0, WeedPousse, ent);

			CPrintToChat(client, "%s Vous avez planté du cannabis.", TEAM);
			LogToFile(logFile, "Le joueur %N a planté du cannabis.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez atteint la limite de plantes.", TEAM);
	}
	
	FakeClientCommand(client, "rp");
}		

public Action CountDrogueMinus(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		if(IsPlayerAlive(client))
		{
			rp_SetClientInt(client, i_countDrogue, rp_GetClientInt(client, i_countDrogue) - 1);
			ClientCommand(client, "r_screenoverlay 0");
		}
	}
}

/***************** NPC SYSTEM *****************/

int NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Dealer");
	menu.AddItem("drogues", "Drogues");
	menu.AddItem("plantes", "Plantes");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "drogues"))
			SellDrogues(client, client);	
		else if(StrEqual(info, "plantes"))
			SellPlantes(client, client);	
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
	if(rp_GetClientInt(client, i_Job) == 9)
	{
		menu.AddItem("drogues", "Drogues");
		menu.AddItem("plantes", "Plantes");
	}
}	

public int rp_HandleMenuVendre(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "drogues"))
		SellDrogues(client, target);	
	else if(StrEqual(info, "plantes"))
		SellPlantes(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellDrogues(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Drogues disponibles");

	if(rp_GetStock(stock_joint) > 0)
	{
		prix = rp_GetPrice("joint");
		Format(STRING(strFormat), "%i|%i|stock_joint", target, prix);
		Format(STRING(strMenu), "Joint (%i$)", prix);
		menu.AddItem(strFormat, strMenu);
	}
	else
		menu.AddItem("", "Joint (Hors Stock)", ITEMDRAW_DISABLED);
	
	if(rp_GetStock(stock_shit) > 0)
	{
		prix = rp_GetPrice("shit");
		Format(STRING(strFormat), "%i|%i|stock_shit", target, prix);
		Format(STRING(strMenu), "Shit (%i$)", prix);
		menu.AddItem(strFormat, strMenu);
	}
	else
		menu.AddItem("", "Shit (Hors Stock)", ITEMDRAW_DISABLED);	
	
	if(rp_GetStock(stock_amphetamine) > 0)
	{
		prix = rp_GetPrice("amphetamine");
		Format(STRING(strFormat), "%i|%i|stock_amphetamine", target, prix);
		Format(STRING(strMenu), "Amphétamine (%i$)", prix);
		menu.AddItem(strFormat, strMenu);
	}	
	else
		menu.AddItem("", "Amphétamine (Hors Stock)", ITEMDRAW_DISABLED);
	
	if(rp_GetStock(stock_heroine) > 0)
	{
		prix = rp_GetPrice("heroine");
		Format(STRING(strFormat), "%i|%i|stock_heroine", target, prix);
		Format(STRING(strMenu), "Héroïne (%i$)", prix);
		menu.AddItem(strFormat, strMenu);
	}
	else
		menu.AddItem("", "Héroïne (Hors Stock)", ITEMDRAW_DISABLED);
	
	if(rp_GetStock(stock_cocaine) > 0)
	{
		prix = rp_GetPrice("cocaine");
		Format(STRING(strFormat), "%i|%i|stock_cocaine", target, prix);
		Format(STRING(strMenu), "Cocaine (%i$)", prix);
		menu.AddItem(strFormat, strMenu);
	}
	else
		menu.AddItem("", "Cocaine (Hors Stock)", ITEMDRAW_DISABLED);
	
	if(rp_GetStock(stock_ecstasy) > 0)
	{
		prix = rp_GetPrice("ecstasy");
		Format(STRING(strFormat), "%i|%i|stock_ecstasy", target, prix);
		Format(STRING(strMenu), "Ecstasy (%i$)", prix);
		menu.AddItem(strFormat, strMenu);
	}	
	else
		menu.AddItem("", "Ecstasy (Hors Stock)", ITEMDRAW_DISABLED);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}			

Menu SellPlantes(int client, int target)
{
	int prix;
	char strFormat[128], strMenu[128];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Plantes Disponibles");
	
	prix = rp_GetPrice("plante");
	Format(STRING(strFormat), "%i|%i|stock_plante", target, prix);
	Format(STRING(strMenu), "Plante de cannabis (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

public int DoSell(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64], buffer[3][64], strQuantite[128], strFormat[64], strAppart[2][32];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		
		ExplodeString(info, "|", buffer, 3, 64);
		ExplodeString(buffer[2], "_", strAppart, 2, 32);
			
		int target = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[1]);
		int item = StringToInt(buffer[2]);

		/* MENU QUANTITE */
		
		Menu quantity = new Menu(DoMenuQuantity);
		quantity.SetTitle("Choisissez la quantité");
			
		for(int i = 1; i <= 10; i++)
		{			
			Format(STRING(strQuantite), "%i|%i|%s|%i", target, prix, buffer[2], i);
			Format(STRING(strFormat), "%i", i);
			if(rp_GetStock(view_as<stock_item_builded>(item)) > i)
				quantity.AddItem(strQuantite, strFormat);
			else
				quantity.AddItem("", strFormat, ITEMDRAW_DISABLED);			
		}	
		
		Format(STRING(strQuantite), "%i|%i|%s|25", target, prix, buffer[2]);
		if(rp_GetStock(view_as<stock_item_builded>(item)) > 25)
			quantity.AddItem(strQuantite, "25");
		else
			quantity.AddItem("", "25", ITEMDRAW_DISABLED);		
		
		Format(STRING(strQuantite), "%i|%i|%s|50", target, prix, buffer[2]);
		if(rp_GetStock(view_as<stock_item_builded>(item)) > 50)
			quantity.AddItem(strQuantite, "50");
		else
			quantity.AddItem("", "50", ITEMDRAW_DISABLED);	
		
		Format(STRING(strQuantite), "%i|%i|%s|100", target, prix, buffer[2]);
		if(rp_GetStock(view_as<stock_item_builded>(item)) > 100)
			quantity.AddItem(strQuantite, "100");
		else
			quantity.AddItem("", "100", ITEMDRAW_DISABLED);	

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
						rp_SetJobCapital(9, rp_GetJobCapital(9) + prix / 2);
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
						rp_SetJobCapital(9, rp_GetJobCapital(9) + prix / 2);
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
			
			int prix_unit = rp_GetPrice(buffer[2]);
			
			Insert_rp_sell(g_DB, steamID[client], steamID[vendeur], buffer[2], prix_unit, quantity);
			
			if(StrEqual(buffer[2], "joint"))
			{
				rp_SetClientItem(client, i_joint, rp_GetClientItem(client, i_joint) + quantity);	
				SetSQL_Int(g_DB, "rp_dealer", buffer[2], rp_GetClientItem(client, i_joint), steamID[client]);
			}
			else if(StrEqual(buffer[2], "shit"))
			{
				rp_SetClientItem(client, i_shit, rp_GetClientItem(client, i_shit) + quantity);	
				SetSQL_Int(g_DB, "rp_dealer", buffer[2], rp_GetClientItem(client, i_shit), steamID[client]);
			}
			else if(StrEqual(buffer[2], "amphetamine"))
			{
				rp_SetClientItem(client, i_amphetamine, rp_GetClientItem(client, i_amphetamine) + quantity);	
				SetSQL_Int(g_DB, "rp_dealer", buffer[2], rp_GetClientItem(client, i_amphetamine), steamID[client]);
			}
			else if(StrEqual(buffer[2], "heroine"))
			{
				rp_SetClientItem(client, i_heroine, rp_GetClientItem(client, i_heroine) + quantity);	
				SetSQL_Int(g_DB, "rp_dealer", buffer[2], rp_GetClientItem(client, i_heroine), steamID[client]);
			}	
			else if(StrEqual(buffer[2], "cocaine"))
			{
				rp_SetClientItem(client, i_cocaine, rp_GetClientItem(client, i_cocaine) + quantity);	
				SetSQL_Int(g_DB, "rp_dealer", buffer[2], rp_GetClientItem(client, i_cocaine), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ecstasy"))
			{
				rp_SetClientItem(client, i_ecstasy, rp_GetClientItem(client, i_ecstasy) + quantity);	
				SetSQL_Int(g_DB, "rp_dealer", buffer[2], rp_GetClientItem(client, i_ecstasy), steamID[client]);
			}
			else if(StrEqual(buffer[2], "plante"))
			{
				rp_SetClientItem(client, i_plante, rp_GetClientItem(client, i_plante) + quantity);	
				SetSQL_Int(g_DB, "rp_dealer", buffer[2], rp_GetClientItem(client, i_plante), steamID[client]);
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

public Action update(Handle Timer) 
{
	for (int client = 1; client < MAXPLAYERS; client++) 
	{		
		if (IsClientValid(client))
		{			
			if(rp_GetClientInt(client, i_Job) == 9)
			{
				int aim = GetClientAimTarget(client, false);
			
				if (aim != -1 && IsValidEntity(aim))
				{	
					char entModel[256];
					Entity_GetModel(aim, STRING(entModel));
					
					if(Distance(client, aim) <= 80.0)
					{
						if(StrEqual(entModel, "models/revolution/weed/weedplant_pot_v7.mdl"))
							PrintHintText(client, "<font color='#00BC61'>Cette plante est prête pour la recolte.</font>");
						else if(StrContains(entModel, "weedplant_pot_") != -1 && !StrEqual(entModel, "models/revolution/weed/weedplant_pot_v7.mdl"))
							PrintHintText(client, "<font color='#5100A2'>Cette plante n'est pas encore prête pour la recolte.</font>");
							
						if(StrEqual(entModel, "models/drugs/drying_rack/drying_rack.mdl"))
						{		
							char strText[256], Drug[32];
							
							if(drying_drug_type[aim][COCAINE])
								Format(STRING(Drug), "Cocaïne");
							else if(drying_drug_type[aim][AMPHETAMINE])
								Format(STRING(Drug), "Amphétamine");	
							else if(drying_drug_type[aim][HEROINE])
								Format(STRING(Drug), "Heroïne");		
							else if(drying_drug_type[aim][ECSTASY])
								Format(STRING(Drug), "Ecstasy");			
							
							if (drying_timestamp[aim] != 0)
							{
								if (drying_timestamp[aim] >= 1 && drying_timestamp[aim] <= 5)
									Format(STRING(strText), "%s : <font color='#ffffff'>░░░░░░░░░░</font> %i%", Drug, drying_timestamp[aim]);
								else if (drying_timestamp[aim] <= 15)
									Format(STRING(strText), "%s : <font color='#26d100'>█</font><font color='#ffffff'>░░░░░░░░░</font> %i%", Drug, drying_timestamp[aim]);
								else if (drying_timestamp[aim] <= 25)
									Format(STRING(strText), "%s : <font color='#26d100'>██</font><font color='#ffffff'>░░░░░░░░</font> %i%", Drug, drying_timestamp[aim]);
								else if (drying_timestamp[aim] <= 35)
									Format(STRING(strText), "%s : <font color='#26d100'>███</font><font color='#ffffff'>░░░░░░░</font> %i%", Drug, drying_timestamp[aim]);
								else if (drying_timestamp[aim] <= 45)
									Format(STRING(strText), "%s : <font color='#26d100'>████</font><font color='#ffffff'>░░░░░░</font> %i%", Drug, drying_timestamp[aim]);
								else if (drying_timestamp[aim] <= 55)
									Format(STRING(strText), "%s : <font color='#26d100'>█████</font><font color='#ffffff'>░░░░░</font> %i%", Drug, drying_timestamp[aim]);
								else if (drying_timestamp[aim] <= 65)
									Format(STRING(strText), "%s : <font color='#26d100'>██████</font><font color='#ffffff'>░░░░</font> %i%", Drug, drying_timestamp[aim]);
								else if (drying_timestamp[aim] <= 75)
									Format(STRING(strText), "%s : <font color='#26d100'>███████</font><font color='#ffffff'>░░░</font> %i%", Drug, drying_timestamp[aim]);
								else if (drying_timestamp[aim] <= 85)
									Format(STRING(strText), "%s : <font color='#26d100'>████████</font><font color='#ffffff'>░░</font> %i%", Drug, drying_timestamp[aim]);
								else if (drying_timestamp[aim] <= 99)
									Format(STRING(strText), "%s : <font color='#26d100'>█████████</font><font color='#ffffff'>░</font> %i%", Drug, drying_timestamp[aim]);
								else if (drying_timestamp[aim] == 100)
									Format(STRING(strText), "%s : <font color='#26d100'>██████████</font> 100%\n Prêt à être recolté", Drug);
								PrintHintText(client, strText);
							}	
						}	
					}	
				}	
			}	
		}	
		else if (!IsClientValid(client)) 
		{
			TrashTimer(TimerRPT[client], true);
		}
	}
}

Menu MenuDealer(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuDealer);
	menu.SetTitle("Aperçu de votre stock :");
	
	int TotalPlantes = planteCannabis[0] + planteCannabis[1] + planteCannabis[2] + planteCannabis[3] + planteCannabis[4];
	
	char strText[32];
	if (TotalPlantes > 1)
		Format(STRING(strText), "Plantes : %i", TotalPlantes);
	else if(TotalPlantes == 1)
		Format(STRING(strText), "Plante : 1");
	menu.AddItem("", strText, ITEMDRAW_DISABLED);
	Format(STRING(strText), "Cannabis : %ig", grammeCannabis);
	menu.AddItem("", strText, ITEMDRAW_DISABLED);
	menu.AddItem("joint", "Rouler un joint (1g)");
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuDealer(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if (StrEqual(info, "joint"))
		{
			if (grammeCannabis >= 1)
			{
				rp_SetStock(stock_joint, rp_GetStock(stock_joint) + 1);
				grammeCannabis--;
				
				CPrintToChat(client, "%s Vous avez roulé un joint avec 1g.", TEAM);
				PrintHintText(client, "-1g de cannabis.");
			}
			else
				CPrintToChat(client, "%s Vous n'avez pas assez de cannabis pour rouler un joint.", TEAM);
		}
		else if (StrEqual(info, "shit"))
		{
			if (grammeCannabis >= 2)
			{
				rp_SetStock(stock_shit, rp_GetStock(stock_shit) + 1);
				grammeCannabis -= 2;
				
				CPrintToChat(client, "%s Vous avez fait du shit avec le pollen contenu dans 2g.", TEAM);
				PrintHintText(client, "-2g de cannabis.");
			}
			else
				CPrintToChat(client, "%s Vous n'avez pas assez de cannabis pour faire du shit.", TEAM);
		}
		MenuDealer(client);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

Menu MenuDJDealer(int client)
{
	if (IsClientValid(client))
	{
		if (rp_GetClientInt(client, i_Job) == 9)
		{
			rp_SetClientBool(client, b_menuOpen, true);
			Menu menu = new Menu(Menu_DJ);
			menu.SetTitle("Que voulez - vous faire ? ");
			menu.AddItem("placer", "Placer la boule");
			menu.AddItem("retirer", "Retirer la boule");
			menu.AddItem("jouer", "Jouer de la musique");
			menu.AddItem("stop", "Stopper la musique");
			menu.Display(client, MENU_TIME_FOREVER);
			menu.ExitButton = true;
		}
	}
}

public int Menu_DJ(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if (StrEqual(info, "jouer"))
		{
			Menu menu1 = new Menu(DoMusicMenu);
			
			menu1.SetTitle("- Playliste -");
			menu1.AddItem("mmz", "MMZ - Capuché");
			menu1.AddItem("hardbass", "HardBass");
			menu1.Display(client, 0);
			menu1.ExitButton = true;
		}
		else if (StrEqual(info, "placer"))
		{
			if (0 >= RP_GetClientCountDiscoball(client))
			{
				CreateDisco(client);
			}
		}
		else if (StrEqual(info, "retirer"))
		{
			int i = 1;
			while (GetMaxEntities() >= i)
			{			
				if (IsValidEdict(i) && IsValidEntity(i))
				{
					char sName[64];
					GetEntPropString(i, view_as<PropType>(1), "m_iName", sName, 64, 0);
					char sExplode[2][64];
					ExplodeString(sName, "-", sExplode, 2, 64, false);
					
					if (StrEqual(sExplode[0], "discoball", true) && StringToInt(sExplode[1], 10) == GetClientUserId(client))
					{
						RemoveEdict(i);
					}
				}
				i++;
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMusicMenu(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if (StrEqual(info, "mmz", true))
		{
			PrecacheSoundAny("roleplay/dj/mmz.mp3");
			EmitSoundToAllAny("roleplay/dj/mmz.mp3", client, _, _, _, 1.0);
		}
		else if (StrEqual(info, "hardbass", true))
		{
			PrecacheSoundAny("roleplay/dj/hardbass.mp3");
			EmitSoundToAllAny("roleplay/dj/hardbass.mp3", client, _, _, _, 1.0);
		}
		CPrintToChatAll("%s Le DJ %N nous joue un son !", TEAM, client);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int CreateDisco(int client)
{
	float fAim[3] = 0.0;
	float fClient[3] = 0.0;
	GetAimOrigin(client, fAim);
	GetClientAbsOrigin(client, fClient);
	if (GetVectorDistance(fClient, fAim, false) <= 500)
	{
		int ball = CreateEntityByName("prop_dynamic_override", -1);
		char sName[64];
		Format(sName, 64, "discoball- %i", GetClientUserId(client));
		SetEntPropString(ball, view_as<PropType>(1), "m_iName", sName, 0);
		if (!IsModelPrecached("models/props/slow/spiegelkugel/slow_spiegelkugel.mdl"))
		{
			PrecacheModel("models/props/slow/spiegelkugel/slow_spiegelkugel.mdl", false);
		}
		SetEntityModel(ball, "models/props/slow/spiegelkugel/slow_spiegelkugel.mdl");
		DispatchKeyValue(ball, "solid", "0");
		DispatchSpawn(ball);
		TeleportEntity(ball, fAim, NULL_VECTOR, NULL_VECTOR);
		CreateTimer(0.1, Timer_DiscoUpdate, ball, 1);
	}
	else
	{
		PrintToChat(client, "%s : La boule est trop loin.", TEAM);
	}
	
}

public Action Timer_DiscoUpdate(Handle timer, any ball)
{
	if (IsValidEdict(ball) && IsValidEntity(ball))
	{
		float fPropAngle[3] = 0.0;
		GetEntPropVector(ball, view_as<PropType>(1), "m_angRotation", fPropAngle, 0);
		fPropAngle[0] = fPropAngle[0] + g_fDiscoRotation[0];
		fPropAngle[1] += g_fDiscoRotation[1];
		fPropAngle[2] += g_fDiscoRotation[2];
		TeleportEntity(ball, NULL_VECTOR, fPropAngle, NULL_VECTOR);
		float fPos[3] = 0.0;
		float END[3] = 0.0;
		GetEntPropVector(ball, view_as<PropType>(0), "m_vecOrigin", fPos, 0);
		TE_SetupGlowSprite(fPos, g_Glow, 0.1, 2.0, 255);
		TE_SendToAll(0.0);
		int iColor[4] =  { 0, 0, 0, 255 };
		float fNewAngles[3] = 0.0;
		int i;
		while (i <= 5)
		{
			fNewAngles[0] = GetRandomFloat(0.0, 90.0);
			fNewAngles[1] = GetRandomFloat(-180.0, 180.0);
			fNewAngles[2] = 0.0;
			Handle hTrace = TR_TraceRayFilterEx(fPos, fNewAngles, 1174421507, view_as<RayType>(1), TraceEntityFilterPlayer, view_as<any>(0));
			if (TR_DidHit(hTrace))
			{
				TR_GetEndPosition(END, hTrace);
				iColor[0] = g_iDefaultColors_c[i][0];
				iColor[1] = g_iDefaultColors_c[i][1];
				iColor[2] = g_iDefaultColors_c[i][2];
				LaserP(fPos, END, iColor);
			}
			CloseHandle(hTrace);
			i++;
		}
	}
	else
	{
		KillTimer(timer, false);
	}
	return view_as<Action>(0);
}

public void LaserP(float start[3], float end[3], int color[4])
{
	TE_SetupBeamPoints(start, end, g_BeamSpriteFollow, 0, 0, 0, 0.1, 3.0, 3.0, 7, 0.0, color, 0);
	TE_SendToAll(0.0);
}

public int GetAimOrigin(int client, float hOrigin[3])
{
	float vAngles[3] = 0.0;
	float fOrigin[3] = 0.0;
	GetClientEyePosition(client, fOrigin);
	GetClientEyeAngles(client, vAngles);
	Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, 1174421507, view_as<RayType>(1), TraceEntityFilterPlayer, view_as<any>(0));
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(hOrigin, trace);
		CloseHandle(trace);
	}
	else
	{
		CloseHandle(trace);
	}
}

public int RP_GetClientCountDiscoball(int client)
{
	int iCount;
	int i = 1;
	while (GetMaxEntities() >= i)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			char sName[64];
			GetEntPropString(i, view_as<PropType>(1), "m_iName", sName, 64, 0);
			char sExplode[2][64];
			ExplodeString(sName, "-", sExplode, 2, 64, false);
			if (StrEqual(sExplode[0], "discoball", true) && GetClientUserId(client) == StringToInt(sExplode[1], 10))
			{
				iCount++;
			}
		}
		i++;
	}
	return iCount;
}

public int DryingInit(int ent)
{
	CreateTimer(25.0, DryingCooldown, ent, TIMER_REPEAT);
}	

public Action DryingCooldown(Handle Timer, any ent)
{
	if(drying_timestamp[ent] != 100)
		drying_timestamp[ent] += 5;
	else
	{
		drying_timestamp[ent] = 0;
		char entName[64], Drug[32], model[128];
		Entity_GetName(ent, STRING(entName));	
		int client = Client_FindBySteamId(entName);
		
		if(drying_drug_type[ent][COCAINE])
		{
			drying_drug_type[ent][COCAINE] = false;
			Format(STRING(Drug), "Cocaïne");
			Format(STRING(model), "models/drugs/utility/cocaine_pack.mdl");
		}	
		else if(drying_drug_type[ent][AMPHETAMINE])
		{
			drying_drug_type[ent][AMPHETAMINE] = false;
			Format(STRING(Drug), "Amphétamine");
			Format(STRING(model), "models/drugs/utility/leaves.mdl");			
		}	
		else if(drying_drug_type[ent][HEROINE])
		{
			drying_drug_type[ent][HEROINE] = false;
			Format(STRING(Drug), "Heroïne");
			Format(STRING(model), "models/drugs/utility/soda.mdl");
		}	
		else if(drying_drug_type[ent][ECSTASY])
		{
			drying_drug_type[ent][ECSTASY] = false;
			Format(STRING(Drug), "Ecstasy");
			Format(STRING(model), "models/drugs/utility/stove_upgrade.mdl");	
		}	
		
		PrecacheModel(model);
		int drug = CreateEntityByName("prop_physics_override");
		DispatchKeyValue(drug, "solid", "1");
		DispatchKeyValue(drug, "model", model);			
		Entity_SetName(drug, steamID[client]);
		DispatchSpawn(drug);			
		
		float position[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
		position[2] += 40;
		TeleportEntity(drug, position, NULL_VECTOR, NULL_VECTOR);
		
		CPrintToChat(client, "%s Votre %s est prête à être recolté sur l'étendoir", TEAM, Drug);
		
		canUseDrying[ent] = true;
		delete Timer;
	}	
}	

public int DrawDryingDrugBuild(int client, int ent)
{
	if(canUseDrying[ent])
	{
		char strFormat[64];	
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu = new Menu(DoDryingDrug);
		menu.SetTitle("Choisissez la drogue chimique a préparer");
		
		Format(STRING(strFormat), "%i|cocaine", ent);
		menu.AddItem(strFormat, "Cocaïne");
		
		Format(STRING(strFormat), "%i|amphetamine", ent);
		menu.AddItem(strFormat, "Amphétamine");
		
		Format(STRING(strFormat), "%i|heroine", ent);
		menu.AddItem(strFormat, "Heroïne");
		
		Format(STRING(strFormat), "%i|ecstasy", ent);
		menu.AddItem(strFormat, "Ecstasy");
		
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
		CPrintToChat(client, "%s Etendoir déjà en cours de préparation.", TEAM);
}	

public int DoDryingDrug(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], buff[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buff, 2, 64);
		
		int entity = StringToInt(buff[0]);
		
		if(StrEqual(buff[1], "cocaine"))
		{	
			canUseDrying[entity] = false;
			drying_drug_type[entity][COCAINE] = true;
			CPrintToChat(client, "%s En préparation de Cocaïne.", TEAM);
		}	
		else if(StrEqual(buff[1], "amphetamine"))
		{	
			canUseDrying[entity] = false;
			drying_drug_type[entity][AMPHETAMINE] = true;
			CPrintToChat(client, "%s En préparation d'Amphétamine.", TEAM);
		}	
		else if(StrEqual(buff[1], "heroine"))
		{	
			canUseDrying[entity] = false;
			drying_drug_type[entity][HEROINE] = true;
			CPrintToChat(client, "%s En préparation d'Heroïne.", TEAM);
		}
		else if(StrEqual(buff[1], "ecstasy"))
		{	
			canUseDrying[entity] = false;
			drying_drug_type[entity][ECSTASY] = true;
			CPrintToChat(client, "%s En préparation d'Ecstasy.", TEAM);
		}
		
		DryingInit(entity);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
		rp_SetClientBool(client, b_menuOpen, false);
	}	
}