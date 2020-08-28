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

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
➤																					  ➤
							C O M P I L E  -  O P T I O N S
➤																					  ➤
➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#pragma semicolon 1
#pragma newdecls required

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
➤																					  ➤
							P L U G I N  -  I N C L U D E S
➤																					  ➤
➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#if !defined CSS_SUPPORT
#include <multicolors>
#else
#include <morecolors>
#endif
#include <roleplay>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
➤																					  ➤
							G L O B A L  -  V A R S
➤																					  ➤
➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
char logFile[PLATFORM_MAX_PATH];
char dbconfig[] = "roleplay";
Database g_DB;

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
➤																					  ➤
							P L U G I N  -  I N F O
➤																					  ➤
➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Justice", 
	author = "Benito", 
	description = "Métier Justice", 
	version = VERSION, 
	url = URL
};

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
➤																					  ➤
							P L U G I N  -  E V E N T S
➤																					  ➤
➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public void OnPluginStart()
{
	if(rp_licensing_isValid())
	{
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_justice.log");
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();
}

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("DatabaseError", error);
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
	}
}

public Action rp_MenuMetier(int client, Menu menu)
{
	if (rp_GetClientInt(client, i_Job) == 7)
	{
		menu.AddItem("avisrecherche", "Avis de recherche");
		menu.AddItem("enquete", "Ouvrir un dossier");
	}
}	

public int rp_HandlerMenuMetier(int client, const char[] info)
{
	if (StrEqual(info, "enquete"))
		MenuEnquete(client);
	else if (StrEqual(info, "avisrecherche"))
		MenuAvisRecherche(client);
}	

Menu MenuEnquete(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuEnquete);
	menu.SetTitle("Quel dossier voulez-vous ?");
	
	LoopClients(i)
	{
		if (IsClientValid(i))
		{
			char name[32], strI[8];
			IntToString(i, STRING(strI));
			GetClientName(i, STRING(name));
			
			if (rp_GetClientInt(i, i_Job) == 2 && rp_GetClientInt(i, i_Grade) == 1)
				menu.AddItem("", name, ITEMDRAW_DISABLED);
			else 
				menu.AddItem(strI, name);
		}
	}
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuEnquete(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64], strFormat[64];
		menu.GetItem(param, STRING(info));
		int id = StringToInt(info);
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu menu1 = new Menu(DoMenuEnqueteFinal);
		menu1.SetTitle("Dossier de %N :", id);
		
		Format(STRING(strFormat), "Karma : %f", rp_GetClientFloat(id, fl_Vitality));
		menu1.AddItem("", strFormat, ITEMDRAW_DISABLED);
		
		char enquete1[128];
		rp_GetClientEnquete(id, 0, STRING(enquete1));
		if (!StrEqual(enquete1, "none"))
			menu1.AddItem("", enquete1, ITEMDRAW_DISABLED);
		
		char enquete2[128];
		rp_GetClientEnquete(id, 7, STRING(enquete2));
		if (!StrEqual(enquete2, "none"))
			menu1.AddItem("", enquete2, ITEMDRAW_DISABLED);
		
		char enquete3[128];
		rp_GetClientEnquete(id, 1, STRING(enquete3));
		if (!StrEqual(enquete3, "none"))
			menu1.AddItem("", enquete3, ITEMDRAW_DISABLED);
		
		char enquete4[128];
		rp_GetClientEnquete(id, 6, STRING(enquete4));
		if (!StrEqual(enquete4, "none"))
			menu1.AddItem("", enquete4, ITEMDRAW_DISABLED);
		
		char enquete5[128];
		rp_GetClientEnquete(id, 5, STRING(enquete5));
		if (!StrEqual(enquete5, "none"))
			menu1.AddItem("", enquete5, ITEMDRAW_DISABLED);
		
		char enquete6[128];
		rp_GetClientEnquete(id, 2, STRING(enquete6));
		if (!StrEqual(enquete6, "none"))
			menu1.AddItem("", enquete6, ITEMDRAW_DISABLED);
		
		char enquete7[128];
		rp_GetClientEnquete(id, 3, STRING(enquete7));
		if (!StrEqual(enquete7, "none"))
			menu1.AddItem("", enquete7, ITEMDRAW_DISABLED);
		
		char enquete8[128];
		rp_GetClientEnquete(id, 4, STRING(enquete8));
		if (!StrEqual(enquete8, "none"))
			menu1.AddItem("", enquete8, ITEMDRAW_DISABLED);
		
		char enquete9[128];
		rp_GetClientEnquete(id, 8, STRING(enquete9));
		if (!StrEqual(enquete9, "none"))
			menu1.AddItem("", enquete9, ITEMDRAW_DISABLED);
		
		char enquete10[128];
		rp_GetClientEnquete(id, 9, STRING(enquete9));
		if (!StrEqual(enquete10, "none"))
			menu1.AddItem("", enquete10, ITEMDRAW_DISABLED);
		
		menu1.ExitBackButton = true;
		menu1.ExitButton = true;
		menu1.Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		//else if (param == MenuCancel_ExitBack)
			//MenuGererMetier(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuEnqueteFinal(Menu menu1, MenuAction action, int client, int param)
{
	if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if (param == MenuCancel_ExitBack)
			MenuEnquete(client);
	}
	else if (action == MenuAction_End)
		delete menu1;
}

Menu MenuAvisRecherche(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuRecherche);
	menu.SetTitle("Avis de recherche :");
	if (rp_GetClientInt(client, i_Job) == 1 && rp_GetClientInt(client, i_Grade) <= 5 || rp_GetClientInt(client, i_Job) == 7)
		menu.AddItem("avis", "Lancer un avis de recherche");
	menu.AddItem("afficher", "Liste des suspects recherchés");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuRecherche(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if (StrEqual(info, "avis"))
		{
			rp_SetClientBool(client, b_menuOpen, true);
			Menu menu1 = new Menu(DoMenuAvisRecherche);
			menu1.SetTitle("Quel suspect est recherché ?");
			
			bool count;
			char strInfo[16], strMenu[64], jobName[64];
			
			LoopClients(i)
			{
				if (IsClientValid(i) && IsValidEntity(i))
				{
					count = true;
					GetJobName(rp_GetClientInt(i, i_Job), jobName);
					Format(STRING(strMenu), "%N (%s)", i, jobName);
					Format(STRING(strInfo), "%i", i);
					menu1.AddItem(strInfo, strMenu);
				}
			}
			if (!count)
				menu1.AddItem("", "Aucun suspect.", ITEMDRAW_DISABLED);
			
			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(client, MENU_TIME_FOREVER);
		}
		else if (StrEqual(info, "afficher"))
		{
			rp_SetClientBool(client, b_menuOpen, true);
			Menu menu2 = new Menu(DoMenuAfficherRecherche);
			menu2.SetTitle("Liste des suspects recherchés :");
			
			int count;
			char strInfo[16], strMenu[64], jobName[24];
			
			LoopClients(i)
			{
				if (IsClientValid(i) && IsValidEntity(i))
				{
					if (rp_GetClientBool(i, b_IsSearchByTribunal))
					{
						count++;
						Format(STRING(strMenu), "%N (%s)", i, jobName);
						Format(STRING(strInfo), "%i", i);
						if (rp_GetClientInt(client, i_Grade) <= 5)
							menu2.AddItem(strInfo, strMenu);
						else
							menu2.AddItem("", strMenu, ITEMDRAW_DISABLED);
					}
				}
			}
			if (count == 0)
				menu2.AddItem("", "Aucun avis de recherche.", ITEMDRAW_DISABLED);
			
			menu2.ExitBackButton = true;
			menu2.ExitButton = true;
			menu2.Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		//else if (param == MenuCancel_ExitBack)
		//	MenuGererMetier(client);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuAvisRecherche(Menu menu1, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu1.GetItem(param, STRING(info));
		
		int cible = StringToInt(info);
		if (IsClientValid(cible) && IsValidEntity(cible))
		{
			char jobName[64];
			GetJobName(rp_GetClientInt(cible, i_Job), jobName);
			
			rp_SetClientBool(cible, b_IsSearchByTribunal, true);
			CreateTimer(360.0, UnAvisRecherche, client);
			
			if (rp_GetClientInt(client, i_ByteZone) == 777)
				TeleportToBytzone(client, 777);
			
			CPrintToChat(client, "%s Vous avez lancé un avis de recherche sur \x02%N\x01.", TEAM, cible);
			CPrintToChat(cible, "%s Vous êtes recherché par le \x02service de Police\x01, cachez-vous !", TEAM);
			
			LoopClients(i)
			{
				if (IsClientValid(i) && i != client)
				{
					if (rp_GetClientInt(i, i_Job) == 1)
						CPrintToChat(i, "%s A toutes les unités, le suspect \x02%N \x01(%s) est recherché par {orange}%N\x01.", TEAM, cible, jobName, client);
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		//else if (param == MenuCancel_ExitBack)
			//MenuGererMetier(client);
	}
	else if (action == MenuAction_End)
		delete menu1;
}

public Action UnAvisRecherche(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		if(rp_GetClientBool(client, b_IsSearchByTribunal))
		{
			rp_SetClientBool(client, b_IsSearchByTribunal, false);
			LogToFile(logFile, "Le joueur {yellow}%N {default}n'est plus recherché par la police.", client);
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientValid(i))
				{
					if(rp_GetClientInt(i, i_Job) == 1)
					{
						PrintCenterText(i, "<font color='#a35a00'>Suspect en fuite</font> <font color='#ff0000'>!</font>");
						CPrintToChat(i, "%s Le suspect {red}%N {default} s'est enfui, l'avis de recherche est {yellow}annulé{default}.", TEAM, client);
					}
				}
			}
		}
	}
}

public int DoMenuAfficherRecherche(Menu menu2, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu2.GetItem(param, STRING(info));
		
		int cible = StringToInt(info);
		if (IsClientValid(cible) && IsValidEntity(cible))
		{
			if (rp_GetClientBool(cible, b_IsSearchByTribunal))
			{
				char jobName[64], strMenu[32];
				GetJobName(rp_GetClientInt(cible, i_Job), jobName);
				
				rp_SetClientBool(client, b_menuOpen, true);
				Menu menu5 = new Menu(DoMenuModifierRecherche);
				
				menu5.SetTitle("Modifier l'avis de recherche de %N (%s) :", cible, jobName);
				Format(STRING(strMenu), "trouver|%i", cible);
				if (rp_GetClientInt(client, i_Job) == 1)
					menu5.AddItem(strMenu, "Le suspect a été arrêté.");
				else 
					menu5.AddItem(strMenu, "Le suspect a été trouvé.");
				Format(STRING(strMenu), "annuler|%i", cible);
				menu5.AddItem(strMenu, "Annuler l'avis de recherche.");
				menu5.ExitButton = true;
				menu5.Display(client, MENU_TIME_FOREVER);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if (param == MenuCancel_ExitBack)
			MenuAvisRecherche(client);
	}
	else if (action == MenuAction_End)
		delete menu2;
}

public int DoMenuModifierRecherche(Menu menu5, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32], buffer[2][16];
		menu5.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 2, 16);
		// buffer[0] : info
		int cible = StringToInt(buffer[1]);
		
		if (IsValidEntity(cible))
		{
			if (StrEqual(buffer[0], "trouver"))
			{
				rp_SetClientBool(cible, b_IsSearchByTribunal, false);			
				LogToFile(logFile, "Le joueur %N a trouver le suspect %N (avis de recherche).", client, cible);
				
				LoopClients(i)
				{
					if (IsClientValid(i) && i != client)
					{
						char zone[64];
						rp_GetClientString(client, sz_Zone, STRING(zone));
						
						if (rp_GetClientInt(i, i_Job) == 1)
							CPrintToChat(client, "%s Le suspect \x02%N \x01 a été trouvé par {orange}%N \x01 (%s), l'avis de recherche est suspendu.", TEAM, cible, client, zone);
					}
				}
			}
			else if (StrEqual(buffer[0], "annuler"))
			{
				rp_SetClientBool(cible, b_IsSearchByTribunal, false);
				LogToFile(logFile, "Le joueur %N a trouver le suspect %N (avis de recherche).", client, cible);
				
				LoopClients(i)
				{
					if (IsClientValid(i) && i != client)
					{
						if (rp_GetClientInt(i, i_Job) == 1)
						{
							CPrintToChat(client, "%s L'avis de recherche de %N est annulé.", TEAM, cible);
							PrintHintText(client, "L'avis de recherche de %N est annulé.", cible);
						}
					}
				}
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu5;
}