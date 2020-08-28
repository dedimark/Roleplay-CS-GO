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

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							C O M P I L E  -  O P T I O N S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#pragma semicolon 1
#pragma newdecls required

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N C L U D E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib>
#include <sdkhooks>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
bool canBraquage;
bool canHack;

char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];	

Database g_DB;
char dbconfig[] = "roleplay";

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Braquages, Holdup, Hack, Vol...",
	author = "Benito",
	description = "Système de contrebandit",
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
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_bandit.log");
		
		RegConsoleCmd("volargent", Cmd_VolArgent);
		RegConsoleCmd("volarme", Cmd_VolArme);
		RegConsoleCmd("hack", Cmd_Hack);
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
	canHack = true;
	canBraquage = true;
}	

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPutInServer(int client)
{
	rp_SetClientBool(client, b_canVolArgent, true);
	rp_SetClientBool(client, b_canVolArme, true);
}	

public void OnClientDisconnect(int client)
{
	rp_SetClientBool(client, b_canVolArgent, false);
	rp_SetClientBool(client, b_canVolArme, false);
}	

public Action Cmd_VolArgent(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	
	if(rp_GetClientBool(client, b_canVolArgent))
	{
		int target = GetAimEnt(client, false);
		if(IsValidEntity(target))
		{
			bool vol[MAXPLAYERS + 1];
			int reward = GetRandomInt(20, 2500);
			
			if (rp_GetClientInt(target, i_Money) >= reward)
				vol[client] = true;
			
			if(rp_GetClientInt(target, i_Money) != 0)
			{
				if(vol[client])
				{
					rp_SetClientBool(client, b_canVolArgent, false);
					CreateTimer(30.0, ResetData, client);
					rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - reward);
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + reward);
					rp_SetClientInt(client, i_LastVolAmount, reward);
					
					CPrintToChat(client, "%s Vous avez volé %i$ à %N.", TEAM, reward, target);
					CPrintToChat(target, "%s Un voleur vous a volé %i$", TEAM, reward);
						
					Insert_rp_sell(g_DB, steamID[target], steamID[client], "Vol", reward, 0);
					
					rp_SetClientInt(client, i_LastVolTarget, target);
					rp_SetClientInt(target, i_LastVolTime, GetTime());
				}
				else
					CPrintToChat(client, "%s Une erreur s'est produite lors du vol !", TEAM);	
			}
			else
				CPrintToChat(client, "%s Cette personne n'as pas d'argent sur sois.", TEAM);			
		}	
	}
	else
		CPrintToChat(client, "%s Vous devez patienter afin de voler une personne", TEAM);
	
	return Plugin_Handled;
}

public Action Cmd_VolArme(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	
	if(rp_GetClientBool(client, b_canVolArme))
	{
		int target = GetAimEnt(client, false);
		
		if(rp_GetClientBool(target, b_isAfk))
		{
			CPrintToChat(client, "%s Vous ne pouvez pas voler une personne inactive.", TEAM);
			return Plugin_Handled;
		}
		else if(Distance(client, target) > 100.0)
		{
			CPrintToChat(client, "%s Vous devez vous rappocher.", TEAM);
			return Plugin_Handled;
		}
		else if(rp_GetClientInt(client, i_timeJail) > 0)
		{
			CPrintToChat(client, "%s Vous ne pouvez pas voler en prison.", TEAM);
			return Plugin_Handled;
		}
		
		if(rp_GetClientInt(client, i_Job) != rp_GetClientInt(target, i_Job) || rp_GetClientInt(client, i_Job) == rp_GetClientInt(target, i_Job) && rp_GetClientInt(client, i_Grade) < rp_GetClientInt(target, i_Grade))
		{
			rp_SetClientBool(client, b_canVolArme, false);
			rp_SetClientInt(client, i_LastVolTarget, target);
			rp_SetClientInt(target, i_LastVolTime, GetTime());
			
			int weapon = Client_GetActiveWeapon(target);
			char entClass[64];
			Entity_GetClassName(weapon, STRING(entClass));
			if(StrContains(entClass, "knife") != -1)
			{
				CPrintToChat(client, "%s Vous ne pouvez pas voler son couteau.", TEAM);
				return Plugin_Handled;
			}
			
			rp_SetClientInt(client, i_LastVolArme, weapon);
			
			PrintHintText(client, "Vous tentez de voler l'arme de %N, restez près de lui.", target);			
			
			rp_SetClientInt(client, i_LastVolArme, target);
			
			SetEntityRenderColor(client, 255, 20, 20, 192);
			
			if(rp_GetClientInt(client, i_Grade) <= 2)
			{
				CreateTimer(30.0, ResetData, client);
				LoadingBar("Vol", 5, 1.0);
			}
			else if(rp_GetClientInt(client, i_Grade) == 3)
			{
				CreateTimer(60.0, ResetData, client);
				LoadingBar("Vol", 6, 1.0);
			}
			else if(rp_GetClientInt(client, i_Grade) == 4)
			{
				CreateTimer(120.0, ResetData, client);
				LoadingBar("Vol", 7, 1.0);
			}
			CreateTimer(0.1, TimerFinVolArme, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
		else
			CPrintToChat(client, "%s Vous ne pouvez pas voler un supérieur !", TEAM);
	}
	else
		CPrintToChat(client, "%s Vous devez patienter afin de voler une personne", TEAM);
	
	return Plugin_Handled;
}

public Action Cmd_Hack(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	
	if(canHack)
	{
		canHack = false;
		CreateTimer(360.0, ResetData, client);
	}
	else
		CPrintToChat(client, "%s Vous devez patienter afin de hacker les documents confidentiels.", TEAM);
	
	return Plugin_Handled;
}

public Action Cmd_Braquage(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}

	if(canBraquage)
	{
		canBraquage = false;
		CreateTimer(720.0, ResetData, client);
	}	
	else
		CPrintToChat(client, "%s Vous devez patienter afin de braquer la banque.", TEAM);
	
	return Plugin_Handled;
}

public Action ResetData(Handle timer, any client)
{
	if(!rp_GetClientBool(client, b_canVolArgent))
		rp_SetClientBool(client, b_canVolArgent, true);
	if(!rp_GetClientBool(client, b_canVolArme))
		rp_SetClientBool(client, b_canVolArme, true);
	rp_SetClientInt(client, i_LastVolAmount, 0);
	rp_SetClientInt(client, i_LastVolTarget, 0);
	rp_SetClientInt(client, i_LastVolTime, 0);
	rp_SetClientInt(client, i_LastVolArme, 0);

	if(!canBraquage)
	{
		canBraquage = true;
		CPrintToChatAll("%s Les braquages sont de nouveau disponibles.", TEAM);
	}	
	if(!canHack)
	{
		canHack = true;
		CPrintToChatAll("%s Les hack's sont de nouveau disponibles.", TEAM);
	}	
}

/*	TIMER	*/

public Action TimerFinVolArme(Handle timer, any client)
{
	if(IsClientValid(client) && IsValidEntity(client))
	{
		rp_SetDefaultClientColor(client);
		
		char entityClassname[128];
		Entity_GetClassName(rp_GetClientInt(client, i_LastVolArme), STRING(entityClassname));
		
		if(IsValidEntity(rp_GetClientInt(client, i_LastVolArme)))
			rp_DeleteWeapon(client, rp_GetClientInt(client, i_LastVolArme));
		
		int arme = GivePlayerItem(client, entityClassname);
		SetEntityRenderMode(arme, RENDER_TRANSCOLOR);
		SetEntityRenderColor(arme, 255, 20, 20, 255);
		
		PrintHintText(client ,"Vous avez volé l'arme de %N.", rp_GetClientInt(client, i_LastVolTarget));
		
		CPrintToChat(rp_GetClientInt(client, i_LastVolTarget), "%s Votre arme vient d'être {lightred}voler {default}de force.", TEAM);
		LogToFile(logFile, "Le joueur %N a volé une arme a %N.", client, rp_GetClientInt(client, i_LastVolTarget));
		return Plugin_Stop;
	}
	else
	{
		if(Distance(client, rp_GetClientInt(client, i_LastVolTarget)) >= 100.0)
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);			
							
			CPrintToChat(client, "%s Le vol de l'arme de %N a été interrompu.", TEAM, rp_GetClientInt(client, i_LastVolTarget));
			return Plugin_Stop;
		}
		else
			return Plugin_Continue;
	}
}