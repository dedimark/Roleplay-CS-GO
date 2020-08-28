/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://www.revolution-team.be - benitalpa1020@gmail.com
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

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
GlobalForward g_OnBuild;
GlobalForward g_HandleOnBuild;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Build", 
	author = "Benito", 
	description = "Options des métiers", 
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
		g_OnBuild = new GlobalForward("rp_MenuBuild", ET_Event, Param_Cell, Param_Cell);
		g_HandleOnBuild = new GlobalForward("rp_HandlerMenuBuild", ET_Event, Param_Cell, Param_String);	
		RegConsoleCmd("b", Cmd_Build);
		RegConsoleCmd("build", Cmd_Build);
	}	
	else
		UnloadPlugin();
}

public Action Cmd_Build(int client, int args)
{
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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", TEAM);
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