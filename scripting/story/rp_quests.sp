/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://www.lastfate.fr - benitalpa1020@gmail.com
*/

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							C O M P I L E  -  O P T I O N S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#pragma semicolon 1
#pragma newdecls required

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N C L U D E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <roleplay>
#include <multicolors>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤
 
							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/

char steamID[MAXPLAYERS + 1][32];
char playerIP[MAXPLAYERS + 1][64];
char dbconfig[] = "roleplay";

Database g_DB;

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = {
	name = "[Roleplay] Quête: Système", 
	author = "Benito",
	description = "Quête: Système",
	version = VERSION, 
	url = URL
};
	
/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  E V E N T S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public void OnPluginStart() 
{
	if(rp_licensing_isValid())
	{
		Database.Connect(GotDatabase, dbconfig);
	}
	else
		UnloadPlugin();
}

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("%T: %s", "DatabaseError", LANG_SERVER, error);
	} 
	else 
	{
		db.SetCharset("utf8");
		g_DB = db;
		
		char buffer[4096];
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_logs` ( \
		  `Id` bigint(20) NOT NULL AUTO_INCREMENT, \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `playername` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `ip` varchar(64) NOT NULL, \
		  `serial` int(100) NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`Id`), \
		  UNIQUE KEY `steamid` (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
		
		Format(STRING(buffer), 
		"CREATE TABLE IF NOT EXISTS `rp_parrain` ( \
		  `steamid` varchar(32) COLLATE utf8_bin NOT NULL, \
		  `parent` varchar(64) COLLATE utf8_bin NOT NULL, \
		  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`steamid`) \
		  )ENGINE = InnoDB DEFAULT CHARSET = utf8 COLLATE = utf8_bin;");
		g_DB.Query(SQLErrorCheckCallback, buffer);
	}
}

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
	GetClientIP(client, playerIP[client], sizeof(playerIP[]));
}

public void OnClientDisconnect(int client)
{
	rp_SetClientBool(client, b_isClientNew, false);
}

public void OnClientPutInServer(int client)
{
	rp_SetClientBool(client, b_isClientNew, true);
}

public void OnClientPostAdminCheck(int client) 
{	
	char buffer[512];
	Format(STRING(buffer), "SELECT * FROM rp_logs WHERE steamid = '%s';", steamID[client]);
	g_DB.Query(LoadBddData, buffer, GetClientUserId(client));
}

public void LoadBddData(Database db, DBResultSet Results, const char[] error, any data) 
{	
	int client = GetClientOfUserId(data);
	while (!Results.FetchRow() && client != 0) 
	{
		char playername[MAX_NAME_LENGTH + 8];
		GetClientName(client, STRING(playername));
		char clean_playername[MAX_NAME_LENGTH * 2 + 16];
		SQL_EscapeString(db, playername, STRING(clean_playername));
		
		char buffer[2048];
		Format(STRING(buffer), "INSERT IGNORE INTO `rp_logs` (`Id`, `steamid`, `playername`, `ip`, `serial`, `timestamp`) VALUES (NULL, '%s', '%s', '%s', '%i', CURRENT_TIMESTAMP);", steamID[client], clean_playername, playerIP[client], GetClientSerial(client));
		SQL_FastQuery(db, buffer);
		
		if(IsClientValid(client))
		{
			rp_SetClientBool(client, b_isClientNew, true);		
			Q1_Frame(client);
		}	
		
		CPrintToChatAll("%s %N vien de rejoindre le serveur pour la première fois.", TEAM, client);
	}
		
//	delete db;
} 	

// ----------------------------------------------------------------------------
Menu Q1_Frame(int client) 
{
	//SetEntityMoveType(client, MOVETYPE_NOCLIP);
	SetEntityMoveType(client, MOVETYPE_NONE);

	rp_SetClientBool(client, b_menuOpen, true);
	Panel panel = new Panel();
		
	panel.SetTitle("== Bienvenue sur le serveur RolePlay");
	panel.DrawText(" C'est votre première connexion,");
	panel.DrawText("vous devez donc faire notre tutoriel ");
	panel.DrawText("afin de vous familiariser avec ce mode");
	panel.DrawText("de jeu. A la fin de celui-ci vous");
	panel.DrawText("gagnerez 25.000$: la monnaie du jeu");
	panel.DrawText(" ");
	panel.DrawText(" Ce mode Roleplay est une sorte de simulation");
	panel.DrawText("de vie: vous pouvez avoir de l'argent,");
	panel.DrawText("un emploi etc.");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
	
	panel.Send(client, Q1_FrameCallBack, -1);
}

public int Q1_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q2_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

/*----------------------------------------------*/
Menu Q2_Frame(int client) 
{
	TeleportEntity(client, view_as<float>({479.600006, -4172.046875, -2007.968750}), NULL_VECTOR, NULL_VECTOR);
	
	rp_SetClientBool(client, b_menuOpen, true);		
	Panel panel = new Panel();
	
	panel.SetTitle("== Objectif 1: La ville");
	panel.DrawText(" Princeton est la ville dans laquelle");
	panel.DrawText("vous êtes, c'est la map du serveur. La ");
	panel.DrawText("justice y fait souvent défaut. De nombreux");
	panel.DrawText("meurtres y sont commis, et parfois impunis.");
	panel.DrawText(" ");
	panel.DrawText(" Bien que de nombreux citoyens s'entretuent");
	panel.DrawText("sachez, avant tout, que vous risquez de rester");
	panel.DrawText("de longues minutes en prison pour de telles actions.");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
	
	panel.Send(client, Q2_FrameCallBack, -1);
}

public int Q2_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q3_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

Menu Q3_Frame(int client) 
{
	TeleportEntity(client, view_as<float>({2091.670166, 1448.182006, -2015.968750}), NULL_VECTOR, NULL_VECTOR);
	
	rp_SetClientBool(client, b_menuOpen, true);		
	Panel panel = new Panel();
		
	panel.SetTitle("== Objectif 2: Le commissariat");
	panel.DrawText(" Selon le règlement de la police, vous");
	panel.DrawText("pouvez être mis en prison dans ce");
	panel.DrawText("commissariat pour différentes raisons.");
	panel.DrawText(" ");
	panel.DrawText(" Les principales raisons d’incarcération");
	panel.DrawText("sont: Le meurtre ou la tentative");
	panel.DrawText("de meurtre, le tir dans la rue, le vol,");
	panel.DrawText("les nuisances sonores, le trafic illégal");
	panel.DrawText(" ");
	panel.DrawText(" Votre futur emploi définira votre");
	panel.DrawText("camp. Par exemple, un mafieux vole de l'argent,");
	panel.DrawText("un mercenaire exécute des contrats, un");
	panel.DrawText("policier tentera de les en empêcher.");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
		
	panel.Send(client, Q3_FrameCallBack, -1);
}

public int Q3_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q4_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

Menu Q4_Frame(int client) 
{
	TeleportEntity(client, view_as<float>({2575.271484, -49.143787, -2103.9687500}), NULL_VECTOR, NULL_VECTOR);
	
	rp_SetClientBool(client, b_menuOpen, true);		
	Panel panel = new Panel();
	
	panel.SetTitle("== Objectif 3: Mettre son argent en sécurité");
	panel.DrawText(" Dans un premier temps pour éviter de vous");
	panel.DrawText("faire voler votre argent, déposez-le");
	panel.DrawText("en banque.");
	panel.DrawText(" ");
	panel.DrawText(" Pour cela, positionnez-vous devant un");
	panel.DrawText("distributeur, utilisez votre touche action (E).");
	panel.DrawText("Selectionnez l'action déposer argent.");
	panel.DrawText("Déposez-y le montant que vous souhaitez");
	panel.DrawText(" ");
	panel.DrawText(" Sachez tout de même que les banquiers vendent");
	panel.DrawText("des cartes et des comptes bancaires qui vous");
	panel.DrawText("faciliterons la vie plus tard sur le serveur.");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
	
	panel.Send(client, Q4_FrameCallBack, -1);
}

public int Q4_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q5_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

Menu Q5_Frame(int client) 
{
	TeleportEntity(client, view_as<float>({69.714050, -1702.226928, -2007.968750}), NULL_VECTOR, NULL_VECTOR);
	
	rp_SetClientBool(client, b_menuOpen, true);			
	Panel panel = new Panel();
	
	panel.SetTitle("== Objectif 4: Le Tribunal");
	panel.DrawText(" Sachez qu'un policier n'a pas le droit de mettre");
	panel.DrawText("en prison pour des faits qui ne se sont pas déroulés devant");
	panel.DrawText("ses yeux.");
	panel.DrawText(" ");
	panel.DrawText(" Si vous connaissez le nom de la personne qui vous a tué");
	panel.DrawText("et qu'un juge est présent, adressez-vous à lui.");
	panel.DrawText(" ");
	panel.DrawText(" En vérifiant l'historique du serveur, le juge ");
	panel.DrawText("appliquera une condamnation adaptée aux faits");
	panel.DrawText("reprochés. (Meurtre, vol, ...)");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
	
	panel.Send(client, Q5_FrameCallBack, -1);
}

public int Q5_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q6_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

Menu Q6_Frame(int client) 
{	
	TeleportEntity(client, view_as<float>({-1651.953125, 1153.367919, -2135.968750}), NULL_VECTOR, NULL_VECTOR);
	
	rp_SetClientBool(client, b_menuOpen, true);			
	Panel panel = new Panel();
	
	panel.SetTitle("== Objectif 5: L'armurerie");
	panel.DrawText("N'oubliez pas d'acheter un permis");
	panel.DrawText("de port d'arme à un banquier. Dans le cas contraire");
	panel.DrawText("un policier est en droit de vous arrêter.");
	panel.DrawText(" Restez discret, rangez la dans votre poche!");
	panel.DrawText(" Une arme a été ajoutée dans votre inventaire.");
	panel.DrawText("→ Entrez la commande /rp (ou /item) dans le chat général,");
	panel.DrawText("Appuyez sur la touche 1 afin de l'utiliser");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
	
	panel.Send(client, Q6_FrameCallBack, -1);
}

public int Q6_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q7_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

Menu Q7_Frame(int client) 
{
	TeleportEntity(client, view_as<float>({-1136.662353, -1949.210205, -1999.968750}), NULL_VECTOR, NULL_VECTOR);
	
	rp_SetClientBool(client, b_menuOpen, true);			
	Panel panel = new Panel();
	
	panel.SetTitle("== Objectif 6: Les appartements");
	panel.DrawText("");
	panel.DrawText(" Un appartement vous permet d'augmenter");
	panel.DrawText("votre paye. Lorsque vous aurez décroché");
	panel.DrawText("votre premier emploi, il est généralement");
	panel.DrawText("conseillé de louer un appart. Celui-ci");
	panel.DrawText("vous donne de l'énergie et vous rend votre vie.");
	panel.DrawText("Vous pouvez aussi y cacher différents objets");
	panel.DrawText("du jeu, tel que les machines à faux-billets");
	panel.DrawText("plants de drogue, armes, etc.");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
	
	panel.Send(client, Q7_FrameCallBack, -1);
}

public int Q7_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q8_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

Menu Q8_Frame(int client) 
{
	TeleportEntity(client, view_as<float>({1206.774414, 20.860591, -2149.071289}), NULL_VECTOR, NULL_VECTOR);
	
	rp_SetClientBool(client, b_menuOpen, true);	
	Panel panel = new Panel();
	
	panel.SetTitle("== Objectif 7: Un trafic illégal");
	panel.DrawText("");
	panel.DrawText(" Une imprimante à faux-billets et un plant");
	panel.DrawText("de drogue ont été ajoutés à votre");
	panel.DrawText("inventaire.");
	panel.DrawText(" ");
	panel.DrawText(" Trouvez-vous une cachette, et utilisez");
	panel.DrawText("ces objets (/rp -> Inventaire). Si vous êtes mal");
	panel.DrawText("caché, un policier est en droit de vous");
	panel.DrawText("arrêter ! ");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
	
	panel.Send(client, Q8_FrameCallBack, -1);
}

public int Q8_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q9_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

Menu Q9_Frame(int client) 
{
	rp_SetClientBool(client, b_menuOpen, true);	
	Panel panel = new Panel();
		
	panel.SetTitle("== Objectif 8: Le Tchat général");
	panel.DrawText("");
	panel.DrawText(" Le Tchat est divisé en plusieurs");
	panel.DrawText("catégories.");
	panel.DrawText(" ");
	panel.DrawText(" Le Tchat général, celui qui permet");
	panel.DrawText("de communiquer avec tout citoyen");
	panel.DrawText("présent en ville, mais aussi d'exécuter");
	panel.DrawText("diverses commandes (comme le /rp qu'on vient de voir).");
	panel.DrawText(" ");
	panel.DrawText(" Le Tchat équipe, permet de communiquer");
	panel.DrawText("avec les citoyens à coté de vous.");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
		
	panel.Send(client, Q9_FrameCallBack, -1);
}

public int Q9_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q10_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

Menu Q10_Frame(int client) 
{
	rp_SetClientBool(client, b_menuOpen, true);	
	Panel panel = new Panel();
	
	panel.SetTitle("== Objectif 10: Les commandes utiles");
	panel.DrawText("");
	panel.DrawText(" Il existe de nombreuses commandes et touches sur le");
	panel.DrawText("serveur. La plupart liées à votre");
	panel.DrawText("métier, que vous apprendrez sur le tas.");
	panel.DrawText(" - /out permet de sortir un joueur de votre planque");
	panel.DrawText(" - touche 'E' permet de vendre vos produits");
	panel.DrawText(" - /job Permet de voir les différents jobs connectés");
	panel.DrawText(" Afin de trouver un emploi, jetez un oeil à cette");
	panel.DrawText("commande. Elle permet de voir qui est chef,");
	panel.DrawText("vous saurez donc à qui vous adresser pour trouver");
	panel.DrawText("un emploi.");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
	
	panel.Send(client, Q10_FrameCallBack, -1);
}

public int Q10_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q12_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

Menu Q12_Frame(int client) 
{
	rp_SetClientBool(client, b_menuOpen, true);			
	Panel panel = new Panel();
	
	panel.SetTitle("== Objectif 11: Le mot de la fin");
	panel.DrawText("");
	panel.DrawText(" Derniers conseils avant de vous laisser");
	panel.DrawText("partir sur de bonnes bases.");
	panel.DrawText(" ");
	panel.DrawText("- Nous sommes sur CSGO, pas sur ARMA ni GMOD.");
	panel.DrawText("Il y a donc BEAUCOUP de meurtre en ville, armez vous.");
	panel.DrawText("- Seul les policiers et les juges sont là pour");
	panel.DrawText("sanctionner les meurtres. CACHEZ-VOUS.");
	panel.DrawText(" ");
	panel.DrawText("- Trouvez vous un job");
	panel.DrawText("- Décrochez le rang no-pyj");
	panel.DrawText("- Faites un tour sur notre Discord");
	panel.DrawText(" ");
	panel.DrawText(" Bon jeu!");
	panel.DrawText(" ");
	panel.DrawItem("Continuer ->");
	
	panel.Send(client, Q12_FrameCallBack, -1);
}

public int Q12_FrameCallBack(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		Q13_Frame(client);
	}
	else if(action == MenuAction_End) 
	{
		if( menu != INVALID_HANDLE )
			delete menu;
	}
}

Menu Q13_Frame(int client) 
{	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(MenuSelectParrain);
	menu.SetTitle("== Parrainage\n ");
				
	menu.AddItem("", "Quelqu'un de présent vous a t-il invité",		ITEMDRAW_DISABLED);
	menu.AddItem("", "à jouer sur notre serveur?  Si oui, qui?",		ITEMDRAW_DISABLED);
	
	menu.AddItem("none", "Personne, j'ai connu autrement le serveur");
	menu.AddItem("youtube", "Youtube, en regardant une vidéo");
			
	char szName[128];
	LoopClients(i) 
	{
		if( i == client )
			continue;
					
		Format(STRING(szName), "%N", i);					
		menu.AddItem(steamID[i], szName);
	}
				
	menu.ExitButton = true;
	menu.Display(client, 60);
}
public int MenuSelectParrain(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		char options[64];
		menu.GetItem(param2, options, sizeof(options));		
		
		if(!StrEqual(options, "none")) 
		{
			char buffer[1024], szSteamID[64];
			GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
			
			Format(STRING(buffer), "INSERT IGNORE INTO `rp_parrain` (`steamid`, `parent`, `timestamp`) VALUES ('%s', '%s', CURRENT_TIMESTAMP);", szSteamID, options);
			g_DB.Query(SQLErrorCheckCallback, buffer);
		}
		
		Q14_Frame(client);
		
		rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + 7500);
	}
	else if( action == MenuAction_End ) 
	{
		delete menu;
	}
}

Menu Q14_Frame(int client) 
{
	rp_SetClientBool(client, b_menuOpen, true);
		
	Menu menu = new Menu(MenuSelectJob);
	menu.SetTitle("== Votre premier job vous est offert\n ");
	menu.AddItem("", "Sachez que plus tard, vous devrez le trouver", ITEMDRAW_DISABLED);
	menu.AddItem("", "vous-même et être recruté par le chef d'un job.\n ", ITEMDRAW_DISABLED);
		
	char tmp[64], tmp2[8];
	
	for(int i = 1; i <= GetMaxJobs(); i++) 
	{		
		GetJobName(i, tmp);
		Format(STRING(tmp2), "%i", i);
		menu.AddItem(tmp2, tmp);
	}
				
	menu.ExitButton = true;
	menu.Display(client, 60);
}
public int MenuSelectJob(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		char options[64];
		menu.GetItem(param2, STRING(options));
		int job = StringToInt(options);
		
		char jobname[64];
		GetJobName(job, jobname);
		
		Menu menu2 = new Menu(MenuSelectJobFinal);			
		menu2.SetTitle("== Votre premier job vous est offert\nVous avez choisis comme métier\n%s\n \nSachez que plus tard, vous devrez le trouver\nVOUS-MÊME et être recruté par le chef d'un job.\n---------------------", jobname);
		
		Format(options, sizeof(options), "%i", job);
		menu2.AddItem("0", "Je veux choisir un autre job");
		menu2.AddItem(options, "Je confirme mon choix");
		menu2.ExitButton = false;
		menu2.Display(client, 60);
	
		rp_SetClientInt(client, i_Job, job);
		rp_SetClientInt(client, i_Grade, GetMaxGrades(job));
		
		LogToGame("[VR-Hosting.fr] [TUTORIAL] %L a terminé son tutoriel. Il a choisi %s comme job.", client, jobname);
		FakeClientCommand(client, "say /shownotes");
		
		rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + 15000);
		rp_SetClientBool(client, b_isClientNew, false);
		
		LoopClients(i)
		{
			if( i == client )
				continue;
			CPrintToChat(i, "%s %N vient de terminé son tutorial, il est %s. Aidez le !", TEAM, client, jobname);
		}
	}
	else if( action == MenuAction_End ) 
	{
		delete menu;
	}
}

public int MenuSelectJobFinal(Menu menu, MenuAction action, int client, int param) 
{
	if(action == MenuAction_Select) 
	{
		char options[64];
		menu.GetItem(param, STRING(options));
		
		if(StrEqual(options, "0"))
			Q14_Frame(client);
		else
		{
			rp_SetClientBool(client, b_menuOpen, false);
			CPrintToChat(client, "%s Bon jeu !", TEAM);
		}	
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}		