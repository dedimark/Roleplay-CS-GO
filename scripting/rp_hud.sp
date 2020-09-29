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
Handle g_hTimerHUD[MAXPLAYERS+1] = { null, ... };

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Hud", 
	author = "Benito", 
	description = "Système d'hud pour les joueurs", 
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
	
	RegConsoleCmd("hud", Cmd_Menu);	
}

public void OnClientPutInServer(int client) 
{	
	g_hTimerHUD[client] = CreateTimer(1.0, updateHUD, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	
	rp_SetClientBool(client, b_menuOpen, false);
}

public void RP_OnPlayerDisconnect(int client) 
{
	rp_SetClientBool(client, b_menuOpen, false);
	TrashTimer(g_hTimerHUD[client], true);
}

public Action Cmd_Menu(int client, int args)
{	
	if (client == 0)
	{
		char translate[128];
		Format(STRING(translate), "%T", "Command_NotAvailable", LANG_SERVER);
		PrintToServer(translate);
		return Plugin_Handled;
	}

	if(rp_GetEventType() != event_type_none)
	{
		char translate[128];
		Format(STRING(translate), "%T", "Command_HudEvent", LANG_SERVER);
		CPrintToChat(client, "%s %s", TEAM, translate);
	}
	else
	{	
		if (rp_GetClientBool(client, b_menuOpen))
		{
			rp_SetClientBool(client, b_menuOpen, false);
			char translate[128];
			Format(STRING(translate), "%T", "Command_HudDisplay", LANG_SERVER);
			CPrintToChat(client, "%s %s", TEAM, translate);
		}
		else
		{
			rp_SetClientBool(client, b_menuOpen, true);
			char translate[128];
			Format(STRING(translate), "%T", "Command_HudHide", LANG_SERVER);
			CPrintToChat(client, "%s %s", TEAM, translate);
		}
	}	
	
	return Plugin_Handled;
}

public void OnMapStart() 
{
	CreateTimer(1.0, updatePrintText, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action updatePrintText(Handle Timer) 
{
	for (int client = 1; client < MAXPLAYERS; client++) {
		if (IsClientValid(client))	
			showAllHudMessages(client);
	}
}

public Action updateHUD(Handle Timer) 
{
	for (int client = 1; client < MAXPLAYERS; client++) 
	{		
		if (IsClientValid(client))
		{			
			if(!rp_GetClientBool(client, b_isEventParticipant))
			{
				if (!rp_GetClientBool(client, b_menuOpen) && !rp_GetClientBool(client, b_isAfk))
				{					
					if(rp_GetDatabase() != null)
					{
						if(GetVehicle(client) == -1)
						{
							char name[32], grade[16], groupename[64];	
							
							GetJobName(rp_GetClientInt(client, i_Job), STRING(name));
							GetGradeName(rp_GetClientInt(client, i_Grade), rp_GetClientInt(client, i_Job), STRING(grade));
							
							int target = GetClientAimTarget(client, false);
							if(IsValidEntity(target))
							{					
								char HudTarget[128];
								
								if(IsClientValid(target))
								{
									char jobName_Target[32], gradeName_Target[16];
									GetJobName(rp_GetClientInt(target, i_Job), STRING(jobName_Target));
								    GetGradeName(rp_GetClientInt(target, i_Grade), rp_GetClientInt(target, i_Job), STRING(gradeName_Target));

									char strName[32], groupename_T[64];
									GetClientName(target, STRING(strName));
									rp_GetGroupString(rp_GetClientInt(client, i_Group), group_type_name, STRING(groupename_T));
									
									if (rp_GetClientInt(target, i_Job) == 1)
									{
										if(GetClientTeam(target) == CS_TEAM_T)
										{
											if(rp_GetClientInt(target, i_Group) == 0)
												Format(STRING(HudTarget), "%T", "Hud_Target_NoGang", LANG_SERVER, strName, GetClientHealth(target), "Sans Emploi", "");
											else	
												Format(STRING(HudTarget), "%T", "Hud_Target_Gang", LANG_SERVER, strName, GetClientHealth(target), "Sans Emploi", "", groupename_T);	
										}
										else if(GetClientTeam(target) == CS_TEAM_CT)
										{
											if(rp_GetClientInt(target, i_Group) == 0)
												Format(STRING(HudTarget), "%T", "Hud_Target_NoGang", LANG_SERVER, strName, GetClientHealth(target), gradeName_Target, jobName_Target);
											else	
												Format(STRING(HudTarget), "%T", "Hud_Target_Gang", LANG_SERVER, strName, GetClientHealth(target), gradeName_Target, jobName_Target, groupename_T);
										}
									}
									else 
									{
										if(rp_GetClientInt(target, i_Group) == 0)
											Format(STRING(HudTarget), "%T", "Hud_Target_NoGang", LANG_SERVER, strName, GetClientHealth(target), gradeName_Target, jobName_Target);
										else	
											Format(STRING(HudTarget), "%T", "Hud_Target_Gang", LANG_SERVER, strName, GetClientHealth(target), gradeName_Target, jobName_Target, groupename_T);
									}			
									PrintHintText(client, HudTarget);
								}	
								
								char entName[64], entClass[64];
								Entity_GetName(target, STRING(entName));
								Entity_GetClassName(target, STRING(entClass));
								
								if(StrEqual(entClass, "prop_vehicle_driveable"))
								{
									PrintHintText(client, "Voiture de %N\nHP: %0.1f", rp_GetVehicleInt(target, car_owner), rp_GetVehicleFloat(target, car_health));
								}	
							}	
							
							Panel panel = new Panel();
							char strText[128];
								
							
							Format(STRING(strText), "VR Hosting - Roleplay (%s Pre-Alpha)", VERSION);			
							panel.SetTitle(strText);			
							panel.DrawText("─────────────────────────");
									
							Format(STRING(strText), "%T", "Hud_Money", LANG_SERVER, rp_GetClientInt(client, i_Money));
							panel.DrawText(strText);
							
							Format(STRING(strText), "%T", "Hud_Bank", LANG_SERVER, rp_GetClientInt(client, i_Bank));
							panel.DrawText(strText);
							
							panel.DrawText("                                  ");
							
							Format(STRING(strText), "%T", "Hud_Job", LANG_SERVER, grade, name);
							panel.DrawText(strText);
							
							Format(STRING(strText), "%T", "Hud_Salary", LANG_SERVER, rp_GetClientInt(client, i_Salaire));							
							panel.DrawText(strText);
										
							if(rp_GetClientInt(client, i_Grade) == 1)
							{
								Format(STRING(strText), "%T", "Hud_Capital", LANG_SERVER, rp_GetJobCapital(rp_GetClientInt(client, i_Job)));
								panel.DrawText(strText);
							}
							
							Format(STRING(strText), "- Faim: %0.1f%", rp_GetClientFloat(client, fl_Faim));							
							panel.DrawText(strText);
							
							panel.DrawText("                                  ");
							if(rp_GetClientInt(client, i_Group) != 0)
							{
								rp_GetGroupString(rp_GetClientInt(client, i_Group), group_type_name, STRING(groupename));
								Format(STRING(strText), "%T", "Hud_Gang", LANG_SERVER, groupename);
								panel.DrawText(strText);
							}
			
							char zonename[128];
							rp_GetClientString(client, sz_Zone, STRING(zonename));
							
							Format(STRING(strText), "%T", "Hud_Zone", LANG_SERVER, zonename);							
							panel.DrawText(strText);	
							
							char monthname[12];
							GetMonthName(rp_GetTime(i_month), STRING(monthname));		
							
							Format(STRING(strText), "%T", "Hud_Time", LANG_SERVER, rp_GetTime(i_hour1), rp_GetTime(i_hour2), rp_GetTime(i_minute1), rp_GetTime(i_minute2), rp_GetTime(i_day), monthname, rp_GetTime(i_year));
							panel.DrawText(strText);	
									
							panel.DrawText("─────────────────────────");
							panel.Send(client, Handler_NullCancel, 1);
						}	
						else
						{
							int voiture = GetVehicle(client);
							int vitesse = GetEntProp(voiture, Prop_Data, "m_nSpeed");
							
							char brand[64], specs[64], horsepower[64], newton[64];
							GetVehicleInfo(voiture, brand, specs, horsepower, newton);
							
							Panel panel = new Panel();
							char strText[128];
										
							panel.SetTitle(brand);
							Format(STRING(strText), "────────────%iKM/H───────────", vitesse);
							panel.DrawText(strText);
							
							Format(STRING(strText), "- Specs : %s", specs);								
							panel.DrawText(strText);	
							
							Format(STRING(strText), "- Chevaux : %i", rp_GetVehicleInt(voiture, car_horsepower));								
							panel.DrawText(strText);	
							
							/*Format(STRING(strText), "- Couple : %s", newton);								
							panel.DrawText(strText);	*/
							
							if(rp_GetVehicleInt(voiture, car_fueltype) == 1) 
								Format(STRING(strText), "- Carburant : Essence(%0.1fL)", rp_GetVehicleFloat(voiture, car_fuel));
							else
								Format(STRING(strText), "- Carburant : Diesel(%0.1fL)", rp_GetVehicleFloat(voiture, car_fuel));						
							panel.DrawText(strText);
	
							char condition[32];
							if(rp_GetVehicleFloat(voiture, car_health) > 75.0)
								Format(STRING(condition), "Neuf");
							else if(rp_GetVehicleFloat(voiture, car_health) > 25.0)
								Format(STRING(condition), "Testé");	
							else if(rp_GetVehicleFloat(voiture, car_health) < 25.0)
								Format(STRING(condition), "Usée");	
							
							if(rp_GetVehicleFloat(voiture, car_health) != 0.0)
								Format(STRING(strText), "- État : %s (%0.1f)", condition, rp_GetVehicleFloat(voiture, car_health));			
							else
								Format(STRING(strText), "! Voiture en panne !");										
							panel.DrawText(strText);
							
							Format(STRING(strText), "- Distance : %0.1fKM's", rp_GetVehicleFloat(voiture, car_km));						
							panel.DrawText(strText);
							
							panel.DrawText("─────────────────────────");
							
							panel.Send(client, Handler_NullCancel, 1);
						}
					}
					else
					{
						Panel panel = new Panel();
						char strText[128];
						
						Format(STRING(strText), "VR Hosting - Roleplay (%s Magic)", VERSION);			
						panel.SetTitle(strText);			
						panel.DrawText("─────────────────────────");
							
						panel.DrawText("MySQL Server: Error");
							
						panel.DrawText("─────────────────────────");
						panel.Send(client, Handler_NullCancel, 1);
						
					}							
				}
			}
			else
				TrashTimer(g_hTimerHUD[client], true);			
		}	
		else if (!IsClientValid(client))
			TrashTimer(g_hTimerHUD[client], true);
	}
}

void showAllHudMessages(int client) 
{
	showHudMsg(client, "Roleplay CS:GO\nBy VR-Hosting.fr", 25, 188, 212, 0.01, 0.01, 1.05);
}

public void showHudMsg(int client, char[] message, int r, int g, int b, float x, float y, float timeout) 
{
	SetHudTextParams(x, y, timeout, r, g, b, 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, -1, message);
}

public bool isValidRef(int ref) 
{
	int index = EntRefToEntIndex(ref);
	if (index > MaxClients && IsValidEntity(index)) {
		return true;
	}
	return false;
}

stock int getClientViewClient(int client) 
{
	float m_vecOrigin[3];
	float m_angRotation[3];
	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);
	Handle tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	int pEntity = -1;
	if (TR_DidHit(tr)) 
	{
		pEntity = TR_GetEntityIndex(tr);
		delete tr;
		if (!IsClientValid(client))
			return -1;
		if (!IsValidEntity(pEntity))
			return -1;
		if (!IsClientValid(pEntity))
			return -1;
		float playerPos[3];
		float entPos[3];
		GetClientAbsOrigin(client, playerPos);
		GetEntPropVector(pEntity, Prop_Data, "m_vecOrigin", entPos);
		if (GetVectorDistance(playerPos, entPos) > 500.0)
			return -1;
		return pEntity;
	}
	delete tr;
	return -1;
}