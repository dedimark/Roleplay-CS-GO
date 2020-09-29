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
#include <cstrike>
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
GlobalForward g_OnMenuInventory;
GlobalForward g_HandleOnMenuInventory;

int item[MAXPLAYERS + 1][MAXITEMS + 1];
char item_data[MAXITEMS + 1][rp_item_type][64];
bool canUseItem[MAXPLAYERS + 1][MAXITEMS + 1];
bool itemOnTimerReset[MAXPLAYERS + 1][MAXITEMS + 1];
char steamID[MAXPLAYERS + 1][32];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Item",
	author = "Benito",
	description = "Système d'item pour le roleplay",
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
		
	g_OnMenuInventory = new GlobalForward("RP_OnPlayerInventory", ET_Event, Param_Cell, Param_Cell);
	g_HandleOnMenuInventory = new GlobalForward("RP_OnPlayerInventoryHandle", ET_Event, Param_Cell, Param_String);
	RegConsoleCmd("rp_allitem", Cmd_GiveItems);
	RegConsoleCmd("inv", Cmd_Inventory);
	RegConsoleCmd("item", Cmd_Inventory);
	RegConsoleCmd("sac", Cmd_Inventory);
	
	SetItemID();
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPutInServer(int client)
{
	for (int id = 0; id <= MAXITEMS; id++)
	{
		rp_ClientGiveItem(client, id, 0);
		rp_SetCanUseItem(client, id, true);
		rp_SetClientDelayItemStat(client, id, false);
	}	
}			

public void OnPluginEnd()
{
	SaveClient();
}

public void RP_OnPlayerDisconnect(int client)
{
	SaveClient();
}	

public void OnMapEnd()
{
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_price[64];
		rp_GetItemData(i, item_type_prix, STRING(item_price));
		
		rp_SetPrice(i, item_price);
	}	
	SaveClient();
}

void SaveClient()
{
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_price[64];
		rp_GetItemData(i, item_type_prix, STRING(item_price));		
		rp_SetPrice(i, item_price);
		
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
			
		LoopClients(player)
		{	
			if(StrEqual(item_jobid, "4"))
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_hopital` SET `%i` = '%i' WHERE steamid = '%s';", i, rp_GetClientItem(player, i), steamID[player]);
			else if(StrEqual(item_jobid, "6"))
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_armurier` SET `%i` = '%i' WHERE steamid = '%s';", i, rp_GetClientItem(player, i), steamID[player]);
			else if(StrEqual(item_jobid, "8"))
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_immobilier` SET `%i` = '%i' WHERE steamid = '%s';", i, rp_GetClientItem(player, i), steamID[player]);	
			else if(StrEqual(item_jobid, "9"))
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_dealer` SET `%i` = '%i' WHERE steamid = '%s';", i, rp_GetClientItem(player, i), steamID[player]);
			else if(StrEqual(item_jobid, "10"))
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_technicien` SET `%i` = '%i' WHERE steamid = '%s';", i, rp_GetClientItem(player, i), steamID[player]);	
			else if(StrEqual(item_jobid, "13"))
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_artificier` SET `%i` = '%i' WHERE steamid = '%s';", i, rp_GetClientItem(player, i), steamID[player]);	
			else if(StrEqual(item_jobid, "14"))
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_vendeurdeskin` SET `%i` = '%i' WHERE steamid = '%s';", i, rp_GetClientItem(player, i), steamID[player]);	
			else if(StrEqual(item_jobid, "16"))
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_loto` SET `%i` = '%i' WHERE steamid = '%s';", i, rp_GetClientItem(player, i), steamID[player]);			
			else if(StrEqual(item_jobid, "18"))
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_sexshop` SET `%i` = '%i' WHERE steamid = '%s';", i, rp_GetClientItem(player, i), steamID[player]);		
			else if(StrEqual(item_jobid, "20"))
				UpdateSQL(rp_GetDatabase(), "UPDATE `rp_concessionnaire` SET `%i` = '%i' WHERE steamid = '%s';", i, rp_GetClientItem(player, i), steamID[player]);			
		}		
	}
}		

void SetItemID()
{
	KeyValues kv = new KeyValues("Items");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sPath), "configs/roleplay/items.cfg");
	
	if(!kv.ImportFromFile(sPath))
	{
		delete kv;
		PrintToServer("configs/roleplay/items.cfg : NOT FOUND");
	}	
	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_string[32];
		IntToString(i, STRING(item_string));
		if(kv.JumpToKey(item_string))
		{	
			char item_name[64];
			kv.GetString("item_name", STRING(item_name));	
			rp_SetItemData(i, item_type_name, STRING(item_name));
			
			char item_reuse_delay[12];
			kv.GetString("item_reuse_delay", STRING(item_reuse_delay));
			rp_SetItemData(i, item_type_reuse_delay, STRING(item_reuse_delay));
			
			char item_job_id[64];
			kv.GetString("item_job_id", STRING(item_job_id));
			rp_SetItemData(i, item_type_job_id, STRING(item_job_id));
			
			char item_price[64];
			kv.GetString("item_price", STRING(item_price));
			rp_SetItemData(i, item_type_prix, STRING(item_price));
			
			char item_taxes[64];
			kv.GetString("item_taxes", STRING(item_taxes));
			rp_SetItemData(i, item_type_taxes, STRING(item_taxes));

			kv.GoBack();
		}			
	}
	
	kv.Rewind();	
	delete kv;
}	

public Action Cmd_GiveItems(int client, int args)
{
	if(IsClientValid(client) && rp_GetClientInt(client, i_AdminLevel) == 1)
	{
		for(int i = 1; i <= MAXITEMS; i++)
			item[client][i] += 10;
	}	
}	

public void RP_OnPlayerSpawn(int client)
{
	rp_SetClientBool(client, b_canItem, true);
}	

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	CreateNative("rp_GetClientItem", Native_GetClientItem);
	CreateNative("rp_ClientGiveItem", Native_ClientGiveItem);
	
	CreateNative("rp_GetItemData", Native_GetItemData);
	CreateNative("rp_SetItemData", Native_SetItemData);
	
	CreateNative("rp_GetCanUseItem", Native_GetCanUseItem);
	CreateNative("rp_SetCanUseItem", Native_SetCanUseItem);
	
	CreateNative("rp_SetClientDelayItemStat", Native_SetClientDelayItemStat);
}

public int Native_GetClientItem(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	
	if(!IsClientValid(client))
		return -1;
	
	return item[client][itemid];
}

public int Native_ClientGiveItem(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	int value = GetNativeCell(3);
	
	if(!IsClientValid(client))
		return -1;
	
	return item[client][itemid] = value;
}

public int Native_GetItemData(Handle plugin, int numParams) 
{
	int itemID = GetNativeCell(1);
	rp_item_type variable = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
			
	SetNativeString(3, item_data[itemID][variable], maxlen);
	return -1;
}

public int Native_SetItemData(Handle plugin, int numParams) 
{
	int itemID = GetNativeCell(1);
	rp_item_type variable = GetNativeCell(2);
	int maxlen = GetNativeCell(4) + 1;
			
	GetNativeString(3, item_data[itemID][variable], maxlen);
	return -1;
}

public int Native_GetCanUseItem(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	int itemID = GetNativeCell(2);			
	
	return canUseItem[client][itemID];
}

public int Native_SetCanUseItem(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	int itemID = GetNativeCell(2);
	bool value = view_as<bool>(GetNativeCell(3));			
	
	return canUseItem[client][itemID] = value;
}

public int Native_SetClientDelayItemStat(Handle plugin, int numParams) 
{
	int client = GetNativeCell(1);
	int itemID = GetNativeCell(2);
	bool value = view_as<bool>(GetNativeCell(3));			
	
	return itemOnTimerReset[client][itemID] = value;
}

public Action RP_OnPlayerRoleplay(int client, Menu menu)
{
	if(rp_GetClientBool(client, b_canItem))
		menu.AddItem("inv", "Inventaire");
	else
		menu.AddItem("", "Inventaire", ITEMDRAW_DISABLED);	
}

public int RP_OnPlayerRoleplayHandle(int client, const char[] info)
{
	if(StrEqual(info, "inv"))
		BuildInventory(client);
}	

public Action Cmd_Inventory(int client, int args)
{
	if (client == 0)
	{
		char translate[128];
		Format(STRING(translate), "%T", "Command_NotAvailable", LANG_SERVER);
		PrintToServer(translate);
		return Plugin_Handled;
	}
	
	if(IsClientValid(client))
		BuildInventory(client);
		
	return Plugin_Handled;
}		

int BuildInventory(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);	
	Menu menu = new Menu(DoBuildInventory);	
	menu.SetTitle("Sélectionner un objet à utiliser :");	
	Call_StartForward(g_OnMenuInventory);
	Call_PushCell(client);
	Call_PushCell(menu);
	Call_Finish();	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);	
}	

public int DoBuildInventory(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		Call_StartForward(g_HandleOnMenuInventory);
		Call_PushCell(client);
		Call_PushString(info);
		Call_Finish();
		
		if(!canUseItem[client][StringToInt(info)] && !itemOnTimerReset[client][StringToInt(info)])
		{
			itemOnTimerReset[client][StringToInt(info)] = true;		
			char reuse_delay[12];
			rp_GetItemData(StringToInt(info), item_type_reuse_delay, STRING(reuse_delay));
			float delay = StringToFloat(reuse_delay);	
			DataPack dp = new DataPack();
			CreateDataTimer(delay, ResetItem_Delay, dp);
			dp.WriteCell(client);
			dp.WriteCell(StringToInt(info));	
			SaveClient();
		}	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			FakeClientCommand(client, "rp");
	}
	else if(action == MenuAction_End)
		delete menu;
}