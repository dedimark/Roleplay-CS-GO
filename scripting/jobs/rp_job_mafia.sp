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

							G L O B A L  -  D E F I N E S

***************************************************************************************/
#define MAX_KIT 5

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
char logFile[PLATFORM_MAX_PATH];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Mafia", 
	author = "Benito", 
	description = "Métier Mafia", 
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
	
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/jobs/rp_job_mafia.log");
}

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	if(StrEqual(entityName, "coffre_mafia"))
		Coffre(client);	
}	

Menu Coffre(int client)
{	
	if(rp_GetClientInt(client, i_Job) == 2)
	{
		char strMenu[64];
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu = new Menu(DoMenuCoffre);
		menu.SetTitle("Coffre Mafia Japonaise :");	
		
		if(rp_GetClientBool(client, b_asCrowbar))
			menu.AddItem("piedbiche", "Ranger le pied-de-biche");
		else
			menu.AddItem("piedbiche", "Prendre un pied-de-biche");		
			
		if(rp_GetClientInt(client, i_KitCrochetage) != MAX_KIT)
			menu.AddItem("kit", "Prendre un kit de crochetage");
		else
		{
			Format(STRING(strMenu), "Prendre un kit de crochetage(%i MAX)", MAX_KIT);		
			menu.AddItem("", strMenu, ITEMDRAW_DISABLED);		
		}	
		
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
		CPrintToChat(client, "%s Vous n'avez pas accès au coffre de la mafia japonaise.", TEAM);	
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
		else if(StrEqual(info, "kit"))
		{
			rp_SetClientInt(client, i_KitCrochetage, rp_GetClientInt(client, i_KitCrochetage) + 1);
			CPrintToChat(client, "%s Vous avez recupéré un kit de crochetage %i/%i.", TEAM, rp_GetClientInt(client, i_KitCrochetage), MAX_KIT);
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