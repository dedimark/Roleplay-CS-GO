/*
*   Roleplay CS:GO de Benito est mis à disposition selon les termes de la licence Creative Commons Attribution .
* - Pas d’Utilisation Commerciale 
* - Partage dans les Mêmes Conditions 4.0 International.
*
*   Fondé(e) sur une œuvre à https://github.com/Benito1020/Roleplay-CS-GO
*   Les autorisations au-delà du champ de cette licence peuvent être obtenues à https://steamcommunity.com/id/xsuprax/.
*
*   Merci de respecter le travail fourni par le ou les auteurs 
*   https://www.revolution-team.be - benitalpa1020@gmail.com
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
	b_isAfk,
	b_isGag,
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
	b_isMute,
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
	b_canVolArgent,
	b_canVolArme,
	b_isEventParticipant,
	b_asPermis,
	b_asMandat,
	b_isClientNew,
	b_addNote,
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
	i_Faim,
	i_Fuel,
	i_LastVolTarget,
	i_LastVolTime,
	i_LastVolAmount,
	i_LastVolArme,
	i_LastAgression,
	i_LastKilled_Reverse,
	i_MoneySpent_Fines,
	i_LastDangerousShot,
	i_ByteZone,
	i_appartement,
	i_loyer,
	i_poubelles,
	i_garage,
	i_udata_max
};

/**
 * All Float Variables
 *
 * @noreturn
 **/
enum float_user_data {
	fl_Vitality,
	fl_PlayerIP,
	fl_FrozenTime,
	fl_udata_max
};

/**
 * All String Variables
 *
 * @noreturn
 **/
enum sz_user_data {
	String:sz_Skin,
	String:sz_Maladie,
	String:sz_Chirurgie,
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
	i_joint,
	i_shit,
	i_amphetamine,
	i_heroine,
	i_cocaine,
	i_ecstasy,
	i_plante,
	// Technicien
	i_blindage,
	i_recharge,
	i_ameliorationv1,
	i_ameliorationv2,
	i_imprimantes,
	i_rechargebionique,
	i_mines,
	i_propulseur,
	i_gestionnaire,
	// Armurier
	pistol_p2000,
	pistol_usps,
	pistol_glock18,
	pistol_p250,
	pistol_fiveseven,
	pistol_tec9,
	pistol_cz75,
	pistol_dualberettas,
	pistol_deagle,
	pistol_revolver,
	smg_mp9,
	smg_mac10,
	smg_ppbizon,
	smg_mp7,
	smg_ump45,
	smg_p90,
	smg_mp5sd,
	rifle_famas,
	rifle_galilar,
	rifle_m4a4,
	rifle_m4a1s,
	rifle_ak47,
	rifle_aug,
	rifle_sg553,
	rifle_ssg08,
	rifle_awp,
	rifle_scar20,
	rifle_g3sg1,
	heavy_nova,
	heavy_xm1014,
	heavy_mag7,
	heavy_sawedoff,
	heavy_m249,
	heavy_negev,
	grenade_he,
	grenade_flash,
	grenade_smoke,
	grenade_decoy,
	grenade_molotov,
	grenade_incendiary,
	gear_kevlar,
	gear_helmet,
	gear_zeus,
	gear_assaultsuit,
	gear_medishot,
	gear_tacticalgrenade,
	gear_breachcharge,
	gear_parachute,
	gear_axe,
	gear_hammer,
	gear_wrench,
	gear_exojump,
	gear_bumpmine,
	gear_shield,
	i_munition,
	i_munitionsincendiaire,
	i_munitionscaoutchouc,
	i_munitionsperforante,
	i_munitionsexplosive,
	i_sanandreas,
	immo_propatm,
	immo_propfaim,
	//Vendeurdeskin
	i_skin1,
	i_skin2,
	i_skin3,
	i_skin4,
	i_skin5,
	i_skin6,
	i_skin7,
	i_skin8,
	i_skin9,
	i_skin10,
	i_skin11,
	i_skin12,
	i_skin13,
	i_skin14,
	i_skin15,
	// SexShop
	i_sucetteduo,
	i_ensemblesexy,
	i_preservatif,
	i_menotte,
	i_lubrifiant,
	i_kevlarbox,
	// Loto
	i_ticketgratter,
	i_loto,
	i_rapido,
	i_lampetorche,
	i_peinture,
	i_graffiti1,
	i_graffiti2,
	i_graffiti3,
	i_graffiti4,
	i_graffiti5,
	// Concessionaire
	i_jerrican_essence,
	i_jerrican_diesel
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
	String:Sz_groupeName[64],
	i_pointClan,
	i_membres,
	i_maxMembres,
	i_money,
	i_chef,
	i_level
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
	car_fuel,
	car_km,
	car_fueltype, /* 1 = Essence / 2 = Diesel */ 
	car_health
};