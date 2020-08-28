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

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <roleplay>
#include <smlib>

#pragma newdecls required

GlobalForward g_OnMenuPrincipal;
GlobalForward g_HandleOnMenuPrincipal;

public Plugin myinfo = 
{
	name = "[Roleplay] Menu Général",
	author = "Benito",
	description = "Menu Roleplay + Forwards",
	version = "1.10",
	url = URL
};

public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		g_OnMenuPrincipal = new GlobalForward("rp_MenuRoleplay", ET_Event, Param_Cell, Param_Cell);
		g_HandleOnMenuPrincipal = new GlobalForward("rp_HandlerMenuRoleplay", ET_Event, Param_Cell, Param_String);
		
		RegConsoleCmd("rp", Cmd_Roleplay);
		RegConsoleCmd("roleplay", Cmd_Roleplay);
	}	
	else
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
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}