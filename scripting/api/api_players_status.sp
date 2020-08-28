#include <sourcemod>
#include <sdktools>
 
 
char nomDb[64] = "roleplay";
Database db;
// tableau de steamid
char s_PlayerSteamid[MAXPLAYERS+1][60];
 
 
public Plugin myinfo =
{
    name = "RP-CSGO",
    author = "Synchroneyes",
    description = "Plugin CSGO",
    version = "1.0.0.0",
    url = "https://synchroneyes.fr/"
}
 
 
 
public void OnPluginStart()
{
    connexionDB();
 
    //On met tous les joueurs connecté comme étant déconnecté, en cas de crash serveur
    SQL_FastQuery(db, "UPDATE api_players_status SET etat = 'deconnecte', date_deconnexion = CURRENT_TIMESTAMP, date_connexion = date_connexion WHERE etat = 'connecte';");
    CreateTimer(5.0, timerVerifJoueurs, 0, TIMER_REPEAT);
 
}
 
public Action:timerVerifJoueurs(Handle:timer, any:data)
{
    verifTousLesJoueurs();
}
 
public void verifTousLesJoueurs() {
    for(int i = 1; i < MAXPLAYERS; i++)
        verifJoueur(i);
}
 
 
public void verifJoueur(int client) {
    // Si un joueur est deconnecté mais n'est pas marqué comme déconnecté
    // Alors on le marque comme deconnecté
    char steamid[60];
    steamid = s_PlayerSteamid[client];
    char query[2048];
    char erreur[2048];
 
    Format(query, sizeof(query), "SELECT * FROM api_players_status WHERE steamid = '%s' AND etat = 'connecte';", steamid);
    // On fait la requête
 
    DBResultSet rQuery = SQL_Query(db, query);
    SQL_GetError(db, erreur, sizeof(erreur));
 
    if(SQL_GetRowCount(rQuery) != 0){
        // On vérifie qu'il est bien déco
        if(estDeco(steamid, client)) {
            forceDeconnexion(client);
        }
    }
 
    delete rQuery;
   
}
 
 
public bool verifJoueurConnexion(int client) {
    // On récupère le steamID de la personne
    char steamid[60];
    // ON vérifie qu'on peut bien récuperer un steamid
 
    if(!IsClientConnected (client))
        return false;
 
    if(!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true))
        return false;
 
 
    s_PlayerSteamid[client] = steamid;
 
    // On regarde en BDD si un joueur est déjà connecté
    char query[2048];
    char query2[2048];
    char query3[2048];
 
 
    char erreur[500];
 
    Format(query, sizeof(query), "SELECT * FROM api_players_status WHERE steamid = '%s' AND etat = 'connecte';", steamid);
    // On fait la requête
 
    DBResultSet rQuery = SQL_Query(db, query);
    SQL_GetError(db, erreur, sizeof(erreur));
 
    if(SQL_GetRowCount(rQuery) == 0){
        // Il se connecte
        Format(query2, sizeof(query2), "INSERT INTO api_players_status SET steamid = '%s', etat = 'connecte';", steamid);
        s_PlayerSteamid[client] = steamid;
 
    } else {
        // Il est déjà connecté
        // On annule ses dernieres connections
        Format(query2, sizeof(query2), "UPDATE api_players_status SET etat = 'deconnecte', date_deconnexion = CURRENT_TIMESTAMP, date_connexion = date_connexion WHERE etat = 'connecte' AND steamid = '%s';", steamid);
        Format(query3, sizeof(query3), "INSERT INTO api_players_status SET steamid = '%s', etat = 'connecte';", steamid);
 
    }
 
    SQL_FastQuery(db, query2);
    SQL_FastQuery(db, query3);
 
    delete rQuery;
    return true;
}
 
// Quand le joueur se connecte sur le RP
public void OnClientAuthorized(int client){
        verifJoueurConnexion(client);
}
 
// Quand un joueur se déconnecte
public OnClientDisconnect(int client) {
    forceDeconnexion(client);
}
 
 
public bool estDeco(char[] steamid, int idClient) {
    if(StrEqual(s_PlayerSteamid[idClient], steamid, false)) {
        // C'est que le joueur n'est pas deconnecte
        return false;
    }
    // Le joueur est bien déconnecté
    return true;
}
 
public void forceDeconnexion(int idClient) {
    // On marque le joueur comme étant déconnecté
 
    // On récupère l'ancien steamid
    char steamid[64];
    steamid = s_PlayerSteamid[idClient];
 
    // On supprime le steamid
    s_PlayerSteamid[idClient] = "";
    // Et on update la DB
    char query[2048];
    Format(query, sizeof(query), "UPDATE api_players_status SET etat = 'deconnecte', date_deconnexion = CURRENT_TIMESTAMP, date_connexion = date_connexion WHERE etat = 'connecte' AND steamid = '%s';", steamid);
    SQL_FastQuery(db, query);
 
}
 
public void connexionDB(){
    char erreur[255];
    db = SQL_Connect(nomDb, true, erreur, sizeof(erreur));
 
    if (db == null){
        PrintToServer("Erreur lors de la connexion: %s", erreur);
    }
 
    SQL_Query(db, "CREATE TABLE IF NOT EXISTS `api_players_status` ( `id` int(11) NOT NULL AUTO_INCREMENT, `steamid` varchar(60) NOT NULL, `etat` enum('connecte','deconnecte') NOT NULL, `date_connexion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, `date_deconnexion` timestamp NULL DEFAULT NULL, PRIMARY KEY (`id`));");
 
}