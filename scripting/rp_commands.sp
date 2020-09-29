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
#include <emitsoundany>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];


/* Force */
bool canForce[MAXPLAYERS + 1];
bool forceSecurite[MAXPLAYERS + 1] = true;
bool forceDistance[MAXPLAYERS + 1];
bool forceAdmin[MAXPLAYERS + 1];
int cibleForce[MAXPLAYERS + 1];
float distanceForce[MAXPLAYERS + 1];

/* Build */
GlobalForward g_OnBuild;
GlobalForward g_HandleOnBuild;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Global - Commands", 
	author = "Benito", 
	description = "Global - Commands", 
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
	
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/rp_commands.log");
		
	/* Force */
	RegConsoleCmd("+force", Command_Grab);
	RegConsoleCmd("force", Command_Grab);
	
	/* Build */
	g_OnBuild = new GlobalForward("RP_OnPlayerBuild", ET_Event, Param_Cell, Param_Cell);
	g_HandleOnBuild = new GlobalForward("RP_OnPlayerBuildHandle", ET_Event, Param_Cell, Param_String);	
	RegConsoleCmd("b", Cmd_Build);
	RegConsoleCmd("build", Cmd_Build);
	
	/* Unlock & Lock */
	RegConsoleCmd("unlock", Cmd_Unlock);
	RegConsoleCmd("open", Cmd_Unlock);
	RegConsoleCmd("ouvrir", Cmd_Unlock);	
	RegConsoleCmd("fermer", Cmd_Lock);
	RegConsoleCmd("lock", Cmd_Lock);
	RegConsoleCmd("verrouiller", Cmd_Lock);
	
	/* FirstPerson(3RD) */
	RegConsoleCmd("3rd", Cmd_3rd);
	RegConsoleCmd("tp", Cmd_3rd);
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPutInServer(int client)
{
	rp_SetClientBool(client, b_firstPerson, true);
	forceAdmin[client] = false;
	forceDistance[client] = true;
	forceSecurite[client] = true;
	cibleForce[client] = -1;
	canForce[client] = true;
}

public void OnClientDisconnect(int client)
{
	distanceForce[client] = 0.0;
}	

//*********************************************************************
//*                      		 +FORCE                           	  *
//*********************************************************************

public Action RP_OnPlayerSettings(int client, Menu menu)
{
	menu.AddItem("force", "+Force");
}	

public int RP_OnPlayerSettingsHandle(int client, const char[] info)
{
	if(StrEqual(info, "force"))
		MenuForce(client);
}	

public void RP_OnPlayerDeath(int attacker, int victim, int respawnTime)
{
	// Force :
	if (cibleForce[attacker] != -1)
	{
		cibleForce[attacker] = -1;
		canForce[attacker] = true;
	}
}	

public Action Command_Grab(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("%T", "Command_NotAvailable", LANG_SERVER);
		return Plugin_Handled;
	}
	
	if (GetVehicle(client) != -1 || rp_GetClientBool(client, b_isZombie))
		return Plugin_Handled;
	
	char entClass[64];
	int aim;
	if (rp_GetClientInt(client, i_AdminLevel) <= 3)
		aim = GetClientAimTarget(client, false);
	else 
		aim = GetAimEnt(client, false);
	
	if (IsValidEntity(aim))
		Entity_GetClassName(aim, STRING(entClass));
	
	if (!IsPlayerAlive(client))
		return Plugin_Handled;
		
	int jobClient = rp_GetClientInt(client, i_Job);
	int jobTarget = rp_GetClientInt(aim, i_Job);
	int gradeClient = rp_GetClientInt(client, i_Job);
	int gradeTarget = rp_GetClientInt(aim, i_Job);	
	
	if (IsValidEntity(aim) && aim <= MaxClients)
	{
		
		if (rp_GetClientInt(client, i_AdminLevel) != 0)
		{
			if (jobClient == 0 || jobClient == 1 && gradeClient == 7 || jobClient != 1 && jobClient != 7 && gradeClient >= 2)
			{
				if (rp_GetClientInt(client, i_VipTime) == 0)
				{
					CPrintToChat(client, "%s Vous n'êtes pas autorisé à déplacer une personne.", TEAM);
					return Plugin_Handled;
				}
			}
			else if (jobClient == 7 && rp_GetClientInt(client, i_ByteZone) != 7 && gradeClient != 1 && gradeClient != 2)
			{
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à déplacer une personne en dehors du tribunal.", TEAM);
				return Plugin_Handled;
			}
			if (jobClient == jobTarget && gradeClient > gradeTarget)
			{
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à déplacer un supérieur.", TEAM);
				return Plugin_Handled;
			}
			if (jobClient == jobTarget && gradeClient == gradeTarget)
			{
				CPrintToChat(client, "%s Vous n'êtes pas autorisé à déplacer un collègue.", TEAM);
				return Plugin_Handled;
			}
			if (jobTarget == 1)
			{
				if (jobClient == 2 && gradeClient != 1 || jobClient == 1 && gradeClient > 1 || jobClient != 2)
				{
					CPrintToChat(client, "%s Vous n'êtes pas autorisé à déplacer un policier.", TEAM);
					return Plugin_Handled;
				}
			}
			if (jobClient != jobTarget && jobClient != 1 && jobClient != 7)
			{
				CPrintToChat(client, "%s Seul vos employés peuvent être déplacés.", TEAM);
				return Plugin_Handled;
			}
			if (jobTarget == 2 && gradeTarget == 1)
			{
				CPrintToChat(client, "%s Cette personne est trop influente pour être déplacée.", TEAM);
				return Plugin_Handled;
			}
			if (rp_GetClientBool(aim, b_isAfk))
			{
				CPrintToChat(client, "%s Cette personne est inactive.", TEAM);
				return Plugin_Handled;
			}
			if (rp_GetClientInt(client, i_ByteZone) == 777 && rp_GetClientInt(client, i_AdminLevel) != 0)
			{
				CPrintToChat(client, "%s La force est désactivé en zone {lightred}PVP{default}.", TEAM);
				return Plugin_Handled;
			}
			if (GetEntityMoveType(aim) == MOVETYPE_NOCLIP)
			return Plugin_Handled;
		}
	}
	
	if (IsValidEntity(aim) && canForce[client])
	{
		if (forceSecurite[client])
		{
			char entName[64];
			Entity_GetName(aim, STRING(entName));
			
			if (StrContains(entClass, "player") == -1 && StrContains(entClass, "prop_physics") == -1 && StrContains(entClass, "prop_vehicle_driveable") == -1)
			{
				if (rp_GetClientInt(client, i_AdminLevel) != 0)
				{
					if (StrContains(entName, "admin") == -1)
						return Plugin_Handled;
				}
				
				return Plugin_Handled;
			}
			else if (StrContains(entClass, "door") != -1)
				return Plugin_Handled;
			else if (StrContains(entClass, "prop_vehicle_driveable") != -1)
			{
				if (rp_GetVehicleInt(aim, car_owner) != client && rp_GetClientInt(client, i_AdminLevel) == 0)
				{
					if (jobClient != 1)
					{
						NoCommandAcces(client);
						return Plugin_Handled;
					}
					else if (jobClient == 1 && gradeClient == 7)
					{
						NoCommandAcces(client);
						return Plugin_Handled;
					}
				}
			}
			else if (StrContains(entName, "cadavre") != -1)
			{
				if (jobClient != 12 && rp_GetClientInt(client, i_AdminLevel) == 0)
				{
					NoCommandAcces(client);
					return Plugin_Handled;
				}	
			}
			else if (StrContains(entName, "mafia") != -1)
			{
				if (jobClient != 1 && jobClient != 2)
				{
					NoCommandAcces(client);
					return Plugin_Handled;
				}
			}
		}
		
		float minDist, distance;
		distance = Distance(client, aim);
		if (forceDistance[client])
		{
			if (jobClient == 1)
			{
				if (gradeClient <= 2)
					distanceForce[client] = distance;
				else if (gradeClient == 4)
					minDist = 1000.0;
				else if (gradeClient == 5)
					minDist = 500.0;
			}
			else
			{
				minDist = 150.0;
				distanceForce[client] = 40.0;
			}
			
			if (distanceForce[client] < 40.0)
				distanceForce[client] = 40.0;
		}
		else
			distanceForce[client] = distance;
		
		if (minDist == 0.0 || distance <= minDist)
		{
			cibleForce[client] = aim;
			canForce[client] = false;
			
			if (!forceAdmin[client])
				CreateTimer(0.01, DoForce, client);
			else
				CreateTimer(0.01, DoForceAdmin, client);
			
			if (aim <= MaxClients)
				LogToFile(logFile, "[FORCE] Le joueur %N porte %N.", client, aim);
		}
	}
	else
	{
		if (IsValidEntity(cibleForce[client]))
		{
			if (StrEqual(entClass, "player"))
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
		|| rp_GetClientBool(client, b_isTased)
		|| rp_GetClientBool(client, b_isArrested)
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

Menu MenuForce(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menuForce = new Menu(DoMenuForce);
	menuForce.SetTitle("Gérer le pouvoir de la force :");
	if(!forceAdmin[client])
		menuForce.AddItem("typeadmin", "Type : normal");
	else
		menuForce.AddItem("typenormal", "Type : admin");
	if(forceDistance[client])
		menuForce.AddItem("distanceoff", "Distance : activé");
	else
		menuForce.AddItem("distanceon", "Distance : désactivé");
	if(rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		if(forceSecurite[client])
			menuForce.AddItem("securiteoff", "Sécurité : activé");
		else
			menuForce.AddItem("securiteon", "Sécurité : désactivé");
	}
	else
		menuForce.AddItem("", "Sécurité : activé", ITEMDRAW_DISABLED);
	menuForce.ExitBackButton = true;
	menuForce.ExitButton = true;
	menuForce.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuForce(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, info, sizeof(info));
		
		if(StrEqual(info, "typeadmin"))
		{
			forceAdmin[client] = true;
			PrintHintText(client, "Force admin activé.");		
		}
		else if(StrEqual(info, "typenormal"))
		{
			forceAdmin[client] = false;
			PrintHintText(client, "Force admin désactivé.");		
		}
		else if(StrEqual(info, "distanceoff"))
		{
			forceDistance[client] = false;
			PrintHintText(client, "Distance force désactivé.");		
		}
		else if(StrEqual(info, "distanceon"))
		{
			forceDistance[client] = true;
			PrintHintText(client, "Distance force activé.");			
		}
		else if(StrEqual(info, "securiteoff"))
		{
			forceSecurite[client] = false;
			PrintHintText(client, "Sécurité force désactivé.");		
		}
		else if(StrEqual(info, "securiteon"))
		{
			forceSecurite[client] = true;
			PrintHintText(client, "Sécurité force activé.");
		}
		MenuForce(client);
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

//*********************************************************************
//*                      		 BUILD                           	  *
//*********************************************************************
public Action Cmd_Build(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("%T", "Command_NotAvailable", LANG_SERVER);
		return Plugin_Handled;
	}
	
	if(rp_GetClientInt(client, i_Job) != 0)
	{
		rp_SetClientBool(client, b_menuOpen, true);
		
		Menu menu = new Menu(DoMenuBuild);		
		Call_StartForward(g_OnBuild);
		Call_PushCell(client);
		Call_PushCell(menu);
		Call_Finish();
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
		NoCommandAcces(client);
		
	return Plugin_Handled;
}	

public int DoMenuBuild(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		Call_StartForward(g_HandleOnBuild);
		Call_PushCell(client);
		Call_PushString(info);
		Call_Finish();		
		rp_SetClientBool(client, b_menuOpen, false);
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

//*********************************************************************
//*                      	 UNLOCK & LOCK                            *
//*********************************************************************
public Action Cmd_Unlock(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	
	int aim = GetAimEnt(client, false);
	if(IsValidEntity(aim))
	{		
		char entClass[128];
		GetEntityClassname(aim, STRING(entClass));
		char entName[64];
		Entity_GetName(aim, STRING(entName));
		
		int job = rp_GetClientInt(client, i_Job);
		
		if(StrContains(entClass, "door") != -1)
		{
			if(job != 0)
			{
				if(Entity_IsLocked(aim))
				{
					if(rp_GetClientInt(client, i_Job) == 1)
					{
						if(!rp_GetClientBool(client, b_asMandat))
						{
							if(rp_GetClientInt(client, i_Grade) <= 2)
							{
								Entity_Lock(aim);
								PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
							}	
							else if(rp_GetClientInt(client, i_Grade) > 2 && StrContains(entName, "job_police_") != -1 || rp_GetClientInt(client, i_ByteZone) == 1)
							{
								AcceptEntityInput(aim, "Unlock");	
								PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
							}	
							else
								CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
						}								
						else
						{
							if (rp_GetJobPerqui() == 2 && StrContains(entName, "job_mafia_") != -1
								 || rp_GetJobPerqui() == 3 && StrContains(entName, "job_18th_") != -1
								 || rp_GetJobPerqui() == 4 && StrContains(entName, "job_hopital_") != -1
								 || rp_GetJobPerqui() == 5 && StrContains(entName, "job_mairie_") != -1
								 || rp_GetJobPerqui() == 6 && StrContains(entName, "job_armu_") != -1
								 || rp_GetJobPerqui() == 7 && StrContains(entName, "job_justice_") != -1
								 || rp_GetJobPerqui() == 8 && StrContains(entName, "job_immo_") != -1
								 || rp_GetJobPerqui() == 9 && StrContains(entName, "job_dealer_") != -1
								 || rp_GetJobPerqui() == 10 && StrContains(entName, "job_tech_") != -1
								 || rp_GetJobPerqui() == 11 && StrContains(entName, "job_bank_") != -1
								 || rp_GetJobPerqui() == 12 && StrContains(entName, "job_tueur_") != -1
								 || rp_GetJobPerqui() == 13 && StrContains(entName, "job_artif_") != -1
								 || rp_GetJobPerqui() == 14 && StrContains(entName, "job_vendeurdeskin_") != -1
								 || rp_GetJobPerqui() == 15 && StrContains(entName, "job_mcdonalds_") != -1
								 || rp_GetJobPerqui() == 16 && StrContains(entName, "job_loto_ ") != -1
								 || rp_GetJobPerqui() == 17 && StrContains(entName, "job_coach_") != -1
								 || rp_GetJobPerqui() == 18 && StrContains(entName, "job_sexshop_") != -1
								 || rp_GetJobPerqui() == 19 && StrContains(entName, "job_mairie_") != -1
								 || rp_GetJobPerqui() == 20 && StrContains(entName, "job_cardealer_") != -1)
							{
								if (GetClientTeam(client) == CS_TEAM_T)
								{
									PrintCenterText(client, "Vous devez être en uniforme pour perquisitionner !");
									return Plugin_Handled;
								}	
								
								int count, pass;					
								LoopClients(i)
								{
									if (rp_GetClientInt(i, i_Job) == rp_GetJobPerqui() && rp_GetClientInt(i, i_Grade) <= 2)
									{
										CPrintToChat(i, "%s Attention, une perquisition a lieu dans votre planque.", TEAM);
										PrintHintText(i, "Votre planque est perquisitionnée !");
									}
									
									if(rp_GetClientInt(i, i_Job) == 1)
									{
										count++;
										if (Distance(i, aim) <= 500.0)
											pass++;
									}
								}
								
								if (rp_GetClientInt(client, i_Grade) == 5)
								{
									if (count >= 2 && pass < 2)
									{
										CPrintToChat(client, "%s Il faut 2 agents minimum pour lancer la perquisition", TEAM);
										PrintCenterText(client, "2 agents minimum pour la perquisition.", TEAM);
										return Plugin_Handled;
									}
								}
								else if (rp_GetClientInt(client, i_Grade) == 4)
								{
									if (count >= 1 && pass == 0)
									{
										CPrintToChat(client, "%s Il faut 1 agent minimum pour lancer la perquisition", TEAM);
										PrintCenterText(client, "1 agent minimum pour la perquisition.", TEAM);
										return Plugin_Handled;
									}
								}
								
								PrecacheSoundAny("physics/metal/metal_box_break1.wav");
								EmitSoundToAllAny("physics/metal/metal_box_break1.wav", client, _, _, _, 1.0);
								
								char jobName[64];
								GetJobName(rp_GetJobPerqui(), STRING(jobName));
								CPrintToChatAll("%s {lime}Perquisition de la Police municipale/fédérale de Princeton (%s){default}, veuillez coopérer ou vous serez placé en garde à vue.", TEAM, jobName);
								
								AcceptEntityInput(aim, "Unlock");
							}	
						}							
					}	
					else if(rp_GetClientInt(client, i_Job) == 2)
					{
						if(StrContains(entName, "job_mafia_") != -1 || rp_GetClientInt(client, i_ByteZone) == 2)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 3)
					{
						if(StrContains(entName, "job_18th_") != -1 || rp_GetClientInt(client, i_ByteZone) == 3)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 4)
					{
						if(StrContains(entName, "job_hopital_") != -1 || rp_GetClientInt(client, i_ByteZone) == 4)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 5)
					{
						if(StrContains(entName, "job_mairie_") != -1 || rp_GetClientInt(client, i_ByteZone) == 5)
						{
							AcceptEntityInput(aim, "Unlock");	
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 6)
					{
						if(StrContains(entName, "job_armu_") != -1 || rp_GetClientInt(client, i_ByteZone) == 6)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 7)
					{
						if(StrContains(entName, "job_justice_") != -1 || rp_GetClientInt(client, i_ByteZone) == 7)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 8)
					{
						if(StrContains(entName, "job_immo_") != -1 || StrContains(entName, "appart") != -1 || rp_GetClientInt(client, i_ByteZone) == 8)
						{
							AcceptEntityInput(aim, "Unlock");	
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 9)
					{
						if(StrContains(entName, "job_dealer_") != -1 || rp_GetClientInt(client, i_ByteZone) == 9)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 10)
					{
						if(StrContains(entName, "job_tech_") != -1 || rp_GetClientInt(client, i_ByteZone) == 10)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 11)
					{
						if(StrContains(entName, "job_bank_") != -1 || rp_GetClientInt(client, i_ByteZone) == 11)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 12)
					{
						if(StrContains(entName, "job_tueur_") != -1 || rp_GetClientInt(client, i_ByteZone) == 12)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 13)
					{
						if(StrContains(entName, "job_artif_") != -1 || rp_GetClientInt(client, i_ByteZone) == 13)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 14)
					{
						if(StrContains(entName, "job_vendeurdeskin_") != -1 || rp_GetClientInt(client, i_ByteZone) == 14)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 15)
					{
						if(StrContains(entName, "job_mcdonalds_") != -1 || rp_GetClientInt(client, i_ByteZone) == 15)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 16)
					{
						if(StrContains(entName, "job_loto_") != -1 || rp_GetClientInt(client, i_ByteZone) == 16)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 17)
					{
						if(StrContains(entName, "job_coach_") != -1 || rp_GetClientInt(client, i_ByteZone) == 17)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 18)
					{
						if(StrContains(entName, "job_sexshop_") != -1 || rp_GetClientInt(client, i_ByteZone) == 18)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 19)
					{
						if(StrContains(entName, "job_mairie_") != -1 || rp_GetClientInt(client, i_ByteZone) == 19 || rp_GetClientInt(client, i_ByteZone) == 5)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 20)
					{
						if(StrContains(entName, "job_cardealer_") != -1 || rp_GetClientInt(client, i_ByteZone) == 20)
						{
							AcceptEntityInput(aim, "Unlock");
							PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(StrContains(entName, steamID[client]))
					{
						AcceptEntityInput(aim, "Unlock");
						PrintCenterText(client, "Porte <font color='#1AE002'>déverrouillée</font>.");
					}
					else
						CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);					
				}
				else
					CPrintToChat(client, "%s La porte est déjà déverrouillée", TEAM);
			}	
		}	
		else
			CPrintToChat(client, "%s Vous devez viser une porte.", TEAM);
	}	
	else
		CPrintToChat(client, "%s Vous devez viser une entité valide.", TEAM);
			
	return Plugin_Handled;
}	

public Action Cmd_Lock(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	
	int aim = GetAimEnt(client, false);
	if(IsValidEntity(aim))
	{		
		char entClass[128];
		GetEntityClassname(aim, STRING(entClass));
		char entName[64];
		Entity_GetName(aim, STRING(entName));
		
		int job = rp_GetClientInt(client, i_Job);
		
		if(StrContains(entClass, "door") != -1)
		{
			if(job != 0)
			{
				if(!Entity_IsLocked(aim))
				{
					if (rp_GetClientInt(client, i_Job) == rp_GetJobPerqui())
					{
						PrintHintText(client, "Vous ne pouvez pas fermer les portes pendant une perquisition.", TEAM);
						return Plugin_Handled;
					}
					
					if(rp_GetClientInt(client, i_Job) == 1)
					{
						if(rp_GetClientInt(client, i_Grade) <= 2)
						{
							Entity_Lock(aim);
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else if(rp_GetClientInt(client, i_Grade) > 2 && StrContains(entName, "job_police_") != -1 || rp_GetClientInt(client, i_ByteZone) == 1)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}	
					else if(rp_GetClientInt(client, i_Job) == 2)
					{
						if(StrContains(entName, "job_mafia_") != -1 || rp_GetClientInt(client, i_ByteZone) == 2)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 3)
					{
						if(StrContains(entName, "job_18th_") != -1 || rp_GetClientInt(client, i_ByteZone) == 3)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 4)
					{
						if(StrContains(entName, "job_hopital_") != -1 || rp_GetClientInt(client, i_ByteZone) == 4)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 5)
					{
						if(StrContains(entName, "job_mairie_") != -1 || rp_GetClientInt(client, i_ByteZone) == 5)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 6)
					{
						if(StrContains(entName, "job_armu_") != -1 || rp_GetClientInt(client, i_ByteZone) == 6)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 7)
					{
						if(StrContains(entName, "job_justice_") != -1 || rp_GetClientInt(client, i_ByteZone) == 7)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 8)
					{
						if(StrContains(entName, "job_immo_") != -1 || StrContains(entName, "appart") != -1 || rp_GetClientInt(client, i_ByteZone) == 8)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 9)
					{
						if(StrContains(entName, "job_dealer_") != -1 || rp_GetClientInt(client, i_ByteZone) == 9)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 10)
					{
						if(StrContains(entName, "job_tech_") != -1 || rp_GetClientInt(client, i_ByteZone) == 10)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 11)
					{
						if(StrContains(entName, "job_bank_") != -1 || rp_GetClientInt(client, i_ByteZone) == 11)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 12)
					{
						if(StrContains(entName, "job_tueur_") != -1 || rp_GetClientInt(client, i_ByteZone) == 12)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 13)
					{
						if(StrContains(entName, "job_artif_") != -1 || rp_GetClientInt(client, i_ByteZone) == 13)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 14)
					{
						if(StrContains(entName, "job_vendeurdeskin_") != -1 || rp_GetClientInt(client, i_ByteZone) == 14)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 15)
					{
						if(StrContains(entName, "job_mcdonalds_") != -1 || rp_GetClientInt(client, i_ByteZone) == 15)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 16)
					{
						if(StrContains(entName, "job_loto_") != -1 || rp_GetClientInt(client, i_ByteZone) == 16)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 17)
					{
						if(StrContains(entName, "job_coach_") != -1 || rp_GetClientInt(client, i_ByteZone) == 17)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 18)
					{
						if(StrContains(entName, "job_sexshop_") != -1 || rp_GetClientInt(client, i_ByteZone) == 18)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 19)
					{
						if(StrContains(entName, "job_mairie_") != -1 || rp_GetClientInt(client, i_ByteZone) == 19 || rp_GetClientInt(client, i_ByteZone) == 5)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(rp_GetClientInt(client, i_Job) == 20)
					{
						if(StrContains(entName, "job_cardealer_") != -1 || rp_GetClientInt(client, i_ByteZone) == 20)
						{
							AcceptEntityInput(aim, "Lock");	
							PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
						}	
						else
							CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
					}
					else if(StrContains(entName, steamID[client]))
					{
						AcceptEntityInput(aim, "Lock");
						PrintCenterText(client, "Porte <font color='#F80000'>verrouillée</font>.");
					}
					else
						CPrintToChat(client, "%s Vous n'avez pas accès à cette porte.", TEAM);
				}	
				else
					CPrintToChat(client, "%s La porte est déjà verrouillée.", TEAM);
			}	
		}	
		else
			CPrintToChat(client, "%s Vous devez viser une porte.", TEAM);
	}	
	else
		CPrintToChat(client, "%s Vous devez viser une entité valide.", TEAM);
			
	return Plugin_Handled;
}	

//*********************************************************************
//*                      	FirstPerson(3RD)                          *
//*********************************************************************
public Action Cmd_3rd(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("%T", "Command_NoAcces", LANG_SERVER);
		return Plugin_Handled;
	}
	
	if(IsClientValid(client))
	{
		if(!rp_GetClientBool(client, b_firstPerson))
		{
			rp_SetClientBool(client, b_firstPerson, true);
			Client_SetThirdPersonMode(client, false);
			CPrintToChat(client, "%s Vous êtes désormais en première personne.", TEAM);
		}	
		else
		{
			rp_SetClientBool(client, b_firstPerson, false);
			Client_SetThirdPersonMode(client, true);
			CPrintToChat(client, "%s Vous êtes désormais en 3ème personne.", TEAM);
		}	
	}

	return Plugin_Handled;
}	