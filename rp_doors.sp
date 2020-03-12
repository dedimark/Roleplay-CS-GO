#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <roleplay>
#include <devzones>
#include <multicolors>

#define NAME "{yellow}[{green}Roleplay{yellow}]{default}"

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[Roleplay] Unlock & Lock",
	author = "Benito",
	description = "Ouvrir et fermer les portes",
	version = "1.0",
	url = "www.revolution-asso.eu"
};

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
	
	char zone[64];
	Zone_getMostRecentActiveZone(client, zone);
	
	int aim = GetAimEnt(client, false);
	if(IsValidEntity(aim))
	{		
		char entClass[128];
		GetEntityClassname(aim, entClass, sizeof(entClass));
		
		char entName[128];
		GetEntityClassname(aim, entName, sizeof(entName));
		
		int job = rp_GetClientInt(client, i_Job);
		
		if(StrContains(entClass, "door") != -1)
		{
			if(job != 0)
			{
				if(job == 1 && StrContains(zone, "R.V.P.D") != -1 || StrContains(entName, "porte_police_") != -1)
					Entity_UnLock(aim);
				else if(job == 2 && StrContains(zone, "Mafia") != -1 || StrContains(entName, "porte_chinese_") != -1)
					Entity_UnLock(aim);
				else if(job == 3 && StrContains(zone, "18th") != -1 || StrContains(entName, "porte_18th_") != -1)
					Entity_UnLock(aim);
				else if(job == 4 && StrContains(zone, "Hopital") != -1 || StrContains(entName, "porte_hopital_") != -1)
					Entity_UnLock(aim);
				else if(job == 5 && StrContains(zone, "Mairie") != -1 || StrContains(entName, "porte_mairie_") != -1)
					Entity_UnLock(aim);
				else if(job == 6 && StrContains(zone, "Armurerie") != -1 || StrContains(entName, "porte_armurerie_") != -1)
					Entity_UnLock(aim);
				else if(job == 7 && StrContains(zone, "Justice") != -1 || StrContains(entName, "porte_tribunal_") != -1)
					Entity_UnLock(aim);
				else if(job == 8 && StrContains(zone, "Immo") != -1 || StrContains(entName, "porte_immo_") != -1)
					Entity_UnLock(aim);
				else if(job == 9 && StrContains(zone, "Immo") != -1 || StrContains(entName, "porte_dealer_") != -1)
					Entity_UnLock(aim);
				else if(job == 10 && StrContains(zone, "tech") != -1 || StrContains(entName, "porte_tech_") != -1)
					Entity_UnLock(aim);
				else if(job == 11 && StrContains(zone, "banq") != -1 || StrContains(entName, "porte_bank_") != -1)
					Entity_UnLock(aim);
				else if(job == 12 && StrContains(zone, "tueur") != -1 || StrContains(entName, "porte_tueur_") != -1)
					Entity_UnLock(aim);
				else if(job == 13 && StrContains(zone, "marche") != -1 || StrContains(entName, "porte_marchenoir_") != -1)
					Entity_UnLock(aim);
				else if(job == 14 && StrContains(zone, "tabac") != -1 || StrContains(entName, "porte_tabac_") != -1)
					Entity_UnLock(aim);
				else if(job == 15 && StrContains(zone, "Macdo") != -1 || StrContains(entName, "porte_mcdo_") != -1)
					Entity_UnLock(aim);	
					
				PrintHintText(client, "<font color='#00ff95'>Porte déverrouillée</font>");	
			}	
		}	
		else
			CPrintToChat(client, "%s Vous devez viser une porte.", NAME);
	}	
	else
		CPrintToChat(client, "%s Vous devez viser une entité valide.", NAME);
			
	return Plugin_Handled;
}	

public Action Cmd_Lock(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu.");
		return Plugin_Handled;
	}	
	
	char zone[64];
	Zone_getMostRecentActiveZone(client, zone);
	
	int aim = GetAimEnt(client, false);
	if(IsValidEntity(aim))
	{		
		char entClass[128];
		GetEntityClassname(aim, entClass, sizeof(entClass));
		
		char entName[128];
		GetEntityClassname(aim, entName, sizeof(entName));
		
		int job = rp_GetClientInt(client, i_Job);
		
		if(StrContains(entClass, "door") != -1)
		{
			if(job != 0)
			{
				if(job == 1 && StrContains(zone, "R.V.P.D") != -1 || StrContains(entName, "porte_police_") != -1)
					Entity_Lock(aim);
				else if(job == 2 && StrContains(zone, "Mafia") != -1 || StrContains(entName, "porte_chinese_") != -1)
					Entity_Lock(aim);
				else if(job == 3 && StrContains(zone, "18th") != -1 || StrContains(entName, "porte_18th_") != -1)
					Entity_Lock(aim);
				else if(job == 4 && StrContains(zone, "Hopital") != -1 || StrContains(entName, "porte_hopital_") != -1)
					Entity_Lock(aim);
				else if(job == 5 && StrContains(zone, "Mairie") != -1 || StrContains(entName, "porte_mairie_") != -1)
					Entity_Lock(aim);
				else if(job == 6 && StrContains(zone, "Armurerie") != -1 || StrContains(entName, "porte_armurerie_") != -1)
					Entity_Lock(aim);
				else if(job == 7 && StrContains(zone, "Justice") != -1 || StrContains(entName, "porte_tribunal_") != -1)
					Entity_Lock(aim);
				else if(job == 8 && StrContains(zone, "Immo") != -1 || StrContains(entName, "porte_immo_") != -1)
					Entity_Lock(aim);
				else if(job == 9 && StrContains(zone, "Immo") != -1 || StrContains(entName, "porte_dealer_") != -1)
					Entity_Lock(aim);
				else if(job == 10 && StrContains(zone, "tech") != -1 || StrContains(entName, "porte_tech_") != -1)
					Entity_Lock(aim);
				else if(job == 11 && StrContains(zone, "banq") != -1 || StrContains(entName, "porte_bank_") != -1)
					Entity_Lock(aim);
				else if(job == 12 && StrContains(zone, "tueur") != -1 || StrContains(entName, "porte_tueur_") != -1)
					Entity_Lock(aim);
				else if(job == 13 && StrContains(zone, "marche") != -1 || StrContains(entName, "porte_marchenoir_") != -1)
					Entity_Lock(aim);
				else if(job == 14 && StrContains(zone, "tabac") != -1 || StrContains(entName, "porte_tabac_") != -1)
					Entity_Lock(aim);
				else if(job == 15 && StrContains(zone, "Macdo") != -1 || StrContains(entName, "porte_mcdo_") != -1)
					Entity_Lock(aim);	
					
				PrintHintText(client, "<font color='#00ff95'>Porte verrouillée</font>");	
			}	
		}	
		else
			CPrintToChat(client, "%s Vous devez viser une porte.", NAME);
	}	
	else
		CPrintToChat(client, "%s Vous devez viser une entité valide.", NAME);
			
	return Plugin_Handled;
}	