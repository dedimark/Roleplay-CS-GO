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

							G L O B A L  -  V A R S

***************************************************************************************/
GlobalForward g_MenuVendre;
GlobalForward g_Handle_MenuVendre;

GlobalForward g_PushInteractionJoueur;
GlobalForward g_Handle_PushInteractionJoueur;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Système de vente",
	author = "Benito",
	description = "Système de vente pour les métiers",
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
		
	g_MenuVendre = new GlobalForward("RP_OnPlayerSell", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_Handle_MenuVendre = new GlobalForward("RP_OnPlayerSellHandle", ET_Event, Param_Cell, Param_String);
		
	g_PushInteractionJoueur = new GlobalForward("RP_PushToInteraction", ET_Event, Param_Cell, Param_Cell);
	g_Handle_PushInteractionJoueur = new GlobalForward("RP_PushToInteractionHandle", ET_Event, Param_Cell, Param_String);
}

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	if(StrContains(class, "player") != -1)
	{
		if(rp_GetClientInt(client, i_Job) != 0 && rp_GetClientInt(client, i_timeJail) == 0)
		{
			char strIndex[64];
			
			rp_SetClientBool(client, b_menuOpen, true);
			Menu menu = new Menu(DisplayVendreMenu);
			menu.SetTitle("Intéraction avec %N", target);
			Format(STRING(strIndex), "vendre|%i", target);
			menu.AddItem(strIndex, "Vendre");
			Call_StartForward(g_PushInteractionJoueur);
			Call_PushCell(menu);
			Call_PushCell(client);
			Call_Finish();
			menu.ExitButton = true;
			menu.Display(client, MENU_TIME_FOREVER);
		}	
	}
}

public int DisplayVendreMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], buffer[2][32];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 32);
		
		int aim = StringToInt(buffer[1]);
		
		if(StrEqual(buffer[0], "vendre"))
			DoVendre(client, aim);
			
		Call_StartForward(g_Handle_PushInteractionJoueur);
		Call_PushCell(client);
		Call_PushString(info);
		Call_Finish();			
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else
	{
		if(action == MenuAction_End)
			delete menu;
	}
}

Menu DoVendre(int client, int joueur)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(DoVendreSub1);
	menu.SetTitle("Choisissez le produit à vendre :");
	
	Call_StartForward(g_MenuVendre);	
	Call_PushCell(menu);
	Call_PushCell(client);
	Call_PushCell(joueur);
	Call_Finish();
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoVendreSub1(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		Call_StartForward(g_Handle_MenuVendre);
		Call_PushCell(client);
		Call_PushString(info);
		Call_Finish();		
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else
	{
		if(action == MenuAction_End)
			delete menu;
	}
}	

/*public int Final(int client, int vendeur, char[] item, int price, int quantity, bool payCB)
{
	Call_StartForward(g_Handle_MenuVendre);
	Call_PushCell(client);
	Call_PushString(info);
	Call_Finish();	
	
	if (payCB && bank[joueur] >= prix
		 || !payCB && money[joueur] >= prix)
	{
		int restantTVA, pourcentJoueur, pourcentCapital, sommeJoueur, sommeCapital, vol;
		restantTVA = 100 - tva;
		pourcentJoueur = restantTVA / 2;
		pourcentCapital = restantTVA / 2;
		
		// Pas de TVA pour trafiquant, assassin et marché noir :
		
		if (client != vendeur)
		{
			if (payCB)
				bank[joueur] -= prix;
			else
				money[joueur] -= prix;
			SonMoney(joueur, prix, true);
			
			money[client] += sommeJoueur;
			SonMoney(client, sommeJoueur);
			
			capital[jobID[client]] += sommeCapital;
			capital[MAIRIE] += prix - sommeJoueur - sommeCapital;
			
			SaveClientDB(client, 1);
			
			
			Format(enquete[2][client], sizeof(enquete[][]), "Il a vendu %i %s pour %i$ à %N", quantite, strItem, prix, joueur);
			Format(enquete[5][joueur], sizeof(enquete[][]), "Il a acheté %i %s pour %i$ à %N", quantite, strItem, prix, client);
			
			CPrintToChat(joueur, "%s Vous avez acheté %i %s à %N pour %i$.", LOGO, quantite, strItem, client, prix);
			CPrintToChat(client, "%s Vous avez vendu %i %s à %N pour %i$.", LOGO, quantite, strItem, joueur, prix);
			LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", joueur, quantite, strItem, prix, client);
		}
		else
		{
			if (payCB)
				bank[client] -= prix;
			else
				money[client] -= prix;
			SonMoney(client, prix, true);
			
			capital[ARMU] += sommeCapital + sommeJoueur;
			capital[MAIRIE] += prix - sommeJoueur - sommeCapital;
			
			SaveClientDB(client, 1);
			
			CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", LOGO, quantite, strItem, joueur, prix);
			LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantite, strItem, prix);
		}
		
		PrecacheSoundAny("ui/store_item_purchased.wav");
		EmitSoundToClientAny(client, "ui/store_item_purchased.wav", client, _, _, _, 0.4);
		
		return true;
	}
	else if (money[joueur] <= prix)
	{
		if (client != joueur)
			CPrintToChat(client, "%s %N n'a pas assez de liquide.", LOGO, joueur);
		CPrintToChat(joueur, "%s Vous n'avez pas assez de liquide !", LOGO);
	}
	else if (bank[joueur] <= prix)
	{
		if (client != joueur)
			CPrintToChat(client, "%s La carte bleue de %N a été refusée.", LOGO, joueur);
		CPrintToChat(joueur, "%s Votre carte bleue a été refusée !", LOGO);
	}
	else
	{
		if (client != joueur)
			CPrintToChat(client, "%s %N n'a pas assez d'argent.", LOGO, joueur);
		CPrintToChat(joueur, "%s Vous n'avez pas assez d'argent !", LOGO);
	}
	return false;
}*/