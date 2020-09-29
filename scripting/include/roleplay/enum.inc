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

//*********************************************************************
//*                       CORE MAIN ENUM                              *
//*********************************************************************

/**
 * All Boolean Variables
 *
 * @noreturn
 **/
enum bool_user_data {
	b_menuOpen,
	b_inUse,
	b_inReload,
	b_inDuck,
	b_isAfk,
	b_IsMuteGlobal,
	b_IsMuteLocal,
	b_IsMuteVocal,
	b_isInvincible,
	b_isBlind,
	b_isTased,
	b_canItem,
	b_isJoint,
	b_isShit,
	b_isAmphetamine,
	b_isHeroine,
	b_isCocaine,
	b_isEcstasy,
	b_isBeacon,
	b_isBombe,
	b_isDrug,
	b_isInvisible,
	b_isArrested,
	b_isLubrifiant,
	b_canJail,
	b_IsSearchByTribunal,
	b_compteSuisse,
	b_doubleImprimante,
	b_regenerationbionique,
	b_isTeamTalking,
	b_asRib,
	b_asCb,
	b_isEventParticipant,
	b_asPermis,
	b_asMandat,
	b_isClientNew,
	b_isThirdPerson,
	b_addNote,
	b_asChiru_Coeur,
	b_asChiru_Jambe,
	b_asChiru_Foie,
	b_asChiru_Poumon,
	b_asChiru_Muscle,
	b_asMaladie_Covid,
	b_asMaladie_Diarree,
	b_asMaladie_Angine,
	b_asMaladie_Peste,
	b_asRegen_HP,
	b_asRegen_Armor,
	b_asPermisConduire,
	b_asMasque,
	b_asBankedItem,
	b_IsNoPyj,
	b_Crayon,
	b_IsOnCall,
	b_asCrowbar,
	b_firstPerson,
	b_isZombie,
	b_udata_max
};

/**
 * All Integer Variables
 *
 * @noreturn
 **/
enum int_user_data {
	i_Money,
	i_Bank,
	i_Job,
	i_Grade,
	i_Salaire,
	i_AdminLevel,
	i_timeJail,
	i_timeJail_Last,
	i_KillJailDuration,
	i_jailTime_Reason,
	i_JailledBy,
	i_LastButton,
	i_Group,
	i_VipTime,
	i_countDrogue,
	i_Fuel,
	i_LastVolTarget,
	i_LastVolTime,
	i_LastVolAmount,
	i_LastVolArme,
	i_LastAgression,
	i_LastKilled_Reverse,
	i_LastVol,
	i_MoneySpent_Fines,
	i_LastDangerousShot,
	i_ByteZone,
	i_appartement,
	i_loyer,
	i_poubelles,
	i_garage,
	i_maxVie,
	i_MarriedTo,
	i_AppartCount,
	i_PhoneCallReceiver,
	i_KitCrochetage,
	i_AddToPay,
	i_udata_max
};

/**
 * All Float Variables
 *
 * @noreturn
 **/
enum float_user_data {
	Float:fl_Vitality,
	Float:fl_PlayerIP,
	Float:fl_FrozenTime,
	Float:fl_Faim,
	Float:fl_udata_max
};

/**
 * All String Variables
 *
 * @noreturn
 **/
enum sz_user_data {
	String:sz_Skin,
	String:sz_AdminTag,
	String:sz_Zone,
	String:sz_Casier,
	sz_udata_max
};

enum fd_user_data {
	fd_flash,
	fd_udata_max
};

/**
 * All In-Game Avaibles Items
 *
 * @noreturn
 **/
enum item_list {
	// Dealer
	i_joint = 0,
	i_shit = 1,
	i_amphetamine = 2,
	i_heroine = 3,
	i_cocaine = 4,
	i_ecstasy = 5,
	i_plante = 6,
	// Technicien
	i_blindage = 7,
	i_recharge = 8,
	i_ameliorationv1 = 9,
	i_ameliorationv2 = 10,
	i_imprimantes = 11,
	i_rechargebionique = 12,
	i_mines = 13,
	i_propulseur = 14,
	i_gestionnaire = 15,
	// Armurier
	pistol_p2000 = 16,
	pistol_usps = 17,
	pistol_glock18 = 18,
	pistol_p250 = 19,
	pistol_fiveseven = 20,
	pistol_tec9 = 21,
	pistol_cz75 = 22,
	pistol_dualberettas = 23,
	pistol_deagle = 24,
	pistol_revolver = 25,
	smg_mp9 = 26,
	smg_mac10 = 27,
	smg_ppbizon = 28,
	smg_mp7 = 29,
	smg_ump45 = 30,
	smg_p90 = 31,
	smg_mp5sd = 32,
	rifle_famas = 33,
	rifle_galilar = 34,
	rifle_m4a4 = 35,
	rifle_m4a1s = 36,
	rifle_ak47 = 37,
	rifle_aug = 38,
	rifle_sg553 = 39,
	rifle_ssg08 = 40,
	rifle_awp = 41,
	rifle_scar20 = 42,
	rifle_g3sg1 = 43,
	heavy_nova = 44,
	heavy_xm1014 = 45,
	heavy_mag7 = 46,
	heavy_sawedoff = 47,
	heavy_m249 = 48,
	heavy_negev = 49,
	grenade_he = 50,
	grenade_flash = 51,
	grenade_smoke = 52,
	grenade_decoy = 53,
	grenade_molotov = 54,
	grenade_incendiary = 55,
	gear_kevlar = 56,
	gear_helmet = 57,
	gear_zeus = 58,
	gear_assaultsuit = 59,
	gear_medishot = 60,
	gear_tacticalgrenade = 61,
	gear_breachcharge = 62,
	gear_parachute = 63,
	gear_axe = 64,
	gear_hammer = 65,
	gear_wrench = 66,
	gear_exojump = 67,
	gear_bumpmine = 68,
	gear_shield = 69,
	i_munition = 70,
	i_munitionsincendiaire = 71,
	i_munitionscaoutchouc = 72,
	i_munitionsperforante = 73,
	i_munitionsexplosive = 74,
	i_sanandreas = 75,
	immo_propatm = 76,
	immo_propfaim = 77,
	//Vendeurdeskin
	i_skin1 = 78,
	i_skin2 = 79,
	i_skin3 = 80,
	i_skin4 = 81,
	i_skin5 = 82,
	i_skin6 = 83,
	i_skin7 = 84,
	i_skin8 = 85,
	i_skin9 = 86,
	i_skin10 = 87,
	i_skin11 = 88,
	i_skin12 = 89,
	i_skin13 = 90,
	i_skin14 = 91,
	i_skin15 = 92,
	// SexShop
	i_sucetteduo = 93,
	i_ensemblesexy = 94,
	i_preservatif = 95,
	i_menotte = 96,
	i_lubrifiant = 97,
	i_kevlarbox = 98,
	// Loto
	i_ticketgratter = 99,
	i_loto = 100,
	i_rapido = 101,
	i_lampetorche = 102,
	i_peinture = 103,
	i_graffiti1 = 104,
	i_graffiti2 = 105,
	i_graffiti3 = 106,
	i_graffiti4 = 107,
	i_graffiti5 = 108,
	// Concessionaire
	i_jerrican_essence = 109,
	i_jerrican_diesel = 110,
	// Hopital
	i_seringue = 111,
	i_regenhp = 112,
	i_sirop = 113,
	i_remede = 114,
	i_antidote = 115,
	i_masque = 116,
	i_chiru_coeur = 117,
	i_chiru_jambe = 118,
	i_chiru_poumon = 119,
	i_chiru_muscle = 120,
	i_chiru_foie = 121,
	i_bigmac = 122,
	i_happymeal = 123,
	i_royalmcchicken = 124,
	i_soda = 125
};

/**
 * Weapon Ammunition Types
 *
 * @noreturn
 **/
enum enum_ball_type {
	ball_type_none,
	ball_type_fire,
	ball_type_caoutchouc,
	ball_type_poison,
	ball_type_vampire,
	ball_type_antikevlar,
	ball_type_paintball,
	ball_type_reflexive,
	ball_type_explode,
	ball_type_revitalisante,
	ball_type_nosteal,
	ball_type_notk,
	ball_type_braquage,
	ball_type_max
};

/**
 * GameMode Event Types
 *
 * @noreturn
 **/
enum enum_event_type {
	event_type_none,
	event_type_murder,
	event_type_buildwars,
	event_type_max
};

/**
 * All Gang Variables
 *
 * @noreturn
 **/
enum enum_group_data {
	group_type_name,
	group_type_pointClan,
	group_type_membres,
	group_type_maxMembres,
	group_type_money,
	group_type_owner,
	group_type_level
};

/**
 * All item builded and ready to get selled values
 *
 * @noreturn
 **/
enum stock_item_builded {
	stock_joint,
	stock_shit,
	stock_heroine,
	stock_amphetamine,
	stock_cocaine,
	stock_ecstasy,
	stock_plante
};

/**
 * All Vehicle variables
 *
 * @noreturn
 **/
enum vehicle_data {
	Float:car_fuel,
	Float:car_maxFuel,
	Float:car_km,
	Float:car_health,
	car_fueltype, /* 1 = Essence / 2 = Diesel */ 
	car_controle_technique,
	car_owner,
	car_maxPassager,
	car_horsepower,
	car_r,
	car_g,
	car_b,
	car_a,
	car_particle,
	car_donateur,
	car_price,
	car_boost
};

/**
 * All Time variables
 *
 * @noreturn
 **/
enum time_data {
	i_hour1,
	i_hour2,
	i_minute1,
	i_minute2,
	i_day,
	i_month,
	i_year
};

/**
 * Appartement variables
 *
 * @noreturn
 **/
enum appart_data {
	appart_proprio
};

/**
 * Player Rank Variables
 *
 * @noreturn
 **/
enum rankType 
{
	rank_type_id,
	rank_type_level,
	rank_type_name,
	rank_type_description
};

enum rp_item_type 
{
	item_type_name,
	item_type_reuse_delay,
	item_type_job_id,
	item_type_prix,
	item_type_taxes
};

enum rp_phone_type
{
	phone_number,
	phone_credit
};