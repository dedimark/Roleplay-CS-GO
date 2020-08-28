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

							C O M P I L E  -  O P T I O N S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#pragma semicolon 1
#pragma newdecls required

#define SMIC					90 // $

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N C L U D E S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
#include <sourcemod>
#include <sdktools>
#include <roleplay>
#include <smlib>
#include <multicolors>

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							G L O B A L  -  V A R S

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
GlobalForward g_OnMenuMetier;
GlobalForward g_HandleOnMenuMetier;
Database g_DB;
char dbconfig[] = "roleplay";
char steamID[MAXPLAYERS + 1][32];

/*➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤

							P L U G I N  -  I N F O

➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤➤*/
public Plugin myinfo = 
{
	name = "[Roleplay] Menu Métier",
	author = "Benito",
	description = "Menu Métier + Forwards",
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
		g_OnMenuMetier = new GlobalForward("rp_MenuMetier", ET_Event, Param_Cell, Param_Cell);
		g_HandleOnMenuMetier = new GlobalForward("rp_HandlerMenuMetier", ET_Event, Param_Cell, Param_String);
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

public void OnClientAuthorized(int client, const char[] auth) 
{	
	strcopy(steamID[client], sizeof(steamID[]), auth);
}

public Action rp_MenuRoleplay(int client, Menu menu)
{
	menu.AddItem("metier", "Métier");
}

public int rp_HandlerMenuRoleplay(int client, const char[] info)
{
	if(StrEqual(info, "metier"))
		MenuGererMetier(client);
}

Menu MenuGererMetier(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuGererMetier);
	
	menu.SetTitle("Gérer mon métier :");
	if (rp_GetClientInt(client, i_Grade) <= 2)
	{
		menu.AddItem("employes", "Gérer mes employés");
		menu.AddItem("salaire", "Gérer les salaires");
		if (rp_GetClientInt(client, i_Job) != 1 && rp_GetClientInt(client, i_Job) != 2 && rp_GetClientInt(client, i_Job) != 3
		&& rp_GetClientInt(client, i_Job) != 7 && rp_GetClientInt(client, i_Job) != 8 && rp_GetClientInt(client, i_Job) != 12)
		{
			if (rp_GetClientInt(client, i_VipTime) != 0)
				menu.AddItem("prix", "Gérer le prix des produits");
			else
				menu.AddItem("", "Gérer le prix des produits (VIP)", ITEMDRAW_DISABLED);
		}
		
		menu.AddItem("note", "Gérer les notes");
	}
	else
		menu.AddItem("note", "Afficher les notes");
	
	Call_StartForward(g_OnMenuMetier);
	Call_PushCell(client);
	Call_PushCell(menu);
	Call_Finish();	
	
	menu.AddItem("demission", "Démissionner");	
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuGererMetier(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		Call_StartForward(g_HandleOnMenuMetier);
		Call_PushCell(client);
		Call_PushString(info);
		Call_Finish();		
		
		if (StrEqual(info, "employes"))
			MenuEmployes(client);
		else if (StrEqual(info, "note"))
			MenuNote(client);	
		else if (StrEqual(info, "salaire"))
		{
			char strFormat[64], strIndex[16];
			int montant[8];
			
			Menu menu1 = new Menu(DoMenuSalaireEmployes);			
			rp_SetClientBool(client, b_menuOpen, true);
			menu1.SetTitle("Gérer les salaires :");
			
			for (int i = 1; i <= GetMaxGrades(rp_GetClientInt(client, i_Job)); i++)
			{
				montant[i] = GetSalaire(rp_GetClientInt(client, i_Job), i);
				
				char gradeName[64];
				GetGradeName(i, rp_GetClientInt(client, i_Job), gradeName);
				
				Format(STRING(strFormat), "%s (%i$)", gradeName, montant[i]);
				Format(STRING(strIndex), "%i", i);
				menu1.AddItem(strIndex, strFormat);
			}

			menu1.ExitBackButton = true;
			menu1.ExitButton = true;
			menu1.Display(client, MENU_TIME_FOREVER);
		}
		//else if (StrEqual(info, "prix"))
			//MenuVendreModifier(client, -1, true);
		else if (StrEqual(info, "demission"))
		{
			char gradeName[64];
			GetGradeName(rp_GetClientInt(client, i_Grade), rp_GetClientInt(client, i_Job), gradeName);
			
			rp_SetClientBool(client, b_menuOpen, true);
			Menu menu2 = new Menu(DoMenuDemission);
			menu2.SetTitle("Voulez-vous vraiment démissionner de %s ?", gradeName);
			menu2.AddItem("oui", "Oui, je veux démissionner.");
			menu2.AddItem("non", "Non, je veux garder mon emploi.");
			menu2.ExitBackButton = true;
			menu2.ExitButton = true;
			menu2.Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if (param == MenuCancel_ExitBack)
			FakeClientCommand(client, "!rp");
	}
	else if (action == MenuAction_End)
		delete menu;
}

Menu MenuEmployes(int client) 
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuEmployes);
	menu.SetTitle("Gérer mes employés :");	
	menu.AddItem("embaucher", "Embaucher un employé");
	menu.AddItem("contrat", "Modifier contrat d'un employé");	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuEmployes(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "embaucher"))
		{
			int aim = GetAimEnt(client, true);
			if(IsValidEntity(aim))
			{
				if(rp_GetClientInt(aim, i_Job) == 0)
				{
					if(Distance(client, aim) <= 200.0)
						MenuEmbaucher(client, aim);
					else
					{
						CPrintToChat(client, "%s Vous êtes trop éloigné de la personne.", TEAM);
						MenuGererMetier(client);
					}
				}
				else
				{
					CPrintToChat(client, "%s Cette personne a déjà un emploi.", TEAM);
					rp_SetClientBool(client, b_menuOpen, false);
				}
			}
			else
			{
				CPrintToChat(client, "%s Vous devez regarder la personne à embaucher.", TEAM);
				MenuEmployes(client);
			}
		}
		else if(StrEqual(info, "contrat"))
		{
			rp_SetClientBool(client, b_menuOpen, true);
			Menu menuSelectGrade = new Menu(DoMenuGradeEmployes);
			menuSelectGrade.SetTitle("Gérer mes employés :");
			
			char buffer[128];
			Format(STRING(buffer), "SELECT steamid, playername, gradeid FROM rp_jobs WHERE jobid = %i ORDER BY gradeid;", rp_GetClientInt(client, i_Job));
			DBResultSet query = SQL_Query(g_DB, buffer);
			
			int rowCount = SQL_GetRowCount(query);
			if(query && rowCount != 0)
			{
				for(int i = 1; i <= rowCount; i++)
				{
					char name[32], strSteam[64], strJoueur[128], gradeName[64], strMenu[64];
					if(query.FetchRow())
					{
						int grade = query.FetchInt(2);						
						GetGradeName(grade, rp_GetClientInt(client, i_Job), gradeName);
						
						query.FetchString(0, STRING(strSteam));
						query.FetchString(1, STRING(name));
						
						Format(STRING(strJoueur), "%s : %s", name, gradeName);
						Format(STRING(strMenu), "%s|%s", strSteam, name);
						if(grade > rp_GetClientInt(client, i_Grade))
							menuSelectGrade.AddItem(strMenu, strJoueur);
						else
							menuSelectGrade.AddItem("", strJoueur, ITEMDRAW_DISABLED);
					}	
					else
						menuSelectGrade.AddItem("", "Database Error", ITEMDRAW_DISABLED);					
				}
			}
			else
				menuSelectGrade.AddItem("", "Vous n'avez pas d'employés.", ITEMDRAW_DISABLED);
			menuSelectGrade.ExitBackButton = true;
			menuSelectGrade.ExitButton = true;
			menuSelectGrade.Display(client, MENU_TIME_FOREVER);
			
			delete query;
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuGererMetier(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Action rp_SayOnPublic(int client, const char[] arg, const char[] Cmd, int args)
{
	if(rp_GetClientBool(client, b_addNote))
	{
		if(strlen(arg) <= 64)
			SetNote(client, rp_GetClientInt(client, i_Job), arg);
		else
		{
			CPrintToChat(client, "%s La note est trop longue (64 caractères max), veuillez recommencer.", TEAM);
			PrintHintText(client, "Note trop longue !\n64 caractères max !");
		}
			
		MenuNote(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}		

Menu MenuNote(int client)
{
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuNote);
	if(rp_GetClientInt(client, i_Grade) <= 2)
		menu.SetTitle("Gérer les notes :");
	else
		menu.SetTitle("Notes :");
	
	char note[2048];
	rp_GetJobNote(rp_GetClientInt(client, i_Job), STRING(note));
	
	if(StrEqual(note, "none"))
	{
		menu.AddItem("", "Aucune note.", ITEMDRAW_DISABLED);
		if(rp_GetClientInt(client, i_Grade) <= 2)
		{
			if(rp_GetClientBool(client, b_addNote))
			{
				menu.AddItem("", ">> Écrivez la note dans le chat ...", ITEMDRAW_DISABLED);
				menu.AddItem("annuler", ">> Annuler la modification");
			}
			else
				menu.AddItem("ajouter", "Ajouter une note");
		}
	}
	else
	{
		char buffer[64][64], strFormat[8];
		
		int count;
		if(StrContains(note, "|", false) != -1)
		{
			int len = ExplodeString(note, "|", buffer, 64, 64);
			for(int x = 0; x < len; x++)
			{
				Format(STRING(strFormat), "%i", x);
				if(rp_GetClientInt(client, i_Grade) <= 2)
					menu.AddItem(strFormat, buffer[x]);
				else
					menu.AddItem("", buffer[x], ITEMDRAW_DISABLED);
				count++;
			}
		}
		else
		{
			if(rp_GetClientInt(client, i_Grade) <= 2)
				menu.AddItem("0", note);
			else
				menu.AddItem("0", note, ITEMDRAW_DISABLED);
		}
		if(rp_GetClientInt(client, i_Grade) <= 2)
		{
			if(count < 64)
			{
				if(rp_GetClientBool(client, b_addNote))
				{
					menu.AddItem("", ">> Écrivez la note dans le chat ...", ITEMDRAW_DISABLED);
					menu.AddItem("annuler", "Annuler la modification");
				}
				else
					menu.AddItem("ajouter", ">> Ajouter une note");
			}
			else
				menu.AddItem("", ">> Note maximale attente", ITEMDRAW_DISABLED);
		}
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuNote(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "ajouter")) // bool:addNote[client]
		{
			rp_SetClientBool(client, b_addNote, true);
			MenuNote(client);
		}
		else if(StrEqual(info, "annuler"))
		{
			rp_SetClientBool(client, b_addNote, false);
			PrintHintText(client, "Ajout de note annulée.");
			MenuNote(client);
		}

		CPrintToChat(client, "%s Veuillez écrire la nouvelle note dans le chat (maximum 64 caractères).", TEAM);
		PrintHintText(client, "Écrivez la nouvelle note dans le chat.\n64 caratères maximum !");
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuNote(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuSalaireEmployes(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		int grade = StringToInt(info);
		
		MenuSalaireEmployes(client, grade);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuDemission(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		menu.GetItem(param, STRING(info));
		
		if(StrEqual(info, "oui"))
		{
			rp_SetClientInt(client, i_Job, 0);
			rp_SetClientInt(client, i_Grade, 0);
			
			LoadSalaire(client);
			
			CPrintToChat(client, "%s Vous avez démissionné de votre emploi.", TEAM);
			if(GetClientTeam(client) == CS_TEAM_CT)
				CS_SwitchTeam(client, CS_TEAM_T);
		}
		rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuGererMetier(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu MenuEmbaucher(int client, int aim)
{
	char jobNameAim[64], jobNameClient[64], strInfo[32]; 
	GetJobName(rp_GetClientInt(aim, i_Job), jobNameAim);
	GetJobName(rp_GetClientInt(client, i_Job), jobNameClient);
	
	CPrintToChat(client, "%s Vous avez proposé un emploi à %N.", TEAM, aim);
	
	rp_SetClientBool(aim, b_menuOpen, true);
	Menu menu = new Menu(DoMenuEmbaucher);
	menu.SetTitle("%N vous propose un emploi dans %s, accepter ?", client, jobNameClient);
	
	Format(STRING(strInfo), "oui|%i", client);
	menu.AddItem(strInfo, "Oui.");
	Format(STRING(strInfo), "non|%i", client);
	menu.AddItem(strInfo, "Non, refuser l'offre.");
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(aim, MENU_TIME_FOREVER);
}

public int DoMenuGradeEmployes(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], buffer[2][64];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 64);
		// buffer[0] : steamid
		// buffer[1] : name
		
		rp_SetClientBool(client, b_menuOpen, true);
		Menu GradeEmployes = new Menu(DoMenuGradeEmployesFinal);
		GradeEmployes.SetTitle("Éditer le contrat de %s :", buffer[1]);
		
		char strFormat[128];
		Format(STRING(strFormat), "%s|%s|rang", buffer[0], buffer[1]);
		if(rp_GetClientInt(client, i_Job) == 1)
			GradeEmployes.AddItem(strFormat, "Gérer sa promotion", ITEMDRAW_DISABLED);
		else if(rp_GetClientInt(client, i_Job) == 2 || rp_GetClientInt(client, i_Job) == 3)
			GradeEmployes.AddItem(strFormat, "Gérér son rang", ITEMDRAW_DISABLED);
			
		for (int i = 2; i <= GetMaxGrades(rp_GetClientInt(client, i_Job)); i++)
		{
			char gradeName[64];
			GetGradeName(i, rp_GetClientInt(client, i_Job), gradeName);
			
			Format(STRING(strFormat), "%s|%s|%i", buffer[0], buffer[1], i);
			GradeEmployes.AddItem(strFormat, gradeName);
		}	
		
		Format(STRING(strFormat), "%s|%s|0", buffer[0], buffer[1]);
		GradeEmployes.AddItem(strFormat, "Renvoyer");
		
		GradeEmployes.ExitBackButton = true;
		GradeEmployes.ExitButton = true;
		GradeEmployes.Display(client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuGererMetier(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuGradeEmployesFinal(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[128], buffer[3][128];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 3, 128);
		// buffer[0] : steamid
		// buffer[1] : name
		// buffer[2] : rang ou grade
		
		if(!StrEqual(buffer[2], "rang"))
		{
			int id;
			if(StrEqual(buffer[2], "0"))
				id = 0;
			else
				id = rp_GetClientInt(client, i_Job);
			
			int grade = StringToInt(buffer[2]);			
			int joueur = -1;
			
			LoopClients(i)
			{
				if(StrEqual(buffer[0], steamID[i]))
					joueur = Client_FindBySteamId(steamID[i]);
			}
			
			char jobName[64], gradeName[64];
			if(joueur != -1)
			{
				char oldGrade[64];
				GetGradeName(rp_GetClientInt(joueur, i_Grade), rp_GetClientInt(joueur, i_Job), oldGrade);
				
				rp_SetClientInt(joueur, i_Job, id);
				rp_SetClientInt(joueur, i_Grade, grade);

				GetJobName(rp_GetClientInt(joueur, i_Job), jobName);
				GetGradeName(rp_GetClientInt(joueur, i_Grade), rp_GetClientInt(joueur, i_Job), gradeName);
				
				CPrintToChat(joueur, "%s Vous avez été promu %s (%s) par %N.", TEAM, gradeName, jobName, client);
				CPrintToChat(client, "%s Vous avez promu %N au rang de %s (%s).", TEAM, joueur, gradeName, jobName);
				
				char hostname[128];
				GetConVarString(FindConVar("hostname"), STRING(hostname));
				
				DiscordWebHook hook = new DiscordWebHook(DISCORD_WEBHOOK);
				hook.SlackMode = true;	
				hook.SetUsername("Roleplay");	
				
				MessageEmbed Embed = new MessageEmbed();	
				Embed.SetColor("#00fd29");
				Embed.SetTitle(hostname);
				Embed.SetTitleLink("steam://connect/163.172.72.143:27115");
				Embed.AddField("Message", "Promotion", false);
				Embed.AddField("Ancien grade", oldGrade, false);
				Embed.AddField("Nouveau grade", gradeName, false);
				Embed.AddField("Patron", "%N", true, client);
				Embed.AddField("Employé", "%N", true, joueur);
				Embed.SetFooter("Roleplay CS:GO | VR-HOSTING.FR");
				Embed.SetFooterIcon("https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/2c/2cf89047920724a188854e85a1e7056d78a05d9e_full.jpg");
				Embed.SetThumb("https://forum.vr-hosting.fr/uploads/monthly_2020_07/TEAMgros.png.b36847e3e2cbee67ad53cc92955f7c8d.png");
				
				hook.Embed(Embed);	
				hook.Send();
				delete hook;
			}
			else
			{
				CPrintToChat(client, "%s Le contrat de votre employé a été correctement modifié.", TEAM);
				UpdateSQL(g_DB, "UPDATE rp_jobs SET jobid = %i, gradeid = %i WHERE steamid = '%s';", id, grade, buffer[0]);	
			}
			rp_SetClientBool(client, b_menuOpen, false);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuEmployes(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

Menu MenuSalaireEmployes(int client, int grade)
{
	char gradeName[64];
	GetGradeName(grade, rp_GetClientInt(client, i_Job), gradeName);
	
	rp_SetClientBool(client, b_menuOpen, true);
	Menu menu = new Menu(DoMenuSalaireEmployesFinal);
	
	int max;
	if(rp_GetJobCapital(rp_GetClientInt(client, i_Job)) > 2000000)
		max = 3800;
	else if(rp_GetJobCapital(rp_GetClientInt(client, i_Job)) > 1000000)
		max = 2420;
	else if(rp_GetJobCapital(rp_GetClientInt(client, i_Job)) > 900000)
		max = 1650;
	else if(rp_GetJobCapital(rp_GetClientInt(client, i_Job)) > 600000)
		max = 1200;
	else if(rp_GetJobCapital(rp_GetClientInt(client, i_Job)) > 450000)
		max = 800;
	else
		max = 600;
	
	int salaireActuel = GetSalaire(rp_GetClientInt(client, i_Job), grade);
	
	menu.SetTitle("Modifier le salaire du %s (%i$) :", gradeName, salaireActuel);
	char strFormat[16];
	Format(STRING(strFormat), "50|%i|%i", salaireActuel, grade);
	if(salaireActuel + 50 <= max)
		menu.AddItem(strFormat, "Ajouter 50$");
	else
		menu.AddItem("", "Ajouter 50$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "30|%i|%i", salaireActuel, grade);
	if(salaireActuel + 30 <= max)
		menu.AddItem(strFormat, "Ajouter 30$");
	else
		menu.AddItem("", "Ajouter 30$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "10|%i|%i", salaireActuel, grade);
	if(salaireActuel + 10 <= max)
		menu.AddItem(strFormat, "Ajouter 10$");
	else
		menu.AddItem("", "Ajouter 10$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "5|%i|%i", salaireActuel, grade);
	if(salaireActuel + 5 <= max)
		menu.AddItem(strFormat, "Ajouter 5$");
	else
		menu.AddItem("", "Ajouter 5$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "2|%i|%i", salaireActuel, grade);
	if(salaireActuel + 2 <= max)
		menu.AddItem(strFormat, "Ajouter 2$");
	else
		menu.AddItem("", "Ajouter 2$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "1|%i|%i", salaireActuel, grade);
	if(salaireActuel + 1 <= max)
		menu.AddItem(strFormat, "Ajouter 1$");
	else
		menu.AddItem("", "Ajouter 1$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "-1|%i|%i", salaireActuel, grade);
	if(salaireActuel - 1 >= SMIC)
		menu.AddItem(strFormat, "Retirer 1$");
	else
		menu.AddItem("", "Retirer 1$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "-2|%i|%i", salaireActuel, grade);
	if(salaireActuel - 2 >= SMIC)
		menu.AddItem(strFormat, "Retirer 2$");
	else
		menu.AddItem("", "Retirer 2$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "-5|%i|%i", salaireActuel, grade);
	if(salaireActuel - 5 >= SMIC)
		menu.AddItem(strFormat, "Retirer 5$");
	else
		menu.AddItem("", "Retirer 5$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "-10|%i|%i", salaireActuel, grade);
	if(salaireActuel - 10 >= SMIC)
		menu.AddItem(strFormat, "Retirer 10$");
	else
		menu.AddItem("", "Retirer 10$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "-30|%i|%i", salaireActuel, grade);
	if(salaireActuel - 30 >= SMIC)
		menu.AddItem(strFormat, "Retirer 30$");
	else
		menu.AddItem("", "Retirer 30$", ITEMDRAW_DISABLED);
	Format(STRING(strFormat), "-50|%i|%i", salaireActuel, grade);
	if(salaireActuel - 50 >= SMIC)
		menu.AddItem(strFormat, "Retirer 50$");
	else
		menu.AddItem("", "Retirer 50$", ITEMDRAW_DISABLED);
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int DoMenuSalaireEmployesFinal(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], buffer[3][16];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 3, 16);
		
		int montant = StringToInt(buffer[0]);
		int salaireActuel = StringToInt(buffer[1]);
		int grade = StringToInt(buffer[2]);
		int salaireFinal = salaireActuel + montant;
		
		SetSalaire(rp_GetClientInt(client, i_Job), grade, salaireFinal);
		
		PrintHintText(client, "Salaire modifié avec succès (%i$).", salaireFinal);
		
		MenuSalaireEmployes(client, grade);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit)
			rp_SetClientBool(client, b_menuOpen, false);
		else if(param == MenuCancel_ExitBack)
			MenuGererMetier(client);
	}
	else if(action == MenuAction_End)
		delete menu;
}

public int DoMenuEmbaucher(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char info[64], buffer[2][8];
		menu.GetItem(param, STRING(info));
		ExplodeString(info, "|", buffer, 2, 8);

		int patron = StringToInt(buffer[1]);
		
		if(IsValidEntity(patron))
		{
			if(StrEqual(buffer[0], "oui"))
			{
				if(rp_GetClientInt(client, i_Job) == 0)
				{
					rp_SetClientInt(client, i_Job, rp_GetClientInt(patron, i_Job));					
					rp_SetClientInt(client, i_Grade, GetMaxGrades(rp_GetClientInt(patron, i_Job)));
					
					char jobName[64], gradeName[64]; 
					GetJobName(rp_GetClientInt(client, i_Job), jobName);
					GetGradeName(rp_GetClientInt(client, i_Grade), rp_GetClientInt(client, i_Job), gradeName);
					
					CPrintToChat(patron, "%s Vous avez embauché %N.", TEAM, client);
					CPrintToChat(client, "%s Vous avez été embauché %s (%s) par %N.", TEAM, gradeName, jobName, patron);
					
					LoadSalaire(client);
				}
				else
					CPrintToChat(client, "%s Vous avez déjà un emploi.", TEAM);
			}
			else if(StrEqual(buffer[0], "non"))
			{
				CPrintToChat(client, "%s Vous avez refusé un emploi.", TEAM);
				CPrintToChat(patron, "%s %N a refusé la proposition d'embauche.", TEAM, client);
			}
		}
		rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_Exit || param == MenuCancel_ExitBack)
			rp_SetClientBool(client, b_menuOpen, false);
	}
	else if(action == MenuAction_End)
		delete menu;
}