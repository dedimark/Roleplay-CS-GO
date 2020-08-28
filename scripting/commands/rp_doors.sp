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

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Unlock & Lock",
	author = "Benito",
	description = "Ouvrir et fermer les portes",
	version = VERSION,
	url = "www.revolution-team.be"
};

/***************************************************************************************

							P L U G I N  -  E V E N T S

***************************************************************************************/
public void OnPluginStart()
{
	RegConsoleCmd("unlock", Cmd_Unlock);
	RegConsoleCmd("open", Cmd_Unlock);
	RegConsoleCmd("ouvrir", Cmd_Unlock);
	
	RegConsoleCmd("fermer", Cmd_Lock);
	RegConsoleCmd("lock", Cmd_Lock);
	RegConsoleCmd("verrouiller", Cmd_Lock);
}

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
		
		char entName[128];
		GetEntityClassname(aim, STRING(entName));
		
		int job = rp_GetClientInt(client, i_Job);
		int grade = rp_GetClientInt(client, i_Grade);
		
		int hID = Entity_GetHammerId(aim);
		
		if(StrContains(entClass, "door") != -1)
		{
			if(job != 0)
			{
				if(Entity_IsLocked(aim))
				{
					if(job == 1 && GetDoorsAcces(client, 1, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 2 && GetDoorsAcces(client, 2, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 3 && GetDoorsAcces(client, 3, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 4 && GetDoorsAcces(client, 4, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 5 && GetDoorsAcces(client, 5, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 6 && GetDoorsAcces(client, 6, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 7 && GetDoorsAcces(client, 7, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 8 && GetDoorsAcces(client, 8, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 9 && GetDoorsAcces(client, 9, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 10 && GetDoorsAcces(client, 10, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 11 && GetDoorsAcces(client, 11, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 12 && GetDoorsAcces(client, 12, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 13 && GetDoorsAcces(client, 13, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 14 && GetDoorsAcces(client, 14, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 15 && GetDoorsAcces(client, 15, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 16 && GetDoorsAcces(client, 16, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 17 && GetDoorsAcces(client, 17, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 18 && GetDoorsAcces(client, 18, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 19 && GetDoorsAcces(client, 19, grade, hID))	
						Entity_UnLock(aim);
					else if(job == 20 && GetDoorsAcces(client, 20, grade, hID))	
						Entity_UnLock(aim);	
						
					PrintHintText(client, "<font color='#00ff95'>Porte déverrouillée</font>");	
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
		
		if(StrContains(entClass, "door") != -1)
		{
			char entName[128];
			GetEntityClassname(aim, STRING(entName));
			
			int hID = Entity_GetHammerId(aim);
		
			int job = rp_GetClientInt(client, i_Job);
			int grade = rp_GetClientInt(client, i_Job);
			
			if(job != 0)
			{
				if(!Entity_IsLocked(aim))
				{
					if(job == 1 && GetDoorsAcces(client, 1, grade, hID))	
						Entity_Lock(aim);
					else if(job == 2 && GetDoorsAcces(client, 2, grade, hID))	
						Entity_Lock(aim);
					else if(job == 3 && GetDoorsAcces(client, 3, grade, hID))	
						Entity_Lock(aim);
					else if(job == 4 && GetDoorsAcces(client, 4, grade, hID))	
						Entity_Lock(aim);
					else if(job == 5 && GetDoorsAcces(client, 5, grade, hID))	
						Entity_Lock(aim);
					else if(job == 6 && GetDoorsAcces(client, 6, grade, hID))	
						Entity_Lock(aim);
					else if(job == 7 && GetDoorsAcces(client, 7, grade, hID))	
						Entity_Lock(aim);
					else if(job == 8 && GetDoorsAcces(client, 8, grade, hID))	
						Entity_Lock(aim);
					else if(job == 9 && GetDoorsAcces(client, 9, grade, hID))	
						Entity_Lock(aim);
					else if(job == 10 && GetDoorsAcces(client, 10, grade, hID))	
						Entity_Lock(aim);
					else if(job == 11 && GetDoorsAcces(client, 11, grade, hID))	
						Entity_Lock(aim);
					else if(job == 12 && GetDoorsAcces(client, 12, grade, hID))	
						Entity_Lock(aim);
					else if(job == 13 && GetDoorsAcces(client, 13, grade, hID))	
						Entity_Lock(aim);
					else if(job == 14 && GetDoorsAcces(client, 14, grade, hID))	
						Entity_Lock(aim);
					else if(job == 15 && GetDoorsAcces(client, 15, grade, hID))	
						Entity_Lock(aim);
					else if(job == 16 && GetDoorsAcces(client, 16, grade, hID))	
						Entity_Lock(aim);
					else if(job == 17 && GetDoorsAcces(client, 17, grade, hID))	
						Entity_Lock(aim);
					else if(job == 18 && GetDoorsAcces(client, 18, grade, hID))	
						Entity_Lock(aim);
					else if(job == 19 && GetDoorsAcces(client, 19, grade, hID))	
						Entity_Lock(aim);
					else if(job == 20 && GetDoorsAcces(client, 20, grade, hID))	
						Entity_Lock(aim);							
						
					PrintHintText(client, "<font color='#00ff95'>Porte verrouillée</font>");	
				}	
				else
					CPrintToChat(client, "%s La porte est déjà verrouillée", TEAM);
			}	
		}	
		else
			CPrintToChat(client, "%s Vous devez viser une porte.", TEAM);
	}	
	else
		CPrintToChat(client, "%s Vous devez viser une entité valide.", TEAM);
			
	return Plugin_Handled;
}	