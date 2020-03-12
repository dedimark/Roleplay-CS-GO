#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <roleplay>

#define NAME "{yellow}[{green}Roleplay{yellow}]{default}"

#pragma newdecls required

enum struct Roleplay {
	bool canBraquage;
	bool canHoldup;
	bool canVolArme;
	bool canVolArgent;
	bool canHack;
}

Roleplay rp;

char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];	

Database g_DB;
char dbconfig[] = "roleplay";

public Plugin myinfo = 
{
	name = "[Roleplay] Braquages, Holdup, Hack, Vol...",
	author = "Benito",
	description = "Système de contrebandit",
	version = "1.0",
	url = "www.revolution-asso.eu"
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/rp_bandit.log");
		
		RegConsoleCmd("volargent", Cmd_VolArgent);
		RegConsoleCmd("volarme", Cmd_VolArme);
		RegConsoleCmd("holdup", Cmd_Holdup);
		RegConsoleCmd("hack", Cmd_Hack);e
		RegConsoleCmd("braquage", Cmd_Braquage);
		
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
	}
}

public void OnMapStart()
{
	rp.canVolArgent = true;
	rp.canVolArme = true;
	rp.canHack = true;
	rp.canHoldup = true;
	rp.canBraquage = true;
}	

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public Action Cmd_VolArgent(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	
	if(rp.canVolArgent)
	{
		int target = GetAimEnt(client, false);
		if(IsValidEntity(target))
		{
			int reward = GetRandomInt(100, 2500);
			
			if(rp_GetClientInt(target, i_Money) > reward)
			{
				rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - reward);
				rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + reward);
				rp_SetClientInt(client, i_LastVolAmount, reward);
				
				CPrintToChat(client, "%s Vous avez volé %i$ à %d.", NAME, reward, target);
				CPrintToChat(target, "%s Un voleur vous a volé %i$", NAME, reward);
					
				Insert_rp_sell(g_DB, rp_GetClientInt(client, i_Job), 0, "Vol", reward, steamID[client]);
				
				rp_SetClientInt(client, i_LastVolTarget, target);
				rp_SetClientInt(target, i_LastVolTime, GetTime());
			}
			else
				CPrintToChat(client, "%s Cette personne n'as pas d'argent sur sois.", NAME);			
		}	
	}
	else
		CPrintToChat(client, "%s Vous devez patienter afin de voler une personne", NAME);
	
	return Plugin_Handled;
}

public Action Cmd_VolArme(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	
	if(rp.canVolArme)
	{
		
	}
	else
		CPrintToChat(client, "%s Vous devez patienter afin de voler une personne", NAME);
	
	return Plugin_Handled;
}

public Action Cmd_Holdup(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	
	if(rp.canHoldup)
	{
		
	}
	else
		CPrintToChat(client, "%s Vous devez patienter afin de braquer une entreprise.", NAME);
	
	return Plugin_Handled;
}

public Action Cmd_Hack(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	
	if(rp.canHack)
	{
		
	}
	else
		CPrintToChat(client, "%s Vous devez patienter afin de hacker les documents confidentiels.", NAME);
	
	return Plugin_Handled;
}

public Action Cmd_Braquage(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}

	if(rp.canBraquage)
	{
		
	}	
	else
		CPrintToChat(client, "%s Vous devez patienter afin de braquer la banque.", NAME);
	
	return Plugin_Handled;
}