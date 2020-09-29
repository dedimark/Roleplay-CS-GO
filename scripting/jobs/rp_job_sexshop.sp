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
char logFile[PLATFORM_MAX_PATH];
char steamID[MAXPLAYERS + 1][32];

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - SexShop", 
	author = "Benito", 
	description = "Métier SexShop", 
	version = VERSION, 
	url = URL
};

/***************************************************************************************

							P L U G I N  -  E V E N T S

***************************************************************************************/
public void OnPluginStart()
{
	rp_LoadTranslation();	
	GameCheck();
	BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_sexshop.log");
}

public void RP_OnDatabaseLoaded(Database db)
{
	char buffer[4096];
	Format(STRING(buffer), 
	"CREATE TABLE IF NOT EXISTS `rp_sexshop` ( \
	  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
	  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
	  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
	  `93` int(100) NOT NULL, \
	  `94` int(100) NOT NULL, \
	  `95` int(100) NOT NULL, \
	  `96` int(100) NOT NULL, \
	  `97` int(100) NOT NULL, \
	  `98` int(100) NOT NULL, \
	  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
	  PRIMARY KEY (`Id`), \
	  UNIQUE KEY `steamid` (`steamid`) \
	  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
	db.Query(SQLErrorCheckCallback, buffer);
}

public void rp_OnClientSpawn(int client)
{
	rp_SetClientBool(client, b_isLubrifiant, false);
}

public void RP_OnPlayerDeath(int attacker, int victim, int respawnTime)
{
	if(rp_GetClientBool(victim, b_isLubrifiant))
	{
		rp_SetClientBool(victim, b_isLubrifiant, false);
		CPrintToChat(victim, "%s Vous n'êtes plus lubrifié.", TEAM);
	}	
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
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_sexshop` (`Id`, `steamid`, `playername`, `93`, `94`, `95`, `96`, `97`, `98`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	rp_GetDatabase().Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
}	

public void LoadSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_sexshop WHERE steamid = '%s'", steamID[client]);
	rp_GetDatabase().Query(CallBackSQL, buffer, GetClientUserId(client));
}

public void CallBackSQL(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		for (int i = 0; i <= MAXITEMS; i++)
		{
			char item_jobid[64];
			rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
			
			if(StrEqual(item_jobid, "18"))
			{
				char item_string[10];
				IntToString(i, STRING(item_string));
				
				rp_ClientGiveItem(client, i, SQL_FetchIntByName(Results, item_string));
			}	
		}	
	}
}

public Action RP_OnPlayerInventory(int client, Menu menu)
{
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "18"))
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
	if(StrEqual(info, "93") && IsPlayerAlive(client))
	{
		int itemID = StringToInt(info);
		rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
		UpdateSQL(rp_GetDatabase(), "UPDATE `rp_sexshop` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);		
				
		float position[3];
		GetClientAbsOrigin(client, position);
		rp_CreateParticle(position, "explosion_c4_500", 10.0);
		PrecacheSound("weapons/c4/c4_explode1.wav");
		EmitSoundToAll("weapons/c4/c4_explode1.wav", client, _, _, _, 1.0, _, _, position);
		
		int count;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidEntity(i))
			{
				if(!ZonePeaceFull(i))
				{
					int vie = GetClientHealth(i), montant;
					float playerDistance = Distance(client, i);
					if(playerDistance >= 220.0)
						montant = GetRandomInt(5, 35);
					else if(playerDistance <= 150.0)
						ForcePlayerSuicide(i);	
					else
						montant = GetRandomInt(5, 75);
					
					if(vie - montant > 0)
						SetEntityHealth(i, vie - montant);
					else
					{
						ForcePlayerSuicide(i);
						if(i != client)
							count++;
					}
				}
			}
		}
		if(count > 0)
		{
			if(count == 1)
				CPrintToChat(client, "%s Vous avez tué une personne.", TEAM);
			else
				CPrintToChat(client, "%s Vous avez tué %i personnes.", TEAM, count);
		}
		
		ForcePlayerSuicide(client);
	
		CPrintToChat(client, "%s Vous utilisez {lightblue}une sucette duo", TEAM);
		LogToFile(logFile, "Le joueur %N a utilise une sucette duo.", client);
	}
	else if(StrEqual(info, "94") && IsPlayerAlive(client))
	{
		if(GetClientHealth(client) != 500)
		{
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_sexshop` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		
			CreateTimer(1.0, HealthClient, client, TIMER_REPEAT);
			
			rp_SetClientBool(client, b_canItem, false);
			CreateTimer(10.0, canItem, client);
			CPrintToChat(client, "%s Désormais votre menu inventaire ne sera plus accessible pendant 10 secondes.", TEAM);
			
			CPrintToChat(client, "%s Vous utilisez {lightblue}un ensemble sexy.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un ensemble sexy.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà {yellow}500{lightred}HP{default}!", TEAM);
	}
	else if(StrEqual(info, "95") && IsPlayerAlive(client))
	{
		if(Client_GetArmor(client) != 150)
		{
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_sexshop` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		
			Client_SetArmor(client, Client_GetArmor(client) + 25);
			
			CPrintToChat(client, "%s Vous utilisez {lightblue}un préservatif.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un préservatif.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà {yellow}150{lightred}Kevlar{default}!", TEAM);
	}
	else if(StrEqual(info, "96") && IsPlayerAlive(client))
	{
		int aim = GetAimEnt(client, true);
		if(aim != -1 && IsClientValid(aim))
		{
			if(GetEntityMoveType(aim) != MOVETYPE_NONE)
			{
				char model[64];
				Entity_GetModel(aim, model, sizeof(model));
				
				if(StrContains(model, "player") != -1 && Distance(client, aim) < 200)
				{
					int itemID = StringToInt(info);
					rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
					UpdateSQL(rp_GetDatabase(), "UPDATE `rp_sexshop` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
					
					SetEntityMoveType(aim, MOVETYPE_NONE);
					CreateTimer(3.0, SetMoveType, aim);
					
					CPrintToChat(client, "%s Vous avez freeze %N pendant 3 secondes.", TEAM, aim);
					LogToFile(logFile, "Le joueur %N a freeze %N pendant 3 secondes.", client, aim);
				}	
				else
				{
					if(StrContains(model, "player") == -1)
						CPrintToChat(client, "%s Vous devez viser un joueur.", TEAM);
					else
						CPrintToChat(client, "%s Vous devez vous rapprocher de la cible.", TEAM);				
				}	
			}
			else
				CPrintToChat(client, "%s Ce joueur est déjà freeze.", TEAM);
		}
		else
			CPrintToChat(client, "%s Vous dêvez viser un joueur.", TEAM);	
	}
	else if(StrEqual(info, "97") && IsPlayerAlive(client))
	{
		if(!rp_GetClientBool(client, b_isLubrifiant))
		{
			int itemID = StringToInt(info);
			rp_ClientGiveItem(client, itemID, rp_GetClientItem(client, itemID) - 1);		
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_sexshop` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
		
			rp_SetClientBool(client, b_isLubrifiant, true);
			
			CPrintToChat(client, "%s Vous utilisez {lightblue}du lubrifiant.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise du lubrifiant.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà utilisé du lubrifiant!", TEAM);
	}
}	

public Action HealthClient(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		if(GetClientHealth(client) == 500)
		{
			CPrintToChat(client, "%s Vous avez atteint {yellow}500{lightred}HP{default}.", TEAM);
			delete timer;
		}	
		else
			SetEntityHealth(client, GetClientHealth(client) + 1);
	}
}	

public Action canItem(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		CPrintToChat(client, "%s Vous avez désormais accès aux items.", TEAM);
		rp_SetClientBool(client, b_canItem, true);
	}
}	

public Action SetMoveType(Handle timer, any client)
{
	if(IsClientValid(client))
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}	

/***************** NPC SYSTEM *****************/

public Action RP_OnPlayerInteract(int client, int target, const char[] class, const char[] model, const char[] name)
{
	char entityName[256];
	Entity_GetGlobalName(target, STRING(entityName));
	if(StrEqual(entityName, "SexShop") && Distance(client, target) <= 80.0)
	{
		int nbSex;
		LoopClients(i)
		{
			if(rp_GetClientInt(i, i_Job) == 18 && !rp_GetClientBool(i, b_isAfk))
				nbSex++;
		}
		if(nbSex == 0 || nbSex == 1 && rp_GetClientInt(client, i_Job) == 18 || rp_GetClientInt(client, i_Job) == 18 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un SexShop.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un SexShop");
		}
	}	
}

int NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - SexShop");
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
			SellSexShop(client, client);	
	}	
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if (action == MenuAction_End)
		delete menu;
}
	
/************************************************/
/***************** Global Vente *****************/

public Action RP_OnPlayerSell(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 18)
	{
		rp_SetClientBool(client, b_menuOpen, true);
		menu.AddItem("item", "Vendre un objet");
	}
}	

public int RP_OnPlayerSellHandle(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "item"))
		SellSexShop(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellSexShop(int client, int target)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Items Disponibles");
	
	for (int i = 0; i <= MAXITEMS; i++)
	{
		char item_jobid[64];
		rp_GetItemData(i, item_type_job_id, STRING(item_jobid));
		
		if(StrEqual(item_jobid, "18"))
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
						rp_SetJobCapital(18, rp_GetJobCapital(18) + prix / 2);
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
						rp_SetJobCapital(18, rp_GetJobCapital(18) + prix / 2);
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
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_sexshop` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
			UpdateSQL(rp_GetDatabase(), "UPDATE `rp_sexshop` SET `%i` = '%i' WHERE steamid = '%s';", itemID, rp_GetClientItem(client, itemID), steamID[client]);
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
/************************************************/