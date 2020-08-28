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
char dbconfig[] = "roleplay";
Database g_DB;

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
	if(rp_licensing_isValid())
	{
		GameCheck();
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_artificier.log");
		Database.Connect(GotDatabase, dbconfig);
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
		"CREATE TABLE IF NOT EXISTS `rp_artificier` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `he` int(100) NOT NULL, \
		  `flash` int(100) NOT NULL, \
		  `smoke` int(100) NOT NULL, \
		  `decoy` int(100) NOT NULL, \
		  `molotov` int(100) NOT NULL, \
		  `incendiary` int(100) NOT NULL, \
		  `tacticalgrenade` int(100) NOT NULL, \
		  `breachcharge` int(100) NOT NULL, \
		  `munitionsincendiaire` int(100) NOT NULL, \
		  `munitionscaoutchouc` int(100) NOT NULL, \
		  `munitionsperforante` int(100) NOT NULL, \
		  `munitionsexplosive` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void OnMapStart()
{
	g_cBeam = PrecacheModel("particle/beam_taser.vmt");
}	

public void OnClientDisconnect(int client)
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
	SQL_EscapeString(g_DB, playername, STRING(clean_playername));
	
	char buffer[4096];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_artificier` (`Id`, `steamid`, `playername`, `he`, `flash`, `smoke`, `decoy`, `molotov`, `incendiary`, `tacticalgrenade`, `breachcharge`, `munitionsincendiaire`, `munitionscaoutchouc`, `munitionsperforante`, `munitionsexplosive`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadTech(client);
}

public Action rp_OnWeaponFire(int client, int aim, const char[] weaponName)
{
	if (!rp_GetClientBool(client, b_asPermis))
	{
		if (!StrEqual(weaponName, "weapon_knife") && !StrEqual(weaponName, "weapon_fists"))
		{
			CreateTimer(0.01, TimerRecoil, client);
			PrintHintText(client, "Veuillez acheter le permis afin de mieux viser !");
		}
	}
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

public Action rp_reloadData()
{
	LoopClients(i)
	{
		SQLCALLBACK_LoadTech(i);
	}	
}	

public void SQLCALLBACK_LoadTech(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_artificier WHERE steamid = '%s';", steamID[client]);
	g_DB.Query(SQLLoadTechQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadTechQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientItem(client, grenade_he, SQL_FetchIntByName(Results, "he"));
		rp_SetClientItem(client, grenade_flash, SQL_FetchIntByName(Results, "flash"));
		rp_SetClientItem(client, grenade_smoke, SQL_FetchIntByName(Results, "smoke"));
		rp_SetClientItem(client, grenade_decoy, SQL_FetchIntByName(Results, "decoy"));
		rp_SetClientItem(client, grenade_molotov, SQL_FetchIntByName(Results, "molotov"));
		rp_SetClientItem(client, grenade_incendiary, SQL_FetchIntByName(Results, "incendiary"));
		rp_SetClientItem(client, gear_tacticalgrenade, SQL_FetchIntByName(Results, "tacticalgrenade"));
		rp_SetClientItem(client, gear_breachcharge, SQL_FetchIntByName(Results, "breachcharge"));
		rp_SetClientItem(client, i_munitionsincendiaire, SQL_FetchIntByName(Results, "munitionsincendiaire"));
		rp_SetClientItem(client, i_munitionscaoutchouc, SQL_FetchIntByName(Results, "munitionscaoutchouc"));
		rp_SetClientItem(client, i_munitionsperforante, SQL_FetchIntByName(Results, "munitionsperforante"));
		rp_SetClientItem(client, i_munitionsexplosive, SQL_FetchIntByName(Results, "munitionsexplosive"));
	}
} 

public Action rp_MenuBuild(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_Job) == 13)
	{
		menu.SetTitle("Build - Artificier");
		if(rp_GetClientInt(client, i_Job) == 13)
			menu.AddItem("", "He");
	}	
}	

public Action rp_MenuInventory(int client, Menu menu)
{
	//menu.AddItem("", "⁂ Artificier ⁂", ITEMDRAW_DISABLED);
	
	char amount[128];	
	if(rp_GetClientItem(client, grenade_he) >= 1)
	{
		Format(STRING(amount), "Grenade HE [%i]", rp_GetClientItem(client, grenade_he));
		menu.AddItem("he", amount);
	}
	
	if(rp_GetClientItem(client, grenade_flash) >= 1)
	{
		Format(STRING(amount), "Grenade Flash [%i]", rp_GetClientItem(client, grenade_flash));
		menu.AddItem("flash", amount);
	}
	
	if(rp_GetClientItem(client, grenade_smoke) >= 1)
	{
		Format(STRING(amount), "Grenade Smoke [%i]", rp_GetClientItem(client, grenade_smoke));
		menu.AddItem("smoke", amount);
	}
	
	if(rp_GetClientItem(client, grenade_decoy) >= 1)
	{
		Format(STRING(amount), "Grenade Decoy [%i]", rp_GetClientItem(client, grenade_decoy));
		menu.AddItem("decoy", amount);
	}
	
	if(rp_GetClientItem(client, grenade_incendiary) >= 1)
	{
		Format(STRING(amount), "Grenade Incendiaire [%i]", rp_GetClientItem(client, grenade_incendiary));
		menu.AddItem("incendiary", amount);
	}
	
	if(rp_GetClientItem(client, grenade_molotov) >= 1)
	{
		Format(STRING(amount), "Molotov [%i]", rp_GetClientItem(client, grenade_molotov));
		menu.AddItem("molotov", amount);
	}
	
	if(rp_GetClientItem(client, gear_tacticalgrenade) >= 1)
	{
		Format(STRING(amount), "Grenade Tactique [%i]", rp_GetClientItem(client, gear_tacticalgrenade));
		menu.AddItem("tacticalgrenade", amount);
	}
	
	if(rp_GetClientItem(client, gear_breachcharge) >= 1)
	{
		Format(STRING(amount), "Charges Explosives [%i]", rp_GetClientItem(client, gear_breachcharge));
		menu.AddItem("breachcharge", amount);
	}
	
	if(rp_GetClientItem(client, i_munitionsincendiaire) >= 1)
	{
		Format(STRING(amount), "Munitions incendiaires [%i]", rp_GetClientItem(client, i_munitionsincendiaire));
		menu.AddItem("munitionsincendiaire", amount);
	}
	
	if(rp_GetClientItem(client, i_munitionscaoutchouc) >= 1)
	{
		Format(STRING(amount), "Munitions caoutchouc [%i]", rp_GetClientItem(client, i_munitionscaoutchouc));
		menu.AddItem("munitionscaoutchouc", amount);
	}
	
	if(rp_GetClientItem(client, i_munitionsperforante) >= 1)
	{
		Format(STRING(amount), "Munitions perforante [%i]", rp_GetClientItem(client, i_munitionsperforante));
		menu.AddItem("munitionsperforante", amount);
	}
	
	if(rp_GetClientItem(client, i_munitionsexplosive) >= 1)
	{
		Format(STRING(amount), "Munitions explosive [%i]", rp_GetClientItem(client, i_munitionsexplosive));
		menu.AddItem("munitionsexplosive", amount);
	}
}	
	
public int rp_HandlerMenuInventory(int client, char[] info)
{
	if(StrEqual(info, "he") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, grenade_he, rp_GetClientItem(client, grenade_he) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, grenade_he), steamID[client]);
			
		GivePlayerItem(client, "weapon_hegrenade");
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade à fragmentation.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise une grenade a fragmentation.", client);
	}
	else if(StrEqual(info, "flash") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, grenade_flash, rp_GetClientItem(client, grenade_flash) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, grenade_flash), steamID[client]);
			
		GivePlayerItem(client, "weapon_flashbang");
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade Flashbang (GSS).", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise une grenade Flashbang (GSS).", client);
	}
	else if(StrEqual(info, "smoke") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, grenade_smoke, rp_GetClientItem(client, grenade_smoke) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, grenade_smoke), steamID[client]);
			
		GivePlayerItem(client, "weapon_smokegrenade");
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade fumigène.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise une grenade fumigène.", client);
	}
	else if(StrEqual(info, "decoy") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, grenade_decoy, rp_GetClientItem(client, grenade_decoy) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, grenade_decoy), steamID[client]);
			
		GivePlayerItem(client, "weapon_decoy");
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade leurre.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise une grenade leurre.", client);
	}
	else if(StrEqual(info, "molotov") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, grenade_molotov, rp_GetClientItem(client, grenade_molotov) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, grenade_molotov), steamID[client]);
			
		GivePlayerItem(client, "weapon_molotov");
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}un cocktail Molotov.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise un cocktail Molotov.", client);
	}
	else if(StrEqual(info, "incendiary") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, grenade_incendiary, rp_GetClientItem(client, grenade_incendiary) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, grenade_incendiary), steamID[client]);
			
		GivePlayerItem(client, "weapon_incgrenade");
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade incendiaire.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise une grenade incendiaire.", client);
	}
	else if(StrEqual(info, "tacticalgrenade") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, gear_tacticalgrenade, rp_GetClientItem(client, gear_tacticalgrenade) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, gear_tacticalgrenade), steamID[client]);
			
		GivePlayerItem(client, "weapon_tagrenade");
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}une grenade tactique.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise une grenade tactique.", client);
	}
	else if(StrEqual(info, "breachcharge") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, gear_breachcharge, rp_GetClientItem(client, gear_breachcharge) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, gear_breachcharge), steamID[client]);
			
		GivePlayerItem(client, "weapon_breachcharge");
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}des charges explosives.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise des charges explosives.", client);
	}
	else if(StrEqual(info, "munitionsincendiaire") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, i_munitionsincendiaire, rp_GetClientItem(client, i_munitionsincendiaire) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, i_munitionsincendiaire), steamID[client]);
		
		int wepID = Client_GetActiveWeapon(client);
		rp_SetWeaponBallType(wepID, ball_type_fire);
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}des charges explosives.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise des charges explosives.", client);
	}
	else if(StrEqual(info, "munitionscaoutchouc") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, i_munitionscaoutchouc, rp_GetClientItem(client, i_munitionscaoutchouc) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, i_munitionscaoutchouc), steamID[client]);
			
		int wepID = Client_GetActiveWeapon(client);
		rp_SetWeaponBallType(wepID, ball_type_caoutchouc);	
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}des charges explosives.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise des charges explosives.", client);
	}
	else if(StrEqual(info, "munitionsperforante") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, i_munitionsperforante, rp_GetClientItem(client, i_munitionsperforante) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, i_munitionsperforante), steamID[client]);
		
		int wepID = Client_GetActiveWeapon(client);
		rp_SetWeaponBallType(wepID, ball_type_revitalisante);
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}des charges explosives.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise des charges explosives.", client);
	}
	else if(StrEqual(info, "munitionsexplosive") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, i_munitionsexplosive, rp_GetClientItem(client, i_munitionsexplosive) - 1);
		SetSQL_Int(g_DB, "rp_artificier", info, rp_GetClientItem(client, i_munitionsexplosive), steamID[client]);
			
		int wepID = Client_GetActiveWeapon(client);
		rp_SetWeaponBallType(wepID, ball_type_explode);	
			
		CPrintToChat(client, "%s Vous utilisez {lightblue}des charges explosives.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise des charges explosives.", client);
	}
	
	FakeClientCommand(client, "rp");
}		

public Action rp_OnTakeDamage(int victim, int &attacker, float &damage)
{
	int wepID;
	if(victim != attacker || attacker != victim)
	{
		if (IsClientValid(attacker))
			wepID = Client_GetActiveWeapon(attacker);
	}	
	enum_ball_type wepType = rp_GetWeaponBallType(wepID);
	
	/*if( wepType != ball_type_revitalisante )
		rp_ClientAggroIncrement(attacker, victim, RoundFloat(damage));*/
	
	switch( wepType ) {
		case ball_type_fire: {
			float position[3];
			PointVision(attacker, position);
			
			if(IsValidEntity(victim) && victim <= MaxClients)
				IgniteEntity(victim, 10.0, false);
			else
				rp_CreateFire(position, 10.0);
		}
		case ball_type_caoutchouc: {
			damage *= 0.0;
			
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
			damage *= 0.5;
				
			rp_SetClientFloat(victim, fl_FrozenTime, GetGameTime() + 1.5);

		}
		case ball_type_poison: {
			damage *= 0.66;
			//rp_ClientPoison(victim, 30.0, attacker);
		}
		case ball_type_vampire: {
			damage *= 0.75;
			int current = GetClientHealth(attacker);
			if( current < 500 ) {
				current += RoundToFloor(damage*0.2);

				if( current > 500 )
					current = 500;

				SetEntityHealth(attacker, current);
				
				float vecOrigin[3], vecOrigin2[3];
				GetClientEyePosition(attacker, vecOrigin);
				GetClientEyePosition(victim, vecOrigin2);
				
				vecOrigin[2] -= 20.0; vecOrigin2[2] -= 20.0;
				
				TE_SetupBeamPoints(vecOrigin, vecOrigin2, g_cBeam, 0, 0, 0, 0.1, 10.0, 10.0, 0, 10.0, {250, 50, 50, 250}, 10);
				TE_SendToAll();
			}
		}
		case ball_type_paintball: {
			damage *= 1.0;
			
			g_iClientColor[victim][0] = Math_GetRandomInt(50, 255);
			g_iClientColor[victim][1] = Math_GetRandomInt(50, 255);
			g_iClientColor[victim][2] = Math_GetRandomInt(50, 255);
			g_iClientColor[victim][3] = Math_GetRandomInt(100, 240);

			SetEntityRenderColor(victim, g_iClientColor[victim][0], g_iClientColor[victim][1], g_iClientColor[victim][2], g_iClientColor[victim][3]);
		}
		case ball_type_reflexive: {
			damage = 0.9;
		}
		case ball_type_explode: {
			damage *= 0.8;		
			float position[3];
			PointVision(attacker, position);
			
			TE_SetupExplosion(position, -1, 1.0, 1, 0, 200, 200);
			TE_SendToAll();
		}
		case ball_type_revitalisante: {
			int current = GetClientHealth(victim);
			if( current < 500 ) {
				current += RoundToCeil(damage*0.1); // On rend environ 10% des degats infligés sous forme de vie

				if( current > 500 )
					current = 500;

				SetEntityHealth(victim, current);
				
				float vecOrigin[3], vecOrigin2[3];
				GetClientEyePosition(attacker, vecOrigin);
				GetClientEyePosition(victim, vecOrigin2);
				
				vecOrigin[2] -= 20.0; vecOrigin2[2] -= 20.0;
				
				TE_SetupBeamPoints(vecOrigin, vecOrigin2, g_cBeam, 0, 0, 0, 0.1, 10.0, 10.0, 0, 10.0, {0, 255, 0, 250}, 10); // Laser vert entre les deux
				TE_SendToAll();
			}
			damage = 0.0; // L'arme ne fait pas de dégats
		}
		case ball_type_notk: {
			if(rp_GetClientInt(attacker, i_Group) == rp_GetClientInt(victim, i_Group)){
				damage *= 0.0;
			}
		}
	}
}	
	
public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if(StrEqual(entName, "Artificier"))
	{
		int nbArmu;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				if(rp_GetClientInt(i, i_Job) == 13 && !rp_GetClientBool(i, b_isAfk))
					nbArmu++;
			}
		}
		if(nbArmu == 0 || nbArmu == 1 && rp_GetClientInt(client, i_Job) == 13 || rp_GetClientInt(client, i_Job) == 13 && rp_GetClientInt(client, i_Grade) <= 2)
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
	menu.AddItem("grenade", "Grenades");
	menu.AddItem("ammo", "Munitions");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "grenade"))
			SellGrenades(client, client);	
		else if(StrEqual(info, "ammo"))
			SellAmmo(client, client);	
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
	if(rp_GetClientInt(client, i_Job) == 13)
	{
		menu.AddItem("grenade", "Grenades & Explosives");
		menu.AddItem("ammo", "Munitions");
	}
}	

public int rp_HandleMenuVendre(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "grenade"))
		SellGrenades(client, target);	
	else if(StrEqual(info, "ammo"))
		SellAmmo(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellGrenades(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Grenades & Explosives Disponibles");

	prix = rp_GetPrice("grenadehe");
	Format(STRING(strFormat), "%i|%i|grenadehe", target, prix);
	Format(STRING(strMenu), "Grenade HE (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("grenadeflash");
	Format(STRING(strFormat), "%i|%i|grenadeflash", target, prix);
	Format(STRING(strMenu), "Grenade Flash (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("grenadesmoke");
	Format(STRING(strFormat), "%i|%i|grenadesmoke", target, prix);
	Format(STRING(strMenu), "Grenade Smoke (%i$)", prix);
	menu.AddItem(strFormat, strMenu);	
	
	prix = rp_GetPrice("grenadedecoy");
	Format(STRING(strFormat), "%i|%i|grenadedecoy", target, prix);
	Format(STRING(strMenu), "Grenade Decoy (%i$)", prix);
	menu.AddItem(strFormat, strMenu);	
	
	prix = rp_GetPrice("grenadeincendiaire");
	Format(STRING(strFormat), "%i|%i|grenadeincendiaire", target, prix);
	Format(STRING(strMenu), "Grenade Incendiaire (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("molotov");
	Format(STRING(strFormat), "%i|%i|molotov", target, prix);
	Format(STRING(strMenu), "Molotov (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("grenadetactique");
	Format(STRING(strFormat), "%i|%i|grenadetactique", target, prix);
	Format(STRING(strMenu), "Grenade Tactique (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("chargesexplosives");
	Format(STRING(strFormat), "%i|%i|chargesexplosives", target, prix);
	Format(STRING(strMenu), "Charges Explosives (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}			

Menu SellAmmo(int client, int target)
{
	int prix;
	char strFormat[128], strMenu[128];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Munitions Disponibles");
	
	prix = rp_GetPrice("mp9");
	Format(STRING(strFormat), "%i|%i|mp9", target, prix);
	Format(STRING(strMenu), "Mp9 (%i$)", prix);
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
						rp_SetJobCapital(6, rp_GetJobCapital(6) + prix / 2);
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
						rp_SetJobCapital(6, rp_GetJobCapital(6) + prix / 2);
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
			
			if(StrEqual(buffer[2], "p2000"))
			{
				rp_SetClientItem(client, pistol_p2000, rp_GetClientItem(client, pistol_p2000) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_p2000), steamID[client]);
			}	
			else if(StrEqual(buffer[2], "usps"))
			{
				rp_SetClientItem(client, pistol_usps, rp_GetClientItem(client, pistol_usps) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_usps), steamID[client]);
			}
			else if(StrEqual(buffer[2], "glock18"))
			{
				rp_SetClientItem(client, pistol_glock18, rp_GetClientItem(client, pistol_glock18) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_glock18), steamID[client]);
			}
			else if(StrEqual(buffer[2], "p250"))
			{
				rp_SetClientItem(client, pistol_p250, rp_GetClientItem(client, pistol_p250) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_p250), steamID[client]);
			}
			else if(StrEqual(buffer[2], "fiveseven"))
			{
				rp_SetClientItem(client, pistol_fiveseven, rp_GetClientItem(client, pistol_fiveseven) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_fiveseven), steamID[client]);
			}
			else if(StrEqual(buffer[2], "tec9"))
			{
				rp_SetClientItem(client, pistol_tec9, rp_GetClientItem(client, pistol_tec9) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_tec9), steamID[client]);
			}
			else if(StrEqual(buffer[2], "cz75"))
			{
				rp_SetClientItem(client, pistol_cz75, rp_GetClientItem(client, pistol_cz75) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_cz75), steamID[client]);
			}
			else if(StrEqual(buffer[2], "dualberettas"))
			{
				rp_SetClientItem(client, pistol_dualberettas, rp_GetClientItem(client, pistol_dualberettas) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_dualberettas), steamID[client]);
			}
			else if(StrEqual(buffer[2], "deagle"))
			{
				rp_SetClientItem(client, pistol_deagle, rp_GetClientItem(client, pistol_deagle) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_deagle), steamID[client]);
			}
			else if(StrEqual(buffer[2], "revolver"))
			{
				rp_SetClientItem(client, pistol_revolver, rp_GetClientItem(client, pistol_revolver) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_revolver), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mp9"))
			{
				rp_SetClientItem(client, smg_mp9, rp_GetClientItem(client, smg_mp9) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_mp9), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mac10"))
			{
				rp_SetClientItem(client, smg_mac10, rp_GetClientItem(client, smg_mac10) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_mac10), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ppbizon"))
			{
				rp_SetClientItem(client, smg_ppbizon, rp_GetClientItem(client, smg_ppbizon) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_ppbizon), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mp7"))
			{
				rp_SetClientItem(client, smg_mp7, rp_GetClientItem(client, smg_mp7) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_mp7), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ump45"))
			{
				rp_SetClientItem(client, smg_ump45, rp_GetClientItem(client, smg_ump45) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_ump45), steamID[client]);
			}
			else if(StrEqual(buffer[2], "p90"))
			{
				rp_SetClientItem(client, smg_p90, rp_GetClientItem(client, smg_p90) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_p90), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mp5sd"))
			{
				rp_SetClientItem(client, smg_mp5sd, rp_GetClientItem(client, smg_mp5sd) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_mp5sd), steamID[client]);
			}
			else if(StrEqual(buffer[2], "famas"))
			{
				rp_SetClientItem(client, rifle_famas, rp_GetClientItem(client, rifle_famas) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_famas), steamID[client]);
			}
			else if(StrEqual(buffer[2], "galilar"))
			{
				rp_SetClientItem(client, rifle_galilar, rp_GetClientItem(client, rifle_galilar) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_galilar), steamID[client]);
			}
			else if(StrEqual(buffer[2], "m4a4"))
			{
				rp_SetClientItem(client, rifle_m4a4, rp_GetClientItem(client, rifle_m4a4) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_m4a4), steamID[client]);
			}
			else if(StrEqual(buffer[2], "m4a1s"))
			{
				rp_SetClientItem(client, rifle_m4a1s, rp_GetClientItem(client, rifle_m4a1s) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_m4a1s), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ak47"))
			{
				rp_SetClientItem(client, rifle_ak47, rp_GetClientItem(client, rifle_ak47) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_ak47), steamID[client]);
			}
			else if(StrEqual(buffer[2], "aug"))
			{
				rp_SetClientItem(client, rifle_aug, rp_GetClientItem(client, rifle_aug) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_aug), steamID[client]);
			}
			else if(StrEqual(buffer[2], "sg553"))
			{
				rp_SetClientItem(client, rifle_sg553, rp_GetClientItem(client, rifle_sg553) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_sg553), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ssg08"))
			{
				rp_SetClientItem(client, rifle_ssg08, rp_GetClientItem(client, rifle_ssg08) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_ssg08), steamID[client]);
			}
			else if(StrEqual(buffer[2], "awp"))
			{
				rp_SetClientItem(client, rifle_awp, rp_GetClientItem(client, rifle_awp) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_awp), steamID[client]);
			}
			else if(StrEqual(buffer[2], "scar20"))
			{
				rp_SetClientItem(client, rifle_scar20, rp_GetClientItem(client, rifle_scar20) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_scar20), steamID[client]);
			}
			else if(StrEqual(buffer[2], "g3sg1"))
			{
				rp_SetClientItem(client, rifle_g3sg1, rp_GetClientItem(client, rifle_g3sg1) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_g3sg1), steamID[client]);
			}
			else if(StrEqual(buffer[2], "nova"))
			{
				rp_SetClientItem(client, heavy_nova, rp_GetClientItem(client, heavy_nova) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_nova), steamID[client]);
			}
			else if(StrEqual(buffer[2], "xm1014"))
			{
				rp_SetClientItem(client, heavy_xm1014, rp_GetClientItem(client, heavy_xm1014) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_xm1014), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mag7"))
			{
				rp_SetClientItem(client, heavy_mag7, rp_GetClientItem(client, heavy_mag7) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_mag7), steamID[client]);
			}
			else if(StrEqual(buffer[2], "sawedoff"))
			{
				rp_SetClientItem(client, heavy_sawedoff, rp_GetClientItem(client, heavy_sawedoff) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_sawedoff), steamID[client]);
			}
			else if(StrEqual(buffer[2], "m249"))
			{
				rp_SetClientItem(client, heavy_m249, rp_GetClientItem(client, heavy_m249) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_m249), steamID[client]);
			}
			else if(StrEqual(buffer[2], "negev"))
			{
				rp_SetClientItem(client, heavy_negev, rp_GetClientItem(client, heavy_negev) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_negev), steamID[client]);
			}
			else if(StrEqual(buffer[2], "kevlar"))
			{
				rp_SetClientItem(client, gear_kevlar, rp_GetClientItem(client, gear_kevlar) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, gear_kevlar), steamID[client]);
			}
			else if(StrEqual(buffer[2], "helmet"))
			{
				rp_SetClientItem(client, gear_helmet, rp_GetClientItem(client, gear_helmet) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, gear_helmet), steamID[client]);
			}
			else if(StrEqual(buffer[2], "zeus"))
			{
				rp_SetClientItem(client, gear_zeus, rp_GetClientItem(client, gear_zeus) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, gear_zeus), steamID[client]);
			}
			else if(StrEqual(buffer[2], "assaultsuit"))
			{
				rp_SetClientItem(client, gear_assaultsuit, rp_GetClientItem(client, gear_assaultsuit) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, gear_assaultsuit), steamID[client]);
			}
			else if(StrEqual(buffer[2], "hache"))
			{
				rp_SetClientItem(client, gear_axe, rp_GetClientItem(client, gear_axe) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", "axe", rp_GetClientItem(client, gear_axe), steamID[client]);
			}
			else if(StrEqual(buffer[2], "marteau"))
			{
				rp_SetClientItem(client, gear_hammer, rp_GetClientItem(client, gear_hammer) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", "hammer", rp_GetClientItem(client, gear_hammer), steamID[client]);
			}
			else if(StrEqual(buffer[2], "clé à molette"))
			{
				rp_SetClientItem(client, gear_wrench, rp_GetClientItem(client, gear_wrench) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", "wrench", rp_GetClientItem(client, gear_wrench), steamID[client]);
			}
			else if(StrEqual(buffer[2], "munitions"))
			{
				rp_SetClientItem(client, i_munition, rp_GetClientItem(client, i_munition) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, i_munition), steamID[client]);
			}
			else if(StrEqual(buffer[2], "sanandreas"))
			{
				rp_SetClientItem(client, i_sanandreas, rp_GetClientItem(client, i_sanandreas) + quantity);	
				SetSQL_Int(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, i_sanandreas), steamID[client]);
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