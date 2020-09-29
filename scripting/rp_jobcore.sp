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
#include <smlib>
#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <roleplay>
#include <multicolors>
#include <emitsoundany>

/***************************************************************************************

							P L U G I N  -  D E F I N E S

***************************************************************************************/
#define IMPOT_CAPITAL 100
#define IMPOT 50

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];
	
int jobPerqui;
int timePerqui;

char note[MAXJOBS + 1][PLATFORM_MAX_PATH];
int capital[MAXJOBS + 1];
bool canPerquisition[MAXJOBS + 1];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job Core", 
	author = "Benito", 
	description = "Système de job.", 
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
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_jobcore.log");
	
	RegConsoleCmd("job", Cmd_job);
	
	LoadOrSaveCapital(true);
}		

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_jobs` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `jobid` int(10) NOT NULL, \
	  `gradeid` int(10) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
	
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_stocks` ( \
	  `Id` int(20) NOT NULL AUTO_INCREMENT, \
	  `cocaine` int(100) COLLATE utf8_bin NOT NULL, \
	  `heroine` int(100) COLLATE utf8_bin NOT NULL, \
	  `ecstasy` int(100) COLLATE utf8_bin NOT NULL, \
	  `amphetamine` int(100) COLLATE utf8_bin NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	CreateNative("rp_GetJobCapital", Native_GetJobCapital);
	CreateNative("rp_SetJobCapital", Native_SetJobCapital);
	
	CreateNative("rp_GetJobPerqui", Native_GetJobPerqui);
	CreateNative("rp_SetJobPerqui", Native_SetJobPerqui);
	
	CreateNative("rp_CanPerquisition", Native_CanPerquisition);
	CreateNative("rp_SetPerquisitionStat", Native_SetPerquisition);
	
	CreateNative("rp_GetJobNote", Native_GetJobNoteNtv);
	CreateNative("rp_SetJobNote", Native_SetJobNoteNtv);
	
	CreateNative("rp_SetPerquisitionTime", Native_SetPerquisitionTime);
	CreateNative("rp_GetPerquisitionTime", Native_GetPerquisitionTime);
	
	CreateNative("rp_GiveSalaire", Native_GiveSalaire);
}

public int Native_GetJobNoteNtv(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	int maxlen = GetNativeCell(3) + 1;
		
	SetNativeString(2, note[job], maxlen);
}

public int Native_SetJobNoteNtv(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	int maxlen = GetNativeCell(3) + 1;
	
	GetNativeString(2, note[job], maxlen);
}

public int Native_GetJobCapital(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	
	return capital[job];
}

public int Native_SetJobCapital(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	int value = GetNativeCell(2);
	
	return capital[job] = value;
}

public int Native_GetJobPerqui(Handle plugin, int numParams) {
	return jobPerqui;
}

public int Native_SetJobPerqui(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	
	return jobPerqui = job;
}

public int Native_CanPerquisition(Handle plugin, int numParams) 
{
	int jobID = GetNativeCell(1);
	
	return canPerquisition[jobID];
}

public int Native_SetPerquisition(Handle plugin, int numParams) 
{
	int jobID = GetNativeCell(1);
	bool value = view_as<bool>(GetNativeCell(2));
	
	return canPerquisition[jobID] = value;
}

public int Native_GiveSalaire(Handle plugin, int numParams) 
{
	GiveSalary();
}

public int Native_SetPerquisitionTime(Handle plugin, int numParams) 
{
	int delay = GetNativeCell(1);
	
	return timePerqui = delay;
}

public int Native_GetPerquisitionTime(Handle plugin, int numParams) 
{
	return timePerqui;
}

public void OnMapStart()
{
	GetNote();
	
	for (int i = 2; i <= MAXJOBS; i++)
		canPerquisition[i] = true;
		
}	

void GetNote()
{
	for(int i = 1; i <= GetMaxJobs(); i++)
	{
		GetJobNote(i, note[i], sizeof(note[]));
	}
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}	

public void OnPluginEnd()
{
	LoadOrSaveCapital(false);
}

public void OnClientDisconnect(int client)
{
	UpdateSQL(rp_GetDatabase(), "UPDATE `rp_jobs` SET `jobid` = '%i', `gradeid` = '%i' WHERE `steamid` = '%s';", rp_GetClientInt(client, i_Job), rp_GetClientInt(client, i_Grade), steamID[client]);
}	

public void OnClientPostAdminCheck(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(rp_GetDatabase(), playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_jobs` (`Id`, `steamid`, `playername`, `jobid`, `gradeid`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadQuery(client);
}

public void LoadQuery(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_jobs WHERE steamid = '%s'", steamID[client]);
	PrintToServer(buffer);
	rp_GetDatabase().Query(SQLCALLBACK, buffer, GetClientUserId(client));
}

public void SQLCALLBACK(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_Job, SQL_FetchIntByName(Results, "jobid"));
		if(rp_GetClientInt(client, i_Job) == -1)
			rp_SetClientInt(client, i_Job, 0);			
		
		rp_SetClientInt(client, i_Grade, SQL_FetchIntByName(Results, "gradeid"));
		if(rp_GetClientInt(client, i_Grade) == -1)
			rp_SetClientInt(client, i_Grade, 0);	
		
		LoadSalaire(client);
	}
}

stock void LoadOrSaveCapital(bool load = true)
{
	KeyValues kv = new KeyValues("Jobs");
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
		
	for (int i = 0; i <= MAXJOBS; i++)
	{	
		char jobNum[10];
		IntToString(i, STRING(jobNum));
		
		if(kv.JumpToKey(jobNum))
		{	
			if(load)
			{
				capital[i] = kv.GetNum("capital");		
				kv.GoBack();
			}
			else
			{
				kv.SetNum("capital", capital[i]);	
				kv.Rewind();
				kv.ExportToFile(sPath);			
			}	
		}
	}	

	kv.Rewind();
	delete kv;
} 	

void GiveSalary()
{
	for(int i = 1; i <= GetMaxJobs(); i++)
	{
		capital[i] -= IMPOT_CAPITAL;
		capital[5] += IMPOT_CAPITAL;
	}
	
	int juge;
	LoopClients(i)
	{
		if(!rp_GetClientBool(i, b_isAfk))
		{
			if(rp_GetClientInt(i, i_Job) == 7)
				juge++;
			
			if(rp_GetClientInt(i, i_Grade) <= 2)
				CPrintToChat(i, "%s La mairie a prélevée {lightred}80${default} d'impôt sur votre capital.", TEAM);

			if(rp_GetClientInt(i, i_VipTime) >= 1)
			{
				CPrintToChat(i, "%s Vous avez reçu une prime de {green}100${default} grâce à votre statut de {yellow}VIP{default}.", TEAM);
				capital[5] -= 100;
				rp_SetClientInt(i, i_Money, rp_GetClientInt(i, i_Money) + 100);
			}
			
			if(rp_GetClientInt(i, i_timeJail) == 0)
			{
				if(rp_GetClientInt(i, i_AddToPay) >= 1)
				{
					CPrintToChat(i, "%s Vous avez reçu votre prime de {green}%s${default}.", TEAM, rp_GetClientInt(i, i_AddToPay));
					capital[rp_GetClientInt(i, i_Job)] -= rp_GetClientInt(i, i_AddToPay);
					rp_SetClientInt(i, i_Money, rp_GetClientInt(i, i_Money) + rp_GetClientInt(i, i_AddToPay));
					rp_SetClientInt(i, i_AddToPay, 0);
				}
				
				if(rp_GetClientInt(i, i_Job) == 0)
				{
					rp_SetClientInt(i, i_Money, rp_GetClientInt(i, i_Money) + rp_GetClientInt(i, i_Salaire));
					CPrintToChat(i, "%s Vous avez reçu votre allocation chômage de {green}%i${default}.", TEAM, rp_GetClientInt(i, i_Salaire));
				}
				else if(rp_GetClientInt(i, i_Job) != 0)
				{
					if(rp_GetJobCapital(rp_GetClientInt(i, i_Job)) >= rp_GetClientInt(i, i_Salaire))
					{
						if(rp_GetClientInt(i, i_Salaire) > 0)
						{
							CPrintToChat(i, "%s Vous avez reçu votre salaire net de {green}%i${default} ({lightred}-%i${default} impôt).", TEAM, rp_GetClientInt(i, i_Salaire), IMPOT);
							
							capital[5] += IMPOT;
							
							if(rp_GetClientBool(i, b_asRib))
								rp_SetClientInt(i, i_Bank, rp_GetClientInt(i, i_Salaire) - IMPOT);
							else
								rp_SetClientInt(i, i_Money, rp_GetClientInt(i, i_Salaire) - IMPOT);
							
							EmitCashSound(i, rp_GetClientInt(i, i_Salaire) - IMPOT);
							capital[rp_GetClientInt(i, i_Job)] -= rp_GetClientInt(i, i_Salaire);
							LoadOrSaveCapital(false);
						}
						else if(rp_GetClientInt(i, i_Grade) != 1)
							CPrintToChat(i, "%s Votre patron vous a refusé votre salaire, aucun impôts vous seront prélevés.", TEAM);
						else
						CPrintToChat(i, "%s {lightred}Vous avez choisi de ne pas toucher votre salaire{default}.", TEAM);
					}
					else if(rp_GetClientInt(i, i_Grade) != 1)
						CPrintToChat(i, "%s {lightred}Votre patron n'a pas les moyens de vous payer{default}.", TEAM);
				}
			}
			else
				CPrintToChat(i, "%s {lightred}Vous n'avez pas reçu votre salaire car vous êtes en prison{default}.", TEAM);
		}
		else if(rp_GetClientBool(i, b_isAfk))
			CPrintToChat(i, "%s Vous ne recevez pas votre paye étant {purple}inactif{default}.", TEAM);
	}
	
	if(juge > 1)
	{
		capital[5] -= 1000;
		capital[7] += 1000;
	}
}

public Action Cmd_job(int client, int args) 
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu jobmenu = new Menu(MenuJobs);
	jobmenu.SetTitle("Liste des jobs disponibles\n ");
	jobmenu.AddItem("-1", "Tout afficher");
	
	char tmp[12], tmp2[64];
	bool bJob[MAXJOBS];

	LoopClients(i)
	{
		if(!IsClientValid(i))
			continue;
		if(rp_GetClientInt(i, i_Job) == 0)
			continue;
		if(i == client)
			continue;

		int job = rp_GetClientInt(i, i_Job);

		if( job == 1 )
			continue;

		bJob[job] = true;
	}

	for(int i = 1; i < MAXJOBS; i++) 
	{
		if( bJob[i] == false )
			continue;
		Format(STRING(tmp), "%d", i);
		
		GetJobName(i, STRING(tmp2));
		jobmenu.AddItem(tmp, tmp2);
	}

	jobmenu.ExitButton = true;
	jobmenu.Display(client, 60);
	return Plugin_Handled;
}

public int MenuJobs(Menu p_hItemMenu, MenuAction action, int client, int param) 
{
	if (action == MenuAction_Select) 
	{
		char info[8];
		if (p_hItemMenu.GetItem(param, STRING(info)))
		{
			rp_SetClientBool(client, b_menuOpen, true);
			
			Menu menu = new Menu(MenuJobs2);
			menu.SetTitle("Liste des employés connectés\n ");
			int jobid = StringToInt(info);
			int amount = 0;
			char tmp[128], tmp2[128];

			for(int i=1; i<MAXPLAYERS+1;i++)
			{
				if(!IsClientValid(i))
					continue;

				/*if(jobid == -2 && rp_GetClientInt(i, i_Avocat) <= 0)
					continue;*/

				if(jobid >= 0 && (i == client || rp_GetClientInt(i, i_Job) != jobid))
					continue;

				Format(STRING(tmp2), "%i", i);
				int ijob = rp_GetClientInt(i, i_Job) == 1 && GetClientTeam(i) == 2 ? 0 : rp_GetClientInt(i, i_Job);
				GetJobName(ijob, STRING(tmp));

				if(rp_GetClientBool(i, b_isAfk))
					Format(STRING(tmp), "[AFK] %N - %s", i, tmp);
				else if(rp_GetClientInt(i, i_timeJail) > 0)
					Format(STRING(tmp), "[JAIL] %N - %s", i, tmp);
				else if(rp_GetClientInt(i, i_ByteZone) == 777)
					Format(STRING(tmp), "[EVENT] %N - %s", i, tmp);
				else
					Format(STRING(tmp), "%N - %s", i, tmp);

				/*if(jobid == -2)
				{
					Format(STRING(tmp), "%s (%d$)", tmp, rp_GetClientInt(i, i_Avocat));
				}*/
					
				menu.AddItem(tmp2, tmp);
				amount++;
			}

			if( amount == 0 ) 
			{
				delete menu;
			}
			else 
			{
				menu.ExitButton = true;
				menu.Display(client, 60);
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete p_hItemMenu;
}

public int MenuJobs2(Menu p_hItemMenu, MenuAction action, int client, int param) 
{
	if (action == MenuAction_Select) 
	{
		char info[8];
		if (p_hItemMenu.GetItem(param, STRING(info)))
		{
			rp_SetClientBool(client, b_menuOpen, true);
			
			Menu menu = new Menu(MenuJobs3);
			menu.SetTitle("Que voulez vous lui demander ?\n ");
			int target = StringToInt(info);
			int jobid = rp_GetClientInt(target, i_Job);
			int amount = 0;
			char tmp[128], tmp2[128];

			if(rp_GetClientInt(target, i_Job) != 0)
			{
				Format(STRING(tmp2), "%i_-1", target);
				menu.AddItem(tmp2, "Demander à être recruté");
				amount++;
			}
			if(jobid == 2)
			{
				Format(STRING(tmp2), "%i_-2", target);
				menu.AddItem(tmp2, "Demander pour un crochetage de porte");
				amount++;
			}
			else if(jobid == 6)
			{
				Format(STRING(tmp2), "%i_-3", target);
				menu.AddItem(tmp2, "Acheter / Vendre une arme");
				amount++;
			}
			else if(jobid == 7) 
			{
				Format(STRING(tmp2), "%i_-4", target);
				menu.AddItem(tmp2, "Demander pour une audience");
				amount++;
			}
			else if(jobid == 8) 
			{
				Format(STRING(tmp2), "%i_-6", target);
				menu.AddItem(tmp2, "Demander un Appartement");
				amount++;
			}
			else
			{
				for(int i = 1; i < MAXITEMS; i++)
				{
					if(rp_GetClientItem(target, i))
					{
						rp_GetItemData(i, item_type_job_id, STRING(tmp));
						if(StringToInt(tmp) != jobid || StringToInt(tmp)==0)
							continue;
	
						rp_GetItemData(i, item_type_name, STRING(tmp));
						Format(STRING(tmp2), "%i_%i", target, i);
						menu.AddItem(tmp2, tmp);
						amount++;
					}	
				}
			}

			if( amount == 0 ) 
			{
				delete menu;
			}
			else 
			{
				menu.ExitButton = true;
				menu.Display(client, 60);
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete p_hItemMenu;
}

public int MenuJobs3(Menu p_hItemMenu, MenuAction action, int client, int param) 
{
	if (action == MenuAction_Select) 
	{
		char info[16];
		if (p_hItemMenu.GetItem(param, STRING(info)))
		{
			rp_SetClientBool(client, b_menuOpen, true);			
			char data[2][32], tmp[128];
			ExplodeString(info, "_", data, sizeof(data), sizeof(data[]));
			int target = StringToInt(data[0]);
			int item_id = StringToInt(data[1]);
			
			/*if( rp_ClientFloodTriggered(client, target, fd_job) ) 
			{
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez appeler %N, pour le moment.", target);
				return;
			}
			rp_ClientFloodIncrement(client, target, fd_job, 10.0);*/
			
			char zoneName[64];
			rp_GetClientString(client, sz_Zone, STRING(zoneName));
			switch(item_id){
				case -1: CPrintToChat(target, "%s Le joueur %N aimerait être recruté, il est actuellement: %s", TEAM, client, zoneName);
				case -2: CPrintToChat(target, "%s Le joueur %N a besoin d'un crochetage de porte, il est actuellement: %s", TEAM, client, zoneName);
				case -3: CPrintToChat(target, "%s Le joueur %N aimerait acheter ou vendre une arme, il est actuellement: %s", TEAM, client, zoneName);
				case -4: {
					CPrintToChat(target, "%s Le joueur %N a besoin d'un juge, il est actuellement: %s", TEAM, client, zoneName);
					LogToGame("[VRH-RP] [CALL] %L a demandé les services de juge de %L", client, target);
				}
				case -5: CPrintToChat(target, "%s Le joueur %N a besoin d'un avocat, il est actuellement: %s", TEAM, client, zoneName);
				case -6: CPrintToChat(target, "%s Le joueur %N souhaiterait acheter un appartement, merci de le contacter pour plus de renseignement. Il est actuellement: %s", TEAM, client, zoneName);
				default: {
					rp_GetItemData(item_id, item_type_name, tmp, sizeof(tmp));
					CPrintToChat(target, "%s Le joueur %N a besoin de {lime}%s{default}, il est actuellement: %s", TEAM, client, tmp, zoneName);
					LogToGame("[VRH-RP] [CALL] %L a demandé %s à %L", client, tmp, target);
				}
			}
			CPrintToChat(client, "%s La demande à été envoyée à la personne.", TEAM);
			ClientCommand(target, "play buttons/blip1.wav");
			rp_Effect_BeamBox(target, client, 122, 122, 0);
			DataPack dp;
			CreateDataTimer(1.0, ClientTargetTracer, dp, TIMER_DATA_HNDL_CLOSE|TIMER_REPEAT);
			dp.WriteCell(0);
			dp.WriteCell(client);
			dp.WriteCell(target);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete p_hItemMenu;
}

public Action ClientTargetTracer(Handle timer, DataPack dp) 
{
	dp.Reset();
	int count = dp.ReadCell();
	int client = dp.ReadCell();
	int target = dp.ReadCell();	
	
	if(!IsClientValid(client) || !IsClientValid(target)) 
	{
		return Plugin_Stop;
	}
	
	rp_Effect_BeamBox(target, client, 122, 122, 0);
	
	if( count >= 5 ){
		return Plugin_Stop;
	}
	
	dp.Reset();
	dp.WriteCell(count + 1);
	
	return Plugin_Continue;
}

public void OnGameFrame()
{
	LoopClients(client)
	{
		if(jobPerqui != 0 && rp_GetClientInt(client, i_Job) == 1)
		{
			if(jobPerqui == 2 && rp_GetClientInt(client, i_ByteZone) == 2
			|| jobPerqui == 3 && rp_GetClientInt(client, i_ByteZone) == 3
			|| jobPerqui == 4 && rp_GetClientInt(client, i_ByteZone) == 4
			|| jobPerqui == 5 && rp_GetClientInt(client, i_ByteZone) == 5
			|| jobPerqui == 6 && rp_GetClientInt(client, i_ByteZone) == 6
			|| jobPerqui == 7 && rp_GetClientInt(client, i_ByteZone) == 7
			|| jobPerqui == 8 && rp_GetClientInt(client, i_ByteZone) == 8
			|| jobPerqui == 9 && rp_GetClientInt(client, i_ByteZone) == 9
			|| jobPerqui == 10 && rp_GetClientInt(client, i_ByteZone) == 10
			|| jobPerqui == 11 && rp_GetClientInt(client, i_ByteZone) == 11
			|| jobPerqui == 12 && rp_GetClientInt(client, i_ByteZone) == 12
			|| jobPerqui == 13 && rp_GetClientInt(client, i_ByteZone) == 13
			|| jobPerqui == 14 && rp_GetClientInt(client, i_ByteZone) == 14
			|| jobPerqui == 15 && rp_GetClientInt(client, i_ByteZone) == 15
			|| jobPerqui == 16 && rp_GetClientInt(client, i_ByteZone) == 16
			|| jobPerqui == 17 && rp_GetClientInt(client, i_ByteZone) == 17
			|| jobPerqui == 18 && rp_GetClientInt(client, i_ByteZone) == 18
			|| jobPerqui == 19 && rp_GetClientInt(client, i_ByteZone) == 19
			|| jobPerqui == 20 && rp_GetClientInt(client, i_ByteZone) == 20)
			{
				char strTime[32];
				StringTime(timePerqui, STRING(strTime));
				PrintHintText(client, "Temps restant :\n%s", strTime);
			}
		}
	}	
}		