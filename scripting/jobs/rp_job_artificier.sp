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
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
int g_iClientColor[MAXPLAYERS + 1][4];
int g_cBeam;
char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Articifier", 
	author = "Benito", 
	description = "Métier - Articifier", 
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
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_artificier.log");	
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];		
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_artificier` ( \
	  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `50` int(100) NOT NULL, \
	  `51` int(100) NOT NULL, \
	  `52` int(100) NOT NULL, \
	  `53` int(100) NOT NULL, \
	  `54` int(100) NOT NULL, \
	  `55` int(100) NOT NULL, \
	  `61` int(100) NOT NULL, \
	  `62` int(100) NOT NULL, \
	  `71` int(100) NOT NULL, \
	  `72` int(100) NOT NULL, \
	  `73` int(100) NOT NULL, \
	  `74` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

public void OnMapStart()
{
	g_cBeam = PrecacheModel("particle/beam_taser.vmt");
}	

public void RP_OnPlayerDisconnect(int client)
{
	if(!IsClientInGame(client))
		return;
}

public void OnClientPutInServer(int client)
{	
	rp_SetClientBool(client, b_asPermis, false);
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
	
	char buffer[4096];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_artificier` (`Id`, `steamid`, `playername`, `50`, `51`, `52`, `53`, `54`, `55`, `61`, `62`, `71`, `72`, `73`, `74`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
}

public Action TimerRecoil(Handle timer, any client)
{
	if (IsClientValid(client))
	{
		float f_dur = 8.0 / 3.0;

		Handle hShake = StartMessageOne("Shake", client);

		if (hShake != null)
		{
			if (GetUserMessageType() == UM_Protobuf)
			{
				PbSetInt(hShake, "command", 0);
				PbSetFloat(hShake, "local_amplitude", 50.0);
				PbSetFloat(hShake, "frequency", 1.0);
				PbSetFloat(hShake, "duration", f_dur);
			}
			else
			{
				BfWriteByte(hShake, 0);
				BfWriteFloat(hShake, 50.0);
				BfWriteFloat(hShake, 1.0);
				BfWriteFloat(hShake, f_dur);
			}
			EndMessage();

		}
		else
			TrashTimer(timer);
	}
	return Plugin_Continue;
}	

public void LoadSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_artificier WHERE steamid = '%s';", steamID[client]);
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
			
			if(StrEqual(item_jobid, "13"))
			{
				char item_string[10];
				IntToString(i, STRING(item_string));
				
				rp_ClientGiveItem(client, i, SQL_FetchIntByName(Results, item_string));
			}	
		}	
	}
} 

public Action RP_OnPlayerBuild(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_Job) == 13)
	{
		menu.SetTitle("Build - Artificier");
		if(rp_GetClientInt(client, i_Job) == 13)
			menu.AddItem("", "He");
	}	
}	

public Action RP_OnPlayerInventory(int client, Menu menu)
{
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "13"))
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
	if(StrEqual(info, "50") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, grenade_he, rp_GetClientItem(client, grenade_he) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, grenade_he), steamID[client]);
				
			GivePlayerItem(client, "weapon_hegrenade");
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade à fragmentation.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une grenade a fragmentation.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "51") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, grenade_flash, rp_GetClientItem(client, grenade_flash) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, grenade_flash), steamID[client]);
				
			GivePlayerItem(client, "weapon_flashbang");
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade Flashbang (GSS).", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une grenade Flashbang (GSS).", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "52") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, grenade_smoke, rp_GetClientItem(client, grenade_smoke) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, grenade_smoke), steamID[client]);
				
			GivePlayerItem(client, "weapon_smokegrenade");
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade fumigène.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une grenade fumigène.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "53") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, grenade_decoy, rp_GetClientItem(client, grenade_decoy) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, grenade_decoy), steamID[client]);
				
			GivePlayerItem(client, "weapon_decoy");
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade leurre.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une grenade leurre.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "54") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, grenade_molotov, rp_GetClientItem(client, grenade_molotov) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, grenade_molotov), steamID[client]);
				
			GivePlayerItem(client, "weapon_molotov");
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un cocktail Molotov.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un cocktail Molotov.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "55") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, grenade_incendiary, rp_GetClientItem(client, grenade_incendiary) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, grenade_incendiary), steamID[client]);
				
			GivePlayerItem(client, "weapon_incgrenade");
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade incendiaire.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une grenade incendiaire.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "64") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, gear_tacticalgrenade, rp_GetClientItem(client, gear_tacticalgrenade) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, gear_tacticalgrenade), steamID[client]);
				
			GivePlayerItem(client, "weapon_tagrenade");
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade tactique.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une grenade tactique.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "62") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, gear_breachcharge, rp_GetClientItem(client, gear_breachcharge) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, gear_breachcharge), steamID[client]);
				
			GivePlayerItem(client, "weapon_breachcharge");
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}des charges explosives.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise des charges explosives.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "71") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, i_munitionsincendiaire, rp_GetClientItem(client, i_munitionsincendiaire) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, i_munitionsincendiaire), steamID[client]);
			
			int wepID = Client_GetActiveWeapon(client);
			if(wepID != -1)
				rp_SetWeaponBallType(wepID, ball_type_fire);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}des munitions incendiaires.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise des munitions incendiaires.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "72") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, i_munitionscaoutchouc, rp_GetClientItem(client, i_munitionscaoutchouc) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, i_munitionscaoutchouc), steamID[client]);
				
			int wepID = Client_GetActiveWeapon(client);
			if(wepID != -1)
				rp_SetWeaponBallType(wepID, ball_type_caoutchouc);	
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}des munitions caoutchouc.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise des munitions caoutchouc.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "munitionsperforante") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, i_munitionsperforante, rp_GetClientItem(client, i_munitionsperforante) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, i_munitionsperforante), steamID[client]);
			
			int wepID = Client_GetActiveWeapon(client);
			if(wepID != -1)
				rp_SetWeaponBallType(wepID, ball_type_revitalisante);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}des munitions perforantes.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise des munitions perforantes.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	else if(StrEqual(info, "74") && IsPlayerAlive(client))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, i_munitionsexplosive, rp_GetClientItem(client, i_munitionsexplosive) - 1);
			SetSQL_Int(rp_GetDatabase(), "rp_artificier", info, rp_GetClientItem(client, i_munitionsexplosive), steamID[client]);
				
			int wepID = Client_GetActiveWeapon(client);
			if(wepID != -1)
				rp_SetWeaponBallType(wepID, ball_type_explode);	
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}des munitions explosives.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise des munitions explosives.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
	
	FakeClientCommand(client, "rp");
}	

public Action RP_OnPlayerFire(int client, int target, const char[] weapon)
{
	int wepID;
	if (IsClientValid(client))
		wepID = Client_GetActiveWeapon(client);	
	enum_ball_type wepType = rp_GetWeaponBallType(wepID);
	
	if(wepType & ball_type_fire) 
	{
		float position[3];
		PointVision(client, position);
			
		if(IsValidEntity(target) && target <= MaxClients)
			IgniteEntity(target, 10.0, false);
		else
			rp_CreateFire(position, 10.0);
	}
	else if(wepType & ball_type_caoutchouc) 
	{
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
		rp_SetClientFloat(client, fl_FrozenTime, GetGameTime() + 1.5);
	}
	else if(wepType & ball_type_paintball)	
	{
		g_iClientColor[client][0] = Math_GetRandomInt(50, 255);
		g_iClientColor[client][1] = Math_GetRandomInt(50, 255);
		g_iClientColor[client][2] = Math_GetRandomInt(50, 255);
		g_iClientColor[client][3] = Math_GetRandomInt(100, 240);

		SetEntityRenderColor(target, g_iClientColor[client][0], g_iClientColor[client][1], g_iClientColor[client][2], g_iClientColor[client][3]);
	}
	else if(wepType & ball_type_explode)
	{	
		float position[3];
		PointVision(client, position);
			
		TE_SetupExplosion(position, -1, 1.0, 1, 0, 200, 200);
		TE_SendToAll();
	}
	
	if (!rp_GetClientBool(target, b_asPermis))
	{
		if (!StrEqual(weapon, "weapon_knife") && !StrEqual(weapon, "weapon_fists"))
		{
			CreateTimer(0.01, TimerRecoil, target);
			PrintHintText(target, "Veuillez acheter le permis afin de mieux viser !");
		}
	}
}	

public Action RP_OnPlayerTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	int wepID;
	if (IsClientValid(attacker))
		wepID = Client_GetActiveWeapon(attacker);	
	enum_ball_type wepType = rp_GetWeaponBallType(wepID);
	
	/*if( wepType != ball_type_revitalisante )
		rp_ClientAggroIncrement(attacker, client, RoundFloat(damage));*/
	
	if(wepType & ball_type_fire) 
	{
		float position[3];
		PointVision(attacker, position);
			
		if(IsValidEntity(client) && client <= MaxClients)
			IgniteEntity(client, 10.0, false);
		else
			rp_CreateFire(position, 10.0);
	}
	else if(wepType == ball_type_caoutchouc) 
	{
		damage *= 0.0;
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
		damage *= 0.5;
			
		rp_SetClientFloat(client, fl_FrozenTime, GetGameTime() + 1.5);

	}
	else if(wepType == ball_type_poison) 
	{
		damage *= 0.66;
		//rp_ClientPoison(client, 30.0, attacker);
	}
	else if(wepType == ball_type_vampire) 
	{
		damage *= 0.75;
		int current = GetClientHealth(attacker);
		if( current < 500 ) 
		{
			current += RoundToFloor(damage*0.2);

			if( current > 500 )
				current = 500;

			SetEntityHealth(attacker, current);
			
			float vecOrigin[3], vecOrigin2[3];
			GetClientEyePosition(attacker, vecOrigin);
			GetClientEyePosition(client, vecOrigin2);
			
			vecOrigin[2] -= 20.0; vecOrigin2[2] -= 20.0;
			
			TE_SetupBeamPoints(vecOrigin, vecOrigin2, g_cBeam, 0, 0, 0, 0.1, 10.0, 10.0, 0, 10.0, {250, 50, 50, 250}, 10);
			TE_SendToAll();
		}
	}
	else if(wepType == ball_type_paintball)	
	{
		damage *= 1.0;
		
		g_iClientColor[client][0] = Math_GetRandomInt(50, 255);
		g_iClientColor[client][1] = Math_GetRandomInt(50, 255);
		g_iClientColor[client][2] = Math_GetRandomInt(50, 255);
		g_iClientColor[client][3] = Math_GetRandomInt(100, 240);

		SetEntityRenderColor(client, g_iClientColor[client][0], g_iClientColor[client][1], g_iClientColor[client][2], g_iClientColor[client][3]);
	}
	else if(wepType == ball_type_reflexive)	
	{
		damage = 0.9;
	}
	else if(wepType == ball_type_explode)
	{
		damage *= 0.8;		
		float position[3];
		PointVision(attacker, position);
			
		TE_SetupExplosion(position, -1, 1.0, 1, 0, 200, 200);
		TE_SendToAll();
	}
	else if(wepType == ball_type_revitalisante)
	{
		int current = GetClientHealth(client);
		if( current < 500 ) 
		{
			current += RoundToCeil(damage*0.1); // On rend environ 10% des degats infligés sous forme de vie

			if( current > 500 )
				current = 500;

			SetEntityHealth(client, current);
			
			float vecOrigin[3], vecOrigin2[3];
			GetClientEyePosition(attacker, vecOrigin);
			GetClientEyePosition(client, vecOrigin2);
			
			vecOrigin[2] -= 20.0; vecOrigin2[2] -= 20.0;
			
			TE_SetupBeamPoints(vecOrigin, vecOrigin2, g_cBeam, 0, 0, 0, 0.1, 10.0, 10.0, 0, 10.0, {0, 255, 0, 250}, 10); // Laser vert entre les deux
			TE_SendToAll();
		}
		damage = 0.0; // L'arme ne fait pas de dégats
	}
	else if(wepType == ball_type_notk)
	{
		if(rp_GetClientInt(attacker, i_Group) == rp_GetClientInt(client, i_Group))
		{
				damage *= 0.0;
		}
	}
}	
	
public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	if(StrEqual(entityName, "Artificier"))
	{
		int nbArti;
		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Job) == 13 && !rp_GetClientBool(i, b_isAfk))
				nbArti++;
		}
		if(nbArti == 0 || nbArti == 1 && rp_GetClientInt(client, i_Job) == 13 || rp_GetClientInt(client, i_Job) == 13 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un artificier.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un artificier.");
		}	
	}
}	

/***************** NPC SYSTEM *****************/

int NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Artificier");
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
			SellArtificier(client, client);	
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
	if(rp_GetClientInt(client, i_Job) == 13)
	{
		menu.AddItem("item", "Vendre un objet");
	}
}	

public int RP_OnPlayerSellHandle(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "item"))
		SellArtificier(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellArtificier(int client, int target)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Items Disponibles");
	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "13"))
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
						rp_SetJobCapital(13, rp_GetJobCapital(13) + prix / 2);
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
						rp_SetJobCapital(13, rp_GetJobCapital(13) + prix / 2);
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
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_artificier` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
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