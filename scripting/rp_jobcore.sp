/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://vr-hosting.fr- benitalpa1020@gmail.com
*/

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							C O M P I L E  -  O P T I O N S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#pragma semicolon 1
#pragma newdecls required

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N C L U D E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#include <smlib>
#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <roleplay>
#include <multicolors>
#include <emitsoundany>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  D E F I N E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#define IMPOT_CAPITAL 100
#define IMPOT 50

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
Database g_DB;

char 
	dbconfig[] = "roleplay",
	steamID[MAXPLAYERS + 1][32],
	enquete[10][MAXPLAYERS+1][64],
	note[MAXJOBS + 1][PLATFORM_MAX_PATH],
	logFile[PLATFORM_MAX_PATH];
	
int capital[MAXJOBS + 1];
int jobPerqui;
bool canPerquisition[MAXJOBS + 1];

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Job Core", 
	author = "Benito", 
	description = "Système de job.", 
	version = VERSION, 
	url = URL
};

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  E V E N T S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_jobcore.log");
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();
}	

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("%T: %s", "DatabaseError", LANG_SERVER, error);
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
		
		char buffer[4096];
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_jobs` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `jobid` int(10) NOT NULL, \
		  `gradeid` int(10) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	CreateNative("rp_GetJobCapital", GetJobCapital);
	CreateNative("rp_SetJobCapital", SetJobCapital);
	
	CreateNative("rp_GetJobPerqui", GetJobPerqui);
	CreateNative("rp_SetJobPerqui", SetJobPerqui);
	
	CreateNative("rp_GetClientEnquete", GetClientEnquete);
	CreateNative("rp_SetClientEnquete", SetClientEnquete);
	
	CreateNative("rp_CanPerquisition", CanPerquisition);
	
	CreateNative("rp_GetJobNote", GetJobNoteNtv);
	CreateNative("rp_SetJobNote", SetJobNoteNtv);
}

public int GetJobNoteNtv(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	int maxlen = GetNativeCell(3) + 1;
		
	SetNativeString(2, note[job], maxlen);
}

public int SetJobNoteNtv(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	int maxlen = GetNativeCell(3) + 1;
	
	GetNativeString(2, note[job], maxlen);
}

public int GetJobCapital(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	
	return capital[job];
}

public int SetJobCapital(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	int value = GetNativeCell(2);
	
	return capital[job] = value;
}

public int GetJobPerqui(Handle plugin, int numParams) {
	return jobPerqui;
}

public int SetJobPerqui(Handle plugin, int numParams) {
	int job = GetNativeCell(1);
	
	return jobPerqui = job;
}

public int GetClientEnquete(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int id = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
	
	if(!IsClientValid(client))
		return -1;
		
	SetNativeString(3, enquete[id][client], maxlen);
		
	return -1;
}

public int SetClientEnquete(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int id = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
	
	if(!IsClientValid(client))
		return -1;
			
	GetNativeString(3, enquete[id][client], maxlen);
	return -1;
}

public int CanPerquisition(Handle plugin, int numParams) 
{
	int jobID = GetNativeCell(1);
	
	if (canPerquisition[jobID])
		return true;
	else
		return false;
}

public void OnMapStart()
{
	GetNote();
}	

void GetNote()
{
	for(int i = 1; i <= GetMaxJobs(); i++)
	{
		GetJobNote(i, note[i], sizeof(note[]));
	}
}

public void OnClientPutInServer(int client) {	
	CreateTimer(1800.0, GiveSalary, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnMapEnd()
{
	for(int i = 1; i <= GetMaxJobs(); i++)
		LoadAndSaveCapital(i);
}		

public void OnClientPostAdminCheck(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_jobs` (`Id`, `steamid`, `playername`, `jobid`, `gradeid`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	for(int i = 1; i <= GetMaxJobs(); i++)
		LoadAndSaveCapital(i);
}

stock void LoadAndSaveCapital(int jobID, bool load = true)
{
	KeyValues kv = new KeyValues("Jobs");
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/jobs.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/jobs.cfg : NOT FOUND");
	}	
	
	char jobString[32];
	IntToString(jobID, STRING(jobString));
	kv.JumpToKey(jobString);
	
	kv.JumpToKey("capital");	
	
	if(load)
	{
		capital[jobID] = kv.GetNum("total");		
		
		kv.Rewind();
		delete kv;
	}
	else
	{
		kv.SetNum("total", capital[jobID]);		
		
		kv.Rewind();
		delete kv;
	}	
}

public void SQLLoadJobsQueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientInt(client, i_Job, SQL_FetchIntByName(Results, "jobid"));		
		rp_SetClientInt(client, i_Grade, SQL_FetchIntByName(Results, "gradeid"));
		LoadSalaire(client);
	}
} 	

public Action GiveSalary(Handle timer)
{
	for(int i = 1; i <= GetMaxJobs(); i++)
	{
		capital[i] -= IMPOT_CAPITAL;
		capital[5] += IMPOT_CAPITAL;
	}
	
	int juge;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			char maladie[64];
			rp_GetClientString(i, sz_Maladie, STRING(maladie));
			
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
				
				// Phase des cancers
				if(StrContains(maladie, "cancer") != -1)
				{
					if(StrEqual(maladie, "cancer1"))
						rp_SetClientString(i, sz_Maladie, "cancer2", 64);
					else if(StrEqual(maladie, "cancer2"))
						rp_SetClientString(i, sz_Maladie, "cancer3", 64);
					else if(StrEqual(maladie, "cancer3"))
						rp_SetClientString(i, sz_Maladie, "cancerterminal", 64);
				}
				if(rp_GetClientInt(i, i_timeJail) == 0)
				{
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
	}
	
	if(juge > 1)
	{
		capital[5] -= 1000;
		capital[7] += 1000;
	}
}