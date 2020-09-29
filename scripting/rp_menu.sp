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
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/***************************************************************************************

							G L O B A L  -  V A R S

***************************************************************************************/
GlobalForward g_OnMenuPrincipal;
GlobalForward g_HandleOnMenuPrincipal;

GlobalForward g_OnMenuSettings;
GlobalForward g_HandleOnMenuSettings;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Menu Général",
	author = "Benito",
	description = "Menu Roleplay + Forwards",
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
		
	g_OnMenuPrincipal = new GlobalForward("RP_OnPlayerRoleplay", ET_Event, Param_Cell, Param_Cell);
	g_HandleOnMenuPrincipal = new GlobalForward("RP_OnPlayerRoleplayHandle", ET_Event, Param_Cell, Param_String);
	
	g_OnMenuSettings = new GlobalForward("RP_OnPlayerSettings", ET_Event, Param_Cell, Param_Cell);
	g_HandleOnMenuSettings = new GlobalForward("RP_OnPlayerSettingsHandle", ET_Event, Param_Cell, Param_String);
		
	RegConsoleCmd("rp", Cmd_Roleplay);
	RegConsoleCmd("roleplay", Cmd_Roleplay);
}

public void rp_OnLicenceLoaded(bool licenceValid)
{
	if(!licenceValid)
		UnloadPlugin();
}

public Action Cmd_Roleplay(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("Commande disponible uniquement en jeu !");
		return Plugin_Handled;
	}

	if(IsClientValid(client))
	{
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu = new Menu(DoMenuRoleplay);
		menu.SetTitle("Roleplay - Menu Principal");
		Call_StartForward(g_OnMenuPrincipal);
		Call_PushCell(client);
		Call_PushCell(menu);
		Call_Finish();	
		menu.AddItem("settings", "Paramètres");
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}	
	
	return Plugin_Handled;
}

public int DoMenuRoleplay(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		Call_StartForward(g_HandleOnMenuPrincipal);
		Call_PushCell(client);
		Call_PushString(info);
		Call_Finish();		
		
		if(StrEqual(info, "settings"))
			MenuSettings(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu MenuSettings(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuSettings);
	menu.SetTitle("Paramètres");
	
	Call_StartForward(g_OnMenuSettings);
	Call_PushCell(client);
	Call_PushCell(menu);
	Call_Finish();	
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuSettings(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		Call_StartForward(g_HandleOnMenuSettings);
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