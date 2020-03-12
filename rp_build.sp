#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <roleplay>
#include <multicolors>

#pragma newdecls required

#define NAME "{yellow}[{green}Roleplay{yellow}]{default}"

GlobalForward g_OnBuild;
GlobalForward g_HandleOnBuild;

public Plugin myinfo = 
{
	name = "[Roleplay] Build", 
	author = "Benito", 
	description = "Options des métiers", 
	version = "1.0", 
	url = "www.revolution-asso.eu"
};

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
		CPrintToChat(client, "%s Vous n'avez pas accès à cette commande.", NAME);
}	

public int DoMenuBuild(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, info, sizeof(info));
		
		Call_StartForward(g_HandleOnBuild);
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