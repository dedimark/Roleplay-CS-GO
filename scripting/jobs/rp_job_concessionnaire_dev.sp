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
#include <cstrike>
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
char dbconfig[] = "roleplay";
char steamID[MAXPLAYERS + 1][64];
Database g_DB;

/***************************************************************************************

							P L U G I N  -  I N F O

***************************************************************************************/
public Plugin myinfo = 
{
	name = "[Roleplay] Job - Concessionnaire", 
	author = "Benito", 
	description = "Métier Concessionnaire", 
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
		BuildPath(Path_SM, logFile, sizeof(logFile), "logs/roleplay/jobs/rp_job_concessionaire.log");
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
		return;
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
		
		char buffer[4096];
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_concessionnaire` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `jerrican_essence` int(100) NOT NULL, \
		  `jerrican_diesel` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	char steamID_64[64];
	GetClientAuthId(client, AuthId_SteamID64, STRING(steamID_64));	
	strcopy(steamID[client], sizeof(steamID[]), steamID_64);
}

public void OnClientPostAdminCheck(int client) 
{	
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, STRING(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_concessionnaire` (`Id`, `steamid`, `playername`, `jerrican_essence`, `jerrican_diesel`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	LoadSQL(client);
}

public Action rp_reloadData()
{
	LoopClients(i)
	{
		LoadSQL(i);
	}	
}

public void LoadSQL(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_concessionnaire WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(LoadCallBackSQL, buffer, GetClientUserId(client));
}

public void LoadCallBackSQL(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientItem(client, i_jerrican_essence, SQL_FetchIntByName(Results, "jerrican_essence"));
		rp_SetClientItem(client, i_jerrican_diesel, SQL_FetchIntByName(Results, "jerrican_diesel"));
	}
}

/************************************************/
/***************** Global Forwards *****************/

public Action rp_MenuInventory(int client, Menu menu)
{
	char amount[64];
	
	if(rp_GetClientItem(client, i_jerrican_essence) >= 1)
	{
		Format(STRING(amount), "Jerrican d'essence [%i]", rp_GetClientItem(client, i_jerrican_essence));
		menu.AddItem("jerrican_essence", amount);
	}
	if(rp_GetClientItem(client, i_jerrican_diesel) >= 1)
	{
		Format(STRING(amount), "Jerrican de Diesel [%i]", rp_GetClientItem(client, i_jerrican_diesel));
		menu.AddItem("jerrican_diesel", amount);
	}
}	
	
public int rp_HandlerMenuInventory(int client, char[] info)
{
	char currentSkin[256];
	rp_GetClientString(client, sz_Skin, currentSkin, 256);
	
	if(StrEqual(info, "jerrican_essence") && IsPlayerAlive(client))
	{
		int car = GetAimEnt(client, false);
		if(IsValidEntity(car))
		{
			char entClass[64], entName[64];
			Entity_GetClassName(car, STRING(entClass));
			
			if(StrEqual(entClass, "prop_vehicle_driveable"))
			{
				Entity_GetName(car, STRING(entName));
				char carinfo[4][32];
				ExplodeString(entName, "|", carinfo, 4, 32);
				
				int carID = StringToInt(carinfo[3]);
				
				if(StrEqual(carinfo[1], steamID[client]))
				{
					if(rp_GetVehicleInt(car, car_fueltype) == 1)
					{
						if(rp_GetVehicleInt(car, car_fuel) < Vehicle_GetMaxFuel(carID))
						{
							rp_SetClientItem(client, i_jerrican_essence, rp_GetClientItem(client, i_jerrican_essence) - 1);						
							rp_SetVehicleInt(car, car_fuel, rp_GetVehicleInt(car, car_fuel) + 5);
							
							CPrintToChat(client, "%s Vous avez versé 5L d'essence dans votre voiture, elle a maintenant %iL.", TEAM, rp_GetVehicleInt(car, car_fuel));
							LogToFile(logFile, "Le joueur %N a consomme un jerrican d'essence.", client);
						}
						else 
							CPrintToChat(client, "%s Votre voiture a déjà le plein.", TEAM);
					}		
					else 
						CPrintToChat(client, "%s Votre voiture consomme de l'essence pas du diesel.", TEAM);
				}
				else 
					CPrintToChat(client, "%s Ce n'est pas votre vehicle.", TEAM);
			}
		}
		else CPrintToChat(client, "%s Vous devez viser votre voiture pour mettre du carburant.", TEAM);
	}
	else if(StrEqual(info, "jerrican_diesel") && IsPlayerAlive(client))
	{
		int car = GetAimEnt(client, false);
		if(IsValidEntity(car))
		{
			char entClass[64], entName[64];
			Entity_GetClassName(car, entClass, sizeof(entClass));
			
			if(StrEqual(entClass, "prop_vehicle_driveable"))
			{
				Entity_GetName(car, entName, sizeof(entName));
				char carinfo[4][32];
				ExplodeString(entName, "|", carinfo, 4, 32);
				
				int carID = StringToInt(carinfo[3]);
				
				if(StrEqual(carinfo[1], steamID[client]))
				{
					if(rp_GetVehicleInt(car, car_fueltype) == 2)
					{
						if(rp_GetVehicleInt(car, car_fuel) < Vehicle_GetMaxFuel(carID))
						{
							rp_SetClientItem(client, i_jerrican_essence, rp_GetClientItem(client, i_jerrican_essence) - 1);						
							rp_SetVehicleInt(car, car_fuel, rp_GetVehicleInt(car, car_fuel) + 5);
							
							CPrintToChat(client, "%s Vous avez versé 5L d'essence dans votre voiture, elle a maintenant %iL.", TEAM, rp_GetVehicleInt(car, car_fuel));
							LogToFile(logFile, "Le joueur %N a consomme un jerrican d'essence.", client);
						}
						else 
							CPrintToChat(client, "%s Votre voiture a déjà le plein.", TEAM);
					}		
					else 
						CPrintToChat(client, "%s Votre voiture consomme du diesel pas de l'essence.", TEAM);
				}
				else 
					CPrintToChat(client, "%s Ce n'est pas votre vehicle.", TEAM);
			}
		}
		else CPrintToChat(client, "%s Vous devez viser votre voiture pour mettre du carburant.", TEAM);
	}
}		

/***************** NPC SYSTEM *****************/

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if(StrEqual(entName, "Concessionnaire") && Distance(client, aim) <= 80.0)
	{
		int nbConcess;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				if(rp_GetClientInt(i, i_Job) == 20 && !rp_GetClientBool(i, b_isAfk))
					nbConcess++;
			}
		}
		if(nbConcess == 0 || nbConcess == 1 && rp_GetClientInt(client, i_Job) == 20 || rp_GetClientInt(client, i_Job) == 20 && rp_GetClientInt(client, i_Grade) <= 2)
			NPC_MENU(client);
		else 
		{
			PrintHintText(client, "Malheureusement je suis indisponible, contactez un Concessionnaire.");
			CPrintToChat(client, "Malheureusement je suis indisponible, contactez un Concessionnaire.");
		}
	}
}

int NPC_MENU(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	
	Menu menu = new Menu(NPC_MENU_HANDLE);
	menu.SetTitle("PNJ - Concessionnaire");
	menu.AddItem("cars", "Voitures");
	menu.AddItem("upgrade", "Améliorations");
	menu.AddItem("perks", "Atouts");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "cars"))
			SellCars(client, client);	
		else if(StrEqual(info, "upgrade"))
			SellUpgrades(client, client);
		else if(StrEqual(info, "perks"))
			SellPerks(client, client);
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

public Action rp_MenuVendre(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 20)
	{
		menu.AddItem("cars", "Voitures");
		menu.AddItem("upgrade", "Améliorations");
		menu.AddItem("perks", "Atouts");
	}
}	

public int rp_HandleMenuVendre(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "cars"))
		SellCars(client, target);	
	else if(StrEqual(info, "upgrade"))
		SellUpgrades(client, target);
	else if(StrEqual(info, "perks"))
		SellPerks(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellCars(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Voitures Disponibles");

	for (int i = 1; i <= Vehicle_GetMaxCars(); i++)
	{
		prix = Vehicle_Price(i);		
		char carname[64];
		Vehicle_GetName(i, carname);
		
		Format(STRING(strFormat), "%i|%i|%i", target, prix, i);
		Format(STRING(strMenu), "%s (%i$)", carname, prix);
		menu.AddItem(strFormat, strMenu);
	}	
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

Menu SellUpgrades(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Améliorations Disponibles");

	prix = rp_GetPrice("turbo");			
	Format(STRING(strFormat), "%i|%i|turbo", target, prix);
	Format(STRING(strMenu), "Turbo +10KM/h (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("stage1");			
	Format(STRING(strFormat), "%i|%i|stage1", target, prix);
	Format(STRING(strMenu), "Stage 1[+10HP] (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("stage2");			
	Format(STRING(strFormat), "%i|%i|stage2", target, prix);
	Format(STRING(strMenu), "Stage 2[+25HP] (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("stage3");			
	Format(STRING(strFormat), "%i|%i|stage3", target, prix);
	Format(STRING(strMenu), "Stage 3[+50HP] (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

Menu SellPerks(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Atouts Disponibles");

	prix = rp_GetPrice("jerrican_essence");			
	Format(STRING(strFormat), "%i|%i|jerrican_essence", target, prix);
	Format(STRING(strMenu), "Jerrican d'essence (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("jerrican_diesel");			
	Format(STRING(strFormat), "%i|%i|jerrican_diesel", target, prix);
	Format(STRING(strMenu), "Jerrican de diesel (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
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
		int carid;
		
		if(String_IsNumeric(buffer[2]))
			carid = StringToInt(buffer[2]);
		
		Menu quantity = new Menu(DoMenuQuantity);
		quantity.SetTitle("Choisissez la quantité");
			
		if(!String_IsNumeric(buffer[2]))
		{
			for(int i = 1; i <= 10; i++)
			{			
				Format(STRING(strQuantite), "%i|%i|%s|%i", target, prix, buffer[2], i);
				Format(STRING(strFormat), "%i", i);
				quantity.AddItem(strQuantite, strFormat);
			}	
			Format(STRING(strQuantite), "%i|%i|%s|25", target, prix, buffer[2]);
			quantity.AddItem(strQuantite, "25");
			Format(STRING(strQuantite), "%i|%i|%s|50", target, prix, buffer[2]);
			quantity.AddItem(strQuantite, "50");
			Format(STRING(strQuantite), "%i|%i|%s|100", target, prix, buffer[2]);
			quantity.AddItem(strQuantite, "100");
		}
		else
		{
			char carname[64], strIndex[64];
			Vehicle_GetName(carid, carname);
			
			Format(STRING(strQuantite), "%i|%i|%i|1", target, prix, carid);
			Format(STRING(strIndex), "Vendre une %s", carname);
			menu.AddItem(strQuantite, strIndex);
		}	
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
		int quantity = StringToInt(buffer[3]);
		int prix = StringToInt(buffer[1]) * quantity;
		int carid;
		
		if(String_IsNumeric(buffer[2]))
			carid = StringToInt(buffer[2]);
		
		rp_SetClientBool(target, b_menuOpen, true);
		Menu request = new Menu(FinalMenu);
		
		if(String_IsNumeric(buffer[2]))
		{
			char carname[64];
			Vehicle_GetName(carid, carname);
			
			if(target != client)
				request.SetTitle("%N vous propose une %s pour %i$, acheter ?", client, carname, prix);	
			else
				request.SetTitle("Acheter une %s pour %i$ ?", carname, prix);		
		}		
				
		
		if(String_IsNumeric(buffer[2]))
			Format(STRING(response), "%i|%i|%i|%i|oui", client, quantity, carid, prix);
		else
			Format(STRING(response), "%i|%i|%s|%i|oui", client, quantity, buffer[2], prix);		
		request.AddItem(response, "Payer en liquide.");
		
		if(rp_GetClientBool(target, b_asCb))
		{
			if(String_IsNumeric(buffer[2]))
				Format(STRING(response), "%i|%i|%i|%i|cb", client, quantity, carid, prix);		
			else
				Format(STRING(response), "%i|%i|%s|%i|cb", client, quantity, buffer[2], prix);					
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
		bool payCB;
		bool canPass;
		int carid;
		char carname[64];
		
		if(String_IsNumeric(buffer[2]))
		{
			Vehicle_GetName(carid, carname);
			carid = StringToInt(buffer[2]);
		}	
		
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
						rp_SetJobCapital(20, rp_GetJobCapital(20) + prix / 2);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);
					
					canPass = true;
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
						rp_SetJobCapital(20, rp_GetJobCapital(20) + prix / 2);
						rp_SetJobCapital(5, rp_GetJobCapital(5) + prix / 2);
					}
					else
						rp_SetClientInt(vendeur, i_Money, rp_GetClientInt(vendeur, i_Money) + prix / 4);					
					
					canPass = true;
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
			
			if(canPass)
			{
				if(vendeur == client)
				{
					CPrintToChat(client, "%s Vous avez acheté %i %s pour %i$.", TEAM, quantity, buffer[2], prix);
					LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$.", client, quantity, buffer[2], prix);
				}
				else
				{
					CPrintToChat(client, "%s Vous avez acheté %i %s à %N pour %i$.", TEAM, quantity, buffer[2], vendeur, prix);
					CPrintToChat(vendeur, "%s Vous avez vendu %i %s à %N pour %i$.", TEAM, quantity, buffer[2], client, prix);
					LogToFile(logFile, "Le joueur %N a achete %i %s pour %i$ a %N.", client, quantity, buffer[2], prix, client);
				}
				
				rp_SetClientBool(vendeur, b_menuOpen, false);
				rp_SetClientBool(client, b_menuOpen, false);
			}	
			
			if(StrEqual(buffer[2], "jerrican_diesel"))
			{
				rp_SetClientItem(client, i_jerrican_diesel, rp_GetClientItem(client, i_jerrican_diesel) + 1);
				SetSQL_Int(g_DB, "rp_concessionnaire", "jerrican_diesel", rp_GetClientItem(client, i_jerrican_diesel), steamID[client]);
			}	
			else if(StrEqual(buffer[2], "jerrican_essence"))
			{
				rp_SetClientItem(client, i_jerrican_essence, rp_GetClientItem(client, i_jerrican_essence) + 1);
				SetSQL_Int(g_DB, "rp_concessionnaire", "jerrican_essence", rp_GetClientItem(client, i_jerrican_essence), steamID[client]);
			}
			else if(String_IsNumeric(buffer[2]))
			{
				char playername[MAX_NAME_LENGTH + 8];
				GetClientName(client, STRING(playername));
				char clean_playername[MAX_NAME_LENGTH * 2 + 16];
				SQL_EscapeString(g_DB, playername, STRING(clean_playername));
				
				char SQLBuff[2048];
				Format(STRING(SQLBuff), "INSERT IGNORE INTO `rp_garage` (`Id`, `steamid`, `playername`, `carID`, `r`, `g`, `b`, `fuel`, `health`, `km`, `stat`, `timestamp`) VALUES (NULL, '%s', '%s', '%i', '255', '255', '255', '%i', '100', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername, carid, Vehicle_GetMaxFuel(carid));
				g_DB.Query(SQLErrorCheckCallback, SQLBuff);
			}	
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