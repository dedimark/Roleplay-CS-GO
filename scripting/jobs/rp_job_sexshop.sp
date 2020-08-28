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
char dbconfig[] = "roleplay";
char steamID[MAXPLAYERS + 1][32];
Database g_DB;

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
	if(rp_licensing_isValid())
	{
		GameCheck();
		BuildPath(Path_SM, STRING(logFile), "logs/roleplay/jobs/rp_job_sexshop.log");
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
		
		char buffer[4096];
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_sexshop` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `sucetteduo` int(100) NOT NULL, \
		  `ensemblesexy` int(100) NOT NULL, \
		  `preservatif` int(100) NOT NULL, \
		  `menotte` int(100) NOT NULL, \
		  `lubrifiant` int(100) NOT NULL, \
		  `kevlarbox` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void rp_OnClientSpawn(int client)
{
	rp_SetClientBool(client, b_isLubrifiant, false);
}

public void rp_OnClientDeath(int client)
{
	if(rp_GetClientBool(client, b_isLubrifiant))
	{
		rp_SetClientBool(client, b_isLubrifiant, false);
		CPrintToChat(client, "%s Vous n'êtes plus lubrifié.", TEAM);
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
	SQL_EscapeString(g_DB, playername, STRING(clean_playername));
	
	char buffer[2048];
	Format(STRING(buffer), "INSERT IGNORE INTO `rp_sexshop` (`Id`, `steamid`, `playername`, `sucetteduo`, `ensemblesexy`, `preservatif`, `menotte`, `lubrifiant`, `kevlarbox`, `timestamp`) VALUES (NULL, '%s', '%s', '0', '0', '0', '0', '0', '0', CURRENT_TIMESTAMP);", steamID[client], clean_playername);
	g_DB.Query(SQLErrorCheckCallback, buffer);
	
	LoadSexshop(client);
}

public Action rp_reloadData()
{
	LoopClients(i)
	{
		LoadSexshop(i);
	}	
}	

public void LoadSexshop(int client) 
{
	if (!IsClientValid(client))
		return;
			
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_sexshop WHERE steamid = '%s'", steamID[client]);
	g_DB.Query(LoadCallBackSQL, buffer, GetClientUserId(client));
}

public void LoadCallBackSQL(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (Results.FetchRow()) 
	{
		rp_SetClientItem(client, i_sucetteduo, SQL_FetchIntByName(Results, "sucetteduo"));
		rp_SetClientItem(client, i_ensemblesexy, SQL_FetchIntByName(Results, "ensemblesexy"));
		rp_SetClientItem(client, i_preservatif, SQL_FetchIntByName(Results, "preservatif"));
		rp_SetClientItem(client, i_menotte, SQL_FetchIntByName(Results, "menotte"));
		rp_SetClientItem(client, i_lubrifiant, SQL_FetchIntByName(Results, "lubrifiant"));
		rp_SetClientItem(client, i_kevlarbox, SQL_FetchIntByName(Results, "kevlarbox"));
	}
}

public Action rp_MenuInventory(int client, Menu menu)
{
	char amount[128];
	
	//menu.AddItem("", "⁂ SexShop ⁂", ITEMDRAW_DISABLED);
	
	if(rp_GetClientItem(client, i_sucetteduo) >= 1)
	{
		Format(STRING(amount), "Sucette Duo [%i]", rp_GetClientItem(client, i_sucetteduo));
		menu.AddItem("sucetteduo", amount);
	}
	
	if(rp_GetClientItem(client, i_ensemblesexy) >= 1)
	{
		Format(STRING(amount), "Ensemble Sexy [%i]", rp_GetClientItem(client, i_ensemblesexy));
		menu.AddItem("ensemblesexy", amount);
	}
	
	if(rp_GetClientItem(client, i_preservatif) >= 1)
	{
		Format(STRING(amount), "Préservatif [%i]", rp_GetClientItem(client, i_preservatif));
		menu.AddItem("preservatif", amount);
	}
	
	if(rp_GetClientItem(client, i_menotte) >= 1)
	{
		Format(STRING(amount), "Menottes [%i]", rp_GetClientItem(client, i_menotte));
		menu.AddItem("menottes", amount);
	}
	
	if(rp_GetClientItem(client, i_lubrifiant) >= 1)
	{
		Format(STRING(amount), "Lubrifiant [%i]", rp_GetClientItem(client, i_lubrifiant));
		menu.AddItem("lubrifiant", amount);
	}
}	
	
public int rp_HandlerMenuInventory(int client, char[] info)
{
	if(StrEqual(info, "sucetteduo") && IsPlayerAlive(client))
	{
		rp_SetClientItem(client, i_sucetteduo, rp_GetClientItem(client, i_sucetteduo) - 1);
		SetSQL_Int(g_DB, "rp_sexshop", info, rp_GetClientItem(client, i_sucetteduo), steamID[client]);
				
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
	else if(StrEqual(info, "ensemblesexy") && IsPlayerAlive(client))
	{
		if(GetClientHealth(client) != 500)
		{
			rp_SetClientItem(client, i_ensemblesexy, rp_GetClientItem(client, i_ensemblesexy) - 1);
			SetSQL_Int(g_DB, "rp_sexshop", info, rp_GetClientItem(client, i_ensemblesexy), steamID[client]);
		
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
	else if(StrEqual(info, "preservatif") && IsPlayerAlive(client))
	{
		if(Client_GetArmor(client) != 150)
		{
			rp_SetClientItem(client, i_preservatif, rp_GetClientItem(client, i_preservatif) - 1);
			SetSQL_Int(g_DB, "rp_sexshop", info, rp_GetClientItem(client, i_preservatif), steamID[client]);
		
			Client_SetArmor(client, Client_GetArmor(client) + 25);
			
			CPrintToChat(client, "%s Vous utilisez {lightblue}un préservatif.", TEAM);
			LogToFile(logFile, "Le joueur %N a utilise un préservatif.", client);
		}
		else
			CPrintToChat(client, "%s Vous avez déjà {yellow}150{lightred}Kevlar{default}!", TEAM);
	}
	else if(StrEqual(info, "menottes") && IsPlayerAlive(client))
	{
		int aim = GetAimEnt(client, true);
		if(GetEntityMoveType(aim) != MOVETYPE_NONE)
		{
			char model[64];
			Entity_GetModel(aim, model, sizeof(model));
			
			if(StrContains(model, "player") != -1 && Distance(client, aim) < 200)
			{
				rp_SetClientItem(client, i_menotte, rp_GetClientItem(client, i_menotte) - 1);
				SetSQL_Int(g_DB, "rp_sexshop", info, rp_GetClientItem(client, i_menotte), steamID[client]);
				
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
	else if(StrEqual(info, "lubrifiant") && IsPlayerAlive(client))
	{
		if(!rp_GetClientBool(client, b_isLubrifiant))
		{
			rp_SetClientItem(client, i_lubrifiant, rp_GetClientItem(client, i_lubrifiant) - 1);
			SetSQL_Int(g_DB, "rp_sexshop", info, rp_GetClientItem(client, i_lubrifiant), steamID[client]);
		
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

public Action rp_OnClientInteract(int client, int aim, const char[] entName, const char[] entModel, const char[] entClassName)
{
	if(StrEqual(entName, "SexShop") && Distance(client, aim) <= 80.0)
	{
		int nbSex;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				if(rp_GetClientInt(i, i_Job) == 18 && !rp_GetClientBool(i, b_isAfk))
					nbSex++;
			}
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
	menu.AddItem("sexshop", "SexShop");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NPC_MENU_HANDLE(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "sexshop"))
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

public Action rp_MenuVendre(Menu menu, int client, int target)
{
	if(rp_GetClientInt(client, i_Job) == 18)
	{
		rp_SetClientBool(client, b_menuOpen, true);
		menu.AddItem("sexshop", "SexShop");
	}
}	

public int rp_HandleMenuVendre(int client, const char[] info)
{
	int target = GetAimEnt(client, false);
	
	if(StrEqual(info, "sexshop"))
		SellSexShop(client, target);	
}

/************************************************/
/***************** Menu Vente *****************/
Menu SellSexShop(int client, int target)
{
	int prix;
	char strFormat[64], strMenu[64];
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoSell);
	menu.SetTitle("Atouts Disponibles");

	prix = rp_GetPrice("sucetteduo");	
	Format(STRING(strFormat), "%i|%i|Sucette Duo", target, prix);
	Format(STRING(strMenu), "Sucette Duo (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("ensemblesexy");	
	Format(STRING(strFormat), "%i|%i|Ensemble sexy", target, prix);
	Format(STRING(strMenu), "Ensemble sexy (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("preservatif");	
	Format(STRING(strFormat), "%i|%i|Préservatif", target, prix);
	Format(STRING(strMenu), "Préservatif (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("menottes");	
	Format(STRING(strFormat), "%i|%i|Menottes", target, prix);
	Format(STRING(strMenu), "Menottes (%i$)", prix);
	menu.AddItem(strFormat, strMenu);
	
	prix = rp_GetPrice("lubrifiant");	
	Format(STRING(strFormat), "%i|%i|Lubrifiant", target, prix);
	Format(STRING(strMenu), "Lubrifiant (%i$)", prix);
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

		/* MENU QUANTITE */
		
		Menu quantity = new Menu(DoMenuQuantity);
		quantity.SetTitle("Choisissez la quantité");
			
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
		
		rp_SetClientBool(target, b_menuOpen, true);
		Menu request = new Menu(FinalMenu);
		
		if(target != client)
			request.SetTitle("%N vous propose %i %s pour %i$, acheter ?", client, quantity, buffer[2], prix);	
		else
			request.SetTitle("Acheter %i %s pour %i$ ?", quantity, buffer[2], prix);				
				
		
		Format(STRING(response), "%i|%i|%s|%i|oui", client, quantity, buffer[2], prix);		
		request.AddItem(response, "Payer en liquide.");
		
		if(rp_GetClientBool(target, b_asCb))
		{
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
			
			if(StrEqual(buffer[2], "Sucette Duo"))
			{
				rp_SetClientItem(client, i_sucetteduo, rp_GetClientItem(client, i_sucetteduo) + 1);
				SetSQL_Int(g_DB, "rp_sexshop", "sucetteduo", rp_GetClientItem(client, i_sucetteduo), steamID[client]);
			}	
			else if(StrEqual(buffer[2], "Ensemble sexy"))
			{
				rp_SetClientItem(client, i_ensemblesexy, rp_GetClientItem(client, i_ensemblesexy) + 1);
				SetSQL_Int(g_DB, "rp_sexshop", "ensemblesexy", rp_GetClientItem(client, i_ensemblesexy), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Préservatif"))
			{
				rp_SetClientItem(client, i_preservatif, rp_GetClientItem(client, i_preservatif) + 1);
				SetSQL_Int(g_DB, "rp_sexshop", "preservatif", rp_GetClientItem(client, i_preservatif), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Menottes"))
			{
				rp_SetClientItem(client, i_menotte, rp_GetClientItem(client, i_menotte) + 1);
				SetSQL_Int(g_DB, "rp_sexshop", "menottes", rp_GetClientItem(client, i_menotte), steamID[client]);
			}
			else if(StrEqual(buffer[2], "Lubrifiant"))
			{
				rp_SetClientItem(client, i_lubrifiant, rp_GetClientItem(client, i_lubrifiant) + 1);
				SetSQL_Int(g_DB, "rp_sexshop", "lubrifiant", rp_GetClientItem(client, i_lubrifiant), steamID[client]);
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
/************************************************/