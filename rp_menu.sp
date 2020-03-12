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
	url = "www.revolution-asso.eu"
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
		menu.SetTitle("Roleplay - Revolution");
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
		menu.GetItem(param, info, sizeof(info));
		
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