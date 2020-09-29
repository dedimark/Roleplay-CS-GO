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
#include <cstrike>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
char logFile[PLATFORM_MAX_PATH];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - 18TH", 
	author = "Benito", 
	description = "Métier 18th", 
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
	
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/jobs/rp_job_18th.log");
}

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	if(StrEqual(entityName, "coffre_18th"))
		Coffre(client);	
}	

Menu Coffre(int client)
{	
	if(rp_GetClientInt(client, i_Job) == 3)
	{
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu = new Menu(DoMenuCoffre);
		menu.SetTitle("Coffre 18TH :");	
		
		if(rp_GetClientBool(client, b_asCrowbar))
			menu.AddItem("piedbiche", "Ranger le pied-de-biche");
		else
			menu.AddItem("piedbiche", "Prendre un pied-de-biche");		
		
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
		CPrintToChat(client, "%s Vous n'avez pas accès au coffre de la 18TH.", TEAM);	
}

public int DoMenuCoffre(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "piedbiche"))
		{
			if(rp_GetClientBool(client, b_asCrowbar))
			{
				CPrintToChat(client, "%s Vous avez ranger votre pied-de-biche.", TEAM);
				rp_SetClientBool(client, b_asCrowbar, false);
			}
			else
			{
				CPrintToChat(client, "%s Vous avez recupéré un pied-de-biche.", TEAM);
				rp_SetClientBool(client, b_asCrowbar, true);
			}	
		}
		rp_SetClientBool(client, b_menuOpen, false);		
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}