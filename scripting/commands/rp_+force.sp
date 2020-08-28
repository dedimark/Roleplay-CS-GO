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
#include <sdkhooks>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>
#include <smlib>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
bool canForce[MAXPLAYERS + 1];
bool forceSecurite[MAXPLAYERS + 1] = true;
bool forceDistance[MAXPLAYERS + 1];
bool forceAdmin[MAXPLAYERS + 1];

char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];

float distanceForce[MAXPLAYERS + 1];

int cibleForce[MAXPLAYERS + 1];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] +Force", 
	author = "Benito", 
	description = "Module +Force", 
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
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/rp_+force.log");
		
		RegConsoleCmd("force", Command_Force);
		RegConsoleCmd("+force", Command_Force);
	}	
	else
		UnloadPlugin();
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void rp_OnClientDeath(int attacker, int victim, const char[] weapon, bool headshot)
{
	// Force :
	if(cibleForce[attacker] != -1)
	{
		cibleForce[attacker] = -1;
		canForce[attacker] = true;
	}
	
	canForce[attacker] = true;
	cibleForce[attacker] = -1;
}	

public void rp_OnClientPutInServer(int client)
{
	cibleForce[client] = -1;
	canForce[client] = true;
	forceAdmin[client] = false;
	forceDistance[client] = true;
	forceSecurite[client] = true;
}

public void rp_OnClientDisconnect(int client)
{
	distanceForce[client] = 0.0;
	cibleForce[client] = -1;
	forceAdmin[client] = false;
	forceDistance[client] = false;
	forceSecurite[client] = false;
}	

public Action Command_Force(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}
	
	char entClass[64];
	int aim;
	if(IsADMIN(client))
		aim = GetClientAimTarget(client, false);
	else 
		aim = GetAimEnt(client, false);
	
	if(IsValidEntity(aim))
		Entity_GetClassName(aim, STRING(entClass));
	
	if(!IsPlayerAlive(client))
		return Plugin_Handled;
	
	if(IsValidEntity(aim) && aim <= MaxClients)
	{
		if(!IsADMIN(client))
		{
			if(rp_GetClientInt(client, i_Job) == 0
			|| rp_GetClientInt(client, i_Job) == 1 && rp_GetClientInt(client, i_Grade) == 6
			|| rp_GetClientInt(client, i_Job) != 1 && rp_GetClientInt(client, i_Job) != 7 && rp_GetClientInt(client, i_Grade) >= 2)
			{
				if(!IsVIP(client))
				{
					CPrintToChat(client, "%s Vous n'êtes pas autorisé à déplacer une personne.", TEAM);
					return Plugin_Handled;
				}
			}
			else if(rp_GetClientInt(client, i_Job) == 7 && rp_GetClientInt(client, i_ByteZone) != 7 && rp_GetClientInt(client, i_Grade) != 1 && rp_GetClientInt(client, i_Grade) != 2)
			{
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à déplacer une personne en dehors du tribunal.", TEAM);
				return Plugin_Handled;
			}
			if(rp_GetClientInt(client, i_Job) == rp_GetClientInt(aim, i_Job) && rp_GetClientInt(client, i_Grade) > rp_GetClientInt(aim, i_Grade))
			{
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à déplacer un supérieur.", TEAM);
				return Plugin_Handled;
			}
			if(rp_GetClientInt(client, i_Job) == rp_GetClientInt(aim, i_Job) && rp_GetClientInt(client, i_Grade) == rp_GetClientInt(aim, i_Grade))
			{
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à déplacer un collègue.", TEAM);
				return Plugin_Handled;
			}
			if(rp_GetClientInt(aim, i_Job) == 1)
			{
				if(rp_GetClientInt(client, i_Job) == 2 && rp_GetClientInt(client, i_Grade) != 1
				|| rp_GetClientInt(client, i_Job) == 1 && rp_GetClientInt(client, i_Grade) > 1
				|| rp_GetClientInt(client, i_Job) != 2)
				{
					CPrintToChat(client, "%s Vous n'êtes pas autorisé à déplacer un policier.", TEAM);
					return Plugin_Handled;
				}
			}
			if(rp_GetClientInt(client, i_Job) != rp_GetClientInt(aim, i_Job) && rp_GetClientInt(client, i_Job) != 1 && rp_GetClientInt(client, i_Job) != 7)
			{
				CPrintToChat(client, "%s Seul vos employés peuvent être déplacés.", TEAM);
				return Plugin_Handled;
			}
			if(rp_GetClientInt(aim, i_Job) == 2 && rp_GetClientInt(aim, i_Grade) == 1)
			{
				CPrintToChat(client, "%s Cette personne est trop influente pour être déplacée.", TEAM);
				return Plugin_Handled;
			}
			if(rp_GetClientBool(aim, b_isAfk))
			{
				CPrintToChat(client, "%s Cette personne est inactive.", TEAM);
				return Plugin_Handled;
			}
			if(rp_GetClientInt(client, i_ByteZone) == 777)
			{
				CPrintToChat(client, "%s La force est désactivé en zone {lightred}PVP{default}.", TEAM);
				return Plugin_Handled;
			}
			if(GetEntProp(aim, Prop_Send, "m_iPlayerState") == 1
			|| GetEntityMoveType(aim) == MOVETYPE_NOCLIP)
				return Plugin_Handled;
		}
	}
	
	if(IsValidEntity(aim) && canForce[client])
	{
		if(forceSecurite[client])
		{
			char entName[64];
			Entity_GetName(aim, STRING(entName));
			
			if(StrContains(entClass, "player") == -1
			&& StrContains(entClass, "prop_physics") == -1
			&& StrContains(entClass, "prop_vehicle_driveable") == -1
			&& !IsADMIN(client))
			{
				if(IsADMIN(client))
				{
					if(StrContains(entName, "admin") == -1)
						return Plugin_Handled;
				}
				
				return Plugin_Handled;
			}
			else if(StrContains(entClass, "door") != -1)
				return Plugin_Handled;
		}
		
		float minDist, distance;
		distance = Distance(client, aim);
		if(forceDistance[client])
		{
			if(rp_GetClientInt(client, i_Job) == 1)
			{
				if(rp_GetClientInt(client, i_Grade) <= 2)
					distanceForce[client] = distance;
				else if(rp_GetClientInt(client, i_Grade) == 4)
					minDist = 1000.0;
				else if(rp_GetClientInt(client, i_Grade) == 5)
					minDist = 500.0;
			}
			else
			{
				minDist = 150.0;
				distanceForce[client] = 40.0;
			}
			
			if(distanceForce[client] < 40.0)
				distanceForce[client] = 40.0;
		}
		else
			distanceForce[client] = distance;
		
		if(minDist == 0.0 || distance <= minDist)
		{
			cibleForce[client] = aim;
			canForce[client] = false;
			
			if(!forceAdmin[client])
				CreateTimer(0.01, DoForce, client);
			else
				CreateTimer(0.01, DoForceAdmin, client);
			
			if(aim <= MaxClients)
				LogToFile(logFile, "[FORCE] Le joueur %N porte %N.", client, aim);
		}
	}
	else
	{
		if(IsValidEntity(cibleForce[client]))
		{
			if(StrEqual(entClass, "player"))
				SetEntityMoveType(cibleForce[client], MOVETYPE_WALK);
		}
		
		canForce[client] = true;
		cibleForce[client] = -1;
	}
	return Plugin_Handled;
}

public Action DoForce(Handle timer, any client)
{
	if(IsValidEntity(cibleForce[client]))
	{
		if(cibleForce[client] <= MaxClients
		&& !IsPlayerAlive(cibleForce[client])
		|| !rp_GetClientBool(client, b_isTased)
		|| !rp_GetClientBool(client, b_isArrested)
		|| !IsPlayerAlive(client))
		{
			cibleForce[client] = -1;
			canForce[client] = true;
			return Plugin_Handled;
		}
		
		float direction[3], position[3], velocity[3], angle[3];
		
		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, direction, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, position);
		
		if(distanceForce[client] <= 40.0)
		{
			position[0] += direction[0] * (distanceForce[client] + 100.0);
			position[1] += direction[1] * (distanceForce[client] + 100.0);
		}
		else
		{
			position[0] += direction[0] * distanceForce[client];
			position[1] += direction[1] * distanceForce[client];
		}
		position[2] += direction[2] * distanceForce[client];
		
		GetEntPropVector(cibleForce[client], Prop_Send, "m_vecOrigin", direction);
		
		SubtractVectors(position, direction, velocity);
		ScaleVector(velocity, 10.0);
		
		TeleportEntity(cibleForce[client], NULL_VECTOR, NULL_VECTOR, velocity);
		
		if(!forceAdmin[client])
			CreateTimer(0.01, DoForce, client);
		else
			CreateTimer(0.01, DoForceAdmin, client);
		
		if(cibleForce[client] <= MaxClients)
		{
			PrintHintText(client, "Vous portez %N.", cibleForce[client]);				
			PrintHintText(cibleForce[client], "%N vous porte.", client);
		}
	}
	else
	{
		canForce[client] = true;
		cibleForce[client] = -1;
	}
	return Plugin_Handled;
}

public Action DoForceAdmin(Handle timer, any client)
{
	if(IsValidEntity(cibleForce[client]))
	{
		if(cibleForce[client] <= MaxClients && !IsPlayerAlive(cibleForce[client]))
		{
			cibleForce[client] = -1;
			canForce[client] = true;
			return Plugin_Handled;
		}
		
		float direction[3], position[3], angle[3];
		
		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, direction, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, position);
		
		if(distanceForce[client] <= 40.0)
		{
			position[0] += direction[0] * (distanceForce[client] + 100.0);
			position[1] += direction[1] * (distanceForce[client] + 100.0);
		}
		else
		{
			position[0] += direction[0] * distanceForce[client];
			position[1] += direction[1] * distanceForce[client];
		}
		position[2] += direction[2] * distanceForce[client];
		
		TeleportEntity(cibleForce[client], position, NULL_VECTOR, NULL_VECTOR);
		
		if(!forceAdmin[client])
			CreateTimer(0.01, DoForce, client);
		else
			CreateTimer(0.01, DoForceAdmin, client);
		
		if(cibleForce[client] <= MaxClients)
		{
			PrintHintText(client, "Vous portez %N.", cibleForce[client]);
			PrintCenterText(cibleForce[client], "%N vous porte.", client);
		}
	}
	else
	{
		canForce[client] = true;
		cibleForce[client] = -1;
	}
	return Plugin_Handled;
}