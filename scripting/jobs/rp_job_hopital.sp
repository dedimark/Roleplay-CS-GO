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
char steamID[MAXPLAYERS + 1][32];
char logFile[PLATFORM_MAX_PATH];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Hôpital", 
	author = "Benito", 
	description = "Métier Hôpital", 
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
		
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_hopital.log");
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];		
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_hopital` ( \
	  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(20) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `111` int(100) NOT NULL, \
	  `112` int(100) NOT NULL, \
	  `113` int(100) NOT NULL, \
	  `114` int(100) NOT NULL, \
	  `115` int(100) NOT NULL, \
	  `116` int(100) NOT NULL, \
	  `117` int(100) NOT NULL, \
	  `118` int(100) NOT NULL, \
	  `119` int(100) NOT NULL, \
	  `120` int(100) NOT NULL, \
	  `121` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public void OnClientPostAdminCheck(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(rp_GetDatabase(), playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_hopital` (`Id`, `steamid`, `playername`, `111`, `112`, `113`, `114`, `115`, `116`, `117`, `118`, `119`, `120`, `121`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
	rp_SetClientInt(client, i_maxVie, 100);
}

/***************************************************************************************

								P L U G I N  -  S Q L

***************************************************************************************/

public void LoadSQL(int client) 
{
	if(!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_hopital WHERE steamid = '%s';", steamID[client]);
	rp_GetDatabase().Query(QueryCallback, buffer);
}

public void QueryCallback(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		for (int i = 0; i <= MAXITEMS; i++)
		{
			char item_jobid[64];
			rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
			
			if(StrEqual(item_jobid, "4"))
			{
				char item_string[10];
				IntToString(i, STRING(item_string));
				
				rp_ClientGiveItem(client, i, SQL_FetchIntByName(Results, item_string));
			}	
		}	
	}
}

/***************************************************************************************

						P L U G I N  -  G L O B A L  F O R W A R D

***************************************************************************************/

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	
	if(StrEqual(entityName, "Hopital"))
	{
		int nbHopital;
		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Job) == 4 && !rp_GetClientBool(i, b_isAfk))
				nbHopital++;
		}
		if(nbHopital == 0 || nbHopital == 1 && rp_GetClientInt(client, i_Job) == 4 || rp_GetClientInt(client, i_Job) == 4 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un medecin.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un medecin.");
		}	
	}	
}	

/***************************************************************************************

								P L U G I N  - N P C

***************************************************************************************/

Menu NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Hôpital");
	menu.AddItem("item", "Acheter un objet");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "item"))
			SellHopital(client, client);		
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public Action RP_OnPlayerSell(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 4)
	{
		menu.AddItem("item", "Vendre un objet");
	}
}	

public int RP_OnPlayerSellHandle(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "item"))
		SellHopital(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellHopital(int client, int target)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Items Disponibles");
	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "4"))
		{
			char item_name[64], item_handle[64], item_price[32];
			rp_GetItemData(i, item_type_name, STRING(item_name));
			rp_GetItemData(i, item_type_prix, STRING(item_price));
			Format(STRING(item_name), "%s [%s$]", item_name, item_price);
			Format(STRING(item_handle), "%i|%i|%i", target, StringToInt(item_price), i);
			menu.AddItem(item_handle, item_name);
		}
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}		

public int DoSell(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[64], buffer[3][64], strQuantite[128], strFormat[64];
		menu.GetItem(param, STRING(info));
		
		rp_SetClientBool(client, b_menuOpen, true);
		
		ExplodeString(info, "|", buffer, 3, 64);
			
		int target = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[1]);
		int itemID = StringToInt(buffer[2]);

		/* MENU QUANTITE */
		
		Menu quantity = new Menu(DoMenuQuantity);
		quantity.SetTitle("Choisissez la quantité");
			
		for(int i = 1; i <= 10; i++)
		{			
			Format(STRING(strQuantite), "%i|%i|%i|%i", target, prix, itemID, i);
			Format(STRING(strFormat), "%i", i);
			quantity.AddItem(strQuantite, strFormat);
		}	
		Format(STRING(strQuantite), "%i|%i|%i|25", target, prix, itemID);
		quantity.AddItem(strQuantite, "25");
		Format(STRING(strQuantite), "%i|%i|%i|50", target, prix, itemID);
		quantity.AddItem(strQuantite, "50");
		Format(STRING(strQuantite), "%i|%i|%i|100", target, prix, itemID);
		quantity.AddItem(strQuantite, "100");

		quantity.ExitButton = true;
		quantity.Display(client, MENU_TIME_FOREVER);
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int DoMenuQuantity(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], buffer[4][64], response[128];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 4, 64);
			
		int target = StringToInt(buffer[0]);
		int itemID = StringToInt(buffer[2]);
		int quantity = StringToInt(buffer[3]);
		int prix = StringToInt(buffer[1]) * quantity;
		
		char item_name[32];
		rp_GetItemData(itemID, item_type_name, STRING(item_name));
		
		rp_SetClientBool(target, b_menuOpen, true);
		Menu request = new Menu(FinalMenu);
		
		if(target != client)
			request.SetTitle("%N vous propose %i %s pour %i$, acheter ?", client, quantity, item_name, prix);	
		else
			request.SetTitle("Acheter %i %s pour %i$ ?", quantity, item_name, prix);				
				
		
		Format(STRING(response), "%i|%i|%i|%i|oui", client, quantity, itemID, prix);		
		request.AddItem(response, "Payer en liquide.");
		
		if(rp_GetClientBool(target, b_asCb))
		{
			Format(STRING(response), "%i|%i|%i|%i|cb", client, quantity, itemID, prix);			
			request.AddItem(response, "Payer avec ma carte bleue.");
		}
		
		request.AddItem("non", "Refuser l'achat.");
		
		request.ExitButton = false;
		request.Display(target, MENU_TIME_FOREVER);
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

public int FinalMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], buffer[5][128], strAppart[2][32];
		menu.GetItem(param, STRING(info));
		
		ExplodeString(info, "|", buffer, 5, 128);
		ExplodeString(buffer[2], "_", strAppart, 2, 32);
			
		int vendeur = StringToInt(buffer[0]);
		int prix = StringToInt(buffer[3]);
		int quantity = StringToInt(buffer[1]);
		int itemID = StringToInt(buffer[2]);
		bool payCB;
		
		char item_name[32];
		rp_GetItemData(itemID, item_type_name, STRING(item_name));
		
		if(StrEqual(buffer[4], "cb"))
			payCB = true;
			
		if(!StrEqual(buffer[4], "non"))
		{
			if(payCB)
			{
				if(rp_GetClientInt(client, i_Bank) >= prix)
				{
					rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - prix);
					
					if(vendeur == client)
					{
						rp_SetJobCapital(4, rp_GetJobCapital(4) + prix / 2);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);
					
					if(vendeur == client)
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, item_name, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, item_name, prix);
					}
					else
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, item_name, vendeur, prix);
						CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, item_name, client, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, item_name, prix, client);
					}
					
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
				}
				else
				{
					if(client != vendeur)
						CPrintToChat(vendeur, "%s %N n'a pas assez d'argent en banque.", TEAM, client);
					CPrintToChat(client, "%s Vous n'avez pas assez d'argent en banque.", TEAM);
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
					return;
				}	
			}
			else
			{
				if(rp_GetClientInt(client, i_Money) >= prix)
				{
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - prix);
					
					if(vendeur == client)
					{
						rp_SetJobCapital(4, rp_GetJobCapital(4) + prix / 2);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);					
					
					if(vendeur == client)
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, item_name, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, item_name, prix);
					}
					else
					{
						CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, item_name, vendeur, prix);
						CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, item_name, client, prix);
						LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, item_name, prix, client);
					}
					
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
				}
				else
				{
					if(client != vendeur)
						CPrintToChat(vendeur, "%s %N n'a pas assez d'argent en liquide.", TEAM, client);
					CPrintToChat(client, "%s Vous n'avez pas assez d'argent en liquide.", TEAM);
					rp_SetClientBool(vendeur, b_menuOpen, false);
					rp_SetClientBool(client, b_menuOpen, false);
					return;
				}
			}
			
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) + quantity);
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_hopital` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		}
		else if(StrEqual(buffer[4], "non"))
		{
			if(client != vendeur)
			{
				CPrintToChat(vendeur, "%s %N a refusé votre offre.", TEAM, client);
				CPrintToChat(client, "%s Vous avez refusé la vente de %N.", TEAM, vendeur);
				
				rp_SetClientBool(vendeur, b_menuOpen, false);
				rp_SetClientBool(client, b_menuOpen, false);
			}
			else CPrintToChat(client, "%s Vous avez refusé le paiement.", TEAM);
		}
		if(!StrEqual(buffer[4], "non"))
		{
			rp_SetupRingPoint(client, vendeur);
		}		
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

public Action RP_OnPlayerInventory(int client, Menu menu)
{
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "4"))
		{
			if(rp_GetClientItem(client, i) >= 1)
			{
				char item_name[64], item_handle[64];
				rp_GetItemData(i, item_type_name, STRING(item_name));
				Format(STRING(item_name), "%s [%i]", item_name, rp_GetClientItem(client, i));
				Format(STRING(item_handle), "%i", i);
				menu.AddItem(item_handle, item_name);
			}
		}
	}
}	

public int RP_OnPlayerInventoryHandle(int client, char[] info)
{
	if(StrEqual(info, "111"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, i_seringue, rp_GetClientItem(client, i_seringue) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_seringue), steamID[client]);
			
			GivePlayerItem(client, "weapon_healthshot");
				
			CPrintToChat(client, "%s Vous utilisez {lightblue}une seringue.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise une seringue.", client);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);
	}
	else if(StrEqual(info, "112"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if (!rp_GetClientBool(client, b_asRegen_HP))
			{
				rp_ClientGiveItem(client, i_regenhp, rp_GetClientItem(client, i_regenhp) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_regenhp), steamID[client]);
				
				rp_SetClientBool(client, b_asRegen_HP, true);
				
				CPrintToChat(client, "%s Vous êtes désormais sous l'emprise de la regénération de vie.", TEAM);
				LogToFile(logFile, "Le joueur %N à utilise une regeneration HP.", client);
			}
			else
				CPrintToChat(client, "%s Vous êtes déjà sous l'emprise de la regénération de vie.", TEAM);
		}	
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "113"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, i_sirop, rp_GetClientItem(client, i_sirop) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_sirop), steamID[client]);
		
			if (rp_GetClientBool(client, b_asMaladie_Angine))
			{
				rp_SetClientBool(client, b_asMaladie_Angine, false);
				
				CPrintToChat(client, "%s Vous avez guéri de votre Angine.", TEAM);
				LogToFile(logFile, "Le joueur %N a gueri de son Angine.", client);
			}
			else
				CPrintToChat(client, "%s Ce médicament n'a aucun effet.", TEAM);
		}	
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);			
	}
	else if(StrEqual(info, "114"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, i_remede, rp_GetClientItem(client, i_remede) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_remede), steamID[client]);
		
			if (rp_GetClientBool(client, b_asMaladie_Peste))
			{
				rp_SetClientBool(client, b_asMaladie_Peste, false);
				
				CPrintToChat(client, "%s Vous avez guéri de votre peste.", TEAM);
				LogToFile(logFile, "Le joueur %N a gueri de sa peste.", client);
			}
			else
				CPrintToChat(client, "%s Ce médicament n'a aucun effet.", TEAM);
		}	
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "115"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, i_antidote, rp_GetClientItem(client, i_antidote) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_antidote), steamID[client]);
		
			if (rp_GetClientBool(client, b_asMaladie_Covid))
			{
				rp_SetClientBool(client, b_asMaladie_Covid, false);
				
				CPrintToChat(client, "%s Vous avez guéri du covid-19.", TEAM);
				LogToFile(logFile, "Le joueur %N a gueri du covid-19.", client);
			}
			else
				CPrintToChat(client, "%s Ce médicament n'a aucun effet.", TEAM);
		}	
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "116"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			rp_ClientGiveItem(client, i_masque, rp_GetClientItem(client, i_masque) - 1);
			UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_masque), steamID[client]);
			
			if (!rp_GetClientBool(client, b_asMasque))
			{
				rp_SetClientBool(client, b_asMasque, true);
				
				CPrintToChat(client, "%s Vous portez désormais un masque anti-covid.", TEAM);
				LogToFile(logFile, "Le joueur %N porte désormais un masque.", client);
			}
			else
				CPrintToChat(client, "%s Ce médicament n'a aucun effet.", TEAM);
		}		
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);
	}
	else if(StrEqual(info, "116"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if (!rp_GetClientBool(client, b_asMasque))
			{
				rp_ClientGiveItem(client, i_masque, rp_GetClientItem(client, i_masque) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_masque), steamID[client]);
				
				rp_SetClientBool(client, b_asMasque, true);
				
				CPrintToChat(client, "%s Vous portez désormais un masque anti-covid.", TEAM);
				LogToFile(logFile, "Le joueur %N à utilise un masque anti-covid.", client);
			}
			else
				CPrintToChat(client, "%s Vous portez déjà un masque anti-covid.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "117"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if (!rp_GetClientBool(client, b_asChiru_Coeur))
			{
				rp_ClientGiveItem(client, i_chiru_coeur, rp_GetClientItem(client, i_chiru_coeur) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_chiru_coeur), steamID[client]);
				
				rp_SetClientBool(client, b_asChiru_Coeur, true);
				
				CPrintToChat(client, "%s Chirurgie du coeur: {lightgreen}Activé{default}.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une chirurgie du coeur.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une chirurgie du coeur.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "118"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if (!rp_GetClientBool(client, b_asChiru_Jambe))
			{
				rp_ClientGiveItem(client, i_chiru_jambe, rp_GetClientItem(client, i_chiru_jambe) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_chiru_jambe), steamID[client]);
				
				rp_SetClientBool(client, b_asChiru_Jambe, true);
				
				CPrintToChat(client, "%s Chirurgie des jambes: {lightgreen}Activé{default}.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une chirurgie de jambes.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une chirurgie des jambes.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "119"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if (!rp_GetClientBool(client, b_asChiru_Poumon))
			{
				rp_ClientGiveItem(client, i_chiru_poumon, rp_GetClientItem(client, i_chiru_poumon) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_chiru_poumon), steamID[client]);
				
				rp_SetClientBool(client, b_asChiru_Poumon, true);
				
				CPrintToChat(client, "%s Chirurgie des poumons: {lightgreen}Activé{default}.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une chirurgie des poumons.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une chirurgie des poumons.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "120"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if (!rp_GetClientBool(client, b_asChiru_Muscle))
			{
				rp_ClientGiveItem(client, i_chiru_muscle, rp_GetClientItem(client, i_chiru_muscle) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_chiru_muscle), steamID[client]);
				
				rp_SetClientBool(client, b_asChiru_Muscle, true);
				
				CPrintToChat(client, "%s Chirurgie des muscles: {lightgreen}Activé{default}.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une chirurgie des muscles.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une chirurgie des muscles.", TEAM);
		}	
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);		
	}
	else if(StrEqual(info, "121"))
	{
		if(rp_GetCanUseItem(client, StringToInt(info)))
		{
			rp_SetCanUseItem(client, StringToInt(info), false);
			if (!rp_GetClientBool(client, b_asChiru_Foie))
			{
				rp_ClientGiveItem(client, i_chiru_foie, rp_GetClientItem(client, i_chiru_foie) - 1);
				UpdateSQL_Item(rp_GetDatabase(), "rp_hopital", info, rp_GetClientItem(client, i_chiru_foie), steamID[client]);
				
				rp_SetClientBool(client, b_asChiru_Foie, true);
				
				CPrintToChat(client, "%s Chirurgie du foie: {lightgreen}Activé{default}.", TEAM);
				LogToFile(logFile, "Le joueur %N a utilise une chirurgie du foie.", client);
			}
			else
				CPrintToChat(client, "%s Vous avez déjà une chirurgie du foie.", TEAM);
		}
		else		
			CPrintToChat(client, "%s Vous devez patienter avant de re-utiliser cet item.", TEAM);	
	}
}	

public void OnGameFrame()
{
	LoopClients(i)
	{
		if(rp_GetClientBool(i, b_asRegen_Armor))
		{
			int vie = GetClientHealth(i);
			if(rp_GetClientInt(i, i_maxVie) > vie)
				SetEntityHealth(i, vie + 1);
		}
	}	
}	