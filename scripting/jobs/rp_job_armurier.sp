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
char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];
char dbconfig[] = "roleplay";
Database g_DB;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Armurier", 
	author = "Benito", 
	description = "Métier Armurier", 
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
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_armurier.log");
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
		"CREATE TABLE IF NOT EXISTS `rp_armurier` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `p2000` int(100) NOT NULL, \
		  `usps` int(100) NOT NULL, \
		  `glock18` int(100) NOT NULL, \
		  `p250` int(100) NOT NULL, \
		  `fiveseven` int(100) NOT NULL, \
		  `tec9` int(100) NOT NULL, \
		  `cz75` int(100) NOT NULL, \
		  `dualberettas` int(100) NOT NULL, \
		  `deagle` int(100) NOT NULL, \
		  `revolver` int(100) NOT NULL, \
		  `mp9` int(100) NOT NULL, \
		  `mac10` int(100) NOT NULL, \
		  `ppbizon` int(100) NOT NULL, \
		  `mp7` int(100) NOT NULL, \
		  `ump45` int(100) NOT NULL, \
		  `p90` int(100) NOT NULL, \
		  `mp5sd` int(100) NOT NULL, \
		  `famas` int(100) NOT NULL, \
		  `galilar` int(100) NOT NULL, \
		  `m4a4` int(100) NOT NULL, \
		  `m4a1s` int(100) NOT NULL, \
		  `ak47` int(100) NOT NULL, \
		  `aug` int(100) NOT NULL, \
		  `sg553` int(100) NOT NULL, \
		  `ssg08` int(100) NOT NULL, \
		  `awp` int(100) NOT NULL, \
		  `scar20` int(100) NOT NULL, \
		  `g3sg1` int(100) NOT NULL, \
		  `nova` int(100) NOT NULL, \
		  `xm1014` int(100) NOT NULL, \
		  `mag7` int(100) NOT NULL, \
		  `sawedoff` int(100) NOT NULL, \
		  `m249` int(100) NOT NULL, \
		  `negev` int(100) NOT NULL, \
		  `kevlar` int(100) NOT NULL, \
		  `helmet` int(100) NOT NULL, \
		  `zeus` int(100) NOT NULL, \
		  `assaultsuit` int(100) NOT NULL, \
		  `axe` int(100) NOT NULL, \
		  `hammer` int(100) NOT NULL, \
		  `wrench` int(100) NOT NULL, \
		  `munitions` int(100) NOT NULL, \
		  `sanandreas` int(100) NOT NULL, \
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
}

public void OnClientPutInServer(int client)
{	
}

public void OnMapStart()
{
	PrecacheModel("models/props_survival/upgrades/upgrade_dz_armor_helmet.mdl", true);
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
	Format(STRING(buffer), 
		"INSERT IGNORE INTO `rp_armurier` ( \
		  `Id`, \
		  `steamid`, \
		  `playername`, \
		  `p2000`, \
		  `usps`, \
		  `glock18`, \
		  `p250`, \
		  `fiveseven`, \
		  `tec9`, \
		  `cz75`, \
		  `dualberettas`, \
		  `deagle`, \
		  `revolver`, \
		  `mp9`, \
		  `mac10`, \
		  `ppbizon`, \
		  `mp7`, \
		  `ump45`, \
		  `p90`, \
		  `mp5sd`, \
		  `famas`, \
		  `galilar`, \
		  `m4a4`, \
		  `m4a1s`, \
		  `ak47`, \
		  `aug`, \
		  `sg553`, \
		  `ssg08`, \
		  `awp`, \
		  `scar20`, \
		  `g3sg1`, \
		  `nova`, \
		  `xm1014`, \
		  `mag7`, \
		  `sawedoff`, \
		  `m249`, \
		  `negev`, \
		  `kevlar`, \
		  `helmet`, \
		  `zeus`, \
		  `assaultsuit`, \
		  `axe`, \
		  `hammer`, \
		  `wrench`, \
		  `munitions`, \
		  `sanandreas`, \
		  `timestamp`\
		  ) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	SQLCALLBACK_LoadTech(client);
}

/***************************************************************************************

								P L U G I N  -  S Q L

***************************************************************************************/

public void SQLCALLBACK_LoadTech(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_armurier WHERE steamid = '%s';", steamID[client]);
	g_DB.Query(SQLLoadTechQueryCallback, buffer, GetClientUserId(client));
}

public void SQLLoadTechQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientItem(client, pistol_p2000, SQL_FetchIntByName(Results, "p2000"));
		rp_SetClientItem(client, pistol_usps, SQL_FetchIntByName(Results, "usps"));
		rp_SetClientItem(client, pistol_glock18, SQL_FetchIntByName(Results, "glock18"));
		rp_SetClientItem(client, pistol_p250, SQL_FetchIntByName(Results, "p250"));
		rp_SetClientItem(client, pistol_fiveseven, SQL_FetchIntByName(Results, "fiveseven"));
		rp_SetClientItem(client, pistol_tec9, SQL_FetchIntByName(Results, "tec9"));
		rp_SetClientItem(client, pistol_cz75, SQL_FetchIntByName(Results, "cz75"));
		rp_SetClientItem(client, pistol_dualberettas, SQL_FetchIntByName(Results, "dualberettas"));
		rp_SetClientItem(client, pistol_deagle, SQL_FetchIntByName(Results, "deagle"));
		rp_SetClientItem(client, pistol_revolver, SQL_FetchIntByName(Results, "revolver"));
		rp_SetClientItem(client, smg_mp9, SQL_FetchIntByName(Results, "mp9"));
		rp_SetClientItem(client, smg_mac10, SQL_FetchIntByName(Results, "mac10"));
		rp_SetClientItem(client, smg_ppbizon, SQL_FetchIntByName(Results, "ppbizon"));
		rp_SetClientItem(client, smg_mp7, SQL_FetchIntByName(Results, "mp7"));
		rp_SetClientItem(client, smg_ump45, SQL_FetchIntByName(Results, "ump45"));
		rp_SetClientItem(client, smg_p90, SQL_FetchIntByName(Results, "p90"));
		rp_SetClientItem(client, smg_mp5sd, SQL_FetchIntByName(Results, "mp5sd"));
		rp_SetClientItem(client, rifle_famas, SQL_FetchIntByName(Results, "famas"));
		rp_SetClientItem(client, rifle_galilar, SQL_FetchIntByName(Results, "galilar"));
		rp_SetClientItem(client, rifle_m4a4, SQL_FetchIntByName(Results, "m4a4"));
		rp_SetClientItem(client, rifle_m4a1s, SQL_FetchIntByName(Results, "m4a1s"));
		rp_SetClientItem(client, rifle_ak47, SQL_FetchIntByName(Results, "ak47"));
		rp_SetClientItem(client, rifle_aug, SQL_FetchIntByName(Results, "aug"));
		rp_SetClientItem(client, rifle_sg553, SQL_FetchIntByName(Results, "sg553"));
		rp_SetClientItem(client, rifle_ssg08, SQL_FetchIntByName(Results, "ssg08"));
		rp_SetClientItem(client, rifle_awp, SQL_FetchIntByName(Results, "awp"));
		rp_SetClientItem(client, rifle_scar20, SQL_FetchIntByName(Results, "scar20"));
		rp_SetClientItem(client, rifle_g3sg1, SQL_FetchIntByName(Results, "g3sg1"));
		rp_SetClientItem(client, heavy_nova, SQL_FetchIntByName(Results, "nova"));
		rp_SetClientItem(client, heavy_xm1014, SQL_FetchIntByName(Results, "xm1014"));
		rp_SetClientItem(client, heavy_mag7, SQL_FetchIntByName(Results, "mag7"));
		rp_SetClientItem(client, heavy_sawedoff, SQL_FetchIntByName(Results, "sawedoff"));
		rp_SetClientItem(client, heavy_m249, SQL_FetchIntByName(Results, "m249"));
		rp_SetClientItem(client, heavy_negev, SQL_FetchIntByName(Results, "negev"));
		rp_SetClientItem(client, gear_kevlar, SQL_FetchIntByName(Results, "kevlar"));
		rp_SetClientItem(client, gear_helmet, SQL_FetchIntByName(Results, "helmet"));
		rp_SetClientItem(client, gear_zeus, SQL_FetchIntByName(Results, "	zeus"));
		rp_SetClientItem(client, gear_assaultsuit, SQL_FetchIntByName(Results, "assaultsuit"));
		rp_SetClientItem(client, gear_axe, SQL_FetchIntByName(Results, "axe"));
		rp_SetClientItem(client, gear_hammer, SQL_FetchIntByName(Results, "hammer"));
		rp_SetClientItem(client, gear_wrench, SQL_FetchIntByName(Results, "wrench"));
		rp_SetClientItem(client, i_munition, SQL_FetchIntByName(Results, "munitions"));
		rp_SetClientItem(client, i_sanandreas, SQL_FetchIntByName(Results, "sanandreas"));
	}
} 

/***************************************************************************************

						P L U G I N  -  G L O B A L  F O R W A R D

***************************************************************************************/
public void rp_OnClientDeath(int attacker, int victim, const char[] weapon, bool headshot)
{
}

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if(StrEqual(entModel, "models/weapons/w_axe_dropped.mdl"))
	{
		int iMelee = GivePlayerItem(client, "weapon_axe");
		EquipPlayerWeapon(client, iMelee);
		RemoveEdict(aim);
		CPrintToChat(client, "%s Vous avez ramassé une hache.", TEAM);
	}
	else if(StrEqual(entModel, "models/weapons/w_hammer_dropped.mdl"))		
	{
		int iMelee = GivePlayerItem(client, "weapon_hammer");
		EquipPlayerWeapon(client, iMelee);
		RemoveEdict(aim);
		
		CPrintToChat(client, "%s Vous avez ramassé un marteau.", TEAM);
	}
	else if(StrEqual(entModel, "models/weapons/w_spanner_dropped.mdl"))
	{
		int iMelee = GivePlayerItem(client, "weapon_spanner");
		EquipPlayerWeapon(client, iMelee);
		RemoveEdict(aim);
		
		CPrintToChat(client, "%s Vous avez ramassé une clé à molette.", TEAM);
	}	
	
	if(StrEqual(entName, "Armurerie"))
	{
		int nbArmu;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				if(rp_GetClientInt(i, i_Job) == 6 && !rp_GetClientBool(i, b_isAfk))
					nbArmu++;
			}
		}
		if(nbArmu == 0 || nbArmu == 1 && rp_GetClientInt(client, i_Job) == 6 || rp_GetClientInt(client, i_Job) == 6 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un armurier.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un armurier.");
		}	
	}
}	

public Action rp_MenuBuild(int client, Menu menu)
{
	if(rp_GetClientInt(client, i_Job) == 6)
	{
		menu.SetTitle("Build - Armurier");
		menu.AddItem("", "En Développement", ITEMDRAW_DISABLED);
	}	
}	

public Action rp_MenuInventory(int client, Menu menu)
{
	char amount[128];
	
	if(rp_GetClientItem(client, pistol_p2000) >= 1)
	{
		Format(STRING(amount), "P2000: %i", rp_GetClientItem(client, pistol_p2000));
		menu.AddItem("p2000", amount);
	}
	
	if(rp_GetClientItem(client, pistol_usps) >= 1)
	{
		Format(STRING(amount), "Usp-s: %i", rp_GetClientItem(client, pistol_usps));
		menu.AddItem("usps", amount);
	}
	
	if(rp_GetClientItem(client, pistol_glock18) >= 1)
	{
		Format(STRING(amount), "Glock18: %i", rp_GetClientItem(client, pistol_glock18));
		menu.AddItem("glock18", amount);
	}
	
	if(rp_GetClientItem(client, pistol_p250) >= 1)
	{
		Format(STRING(amount), "P250: %i", rp_GetClientItem(client, pistol_p250));
		menu.AddItem("p250", amount);
	}
	
	if(rp_GetClientItem(client, pistol_fiveseven) >= 1)
	{
		Format(STRING(amount), "Fiveseven: %i", rp_GetClientItem(client, pistol_fiveseven));
		menu.AddItem("fiveseven", amount);
	}
	
	if(rp_GetClientItem(client, pistol_tec9) >= 1)
	{
		Format(STRING(amount), "Tec-9: %i", rp_GetClientItem(client, pistol_tec9));
		menu.AddItem("tec9", amount);
	}
	
	if(rp_GetClientItem(client, pistol_cz75) >= 1)
	{
		Format(STRING(amount), "Cz-75: %i", rp_GetClientItem(client, pistol_cz75));
		menu.AddItem("cz75", amount);
	}
	
	if(rp_GetClientItem(client, pistol_dualberettas) >= 1)
	{
		Format(STRING(amount), "Dual Berettas: %i", rp_GetClientItem(client, pistol_dualberettas));
		menu.AddItem("dualberettas", amount);
	}
	
	if(rp_GetClientItem(client, pistol_deagle) >= 1)
	{
		Format(STRING(amount), "Deagle: %i", rp_GetClientItem(client, pistol_deagle));
		menu.AddItem("deagle", amount);
	}
	
	if(rp_GetClientItem(client, pistol_revolver) >= 1)
	{
		Format(STRING(amount), "Revolver: %i", rp_GetClientItem(client, pistol_revolver));
		menu.AddItem("revolver", amount);
	}
	
	if(rp_GetClientItem(client, smg_mp9) >= 1)
	{
		Format(STRING(amount), "Mp9: %i", rp_GetClientItem(client, smg_mp9));
		menu.AddItem("mp9", amount);
	}
	
	if(rp_GetClientItem(client, smg_mac10) >= 1)
	{
		Format(STRING(amount), "Mac-10: %i", rp_GetClientItem(client, smg_mac10));
		menu.AddItem("mac10", amount);
	}
	
	if(rp_GetClientItem(client, smg_ppbizon) >= 1)
	{
		Format(STRING(amount), "PP-Bizon: %i", rp_GetClientItem(client, smg_ppbizon));
		menu.AddItem("ppbizon", amount);
	}
	
	if(rp_GetClientItem(client, smg_mp7) >= 1)
	{
		Format(STRING(amount), "Mp7: %i", rp_GetClientItem(client, smg_mp7));
		menu.AddItem("mp7", amount);
	}
	
	if(rp_GetClientItem(client, smg_ump45) >= 1)
	{
		Format(STRING(amount), "Ump-45: %i", rp_GetClientItem(client, smg_ump45));
		menu.AddItem("ump45", amount);
	}
	
	if(rp_GetClientItem(client, smg_p90) >= 1)
	{
		Format(STRING(amount), "P90: %i", rp_GetClientItem(client, smg_p90));
		menu.AddItem("p90", amount);
	}
	
	if(rp_GetClientItem(client, smg_mp5sd) >= 1)
	{
		Format(STRING(amount), "Mp5-sd: %i", rp_GetClientItem(client, smg_mp5sd));
		menu.AddItem("mp5sd", amount);
	}
	
	if(rp_GetClientItem(client, rifle_famas) >= 1)
	{
		Format(STRING(amount), "Famas: %i", rp_GetClientItem(client, rifle_famas));
		menu.AddItem("famas", amount);
	}
	
	if(rp_GetClientItem(client, rifle_galilar) >= 1)
	{
		Format(STRING(amount), "Galilar: %i", rp_GetClientItem(client, rifle_galilar));
		menu.AddItem("galilar", amount);
	}
	
	if(rp_GetClientItem(client, rifle_m4a4) >= 1)
	{
		Format(STRING(amount), "M4a4: %i", rp_GetClientItem(client, rifle_m4a4));
		menu.AddItem("m4a4", amount);
	}
	
	if(rp_GetClientItem(client, rifle_m4a1s) >= 1)
	{
		Format(STRING(amount), "M4a1s: %i", rp_GetClientItem(client, rifle_m4a1s));
		menu.AddItem("m4a1s", amount);
	}
	
	if(rp_GetClientItem(client, rifle_ak47) >= 1)
	{
		Format(STRING(amount), "Ak-47: %i", rp_GetClientItem(client, rifle_ak47));
		menu.AddItem("ak47", amount);
	}
	
	if(rp_GetClientItem(client, rifle_aug) >= 1)
	{
		Format(STRING(amount), "Aug: %i", rp_GetClientItem(client, rifle_aug));
		menu.AddItem("aug", amount);
	}
	
	if(rp_GetClientItem(client, rifle_sg553) >= 1)
	{
		Format(STRING(amount), "Sg-553: %i", rp_GetClientItem(client, rifle_sg553));
		menu.AddItem("sg553", amount);
	}
	
	if(rp_GetClientItem(client, rifle_ssg08) >= 1)
	{
		Format(STRING(amount), "Ssg-08: %i", rp_GetClientItem(client, rifle_ssg08));
		menu.AddItem("ssg08", amount);
	}
	
	if(rp_GetClientItem(client, rifle_awp) >= 1)
	{
		Format(STRING(amount), "Awp: %i", rp_GetClientItem(client, rifle_awp));
		menu.AddItem("awp", amount);
	}
	
	if(rp_GetClientItem(client, rifle_scar20) >= 1)
	{
		Format(STRING(amount), "Scar-20: %i", rp_GetClientItem(client, rifle_scar20));
		menu.AddItem("scar20", amount);
	}
	
	if(rp_GetClientItem(client, rifle_g3sg1) >= 1)
	{
		Format(STRING(amount), "G3sg1: %i", rp_GetClientItem(client, rifle_g3sg1));
		menu.AddItem("g3sg1", amount);
	}
	
	if(rp_GetClientItem(client, heavy_nova) >= 1)
	{
		Format(STRING(amount), "Nova: %i", rp_GetClientItem(client, heavy_nova));
		menu.AddItem("nova", amount);
	}
	
	if(rp_GetClientItem(client, heavy_xm1014) >= 1)
	{
		Format(STRING(amount), "Xm-1014: %i", rp_GetClientItem(client, heavy_xm1014));
		menu.AddItem("xm1014", amount);
	}
	
	if(rp_GetClientItem(client, heavy_mag7) >= 1)
	{
		Format(STRING(amount), "Mag7: %i", rp_GetClientItem(client, heavy_mag7));
		menu.AddItem("mag7", amount);
	}
	
	if(rp_GetClientItem(client, heavy_sawedoff) >= 1)
	{
		Format(STRING(amount), "Sawedoff: %i", rp_GetClientItem(client, heavy_sawedoff));
		menu.AddItem("sawedoff", amount);
	}
	
	if(rp_GetClientItem(client, heavy_m249) >= 1)
	{
		Format(STRING(amount), "M249: %i", rp_GetClientItem(client, heavy_m249));
		menu.AddItem("m249", amount);
	}
	
	if(rp_GetClientItem(client, heavy_negev) >= 1)
	{
		Format(STRING(amount), "Negev: %i", rp_GetClientItem(client, heavy_negev));
		menu.AddItem("negev", amount);
	}
	
	if(rp_GetClientItem(client, gear_kevlar) >= 1)
	{
		Format(STRING(amount), "Kevlar: %i", rp_GetClientItem(client, gear_kevlar));
		menu.AddItem("kevlar", amount);
	}
	
	if(rp_GetClientItem(client, gear_helmet) >= 1)
	{
		Format(STRING(amount), "Casque: %i", rp_GetClientItem(client, gear_helmet));
		menu.AddItem("helmet", amount);
	}
	
	if(rp_GetClientItem(client, gear_zeus) >= 1)
	{
		Format(STRING(amount), "Zeus: %i", rp_GetClientItem(client, gear_zeus));
		menu.AddItem("zeus", amount);
	}
	
	if(rp_GetClientItem(client, gear_assaultsuit) >= 1)
	{
		Format(STRING(amount), "Armure lourde: %i", rp_GetClientItem(client, gear_assaultsuit));
		menu.AddItem("assaultsuit", amount);
	}
	
	if(rp_GetClientItem(client, gear_axe) >= 1)
	{
		Format(STRING(amount), "Hache: %i", rp_GetClientItem(client, gear_axe));
		menu.AddItem("axe", amount);
	}
	
	if(rp_GetClientItem(client, gear_hammer) >= 1)
	{
		Format(STRING(amount), "Marteau: %i", rp_GetClientItem(client, gear_hammer));
		menu.AddItem("hammer", amount);
	}
	
	if(rp_GetClientItem(client, gear_wrench) >= 1)
	{
		Format(STRING(amount), "Clé a molette: %i", rp_GetClientItem(client, gear_wrench));
		menu.AddItem("wrench", amount);
	}
	
	if(rp_GetClientItem(client, i_munition) >= 1)
	{
		Format(STRING(amount), "Munitions: %i", rp_GetClientItem(client, i_munition));
		menu.AddItem("munitions", amount);
	}
	
	if(rp_GetClientItem(client, i_sanandreas) >= 1)
	{
		Format(STRING(amount), "San Andreas: %i", rp_GetClientItem(client, i_sanandreas));
		menu.AddItem("sanandreas", amount);
	}
}	
	
public int rp_HandlerMenuInventory(int client, char[] info)
{
	if(StrEqual(info, "p2000") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
		{
			rp_SetClientItem(client, pistol_p2000, rp_GetClientItem(client, pistol_p2000) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, pistol_p2000), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_hkp2000");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un p2000.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un p2000.", client);
		}	
		else
			CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
	}
	else if(StrEqual(info, "usps") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
		{
			rp_SetClientItem(client, pistol_usps, rp_GetClientItem(client, pistol_usps) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, pistol_usps), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_usp_silencer");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un usp.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un usp.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
	}
	else if(StrEqual(info, "glock18") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
		{
			rp_SetClientItem(client, pistol_glock18, rp_GetClientItem(client, pistol_glock18) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, pistol_glock18), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_glock");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un glock-18.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un glock-18.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
	}
	else if(StrEqual(info, "p250") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
		{
			rp_SetClientItem(client, pistol_p250, rp_GetClientItem(client, pistol_p250) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, pistol_p250), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_p250");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un p250.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un p250.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
	}
	else if(StrEqual(info, "fiveseven") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
		{
			rp_SetClientItem(client, pistol_fiveseven, rp_GetClientItem(client, pistol_fiveseven) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, pistol_fiveseven), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_fiveseven");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un five-seven.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un five-seven.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
	}	
	else if(StrEqual(info, "tec9") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
		{
			rp_SetClientItem(client, pistol_tec9, rp_GetClientItem(client, pistol_tec9) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, pistol_tec9), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_tec9");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un tec-9.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un tec-9.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
	}
	else if(StrEqual(info, "cz75") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
		{
			rp_SetClientItem(client, pistol_cz75, rp_GetClientItem(client, pistol_cz75) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, pistol_cz75), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_cz75a");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un cz-75.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un cz-75.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
	}
	else if(StrEqual(info, "dualberettas") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
		{
			rp_SetClientItem(client, pistol_dualberettas, rp_GetClientItem(client, pistol_dualberettas) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, pistol_dualberettas), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_elite");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}des Dual-berettas.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise des Dual-berettas.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
	}
	else if(StrEqual(info, "deagle") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
		{
			rp_SetClientItem(client, pistol_deagle, rp_GetClientItem(client, pistol_deagle) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, pistol_deagle), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_deagle");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un deagle.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un deagle.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
	}
	else if(StrEqual(info, "revolver") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == -1)
		{
			rp_SetClientItem(client, pistol_revolver, rp_GetClientItem(client, pistol_revolver) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, pistol_revolver), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_revolver");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un revolver.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un revolver.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà un pistolet sur vous.", TEAM);
	}
	else if(StrEqual(info, "mp9") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, smg_mp9, rp_GetClientItem(client, smg_mp9) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, smg_mp9), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_mp9");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une mp9.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une mp9.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "mac10") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, smg_mac10, rp_GetClientItem(client, smg_mac10) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, smg_mac10), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_mac10");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une mac-10.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une mac-10.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "ppbizon") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, smg_ppbizon, rp_GetClientItem(client, smg_ppbizon) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, smg_ppbizon), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_bizon");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une mac-10.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une mac-10.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "mp7") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, smg_mp7, rp_GetClientItem(client, smg_mp7) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, smg_mp7), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_mp7");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une mp7.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une mp7.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "ump45") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, smg_ump45, rp_GetClientItem(client, smg_ump45) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, smg_ump45), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_ump45");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une ump45.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une ump45.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "p90") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, smg_p90, rp_GetClientItem(client, smg_p90) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, smg_p90), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_p90");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une p90.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une p90.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "mp5sd") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, smg_mp5sd, rp_GetClientItem(client, smg_mp5sd) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, smg_mp5sd), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_mp5sd");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une mp5-sd.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une mp5-sd.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "famas") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_famas, rp_GetClientItem(client, rifle_famas) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_famas), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_famas");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une famas.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une famas.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "galilar") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_galilar, rp_GetClientItem(client, rifle_galilar) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_galilar), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_galilar");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une galilar.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une galilar.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "m4a4") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_m4a4, rp_GetClientItem(client, rifle_m4a4) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_m4a4), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_m4a1");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une m4a4.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une m4a4.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "m4a1s") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_m4a1s, rp_GetClientItem(client, rifle_m4a1s) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_m4a1s), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_m4a1_silencer");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une m4a1-s.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une m4a1-s.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "ak47") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_ak47, rp_GetClientItem(client, rifle_ak47) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_ak47), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_ak47");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une ak-47.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une ak-47.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "aug") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_aug, rp_GetClientItem(client, rifle_aug) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_aug), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_aug");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une aug.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une aug.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "sg553") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_sg553, rp_GetClientItem(client, rifle_sg553) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_sg553), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_sg553");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une sg553.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une sg553.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "ssg08") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_ssg08, rp_GetClientItem(client, rifle_ssg08) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_ssg08), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_ssg08");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une ssg08.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une ssg08.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "awp") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_awp, rp_GetClientItem(client, rifle_awp) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_awp), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_awp");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une awp.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une awp.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "scar20") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_scar20, rp_GetClientItem(client, rifle_scar20) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_scar20), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_scar20");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une scar-20.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une scar-20.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "g3sg1") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, rifle_g3sg1, rp_GetClientItem(client, rifle_g3sg1) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, rifle_g3sg1), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_g3sg1");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un g3sg1.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un g3sg1.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "nova") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, heavy_nova, rp_GetClientItem(client, heavy_nova) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, heavy_nova), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_nova");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une nova.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une nova.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "xm1014") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, heavy_xm1014, rp_GetClientItem(client, heavy_xm1014) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, heavy_xm1014), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_xm1014");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un xm1014.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un xm1014.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "mag7") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, heavy_mag7, rp_GetClientItem(client, heavy_mag7) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, heavy_mag7), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_mag7");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}un mag7.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un mag7.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "sawedoff") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, heavy_sawedoff, rp_GetClientItem(client, heavy_sawedoff) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, heavy_sawedoff), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_sawedoff");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une sawedoff.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une sawedoff.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "m249") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, heavy_m249, rp_GetClientItem(client, heavy_m249) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, heavy_m249), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_m249");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une m249.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une m249.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "negev") && IsPlayerAlive(client))
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == -1)
		{
			rp_SetClientItem(client, heavy_negev, rp_GetClientItem(client, heavy_negev) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, heavy_negev), steamID[client]);
				
			int wepID = GivePlayerItem(client, "weapon_negev");
			rp_SetClientAmmo(client, wepID, 0, 0);
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une negev.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une negev.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà une rafale sur vous.", TEAM);
	}
	else if(StrEqual(info, "kevlar") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, gear_kevlar, rp_GetClientItem(client, gear_kevlar) - 1);
		UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, gear_kevlar), steamID[client]);
				
		GivePlayerItem(client, "prop_weapon_upgrade_armor_helmet");
				
		CPrintToChat(client, "%s Vous utilisez {lightblue}un kevlar.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise un kevlar.", client);
	}
	else if(StrEqual(info, "helmet") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, gear_helmet, rp_GetClientItem(client, gear_helmet) - 1);
		UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, gear_helmet), steamID[client]);
				
		GivePlayerItem(client, "prop_weapon_upgrade_helmet");
				
		CPrintToChat(client, "%s Vous utilisez {lightblue}un casque.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise un casque.", client);
	}
	else if(StrEqual(info, "zeus") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, gear_zeus, rp_GetClientItem(client, gear_zeus) - 1);
		UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, gear_zeus), steamID[client]);
				
		int wepID = GivePlayerItem(client, "weapon_taser");
		rp_SetClientAmmo(client, wepID, 0, 0);
				
		CPrintToChat(client, "%s Vous utilisez {lightblue}un zeus x27.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise un zeus x27.", client);
	}
	else if(StrEqual(info, "assaultsuit") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, gear_assaultsuit, rp_GetClientItem(client, gear_assaultsuit) - 1);
		UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, gear_assaultsuit), steamID[client]);
				
		GivePlayerItem(client, "prop_weapon_refill_heavyarmor");
				
		CPrintToChat(client, "%s Vous utilisez {lightblue}une armure lourde.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise une armure lourde.", client);
	}
	else if(StrEqual(info, "axe") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, gear_axe, rp_GetClientItem(client, gear_axe) - 1);
		UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, gear_axe), steamID[client]);
				
		int iMelee = GivePlayerItem(client, "weapon_axe");
		EquipPlayerWeapon(client, iMelee);
				
		CPrintToChat(client, "%s Vous utilisez {lightblue}une hache.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise une hache.", client);
	}
	else if(StrEqual(info, "hammer") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, gear_hammer, rp_GetClientItem(client, gear_hammer) - 1);
		UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, gear_hammer), steamID[client]);
		
		int iMelee = GivePlayerItem(client, "weapon_hammer");
		EquipPlayerWeapon(client, iMelee);
				
		CPrintToChat(client, "%s Vous utilisez {lightblue}un marteau.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise un marteau.", client);
	}
	else if(StrEqual(info, "wrench") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, gear_wrench, rp_GetClientItem(client, gear_wrench) - 1);
		UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, gear_wrench), steamID[client]);
		
		int iMelee = GivePlayerItem(client, "weapon_spanner");
		EquipPlayerWeapon(client, iMelee);
				
		CPrintToChat(client, "%s Vous utilisez {lightblue}une clé à molette.", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise une clé à molette.", client);
	}
	else if(StrEqual(info, "munitions") && IsPlayerAlive(client))
	{
		int weapon = Client_GetActiveWeapon(client);
		char weaponName[64];
		Entity_GetClassName(weapon, STRING(weaponName));
		
		if(rp_canSetAmmo(client, weapon))
		{
			rp_SetClientItem(client, i_munition, rp_GetClientItem(client, i_munition) - 1);
			UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, i_munition), steamID[client]);
			
			RemoveEdict(weapon);
					
			int ent = GivePlayerItem(client, weaponName);
			Entity_SetName(ent, weaponName);
			
			CPrintToChat(client, "%s Vous utilisez {lightblue}des munitions.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise des munitions.", client);
		}
		else
			CPrintToChat(client, "%s Les munitions doivent être utilisées sur une arme.", TEAM);			
				
	}
	else if(StrEqual(info, "sanandreas") && IsPlayerAlive(client))
	{
		int weapon = Client_GetActiveWeapon(client);
		
		if(rp_canSetAmmo(client, weapon))
		{		
			int ammo = Weapon_GetPrimaryClip(weapon);
			if( ammo >= 5000 ) 
			{
				CPrintToChat(client, "%s Vous avez déjà 5000 balles.", TEAM);
			}
			else
			{
				rp_SetClientItem(client, i_sanandreas, rp_GetClientItem(client, i_sanandreas) - 1);
				UpdateSQL_Item(g_DB, "rp_armurier", info, rp_GetClientItem(client, i_sanandreas), steamID[client]);
				
				ammo += 1000;
				if( ammo > 5000 )
					ammo = 5000;
				Weapon_SetPrimaryClip(weapon, ammo);
				
				CPrintToChat(client, "%s Votre arme a maintenant %i balles", TEAM, ammo);
				LogToFile(logFile, "Le joueur %N a utilise un san andreas.", client);
			}	
		}
		else
			CPrintToChat(client, "%s Les munitions doivent être utilisées sur une arme.", TEAM);			
				
	}
	
	FakeClientCommand(client, "rp");
}

/***************************************************************************************

								P L U G I N  - N P C

***************************************************************************************/

Menu NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Armurier");
	menu.AddItem("pistols", "Pistolets");
	menu.AddItem("smg", "Mitrailleuses");
	menu.AddItem("rifle", "Fusils d'assaut");
	menu.AddItem("heavy", "Armes lourdes");
	menu.AddItem("gears", "Outils");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "pistols"))
			SellPistols(client, client);	
		else if(StrEqual(info, "smg"))
			SellSmg(client, client);	
		else if(StrEqual(info, "rifle"))
			SellRifle(client, client);	
		else if(StrEqual(info, "heavy"))
			SellHeavy(client, client);	
		else if(StrEqual(info, "gears"))
			SellGears(client, client);	
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public Action rp_MenuVendre(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 6)
	{
		menu.AddItem("pistols", "Pistolets");
		menu.AddItem("smg", "Mitrailleuses");
		menu.AddItem("rifle", "Fusils d'assaut");
		menu.AddItem("heavy", "Armes lourdes");
		menu.AddItem("gears", "Outils");
	}
}	

public int rp_HandleMenuVendre(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "pistols"))
		SellPistols(client, target);	
	else if(StrEqual(info, "smg"))
		SellSmg(client, target);	
	else if(StrEqual(info, "rifle"))
		SellRifle(client, target);	
	else if(StrEqual(info, "heavy"))
		SellHeavy(client, target);
	else if(StrEqual(info, "gears"))
		SellGears(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellPistols(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Pistolets Disponibles");

	prix = rp_GetPrice("p2000");
	Format(STRING(strFormat), "%i|%i|p2000", target, prix);
	Format(STRING(strMenu), "P2000 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("usps");
	Format(STRING(strFormat), "%i|%i|usps", target, prix);
	Format(STRING(strMenu), "Usp-s (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("glock18");
	Format(STRING(strFormat), "%i|%i|glock18", target, prix);
	Format(STRING(strMenu), "Glock-18 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("p250");
	Format(STRING(strFormat), "%i|%i|p250", target, prix);
	Format(STRING(strMenu), "P250 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("fiveseven");
	Format(STRING(strFormat), "%i|%i|fiveseven", target, prix);
	Format(STRING(strMenu), "Five-seven (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("tec9");
	Format(STRING(strFormat), "%i|%i|tec9", target, prix);
	Format(STRING(strMenu), "Tec-9 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("cz75");
	Format(STRING(strFormat), "%i|%i|cz75", target, prix);
	Format(STRING(strMenu), "Cz-75 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("dualberettas");
	Format(STRING(strFormat), "%i|%i|dualberettas", target, prix);
	Format(STRING(strMenu), "Dual Berettas (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("deagle");
	Format(STRING(strFormat), "%i|%i|deagle", target, prix);
	Format(STRING(strMenu), "Deagle (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("revolver");
	Format(STRING(strFormat), "%i|%i|revolver", target, prix);
	Format(STRING(strMenu), "Revolver (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}			

Menu SellSmg(int client, int target)
{
	int prix;
	char strFormat[128], strMenu[128];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Mitrailleuses Disponibles");
	
	prix = rp_GetPrice("mp9");
	Format(STRING(strFormat), "%i|%i|mp9", target, prix);
	Format(STRING(strMenu), "Mp9 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("mac10");
	Format(STRING(strFormat), "%i|%i|mac10", target, prix);
	Format(STRING(strMenu), "Mac-10 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("ppbizon");
	Format(STRING(strFormat), "%i|%i|ppbizon", target, prix);
	Format(STRING(strMenu), "PP-Bizon (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("mp7");
	Format(STRING(strFormat), "%i|%i|mp7", target, prix);
	Format(STRING(strMenu), "Mp7 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("ump45");
	Format(STRING(strFormat), "%i|%i|ump45", target, prix);
	Format(STRING(strMenu), "Ump-45 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("p90");
	Format(STRING(strFormat), "%i|%i|p90", target, prix);
	Format(STRING(strMenu), "P90 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("mp5sd");
	Format(STRING(strFormat), "%i|%i|mp5sd", target, prix);
	Format(STRING(strMenu), "Mp5-sd (%i$)", prix);
	menu.AddItem(strFormat, strMenu);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

Menu SellRifle(int client, int target)
{
	int prix;
	char strFormat[128], strMenu[128];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Fusils d'assaut Disponibles");
	
	prix = rp_GetPrice("famas");
	Format(STRING(strFormat), "%i|%i|famas", target, prix);
	Format(STRING(strMenu), "Famas (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("galilar");
	Format(STRING(strFormat), "%i|%i|galilar", target, prix);
	Format(STRING(strMenu), "Galilar (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("m4a4");
	Format(STRING(strFormat), "%i|%i|m4a4", target, prix);
	Format(STRING(strMenu), "M4a4 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("m4a1s");
	Format(STRING(strFormat), "%i|%i|m4a1s", target, prix);
	Format(STRING(strMenu), "M4a1s (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("ak47");
	Format(STRING(strFormat), "%i|%i|ak47", target, prix);
	Format(STRING(strMenu), "Ak-47 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("aug");
	Format(STRING(strFormat), "%i|%i|aug", target, prix);
	Format(STRING(strMenu), "Aug (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("sg553");
	Format(STRING(strFormat), "%i|%i|sg553", target, prix);
	Format(STRING(strMenu), "Sg-553 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("ssg08");
	Format(STRING(strFormat), "%i|%i|ssg08", target, prix);
	Format(STRING(strMenu), "Ssg-553 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("awp");
	Format(STRING(strFormat), "%i|%i|awp", target, prix);
	Format(STRING(strMenu), "Awp (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("scar20");
	Format(STRING(strFormat), "%i|%i|scar20", target, prix);
	Format(STRING(strMenu), "Scar-20 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("g3sg1");
	Format(STRING(strFormat), "%i|%i|g3sg1", target, prix);
	Format(STRING(strMenu), "G3sg1 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

Menu SellHeavy(int client, int target)
{
	int prix;
	char strFormat[128], strMenu[128];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Fusils d'assaut Disponibles");
	
	prix = rp_GetPrice("nova");
	Format(STRING(strFormat), "%i|%i|nova", target, prix);
	Format(STRING(strMenu), "Nova (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("xm1014");
	Format(STRING(strFormat), "%i|%i|xm1014", target, prix);
	Format(STRING(strMenu), "Xm1014 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("mag7");
	Format(STRING(strFormat), "%i|%i|mag7", target, prix);
	Format(STRING(strMenu), "Mag-7 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("sawedoff");
	Format(STRING(strFormat), "%i|%i|sawedoff", target, prix);
	Format(STRING(strMenu), "Sawedoff (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("m249");
	Format(STRING(strFormat), "%i|%i|m249", target, prix);
	Format(STRING(strMenu), "M249 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("negev");
	Format(STRING(strFormat), "%i|%i|negev", target, prix);
	Format(STRING(strMenu), "Negev (%i$)", prix);
	menu.AddItem(strFormat, strMenu);

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}	

Menu SellGears(int client, int target)
{
	int prix;
	char strFormat[128], strMenu[128];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Outils");
	
	prix = rp_GetPrice("kevlar");
	Format(STRING(strFormat), "%i|%i|kevlar", target, prix);
	Format(STRING(strMenu), "Kevlar (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("helmet");
	Format(STRING(strFormat), "%i|%i|helmet", target, prix);
	Format(STRING(strMenu), "Helmet (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("zeus");
	Format(STRING(strFormat), "%i|%i|zeus", target, prix);
	Format(STRING(strMenu), "Zeus x27 (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("assaultsuit");
	Format(STRING(strFormat), "%i|%i|assaultsuit", target, prix);
	Format(STRING(strMenu), "Armure lourde (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("axe");
	Format(STRING(strFormat), "%i|%i|hache", target, prix);
	Format(STRING(strMenu), "Hache (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("hammer");
	Format(STRING(strFormat), "%i|%i|marteau", target, prix);
	Format(STRING(strMenu), "Marteau (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("wrench");
	Format(STRING(strFormat), "%i|%i|clé à molette", target, prix);
	Format(STRING(strMenu), "Clé à molette (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("munitions");
	Format(STRING(strFormat), "%i|%i|munitions", target, prix);
	Format(STRING(strMenu), "Munitions (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("sanandreas");
	Format(STRING(strFormat), "%i|%i|sanandreas", target, prix);
	Format(STRING(strMenu), "San Andreas (%i$)", prix);
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
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_p2000), steamID[client]);
			}	
			else if(StrEqual(buffer[2], "usps"))
			{
				rp_SetClientItem(client, pistol_usps, rp_GetClientItem(client, pistol_usps) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_usps), steamID[client]);
			}
			else if(StrEqual(buffer[2], "glock18"))
			{
				rp_SetClientItem(client, pistol_glock18, rp_GetClientItem(client, pistol_glock18) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_glock18), steamID[client]);
			}
			else if(StrEqual(buffer[2], "p250"))
			{
				rp_SetClientItem(client, pistol_p250, rp_GetClientItem(client, pistol_p250) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_p250), steamID[client]);
			}
			else if(StrEqual(buffer[2], "fiveseven"))
			{
				rp_SetClientItem(client, pistol_fiveseven, rp_GetClientItem(client, pistol_fiveseven) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_fiveseven), steamID[client]);
			}
			else if(StrEqual(buffer[2], "tec9"))
			{
				rp_SetClientItem(client, pistol_tec9, rp_GetClientItem(client, pistol_tec9) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_tec9), steamID[client]);
			}
			else if(StrEqual(buffer[2], "cz75"))
			{
				rp_SetClientItem(client, pistol_cz75, rp_GetClientItem(client, pistol_cz75) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_cz75), steamID[client]);
			}
			else if(StrEqual(buffer[2], "dualberettas"))
			{
				rp_SetClientItem(client, pistol_dualberettas, rp_GetClientItem(client, pistol_dualberettas) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_dualberettas), steamID[client]);
			}
			else if(StrEqual(buffer[2], "deagle"))
			{
				rp_SetClientItem(client, pistol_deagle, rp_GetClientItem(client, pistol_deagle) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_deagle), steamID[client]);
			}
			else if(StrEqual(buffer[2], "revolver"))
			{
				rp_SetClientItem(client, pistol_revolver, rp_GetClientItem(client, pistol_revolver) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, pistol_revolver), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mp9"))
			{
				rp_SetClientItem(client, smg_mp9, rp_GetClientItem(client, smg_mp9) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_mp9), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mac10"))
			{
				rp_SetClientItem(client, smg_mac10, rp_GetClientItem(client, smg_mac10) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_mac10), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ppbizon"))
			{
				rp_SetClientItem(client, smg_ppbizon, rp_GetClientItem(client, smg_ppbizon) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_ppbizon), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mp7"))
			{
				rp_SetClientItem(client, smg_mp7, rp_GetClientItem(client, smg_mp7) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_mp7), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ump45"))
			{
				rp_SetClientItem(client, smg_ump45, rp_GetClientItem(client, smg_ump45) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_ump45), steamID[client]);
			}
			else if(StrEqual(buffer[2], "p90"))
			{
				rp_SetClientItem(client, smg_p90, rp_GetClientItem(client, smg_p90) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_p90), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mp5sd"))
			{
				rp_SetClientItem(client, smg_mp5sd, rp_GetClientItem(client, smg_mp5sd) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, smg_mp5sd), steamID[client]);
			}
			else if(StrEqual(buffer[2], "famas"))
			{
				rp_SetClientItem(client, rifle_famas, rp_GetClientItem(client, rifle_famas) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_famas), steamID[client]);
			}
			else if(StrEqual(buffer[2], "galilar"))
			{
				rp_SetClientItem(client, rifle_galilar, rp_GetClientItem(client, rifle_galilar) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_galilar), steamID[client]);
			}
			else if(StrEqual(buffer[2], "m4a4"))
			{
				rp_SetClientItem(client, rifle_m4a4, rp_GetClientItem(client, rifle_m4a4) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_m4a4), steamID[client]);
			}
			else if(StrEqual(buffer[2], "m4a1s"))
			{
				rp_SetClientItem(client, rifle_m4a1s, rp_GetClientItem(client, rifle_m4a1s) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_m4a1s), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ak47"))
			{
				rp_SetClientItem(client, rifle_ak47, rp_GetClientItem(client, rifle_ak47) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_ak47), steamID[client]);
			}
			else if(StrEqual(buffer[2], "aug"))
			{
				rp_SetClientItem(client, rifle_aug, rp_GetClientItem(client, rifle_aug) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_aug), steamID[client]);
			}
			else if(StrEqual(buffer[2], "sg553"))
			{
				rp_SetClientItem(client, rifle_sg553, rp_GetClientItem(client, rifle_sg553) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_sg553), steamID[client]);
			}
			else if(StrEqual(buffer[2], "ssg08"))
			{
				rp_SetClientItem(client, rifle_ssg08, rp_GetClientItem(client, rifle_ssg08) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_ssg08), steamID[client]);
			}
			else if(StrEqual(buffer[2], "awp"))
			{
				rp_SetClientItem(client, rifle_awp, rp_GetClientItem(client, rifle_awp) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_awp), steamID[client]);
			}
			else if(StrEqual(buffer[2], "scar20"))
			{
				rp_SetClientItem(client, rifle_scar20, rp_GetClientItem(client, rifle_scar20) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_scar20), steamID[client]);
			}
			else if(StrEqual(buffer[2], "g3sg1"))
			{
				rp_SetClientItem(client, rifle_g3sg1, rp_GetClientItem(client, rifle_g3sg1) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, rifle_g3sg1), steamID[client]);
			}
			else if(StrEqual(buffer[2], "nova"))
			{
				rp_SetClientItem(client, heavy_nova, rp_GetClientItem(client, heavy_nova) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_nova), steamID[client]);
			}
			else if(StrEqual(buffer[2], "xm1014"))
			{
				rp_SetClientItem(client, heavy_xm1014, rp_GetClientItem(client, heavy_xm1014) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_xm1014), steamID[client]);
			}
			else if(StrEqual(buffer[2], "mag7"))
			{
				rp_SetClientItem(client, heavy_mag7, rp_GetClientItem(client, heavy_mag7) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_mag7), steamID[client]);
			}
			else if(StrEqual(buffer[2], "sawedoff"))
			{
				rp_SetClientItem(client, heavy_sawedoff, rp_GetClientItem(client, heavy_sawedoff) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_sawedoff), steamID[client]);
			}
			else if(StrEqual(buffer[2], "m249"))
			{
				rp_SetClientItem(client, heavy_m249, rp_GetClientItem(client, heavy_m249) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_m249), steamID[client]);
			}
			else if(StrEqual(buffer[2], "negev"))
			{
				rp_SetClientItem(client, heavy_negev, rp_GetClientItem(client, heavy_negev) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, heavy_negev), steamID[client]);
			}
			else if(StrEqual(buffer[2], "kevlar"))
			{
				rp_SetClientItem(client, gear_kevlar, rp_GetClientItem(client, gear_kevlar) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, gear_kevlar), steamID[client]);
			}
			else if(StrEqual(buffer[2], "helmet"))
			{
				rp_SetClientItem(client, gear_helmet, rp_GetClientItem(client, gear_helmet) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, gear_helmet), steamID[client]);
			}
			else if(StrEqual(buffer[2], "zeus"))
			{
				rp_SetClientItem(client, gear_zeus, rp_GetClientItem(client, gear_zeus) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, gear_zeus), steamID[client]);
			}
			else if(StrEqual(buffer[2], "assaultsuit"))
			{
				rp_SetClientItem(client, gear_assaultsuit, rp_GetClientItem(client, gear_assaultsuit) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, gear_assaultsuit), steamID[client]);
			}
			else if(StrEqual(buffer[2], "hache"))
			{
				rp_SetClientItem(client, gear_axe, rp_GetClientItem(client, gear_axe) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", "axe", rp_GetClientItem(client, gear_axe), steamID[client]);
			}
			else if(StrEqual(buffer[2], "marteau"))
			{
				rp_SetClientItem(client, gear_hammer, rp_GetClientItem(client, gear_hammer) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", "hammer", rp_GetClientItem(client, gear_hammer), steamID[client]);
			}
			else if(StrEqual(buffer[2], "clé à molette"))
			{
				rp_SetClientItem(client, gear_wrench, rp_GetClientItem(client, gear_wrench) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", "wrench", rp_GetClientItem(client, gear_wrench), steamID[client]);
			}
			else if(StrEqual(buffer[2], "munitions"))
			{
				rp_SetClientItem(client, i_munition, rp_GetClientItem(client, i_munition) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, i_munition), steamID[client]);
			}
			else if(StrEqual(buffer[2], "sanandreas"))
			{
				rp_SetClientItem(client, i_sanandreas, rp_GetClientItem(client, i_sanandreas) + quantity);	
				UpdateSQL_Item(g_DB, "rp_armurier", buffer[2], rp_GetClientItem(client, i_sanandreas), steamID[client]);
			}	
		}
		else
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