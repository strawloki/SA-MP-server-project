// This is a comment
// uncomment the line below if you want to write a filterscript
//#define FILTERSCRIPT

#include <a_samp>
#include <sscanf2>
#include <YSI\y_ini>
#include <izcmd>

#define COLOR_JOBBLUE 0x3399FFFF
#define WHITE 0xFFFFFFFF
#define RED 0xbf0f0fFF
#define LBROWN 0x826b06FF
#define GREEN 0x7FFF00FF
#define LRED 0xFF4500FF
#define LBLUE 0xADD8E6FF
#define COLOR_POL 0x000099FF
#define COLOR_TAXI 0xFFCC00FF
#define YELLOW 0xFFFF00FF
#define DARK_GREY 0x708090FF
#define COLOR_FACT_ENROLL 0x9acd32FF
#define COLOR_TAXI 0xFFCC00FF
#define COLOR_VLBLUE 0x3399FFFF

#define DIALOG_REGISTER 1
#define DIALOG_LOGIN 2
#define DIALOG_SUCCESS_1 3
#define DIALOG_SUCCESS_2 4
#define DIALOG_JAILTIME 5
#define DIALOG_POL_SANCTION 6
#define DIALOG_CPS_TEAM 7
#define PATH "/Users/%s.ini"


#define FACTION_CIVILIAN 0
#define FACTION_LSPD 1
#define FACTION_SFPD 2
#define FACTION_LVPD 3
#define FACTION_TAXI 4

#define VW_CPS 7533


new bool:copDeliverToLS[MAX_PLAYERS], bool:copDeliverToSF[MAX_PLAYERS], bool:copDeliverToLV[MAX_PLAYERS], playerJailTime[MAX_PLAYERS];
new gToSanction[MAX_PLAYERS] = -1;
new bool:gIsLookingForTaxi[MAX_PLAYERS] = false;
new bool:gOnFare[MAX_PLAYERS] = false;
new gTaxiDriverTimerID[MAX_PLAYERS];
new bool:workLocCP[MAX_PLAYERS];
new bool:onGamemode[MAX_PLAYERS];
new bool:gOnCPSLobby[MAX_PLAYERS];
new gCPSLobbyCount;
new bool:gPlayerVotedToStart[MAX_PLAYERS], bool:gCopCPtoBank[MAX_PLAYERS], gRobCPtoDropoff[MAX_PLAYERS];
new gPlayersVotedToStart;
new gCPSPlayerTeam[MAX_PLAYERS] = -1; //0 = cops, 1 = robbers, -1 default
new gCPSCopsCount, gCPSRobbersCount, gCPSRobbersInCP, bool:firstRobber[MAX_PLAYERS], gCPSLiveCops, gCPSLiveRobbers;
new gCPScars[100];
new gCPSskin[MAX_PLAYERS], Float:gCPShealth[MAX_PLAYERS], Float:gCPSarmour[MAX_PLAYERS];


//------------------------------------------GENERAL JOB RELATED-------------------------------------------------------------------------

new bool:OnJob[MAX_PLAYERS];
enum Jobs
{
	JOB_UNEMPLOYED,
	JOB_DRUGDEALER = 1
}

new playerJob[Jobs];



//-----------------------------------------------------------------------------------------------------------------------------

//-----------------------------------------COPS AND ROBBERS RELATED------------------------------------------------------------

GetPlayerCPSTeam(player)
{
	return gCPSPlayerTeam[player];
}
forward ReleaseRobbers();
public ReleaseRobbers()
{
	for(new k = 0; k <= MAX_PLAYERS; k++)
	{
		if(!IsPlayerConnected(k)) continue;
		
		if(onGamemode[k])
		{
		    SendClientMessage(k, WHITE, "ReleaseRobbers reached. timer is done"); //DEBUG
		    if(GetPlayerCPSTeam(k) == 1)
		    {
		        SetPlayerPos(k, 1456.9622,-1009.9428,26.8438);
				SetPlayerInterior(k, 0);
				SetPlayerVirtualWorld(k, VW_CPS);
		        SendClientMessage(k, LBROWN, "You are now outside! Get to Ocean Docks as a whole to recieve your payment!");
		        SetPlayerCheckpoint(k, 2795.8799,-2529.8679,13.6291, 4.0);
		        gRobCPtoDropoff[k] = true;
		        
		    }
		    else if(GetPlayerCPSTeam(k) == 0)
		    {
		        SendMessageToCPS("The robbers are out of the bank! Get them!", 0, LBROWN);
		        DisablePlayerCheckpoint(k);

		    }
		    
		    //also send message to cops
		    else continue;
		}
	}
	
	return 1;
}


forward LoadCPScars();
public LoadCPScars()
{


	gCPScars[0] = CreateVehicle(596, 1574.2417, -1710.2268, 5.6122, 0, -1, -1, -1); //LSPD cruiser 01
	gCPScars[1] = CreateVehicle(596, 1578.2881,-1710.5026,5.6118, 0, -1, -1, -1); //2
	gCPScars[2] = CreateVehicle(596, 1583.3069,-1710.7852,5.6122, 0, -1, -1, -1); //3
	gCPScars[3] =  CreateVehicle(596, 1587.4552,-1710.2450,5.6117, 0, -1, -1, -1); //4
	gCPScars[4] =  CreateVehicle(523, 1569.9818,-1710.6219,5.4613, 0, -1, -1, -1); //HPV-100 1
	gCPScars[5] =  CreateVehicle(523, 1566.8430,-1710.2568,5.4555, 0, -1, -1, -1); //2
	gCPScars[6] =  CreateVehicle(523, 1563.6534,-1710.2148,5.4614, 0, -1, -1, -1); //3
	gCPScars[7] =  CreateVehicle(523, 1560.5071,-1710.0652,5.4616, 0, -1, -1, -1); //4
	gCPScars[8] =  CreateVehicle(497, 1569.4172,-1641.6417,28.5800, 0, -1, -1, -1); //LSPD heli
	gCPScars[9] =  CreateVehicle(427, 1559.4506,-1696.1320,6.0229, 133.8910, -1, -1, -1);  //Enforcer 1
	gCPScars[10] = CreateVehicle(427, 1571.6390,-1694.2380,6.0225, 179.0, -1, -1, -1);  //2
	gCPScars[11] =  CreateVehicle(601, 1600.6863,-1710.0192,5.6494, 0, -1, -1, -1); //SWAT 1
	gCPScars[12] = CreateVehicle(405, 1461.2388,-1039.1923,23.6112, 270.0, -1, -1, -1); //Sentinel
	gCPScars[13] = CreateVehicle(482, 1472.2046,-1028.7682,23.8600, 270.0, -1, -1, -1); //Burrito
	gCPScars[14] = CreateVehicle(468, 1500.1842,-1021.0579,23.4973, 95.9, -1, -1, -1); //Sanchez
	gCPScars[15] = CreateVehicle(521, 1098.3809,-1775.5804,12.9106, 90.0, -1, -1, -1); //fcr-900
	gCPScars[16] = CreateVehicle(560, 1062.5562,-1757.8948,13.1215, 270.0, -1, -1, -1); //Sultan
    gCPScars[17] = CreateVehicle(401, 1630.1322,-1107.6489,23.6853, 270.0, -1, -1, -1); //Bravura
	gCPScars[18] = CreateVehicle(402, 1078.0110,-1754.9359,13.2261, 270.0, -1, -1, -1); //Buffalo
	gCPScars[19] = CreateVehicle(405, 1099.0432,-1769.8618,13.2218, 270.0, -1, -1, -1); //Sentinel
	gCPScars[20] = CreateVehicle(422, 1620.9915,-1098.6835,23.8914, 270.0, -1, -1, -1); //Bobcat
	gCPScars[21] = CreateVehicle(424, 1648.1508,-1135.8783,23.6877, 270.0, -1, -1, -1); //Bf-inj
	gCPScars[22] = CreateVehicle(458, 1629.4270,-1089.1115,23.7848, 270.0, -1, -1, -1); //Solair
	gCPScars[23] = CreateVehicle(415, 2094.7109,-1982.9490,13.3175, 360.0, -1, -1, -1); //Cheetah
	gCPScars[24] = CreateVehicle(412, 2231.1963,-1994.7498,13.3846, 0, -1, -1, -1); //Voodoo
	gCPScars[25] = CreateVehicle(492, 2230.3628,-1753.0978,13.1723, 360.0, -1, -1, -1); //Greenwood
	gCPScars[26] = CreateVehicle(400, 1084.2764,-1775.4249,13.4371, 270.0, -1, -1, -1); //Landstalker
	gCPScars[27] = CreateVehicle(561, 1098.6614,-1763.6830,13.1639, 270.0, -1, -1, -1); //Stratum

	
    for(new veh = 0; veh <= sizeof(gCPScars); veh++)
	{
	    SetVehicleVirtualWorld(gCPScars[veh], VW_CPS);
	}


	return 1;
}

stock SendMessageToCPS(message[128], team, colour)
{
	
	switch(team)
	{
	    case 0: //cops
	    {

			new string[128];
			format(string, 128, "%s", message);
			for(new cop = 0; cop <= MAX_PLAYERS; cop++)
			{
				if(!onGamemode[cop]) continue;
			
				if(GetPlayerCPSTeam(cop) == 0)
				{
			 	   SendClientMessage(cop, colour, string);
			 	   return 1;
				}
			}
		}
	
		case 1: //robbers
		{

		
	    	new string[128];
	    	format(string, 128, "%s", message);
	    
	    	for(new rob = 0; rob <= MAX_PLAYERS; rob++)
  			{
   				if(!onGamemode[rob]) continue;

				if(GetPlayerCPSTeam(rob) == 1)
				{
				    SendClientMessage(rob, colour, string);
				    return 1;
				}
			}
		}
		case 2: //both
		{
		    new string[128];
			format(string, 128, "%s", message);
			
			for(new all = 0; all <= MAX_PLAYERS; all++)
			{
				if(onGamemode[all])
				{
					SendClientMessage(all, colour, string);
					return 1;
				}
			}
		}
		

	}
	return 1;
}

PickSkinCPS(teamid)
{
    new copSkins[8] =
	{
		280,
		281,
		282,
		284,
		285,
		265,
		266,
		267

	};

	new robberSkins[9] =
	{
		19,
		21,
		22,
		23,
		28,
		29,
		30,
		136,
		137
	};

	new skinid, slot;
	switch(teamid)
	{
	    case 0: //cops
	    {
	        slot = random(sizeof(copSkins));
	        skinid = copSkins[slot];
	    }
	    case 1: //robbers
	    {
	        slot = random(sizeof(robberSkins));
	        skinid = robberSkins[slot];
	    
	    }
	    default:
		{
			skinid = 0;
		}
	}
	return skinid;
}

stock DestroyCPScars()
{
    for(new car = 0; car <= sizeof(gCPScars); car++)
	{
	    DestroyVehicle(gCPScars[car]);
	    
	    if(car == sizeof(gCPScars)) return 1;
 	}
	return 1;
	
}

EndCPS()
{
    	gCPSLobbyCount = 0;
		gPlayersVotedToStart = 0;
		gCPSCopsCount = 0;
		gCPSRobbersCount = 0;
		gCPSRobbersInCP = 0;
		gCPSLiveCops = 0;
		gCPSLiveRobbers = 0;



	    for(new k = 0; k <= MAX_PLAYERS; k++)
	    {
	        if(k == MAX_PLAYERS)
	        {
	            DestroyCPScars();
	            continue;
	        }

	        gOnCPSLobby[k] = false;
			gPlayerVotedToStart[k] = false;
			gCopCPtoBank[k] = false;
			gRobCPtoDropoff[k] = false;
			gCPSPlayerTeam[k] = -1;
			firstRobber[k] = false;

			if(onGamemode[k])
			{
			    onGamemode[k] = false;
				SetPlayerPos(k, 1310.2595,-1367.2544,13.5261);
				SetPlayerVirtualWorld(k, 0);
				SetPlayerSkin(k, gCPSskin[k]);
				SetPlayerHealth(k, gCPShealth[k]);
				SetPlayerArmour(k, gCPSarmour[k]);
				
				DisablePlayerCheckpoint(k);

			}

		}
		return 1;
}


RobberEnterCPS(robber)
{
	gCPSRobbersInCP++;
	
	if(gCPSRobbersInCP == 1)
	{
	    SendClientMessage(robber, GREEN, " * You have entered the checkpoint first and you'll recieve a bonus!");
	    firstRobber[robber] = true;
	    new name[MAX_PLAYER_NAME], msg[128];
	    GetPlayerName(robber, name, sizeof(name));
	    format(msg, 128, " * Robber %s has entered the checkpoint first and will recieve a reward.", name);
	    
	    new copMsg[128];
	    format(copMsg, 128, "Robber %s has managed to escape!", name);
	    
	    SendMessageToCPS(msg, 1, GREEN);
	    SendMessageToCPS(copMsg, 0, RED);
	
	}
	
	if(gCPSRobbersInCP == gCPSLiveRobbers)
	{
	    //make reward first using function.
	
	    //reset variables and reward
		gCPSLobbyCount = 0;
		gPlayersVotedToStart = 0;
		gCPSCopsCount = 0;
		gCPSRobbersCount = 0;
		gCPSRobbersInCP = 0;
		gCPSLiveCops = 0;
		gCPSLiveRobbers = 0;
	    
		
		
	    for(new k = 0; k <= MAX_PLAYERS; k++)
	    {
	        if(k == MAX_PLAYERS)
	        {
	            DestroyCPScars();
	            continue;
	        }
	        
	        gOnCPSLobby[k] = false;
			gPlayerVotedToStart[k] = false;
			gCopCPtoBank[k] = false;
			gRobCPtoDropoff[k] = false;
			gCPSPlayerTeam[k] = -1;
			firstRobber[k] = false;
			
			if(onGamemode[k])
			{
			    onGamemode[k] = false;
				SetPlayerPos(k, 1310.2595,-1367.2544,13.5261);
				SetPlayerVirtualWorld(k, 0);
				SetPlayerSkin(k, gCPSskin[k]);
				SetPlayerHealth(k, gCPShealth[k]);
				SetPlayerArmour(k, gCPSarmour[k]);
				SendClientMessage(k, GREEN, " *** Gamemode is over! ***");
				DisablePlayerCheckpoint(k);
				
			}
			
		}
	
	}
	
	
	
	return 1;

}

InitiateCPSPlayers()
{

	for(new i = 0; i <= MAX_PLAYERS; i++)
	{
	  
	    if(onGamemode[i])
	    {
			switch(GetPlayerCPSTeam(i))
			{
			    case 0: //cops
			    {
			      
					
					SetPlayerSkin(i, PickSkinCPS(0));

					SetPlayerVirtualWorld(i, VW_CPS);
					SetPlayerInterior(i, 0);
					SetPlayerPos(i, 1568.8895,-1689.9803,6.2188); //lspd_spawn

					ResetPlayerWeapons(i);
					GivePlayerWeapon(i, 29, 500); //MP5
					GivePlayerWeapon(i, 3, 1); //Nightstick
					GivePlayerWeapon(i, 31, 150); //M4
					GivePlayerWeapon(i, 34, 35); //Sniper
					GivePlayerWeapon(i, 25, 15); //Shotgun
					SetPlayerHealth(i, 100.0);
					SetPlayerArmour(i, 100.0);

					SendClientMessage(i, LBROWN, "You have 45 seconds to get to the bank and stop them robbers!");
					SetPlayerCheckpoint(i, 1458.1301,-1033.8481,23.3833, 4.0);
					
					gCPSLiveCops = gCPSCopsCount;

					gCopCPtoBank[i] = true;

					
				
				}
				case 1: //robbers
				{
				    
  	     	 		SetPlayerSkin(i, PickSkinCPS(1));

		        	SetPlayerVirtualWorld(i, VW_CPS);
		        	SetPlayerPos(i, 2315.952880,-1.618174,26.742187); //bank_interior
		        	SetPlayerInterior(i, 0);

		        	ResetPlayerWeapons(i);
					GivePlayerWeapon(i, 28, 500); //uzi
					GivePlayerWeapon(i, 4, 1); //knife
					GivePlayerWeapon(i, 30, 100); //ak-47
					GivePlayerWeapon(i, 22, 175); //9mm
					GivePlayerWeapon(i, 18, 5); //molotov
					SetPlayerHealth(i, 100.0);
					SetPlayerArmour(i, 75.0);
					
					gCPSLiveRobbers = gCPSRobbersCount;
					
					
					SendClientMessage(i, LBROWN, "You are currently robbing the bank for 45 seconds. The police are on their way, so watch out when exiting!");
				
					
				}
			}
			
			
	    }
	}

	
	return 1;
}

LoadCPS()
{
	//Clean up lobby variables and related data?
	CallRemoteFunction("LoadCPScars", "");
	SetTimer("ReleaseRobbers", 45000, false); 
	InitiateCPSPlayers();
	
	return 1;
	
}

//-----------------------------------------------------------------------------------------------------------------------------

//------------------------------------------DRUGDEALER JOB RELATED-------------------------------------------------------------

enum DrugsLocation
{
	JobID,
	LocName[128],
	Float:DrugsX,
	Float:DrugsY,
	Float:DrugsZ,
	Payment
}

new DrugsLocations[][DrugsLocation] =
{
	{0, "the Los Santos Docks area", 2632.8940,-2047.4041,13.5500, 431},
	{1, "the garages in Los Santos", 2334.5356,-1239.3452,22.2271, 420},
	{2, "the houses in Marina, Los Santos", 769.8719,-1471.2968,13.3321, 460},
	{3, "the Richman area, Los Santos", 688.5792,-921.5528,75.8848, 490}
};

new DrugLSCarLocations[] = //fix this, this is incorrect, make as the one above
{
	{2523.5803,-2655.8008,13.3655},
	{2796.6567,-1584.6052,10.6540},
	{2382.3489,-1031.9370,53.4426},
	{1577.8600,-1551.0952,13.2943}

};

enum DrugLSCars
{
	LANDSTALKER = 400,
	BRAVURA = 401,
	ESPERANTO =  419,
	SOLAIR = 458,
	RANCHER = 489,
	BUCCANEER = 518
}

new DrugLSCarsID[DrugLSCars];

InitiateDrugDealerJob(player)
{
    if(IsPlayerInRangeOfPoint(player, 10.0, 2212.4729,-2044.7767,13.5469)) //Drug Dealer LS
    {
        new randomLocation = random(sizeof(DrugsLocations));
        new randomCarLoc = random(sizeof(DrugLSCarLocations));
        
        
        new Float:DestX, Float:DestY, Float:DestZ;
        new Float:CarX, Float:CarY, Float:Z;
        
        DestX = DrugsLocations[randomLocation][DrugsX];
        DestY = DrugsLocations[randomLocation][DrugsY];
        DestZ = DrugsLocations[randomLocation][DrugsZ];
        
        CarX =
        CarY
        CarZ
        
    }


}

//------------------------------------------------------------------------------------------------------------------------------------------------

//-------------------------------TAXI RELATED-----------------------------------------------------------------------------------------------------

TaxTaxiFare(fare, oldCount, newCount, taxiDrv)
{
	//convert to minutes, 1min = 6$, +20$

	new toTax = newCount - oldCount;

	toTax = toTax / 60;

	new toPay = (toTax * 1) + 20;

	GivePlayerMoney(fare, -toPay);
	GivePlayerMoney(taxiDrv, toPay);
	new msg[128], msgToTaxiDrv[128];

	format(msg, 128, "You have been driven for %i minutes(1 min = $6) and have been charged %i (including taxi's base fare price.)", toTax, toPay);
	format(msgToTaxiDrv, 128, "You have been driving for %i minutes and have recieved %i dollars for your fare.", toTax, toPay);

	SendClientMessage(fare, COLOR_VLBLUE, msg);
	SendClientMessage(taxiDrv, COLOR_VLBLUE, msgToTaxiDrv);



	return 1;

}

new gTaxiOldSeconds[MAX_PLAYERS];
forward AcceptOrderChecks(taxiDriver, taxiAcceptant, taxiVehID);
public AcceptOrderChecks(taxiDriver, taxiAcceptant, taxiVehID)
{
	
	
	if(IsPlayerInVehicle(taxiAcceptant, taxiVehID))
	{
	    KillTimer(gTaxiDriverTimerID[taxiDriver]);
	    
	    gTaxiOldSeconds[taxiDriver] = GetSecondsSinceStartup();
	    
	    SendClientMessage(taxiDriver, COLOR_VLBLUE, "Your fare has entered the taxi, taxing has begun.");
		SendClientMessage(taxiAcceptant, COLOR_VLBLUE, "You have entered the taxi, taxing has begun.");
	}
	return 1;
	
}

//----------------------------------------------------------------------------------------------------------------------------------------------



//------------------LOAD FACTION FUNCTIONS------------------------------------------------------------------------------------------------------

LoadLSPD(rank, reciever)
{
	switch(rank)
	{
	    
  		case 1:
	    {
			SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 280);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
		}
		case 2:
		{
		    SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 280);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        
		}
		case 3:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
		}
		case 4:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
		}
		case 5:
		{
		 	SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas
		
		}
		case 6:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas
		}
		case 7:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, 1568.6843,-1689.9703,6.2188); //lspd downstairs
		    SetPlayerSkin(reciever, 265);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas
		
		}
	}
	return 1;
}

LoadSFPD(rank, reciever)
{
	switch(rank)
	{

  		case 1:
	    {
			SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //sfpd downstairs
		    SetPlayerSkin(reciever, 281);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
		}
		case 2:
		{
		    SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 281);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun

		}
		case 3:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
		}
		case 4:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
		}
		case 5:
		{
		 	SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas

		}
		case 6:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas
		}
		case 7:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1591.0804,716.0178,-5.2422); //lspd downstairs
		    SetPlayerSkin(reciever, 265);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas

		}
	}
	return 1;
}
	
LoadLVPD(rank, reciever)
{
	switch(rank)
	{

  		case 1:
	    {
			SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //sfpd downstairs
		    SetPlayerSkin(reciever, 282);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
		}
		case 2:
		{
		    SetPlayerArmour(reciever, 50); //half
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 282);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun

		}
		case 3:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
		}
		case 4:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 285);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
		}
		case 5:
		{
		 	SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas

		}
		case 6:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 286);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas
		}
		case 7:
		{
		    SetPlayerArmour(reciever, 100); //full
	        SetPlayerColor(reciever, COLOR_POL);
	        SetPlayerPos(reciever, -1605.5457,710.8530,13.8672); //lspd downstairs
		    SetPlayerSkin(reciever, 265);
         	GivePlayerWeapon(reciever, 29, 250); //MP5
	        GivePlayerWeapon(reciever, 3, 1); //nightstick
	        GivePlayerWeapon(reciever, 22, 100);//9mm
	        GivePlayerWeapon(reciever, 25, 50); //shotgun
	        GivePlayerWeapon(reciever, 24, 150); //deagle
	        GivePlayerWeapon(reciever, 17, 25); //tear gas

		}
	}
	return 1;
}

LoadTaxi(player, rank)
{
	switch(rank)
	{
	    case 1:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 61);
	        
	    }
	    case 2:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 171);
	    }
	    case 3:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 189);
	    }
	    case 4:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 253);
	    }
	    case 5:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 255);
	    }
	    case 6:
	    {
	        SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 255);
	    }
	    case 7:
	    {
	    	SetPlayerColor(player, COLOR_TAXI);
	        SetPlayerPos(player, -2098.7507,-859.8115,32.1719); //sf taxi front door
	        SetPlayerSkin(player, 147);
	    
	    }
	}
	return 1;
}
//--------------------------------------------------------------------------------------------------------------------



//-------------------------------------PLAYER INFO ENUM & LOADING SYSTEM RELATED----------------------------------------------------------------
enum pInfo
{
    pPass,
    pCash,
    pAdmin,
    pKills,
    pDeaths,
    pFaction,
    pFactionRank,
    pPoliceArrests,
    pJob,
    pJailTime
}
new PlayerInfo[MAX_PLAYERS][pInfo];


forward LoadUser_data(playerid,name[],value[]);
public LoadUser_data(playerid,name[],value[])
{
    INI_Int("Password",PlayerInfo[playerid][pPass]);
    INI_Int("Cash",PlayerInfo[playerid][pCash]);
    INI_Int("Admin",PlayerInfo[playerid][pAdmin]);
    INI_Int("Kills",PlayerInfo[playerid][pKills]);
    INI_Int("Deaths",PlayerInfo[playerid][pDeaths]);
    INI_Int("Faction", PlayerInfo[playerid][pFaction]);
    INI_Int("FactionRank", PlayerInfo[playerid][pFactionRank]);
    INI_Int("Police_Arrests", PlayerInfo[playerid][pPoliceArrests]);
    INI_Int("Job", PlayerInfo[playerid][pJob]);
    INI_Int("Jail_time", PlayerInfo[playerid][pJailTime]);
    return 1;
}

stock UserPath(playerid)
{
    new string[128],playername[MAX_PLAYER_NAME];
    GetPlayerName(playerid,playername,sizeof(playername));
    format(string,sizeof(string),PATH,playername);
    return string;
}

stock udb_hash(buf[]) {
    new length=strlen(buf);
    new s1 = 1;
    new s2 = 0;
    new n;
    for (n=0; n<length; n++)
    {
       s1 = (s1 + buf[n]) % 65521;
       s2 = (s2 + s1)     % 65521;
    }
    return (s2 << 16) + s1;
}

//-------------------------------------------------------------------------------------------------------------------

//----------------------------------------FACTION SUBROUTINES-----------------------------------------------------
ReturnPlayerFaction(player)
{
	new n[64];
	switch(PlayerInfo[player][pFaction])
	{
	    case 0: format(n, sizeof(n), "Civilian");
	    case 1: format(n, sizeof(n), "LSPD");
	    case 2: format(n, sizeof(n), "SFPD");
	    case 3: format(n, sizeof(n), "LVPD");
	    case 4: format(n, sizeof(n), "Taxi Company");
	}
	return n;
}

IsPlayerFactionLeader(player)
{
	if(PlayerInfo[player][pFactionRank] == 7)
	{
	    return true;
	}

	return false;

}

GetPlayerFaction(factionee)
{
	return PlayerInfo[factionee][pFaction];
}

IsPlayerCop(player)
{
	if(GetPlayerFaction(player) == 1 || GetPlayerFaction(player) == 2 || GetPlayerFaction(player) == 3) return true;
	
	else return false;
}

JailPlayer(player, time, reasonText[])
{
	SetPlayerInterior(player, 18);
	SetPlayerPos(player, 1302.519897,-1.787510,1001.028259);
	ResetPlayerWeapons(player);
	
	new minutesToJail = time / 60000;
	new msg[128];
	format(msg, sizeof(msg), "Your jail time is %i minutes.\nReason: %s", minutesToJail, reasonText);

	ShowPlayerDialog(player, DIALOG_JAILTIME, DIALOG_STYLE_MSGBOX, "Jail time!", msg, "OK", "");
	SetTimerEx("UnjailPlayer", time, false, "i", player);
	
	return 1;
}

forward UnjailPlayer(toUnjail);
public UnjailPlayer(toUnjail)
{
	SetPlayerInterior(toUnjail, 0);
	PlayerInfo[toUnjail][pJailTime] = 0;
	SpawnPlayer(toUnjail);
	
	return 1;
}

Cuff(player)
{
	return SetPlayerSpecialAction(player, SPECIAL_ACTION_CUFFED);
}

Uncuff(player)
{
    SetPlayerSpecialAction(player, SPECIAL_ACTION_NONE);
}

//-----------------------------------------------------------------------------------------------------------------------

//--------------------------------------------SERVER RELATED FUNCTIONS---------------------------------------------------
IsPlayerServerAdmin(toCheck)
{
	if(PlayerInfo[toCheck][pAdmin] == 1) return true;

	else return false;
}

/*Credits to Dracoblue*/

new bool:srvAdmin[MAX_PLAYERS];
new bool:isWanted[MAX_PLAYERS];

GetWantedPlayersCount()
{
	new ammount;
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
		if(isWanted[i])
		{
		    ammount++;
		}
	}
	return ammount;
}

PlayerIp(playerid)
{
  new ip[16];
  GetPlayerIp(playerid, ip, sizeof(ip));
  return ip;
}

new gSecondsSinceStartup;
GetSecondsSinceStartup()
{
	return gSecondsSinceStartup / 60000;
}

forward AddSecond();
public AddSecond()
{
	gSecondsSinceStartup++;
}

new bool:customCheckpoint[MAX_PLAYERS], gCustCheckTimer[MAX_PLAYERS];
SetCheckpointToPlayer(toCheckpoint, toLocate)
{
	new Float:X, Float:Y, Float:Z;

	GetPlayerPos(toLocate, X, Y, Z);


	SetPlayerCheckpoint(toCheckpoint, X, Y, Z, 5.0);

	customCheckpoint[toCheckpoint] = true;



	gCustCheckTimer[toCheckpoint] = SetTimerEx("CustomCheckpoint", 1500, true, "ii", toCheckpoint, toLocate);
	
	return 1;
}
DisableCheckpointToPlayer(toDisable)
{
	DisablePlayerCheckpoint(toDisable);
	customCheckpoint[toDisable] = false;
	KillTimer(gCustCheckTimer[toDisable]);

	return 1;

}

forward CustomCheckpoint(toCheckpoint, toLocate);
public CustomCheckpoint(toCheckpoint, toLocate)
{
	if(customCheckpoint[toCheckpoint])
	{
    	new Float:X, Float:Y, Float:Z;
		GetPlayerPos(toLocate, X, Y, Z);
		SetPlayerCheckpoint(toCheckpoint, X, Y, Z, 5.0);
	}

	return 1;

}

ReturnPlayerJob(player)
{
	new job[64];

	switch(PlayerInfo[player][pJob])
	{
	    case 0: format(job, 64, "Unemployed");
	    case 1: format(job, 64, "Drug Dealer");
	    default: format(job, 64, "INVALID");
	}
	return job;
}
GetPlayerJob(player)
{
	new jobID;
	
	for(new i = 0; i <= sizeof(playerJob); ++i)
	{
	    if(PlayerInfo[player][pJob] == i)
	    {
	        jobID = i;
	        break;
	    }
	}
	return jobID;
}

IsPlayerInRangeOfJob(player, job)
{

	new bool:status;
	
	if(job == 0) return status = false;
	
	switch(job)
	{
	    case 1: if(IsPlayerInRangeOfPoint(player, 15.0, 2212.4729,-2044.7767,13.5469)) return status = true;//drug dealer LS
	   
	}

	return status;

}
//-------------------------------------------------------------------------------------------------------------------------
main()
{
	print("\n----------------------------------");
	print("Mish Mash by strawloki");
	print("----------------------------------\n");
}



public OnGameModeInit()
{
	SetTimer("AddSecond", 1000, true);

	// Don't use these lines if it's a filterscript
	UsePlayerPedAnims();

	DisableInteriorEnterExits();
	
	AddStaticVehicle(411,-2645.0276,1379.1677,6.8913,270.2996,64,1); // SPAWN_SF_INFERNUS_01
	AddStaticVehicle(560,-2645.3958,1370.1592,6.8706,269.6046,9,39); // SPAWN_SF_SULTAN_01
	AddStaticVehicle(415,-2645.0789,1374.8688,6.9373,89.8730,36,1); // SPAWN_SF_CHEETAH_01
	AddStaticVehicle(522,-2645.5840,1366.5865,6.7400,87.3599,7,79); // SPAWN_SF_NRG500_01
	AddStaticVehicle(559,-2645.5061,1361.9836,6.8224,268.1624,58,8); // SPAWN_SF_JESTER_01
	AddStaticVehicle(521,-2617.4846,1377.7788,6.7076,183.6342,75,13); // SPAWN_FCR900_01
	AddStaticVehicle(596,1558.6707,-1710.3900,5.6141,357.3579,0,1); // MISHMASH_LS_LSPDHQ_POLICECAR01
	AddStaticVehicle(596,1570.3359,-1710.4628,5.6116,1.2785,0,1); // MISHMASH_LS_LSPDHQ_POLICECAR02
	AddStaticVehicle(596,1574.4202,-1710.1465,5.6107,2.5866,0,1); // MISHMASH_LS_LSPDHQ_POLICECAR03
	AddStaticVehicle(596,1578.9292,-1709.7583,5.6128,4.4820,0,1); // MISHMASH_LS_LSPDHQ_POLICECAR04
	AddStaticVehicle(523,1583.7445,-1710.2285,5.4633,357.2284,0,0); // MISHMASH_LS_LSPDHQ_HPV1000_01
	AddStaticVehicle(523,1587.7421,-1710.1182,5.4633,355.1857,0,0); // MISHMASH_LS_LSPDHQ_HPV1000_02
	AddStaticVehicle(523,1591.4536,-1710.1327,5.4626,0.7370,0,0); // MISHMASH_LS_LSPDHQ_HPV1000_03
	AddStaticVehicle(420,-2124.3982,-866.0760,31.8030,265.1079,6,1); // MISHMASH_TAXISF_TAXI01
	AddStaticVehicle(420,-2124.6978,-869.0810,31.8030,269.9733,6,1); // MISHMASH_TAXISF_TAXI02
	AddStaticVehicle(420,-2124.2422,-872.5120,31.8014,270.2090,6,1); // MISHMASH_TAXISF_TAXI03
	AddStaticVehicle(420,-2124.0051,-875.7546,31.8017,269.7689,6,1); // MISHMASH_TAXISF_TAXI04
	AddStaticVehicle(420,-2124.5066,-879.1544,31.8042,269.2123,6,1); // MISHMASH_TAXISF_TAXI05
	AddStaticVehicle(420,-2124.5066,-882.1359,31.8034,270.5925,6,1); // MISHMASH_TAXISF_TAXI06
	AddStaticVehicle(420,-2134.4375,-866.1369,31.8016,87.6846,6,1); // MISHMASH_TAXISF_TAXI07
	AddStaticVehicle(420,-2134.7202,-869.5505,31.8014,90.3331,6,1); // MISHMASH_TAXISF_TAXI08
	AddStaticVehicle(420,-2134.7368,-872.5688,31.8024,91.3299,6,1); // MISHMASH_TAXISF_TAXI09
	AddStaticVehicle(420,-2134.6128,-876.0925,31.8028,87.3045,6,1); // MISHMASH_TAXISF_TAXI10
	AddStaticVehicle(420,-2134.4070,-879.0130,31.8025,92.6012,6,1); // MISHMASH_TAXISF_TAXI11
	AddStaticVehicle(420,-2133.9014,-882.2913,31.8032,87.0873,6,1); // MISHMASH_TAXISF_TAXI12
	AddStaticVehicle(438,-2133.5977,-853.7712,32.0269,90.4232,6,76); // MISHMASH_TAXISF_CABBIE01
	AddStaticVehicle(438,-2133.7810,-850.4107,32.0260,89.5589,6,76); // MISHMASH_TAXISF_CABBIE02
	AddStaticVehicle(438,-2124.6963,-853.7400,32.0285,270.6587,6,76); // MISHMASH_TAXISF_CABBIE03
	AddStaticVehicle(438,-2124.8416,-850.4964,32.0287,271.0287,6,76); // MISHMASH_TAXISF_CABBIE04
	AddStaticVehicle(438,-2124.8770,-847.1948,32.0277,267.3840,6,76); // MISHMASH_TAXISF_CABBIE05
	AddStaticVehicle(438,-2133.9602,-847.5134,32.0272,90.1814,6,76); // MISHMASH_TAXISF_CABBIE06


	Create3DTextLabel("LSPD Headquarters", WHITE, 1553.7343,-1676.0154,16.1953, 5.0, 0, 0); //LSPD frontdoor
	CreatePickup(1239, 1, 1553.7343,-1676.0154,16.1953, 0);

	Create3DTextLabel("Cops and robbers minigame\nType /copsandrobbers to enter", WHITE, 1310.2595,-1367.2544,13.5261, 5.0, 0, 0); //cops and robbers ls
	CreatePickup(1239, 1, 1310.2595,-1367.2544,13.5261, 0); //cops and robbers ls

	
	SetGameModeText("Mish Mash");
	//AddPlayerClass(72, -2626.8721,1381.5051,7.1694,179.8942, 0, 0, 0, 0, 0, 0);
	return 1;
}

public OnGameModeExit()
{
	/*
	for(new i = 0; i<= GetPlayerPoolSize(); i++)
	{
		if(!IsPlayerConnected(i)) continue;
	    new INI:File = INI_Open(UserPath(i));
    	INI_SetTag(File,"data");
 		INI_WriteInt(File,"Cash",GetPlayerMoney(i));
    	INI_WriteInt(File,"Admin",PlayerInfo[i][pAdmin]);
 		INI_WriteInt(File,"Kills",PlayerInfo[i][pKills]);
    	INI_WriteInt(File,"Deaths",PlayerInfo[i][pDeaths]);
    	INI_WriteInt(File, "Faction", PlayerInfo[i][pFaction]);
    	INI_WriteInt(File, "FactionRank", PlayerInfo[i][pFactionRank]);
    	INI_Close(File);
    }
    */
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid, -2681.6416,1399.5428,55.8125);
	SetPlayerCameraPos(playerid, -2681.6416,1399.5428,55.8125);
	SetPlayerCameraLookAt(playerid, -2681.6416,1399.5428,55.8125);
	return 1;
}

public OnPlayerConnect(playerid)
{
    new name[MAX_PLAYER_NAME], string2[23 + MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof(name));
	format(string2, sizeof(string2), "%s joined the clusterfuck.", name);
	SendClientMessageToAll(0xFFFF00FF, string2);
	
	if(fexist(UserPath(playerid)))
    {
        INI_ParseFile(UserPath(playerid), "LoadUser_%s", .bExtra = true, .extra = playerid);
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Login time", "Type yer password to log into this clusterfuck.", "Login", "Maybe later");
    }
    else
    {
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "I SMELL STRANGER!", "oWo uWu type your password plees", "gottem", "lmao later");
    }
    
    
    
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{

    new name[MAX_PLAYER_NAME], string2[23 + MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof(name));
	format(string2, sizeof(string2), "%s has left the clusterfuck.", name);
	SendClientMessageToAll(0xFFFF00FF, string2);
	
	//get player's weapons
	/*
	new weapon[13][2];
	
	for(new i = 0; i <= 12; i++)
	{
	    GetPlayerWeaponData(playerid, i, weapon[i][0], weapon[0][i]);
	}
	
	//-------------------------------------------
 */
	new INI:File = INI_Open(UserPath(playerid));
    INI_SetTag(File,"data");
    INI_WriteInt(File,"Cash",GetPlayerMoney(playerid));
    INI_WriteInt(File,"Admin",PlayerInfo[playerid][pAdmin]);
    INI_WriteInt(File,"Kills",PlayerInfo[playerid][pKills]);
    INI_WriteInt(File,"Deaths",PlayerInfo[playerid][pDeaths]);
    INI_WriteInt(File, "Faction", PlayerInfo[playerid][pFaction]);
    INI_WriteInt(File, "FactionRank", PlayerInfo[playerid][pFactionRank]);
    INI_WriteInt(File, "Police_Arrests", PlayerInfo[playerid][pPoliceArrests]);
    INI_WriteInt(File, "Job", PlayerInfo[playerid][pJob]);
    INI_WriteInt(File, "Jail_time", PlayerInfo[playerid][pJailTime]);
    INI_Close(File);
	
	
	if(onGamemode[playerid])
	{
		

	    if(gPlayerVotedToStart[playerid]) gPlayersVotedToStart--; //does it get reset too?

	    gOnCPSLobby[playerid] = false;
	    gCPSLobbyCount--;

	    if(gCPSPlayerTeam[playerid] == 0)//cops
	    {
	        gCPSPlayerTeam[playerid] = -1;
	        gCPSCopsCount--;
	        if(gCPSCopsCount == 0)
	        {
	            SendMessageToCPS(" * Team Cops is out of players and the game may not continue;", 2, LBLUE);
	            EndCPS();
	        }
	    }

	    if(gCPSPlayerTeam[playerid] == 1)//robbers
	    {
	        gCPSPlayerTeam[playerid] = -1;
	        gCPSRobbersCount--;
	        if(gCPSRobbersCount == 0)
	        {
	            SendMessageToCPS(" * Team Robbers is out of players and the game may not continue;", 2, LBLUE);
	            EndCPS();
	        }
	    }
	
        new msg[128];
		new pName[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pName, sizeof(pName));

		format(msg, sizeof(msg), "Player %s has disconnected. People in lobby: %i", pName, gCPSLobbyCount);
		onGamemode[playerid]= false;

		for(new k = 0; k <= MAX_PLAYERS; k++)
		{
		    if(!IsPlayerConnected(k)) continue;
		    if(!onGamemode[k]) continue;

		    if(onGamemode[k])
		    {
		        SendClientMessage(k, RED, msg);
		    }

		}
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(onGamemode[playerid])
	{
	    onGamemode[playerid] = false;
	
	    SetPlayerPos(playerid, 1310.2595,-1367.2544,13.5261);
		SetPlayerInterior(playerid, 0);
		SetPlayerVirtualWorld(playerid, 0);
	}

	switch(PlayerInfo[playerid][pFaction])
	{
	    case FACTION_LSPD:
	    {
	        LoadLSPD(PlayerInfo[playerid][pFactionRank], playerid);
		}
		case FACTION_SFPD:
		{
		    LoadSFPD(PlayerInfo[playerid][pFactionRank], playerid);
		}
		case FACTION_LVPD:
		{
		    LoadLVPD(PlayerInfo[playerid][pFactionRank], playerid);
		}
		case FACTION_TAXI:
		{
			LoadTaxi(playerid, PlayerInfo[playerid][pFactionRank]);
		}
		default: //civilian
		{
		    if(PlayerInfo[playerid][pJailTime] > 0)
    		{
        		SendClientMessage(playerid, RED, "You've still got jail time to serve.");
      	  		JailPlayer(playerid, PlayerInfo[playerid][pJailTime], "Jail sentence incomplete.");
      	  		SetPlayerColor(playerid, WHITE);
      	  		SetPlayerSkin(playerid, 72);
    		}
		
		    else
		    {
				SetPlayerColor(playerid, WHITE);
		    	SetPlayerPos(playerid, -2626.8721,1381.5051,7.1694);
		    	SetPlayerSkin(playerid, 72);
		    	GivePlayerWeapon(playerid, 10,1);
		    	GivePlayerWeapon(playerid, 28, 300);
		    }
		}
	        
	}
	
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{

	SetPlayerWantedLevel(killerid, GetPlayerWantedLevel(killerid) + 1);
	isWanted[killerid] = true;
	
	new msg[128], killerName[MAX_PLAYER_NAME], playerName[MAX_PLAYER_NAME];
	GetPlayerName(killerid, killerName, sizeof(killerName));
	GetPlayerName(playerid, playerName, sizeof(playerName));
	format(msg, sizeof(msg), "CRIMELOG: Player %s(ID %i) has committed a crime against player %s(ID %i).", killerName, killerid, playerName, playerid);
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    if(onGamemode[i]) continue;
	    
	    if(GetPlayerFaction(i) == 1 || GetPlayerFaction(i) == 2 || GetPlayerFaction(i) == 3)
	    {
	        SendClientMessage(i, COLOR_POL, msg);
	    }
	}

    PlayerInfo[killerid][pKills]++;
    PlayerInfo[playerid][pDeaths]++;
    
    if(onGamemode[playerid])
    {
        
        gOnCPSLobby[playerid] = false;
        gCPSLobbyCount--;
		gPlayerVotedToStart[playerid] = false;
		DisablePlayerCheckpoint(playerid);

        
        switch(GetPlayerCPSTeam(playerid))
        {
            case 0:
            {
				gCPSPlayerTeam[playerid] = -1;
				gCPSLiveCops--;
				
				

				SendClientMessage(playerid, GREEN, "You died during the Cops and Robbers minigame and have been kicked out.");
				
				if(GetPlayerCPSTeam(playerid) == GetPlayerCPSTeam(killerid))
				{
				    new msg1[128], killerName1[MAX_PLAYER_NAME], playerName1[MAX_PLAYER_NAME];
				    GetPlayerName(killerid, killerName1, sizeof(killerName1));
				    GetPlayerName(playerid, playerName1, sizeof(playerName1));
				    
				    format(msg1, 128, "Cop %s teamkilled cop %s and has been kicked out of the game.", killerName1, playerName1);
				    
				    SendMessageToCPS(msg1, 2, RED);
				    
				    onGamemode[killerid] = false;
        			gOnCPSLobby[killerid] = false;
        			gCPSLobbyCount--;
					gPlayerVotedToStart[killerid] = false;
					
					gCPSPlayerTeam[killerid] = -1;
					gCPSLiveCops--;

					SetPlayerPos(killerid, 1310.2595,-1367.2544,13.5261);
					SetPlayerInterior(killerid, 0);
					SetPlayerVirtualWorld(killerid, 0);
					
					new killerMsg[128];
					format(killerMsg, 128, "You have been kicked out of the minigame for teamkilling %s.", playerName1);
					
					SendClientMessage(killerid, RED, killerMsg);

				}
				else
				{
				    new msgToCops[128], killerName2[MAX_PLAYER_NAME], playerName2[MAX_PLAYER_NAME];
				    
				    GetPlayerName(killerid, killerName2, sizeof(killerName2));
				    GetPlayerName(playerid, playerName2, sizeof(playerName2));
				    
				    format(msgToCops, 128, "Robber %s has killed cop %s. %i cops remain.", killerName2, playerName2, gCPSLiveCops);
				    
				    SendMessageToCPS(msgToCops, 2, RED);
				    
				
				}


				
            }
            case 1:
            {
                gCPSPlayerTeam[playerid] = -1;
				gCPSLiveRobbers--;


				SendClientMessage(playerid, GREEN, "You died during the Cops and Robbers minigame and have been kicked out.");
				
				if(GetPlayerCPSTeam(playerid) == GetPlayerCPSTeam(killerid))
				{
				    new msg2[128], killerName3[MAX_PLAYER_NAME], playerName3[MAX_PLAYER_NAME];
				    GetPlayerName(killerid, killerName3, sizeof(killerName3));
				    GetPlayerName(playerid, playerName3, sizeof(playerName3));

				    format(msg2, 128, "Robber %s teamkilled robber %s and has been kicked out of the game.", killerName3, playerName3);

				    SendMessageToCPS(msg2, 2, RED);

				    onGamemode[killerid] = false;
        			gOnCPSLobby[killerid] = false;
        			gCPSLobbyCount--;
					gPlayerVotedToStart[killerid] = false;

					gCPSPlayerTeam[killerid] = -1;
					gCPSLiveCops--;

					SetPlayerPos(killerid, 1310.2595,-1367.2544,13.5261);
					SetPlayerInterior(killerid, 0);
					SetPlayerVirtualWorld(killerid, 0);

					new killerMsg[128];
					format(killerMsg, 128, "You have been kicked out of the minigame for teamkilling %s.", playerName3);

					SendClientMessage(killerid, RED, killerMsg);

				}
				else
				{
				    new msgToRobbers[128], killerName4[MAX_PLAYER_NAME], playerName4[MAX_PLAYER_NAME];

				    GetPlayerName(killerid, killerName4, sizeof(killerName4));
				    GetPlayerName(playerid, playerName4, sizeof(playerName4));

				    format(msgToRobbers, 128, "Cop %s has killed robber %s. %i robbers remain.", killerName4, playerName4, gCPSLiveRobbers);
				    
				    SendMessageToCPS(msgToRobbers, 2, RED);


				}
            }
        }
    }
    
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 1;
}

/*public OnPlayerCommandText(playerid, cmdtext[])
{
	if (strcmp("/mycommand", cmdtext, true, 10) == 0)
	{
		// Do something here
		return 1;
	}
	return 0;
}
*/
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	if(customCheckpoint[playerid])
	{
	    customCheckpoint[playerid] = false;
	    SendClientMessage(playerid, GREEN, "You have reached your destination.");
	    DisablePlayerCheckpoint(playerid);
	}
	
	if(copDeliverToLS[playerid] || copDeliverToSF[playerid] || copDeliverToLV[playerid])
	{
	    SendClientMessage(playerid, GREEN, "You can now put the suspect into jail and have bad things happen to him in the showers.");
     	copDeliverToLS[playerid] = false;
     	copDeliverToSF[playerid] = false;
     	copDeliverToLV[playerid] = false;
     	DisablePlayerCheckpoint(playerid);
	}

	if(gOnFare[playerid])
	{
	    gOnFare[playerid] = false;
		DisablePlayerCheckpoint(playerid);
		
		SendClientMessage(playerid, COLOR_VLBLUE, "You have reached your customer.");

	}
	
	if(workLocCP[playerid])
	{
	    DisablePlayerCheckpoint(playerid);
	    workLocCP[playerid] = false;
	}
	
	if(gCopCPtoBank[playerid])
	{
	    DisablePlayerCheckpoint(playerid);
	    SendMessageToCPS(" * You are at the bank!", 0, LBLUE);
	    gCopCPtoBank[playerid] = false;
	}
	if(gRobCPtoDropoff[playerid])
	{
		DisablePlayerCheckpoint(playerid);
		gRobCPtoDropoff[playerid] = false;
		RobberEnterCPS(playerid);
		
	}
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	if(success)
	{
	    for(new i = 0; i <= MAX_PLAYERS; i++)
		{
		    if(strcmp(ip, PlayerIp(i), true) == 0)
			{
			    srvAdmin[i] = true;
			    SendClientMessage(i, WHITE, "Logged in as RCON admin.");
			    break;
			}
		}
	}
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch( dialogid )
    {
        case DIALOG_REGISTER:
        {
            if (!response) return Kick(playerid);
            if(response)
            {
                if(!strlen(inputtext)) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Nani?", "What the fuck was that? Try again, baka.", "Gomen", "bruh");
                new INI:File = INI_Open(UserPath(playerid));
                INI_SetTag(File,"data");
                INI_WriteInt(File,"Password",udb_hash(inputtext));
                INI_WriteInt(File,"Cash",0);
                INI_WriteInt(File,"Admin",0);
                INI_WriteInt(File,"Kills",0);
                INI_WriteInt(File,"Deaths",0);
                INI_WriteInt(File, "Faction", 0);
                INI_WriteInt(File, "FactionRank", 0);
                INI_Close(File);

                SetSpawnInfo(playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
                SpawnPlayer(playerid);
                ShowPlayerDialog(playerid, DIALOG_SUCCESS_1, DIALOG_STYLE_MSGBOX, "You actually got in", "Nice job, now relog.", "OK", "");
            }
        }

        case DIALOG_LOGIN:
        {
            if ( !response ) return Kick ( playerid );
            if( response )
            {
                if(udb_hash(inputtext) == PlayerInfo[playerid][pPass])
                {
                    INI_ParseFile(UserPath(playerid), "LoadUser_%s", .bExtra = true, .extra = playerid);
                    GivePlayerMoney(playerid, PlayerInfo[playerid][pCash]);
                    PlayerInfo[playerid][pAdmin] = PlayerInfo[playerid][pAdmin];
                    PlayerInfo[playerid][pFaction] = PlayerInfo[playerid][pFaction];
                    PlayerInfo[playerid][pFactionRank] = PlayerInfo[playerid][pFactionRank];
                    PlayerInfo[playerid][pPoliceArrests] = PlayerInfo[playerid][pPoliceArrests];
                    PlayerInfo[playerid][pJob] = PlayerInfo[playerid][pJob];
                    PlayerInfo[playerid][pJailTime] = PlayerInfo[playerid][pJailTime];

                    
                }
                else
                {
                    ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Wrong password mate", "Try again lmao", "OK", "nah");
                }
                return 1;
            }
        }
        case DIALOG_POL_SANCTION:
        {
            if(response)
            {
                
                if(listitem == 0)
                {
					//attack on officer = 3
					
					new msg1[128], msg2[128], sancName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];
					
					GetPlayerName(gToSanction[playerid], sancName, sizeof(sancName));
					GetPlayerName(playerid, copName, sizeof(copName));
					
					format(msg1, sizeof(msg1), "Officer {000099}%s {FFFF00}has sanctioned you with the crime 'Attack on officer'.", copName);
					format(msg2, sizeof(msg2), "You have sanctioned  suspect {FF4500}%s {FFFF00}of the crime 'Attack on officer'.", sancName);
					SendClientMessage(gToSanction[playerid], YELLOW, msg1);
					SendClientMessage(playerid, YELLOW, msg2);
					
					SetPlayerWantedLevel(gToSanction[playerid], GetPlayerWantedLevel(gToSanction[playerid]) + 3);
					
					gToSanction[playerid] = -1;
                }
                else if(listitem == 1)
                {
                    //killing an officer, 5
                    
                    new msg1[128], msg2[128], sancName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];

					GetPlayerName(gToSanction[playerid], sancName, sizeof(sancName));
					GetPlayerName(playerid, copName, sizeof(copName));
					
					format(msg1, sizeof(msg1), "Officer {000099}%s {FFFF00}has sanctioned you with the crime 'Killing an officer'. ", copName);
					format(msg2, sizeof(msg2), "You have sanctioned  suspect {FF4500}%s {FFFF00}of the crime 'Killing an officer'.", sancName);
					SendClientMessage(gToSanction[playerid], YELLOW, msg1);
					SendClientMessage(playerid, YELLOW, msg2);
					
					SetPlayerWantedLevel(gToSanction[playerid], GetPlayerWantedLevel(gToSanction[playerid]) + 5);

					gToSanction[playerid] = -1;

                }
                else if(listitem == 2)
				{
				    new msg1[128], msg2[128], sancName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];

					GetPlayerName(gToSanction[playerid], sancName, sizeof(sancName));
					GetPlayerName(playerid, copName, sizeof(copName));

					format(msg1, sizeof(msg1), "Officer {000099}%s {FFFF00FF}has sanctioned you with the crime 'Unpaid fine'. ", copName);
					format(msg2, sizeof(msg2), "You have sanctioned  suspect {FF4500}%s {FFFF00FF}of the crime 'Unpaid fine'.", sancName);
					SendClientMessage(gToSanction[playerid], YELLOW, msg1);
					SendClientMessage(playerid, YELLOW, msg2);

					SetPlayerWantedLevel(gToSanction[playerid], GetPlayerWantedLevel(gToSanction[playerid]) + 2);

					gToSanction[playerid] = -1;
				
				}
                
                
                
            }

		}
		case DIALOG_CPS_TEAM:
		{
		    
		
		    if(response) //button cops
		    {
	    	   if(gCPSRobbersCount == 0 && gCPSCopsCount == 1)
  		       {
				 SendClientMessage(playerid, LBLUE, "ERROR: There are no players in team robbers, you must join team robbers.");
				 ShowPlayerDialog(playerid, DIALOG_CPS_TEAM, DIALOG_STYLE_MSGBOX, "Choose team", "Click on one of the buttons down below to choose a team.", "Team Cops", "Team Robbers");
		       }
		       else
		       {
		       	gCPSPlayerTeam[playerid] = 0; //team cops
		       	new pName[MAX_PLAYER_NAME];
		       	new msg[128];
		       	GetPlayerName(playerid, pName, sizeof(pName));

				gCPSCopsCount++;
				format(msg, 128, "Player %s has joined team cops. Total cops: %i", pName, gCPSCopsCount);
				
				for(new p = 0; p <= MAX_PLAYERS; p++)
		       	{
				   if(!IsPlayerConnected(p)) continue;
				    
				   if(onGamemode[p])
				   {
				    	SendClientMessage(p, GREEN, msg);
				    	SendClientMessage(p, GREEN, "In order for the game to start, all players must type /start.");
				   }
				    
			   	}
		       
		      }
		    }
		    else //robbers
		    {
			   if(gCPSRobbersCount == 1 && gCPSCopsCount == 0)
			   {
			        SendClientMessage(playerid, LBLUE, "ERROR: There are no players in team cops, you must join team cops.");
			        ShowPlayerDialog(playerid, DIALOG_CPS_TEAM, DIALOG_STYLE_MSGBOX, "Choose team", "Click on one of the buttons down below to choose a team.", "Team Cops", "Team Robbers");
			        
			   }
		    
			   else
			   {
   			   	gCPSPlayerTeam[playerid] = 1;
		        
   			   	new pName[MAX_PLAYER_NAME];
		       	new msg[128];
		       	GetPlayerName(playerid, pName, sizeof(pName));

			   	gCPSRobbersCount++;

			  	format(msg, 128, "Player %s has joined team robbers. Total robbers: %i", pName, gCPSRobbersCount);

			   	for(new p = 0; p <= MAX_PLAYERS; p++)
		       	{
				   if(!IsPlayerConnected(p)) continue;

				   if(onGamemode[p])
				   {
				    	SendClientMessage(p, GREEN, msg);
				    	SendClientMessage(p, GREEN, "In order for the game to start, all players must type /start.");
				   }

			   	}
               }
		        
		    }
		
		}

    }
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}
CMD:veh(playerid, params[])
{
	new car, Vehicle;
	
	new Float:X, Float:Y, Float:Z;
	
	GetPlayerPos(playerid, Float:X, Float:Y, Float:Z);

	if(sscanf(params, "i", car)) SendClientMessage(playerid, LBLUE, "Missing parameters, dumbass.");
	
	else if(car < 400 || car > 611) SendClientMessage(playerid, LBLUE, "The parameter is too high, they didn't make that many models.");
	
	Vehicle = CreateVehicle(car, X, Y, Z, 0, -1, -1, -1);
	PutPlayerInVehicle(playerid, Vehicle, 0);
	return 1;
}

CMD:makeadmin(playerid, params[])
{
	new playerToAdmin;

	if(IsPlayerAdmin(playerid))
	{
	    if(sscanf(params, "i", playerToAdmin)) return SendClientMessage(playerid, LBLUE, "Missing parameters, dumbass.");
	    
	    else if(playerToAdmin < 0 || playerToAdmin > MAX_PLAYERS) return SendClientMessage(playerid, LBLUE, "Wat? IMPOSSIBUL!");
	    
		PlayerInfo[playerToAdmin][pAdmin] = 1;
		
		new name[MAX_PLAYER_NAME], string[MAX_PLAYER_NAME + 23];
		GetPlayerName(playerToAdmin, name,sizeof(name));
		format(string, sizeof(string), "%s is now admin.", name);
		
	    SendClientMessageToAll(LRED, string);
	}
	return 1;
}
CMD:money(playerid)
{
	GivePlayerMoney(playerid, 1000);
	return 1;
}


CMD:setfaction(playerid, params[])
{
	new Factionee, rank, factionid;
	
	if(PlayerInfo[playerid][pAdmin] == 1)
	{
	    if(sscanf(params, "iii", Factionee, factionid, rank)) return SendClientMessage(playerid, LBLUE, "Missing parameters, dumbass.\nUsage: /setfaction <player to enroll in faction> <factionid> <rank>");
	    
	    PlayerInfo[Factionee][pFaction] = factionid;
	    PlayerInfo[Factionee][pFactionRank] = rank;
	    
	    new message[128], enrollerName[MAX_PLAYER_NAME + 24];
	    GetPlayerName(playerid, enrollerName, sizeof(enrollerName));
	    format(message, sizeof(message), "You have been enrolled into faction %i with the rank %i by leader %s. Have fun or whatever.", factionid, rank, enrollerName);
	    
	    SendClientMessage(Factionee, GREEN, message);
	    
	}
	else return SendClientMessage(playerid, LBLUE, "What are you, like and admin or something?");

	return 1;
}

CMD:listwanted(playerid)
{
	if(GetPlayerFaction(playerid) == 0 || GetPlayerFaction(playerid) == 4)
	{
	    SendClientMessage(playerid, LBLUE, "ERROR: You aren't authorized to access that, dummy.");
	}
	
	

	new msg[128], wantedName[MAX_PLAYER_NAME];
	
	SendClientMessage(playerid, WHITE, "-----LIST OF WANTED PLAYERS-----");
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;

	    if(isWanted[i])
	    {
			GetPlayerName(i, wantedName, sizeof(wantedName));
			format(msg, sizeof(msg), "WANTED: %s\tID: %i", wantedName, i);
			SendClientMessage(playerid, LBLUE, msg);
		}
	}
	
	new msg2[128];
	format(msg, sizeof(msg), "Total wanted players on the server: %i", GetWantedPlayersCount());
	SendClientMessage(playerid, WHITE, msg2);
	
	

	return 1;
}

CMD:tp(playerid, params[])
{
	if(!IsPlayerServerAdmin(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: Only super-duper special admins can use that command.");
	
	new toTeleport;
	
	if(sscanf(params, "i", toTeleport)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /tp <id of player to teleport to>");
	
	new Float:X, Float:Y, Float:Z;
	
	GetPlayerPos(toTeleport, X, Y, Z);
	
	SetPlayerPos(playerid, X, Y, Z);
	


	return 1;
}

CMD:cptoplayer(playerid, params[])
{
	if(!IsPlayerServerAdmin(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: Only super-duper special admins can use that command.");

	new toCp;
	
	if(sscanf(params, "i", toCp))return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /cptoplayer <id of player to set a checkpoint to>");

	if(!IsPlayerConnected(toCp)) return SendClientMessage(playerid, LBLUE, "ERROR: The player you're trying to locate doesn't seem to exist on this server my man.");

	SetCheckpointToPlayer(playerid, toCp);
	return 1;
}

CMD:locatesuspect(playerid, params[])
{
	if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
	
	new toCp;
	
	if(sscanf(params, "i", toCp))return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /locatesuspect <id of player to set a checkpoint to>");
	
	if(!isWanted[toCp]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");
	
	SetCheckpointToPlayer(playerid, toCp);
	
	new copName[MAX_PLAYER_NAME], suspectName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, copName, sizeof(copName));
	GetPlayerName(toCp, suspectName, sizeof(suspectName));
	
	new msg[128];
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    
	    if(IsPlayerCop(i)) 
	    {
	        format(msg, sizeof(msg), "ALL UNITS: Officer %s is locating suspect %s.", copName, suspectName);
	        SendClientMessage(i, COLOR_POL, msg);

	    }
	    
	}
	
	return 1;


}

CMD:testcuff(playerid)
{
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CUFFED);
	return 1;
}

CMD:stopanim(playerid)
{
	ClearAnimations(playerid);
	return 1;
}

CMD:stopac(playerid)
{
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
	return 1;
}

CMD:pol(playerid, params[])
{
	if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
	
	new pol;
	
	if(sscanf(params, "i", pol)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /pol <player to ask to surrender>");
	
	if(!isWanted[pol]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");
	
	new Float:crimX, Float:crimY, Float:crimZ;
	
	
	GetPlayerPos(pol, crimX, crimY, crimZ);
	
	if(IsPlayerInRangeOfPoint(playerid, crimX, crimY, crimZ, 25.0))
	{
	
		new msg[128], polMsg[128], polName[MAX_PLAYER_NAME], criminalName[MAX_PLAYER_NAME];
	
		GetPlayerName(playerid, polName, sizeof(polName));
		GetPlayerName(pol, criminalName, sizeof(criminalName));
	
		format(msg, sizeof(msg), "This is officer %s! Stop where you are and surrender, %s!", polName, criminalName);
		format(polMsg, sizeof(polMsg), "This is officer %s! Stop where you are and surrender, %s!{000066}[Get in the officer's car to surrender].", polName, criminalName);
	
		SendClientMessage(pol, YELLOW, polMsg);
		SendClientMessage(playerid, YELLOW, msg);
	}
	else SendClientMessage(playerid, LBLUE, "ERROR. You aren't in range of the specified player.");
	return 1;
}

CMD:arrest(playerid, params[])
{
    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
    
   	new pol, city[1];

	if(sscanf(params, "si", city,pol)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /arrest <LS/SF/LV> <player to arrest>");

	if(!isWanted[pol]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");
	

	
	if(strcmp(city, "ls", true) != 0)
	{
	    SetPlayerCheckpoint(playerid, 1568.6843,-1689.9703,6.2188, 5.0);
     	copDeliverToLS[playerid] = true;

		SendClientMessage(playerid, GREEN, "Deliver the suspect to the LSPD HQ parking lot.");
	}
	else if(strcmp(city, "sf", true) != 0)
	{
	    SetPlayerCheckpoint(playerid, -1591.0804,716.0178,-5.2422, 3.0);
     	copDeliverToSF[playerid] = true;

        SendClientMessage(playerid, GREEN, "Deliver the suspect to the SFPD HQ parking lot.");
	}
	else if(strcmp(city, "lv", true) != 0)
	{
	    SetPlayerCheckpoint(playerid, 2282.1343,2431.3362,3.2734, 3.0);
     	copDeliverToLV[playerid] = true;

		SendClientMessage(playerid, GREEN, "Deliver the suspect to the LVPD HQ parking lot.");
	
	}
	else
	{
		SendClientMessage(playerid, LBLUE, "ERROR: What city is THAT?\nMake sure the city name is something like 'ls'(in non-capical characters).");
	}
	return 1;
}
CMD:jail(playerid, params[])
{
    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
    
    new toJail;
    
    if(sscanf(params, "i", toJail)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /jail <player to put in jail>");
    
    if(!isWanted[toJail]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");
    
    

	if(IsPlayerInRangeOfPoint(playerid, 5.0, 1568.6843,-1689.9703,6.2188) || IsPlayerInRangeOfPoint(playerid, 5.0, -1591.0804,716.0178,-5.2422) || IsPlayerInRangeOfPoint(playerid, 5.0, 2282.1343,2431.3362,3.2734)) //LS
	{
	    if(IsPlayerInRangeOfPoint(toJail, 5.0, 1568.6843,-1689.9703,6.2188) || IsPlayerInRangeOfPoint(toJail, 5.0, -1591.0804,716.0178,-5.2422) || IsPlayerInRangeOfPoint(toJail, 5.0, 2282.1343,2431.3362,3.2734))
	    {
	        new wantedLevel;
	        
	        wantedLevel = GetPlayerWantedLevel(toJail);
	        
	        new milisecondsToJail = (wantedLevel * 20000) + 300000;
	        PlayerInfo[toJail][pJailTime] = milisecondsToJail;
	        new copPayment = (GetPlayerWantedLevel(toJail) * 100) + 125;
	        new copBonus = (PlayerInfo[playerid][pPoliceArrests] * 60) * 25 / 100;
	        
	        if(copBonus > 0)
	        {
	            new finalPayment = copPayment + copBonus;
	            GivePlayerMoney(playerid, finalPayment);
	            
	            new paymentStatement[128], wantedName[MAX_PLAYER_NAME];
	            GetPlayerName(toJail, wantedName, sizeof(wantedName));
	            format(paymentStatement, sizeof(paymentStatement), "Payment statement for arresting %s\n--------------------------------\nInitial income: $%i\nBonus: $%i\nTotal: $%i\n--------------------------------", wantedName, copPayment, copBonus, finalPayment);
	            SendClientMessage(playerid, DARK_GREY, paymentStatement);
	            
	            
			}
	        else
	        {
	            new paymentStatement[128], wantedName[MAX_PLAYER_NAME];
	            GetPlayerName(toJail, wantedName, sizeof(wantedName));
	            format(paymentStatement, sizeof(paymentStatement), "Payment statement for arresting %s\n--------------------------------\nInitial income: $%i\nBonus: $%i\nTotal: $%i\n--------------------------------", wantedName, copPayment, copBonus, copPayment);
	            SendClientMessage(playerid, DARK_GREY, paymentStatement);

	            GivePlayerMoney(playerid, copPayment);
	        }
			isWanted[toJail] = false;
			SetPlayerWantedLevel(toJail, 0);
			PlayerInfo[playerid][pPoliceArrests]++;
			Uncuff(toJail);
			JailPlayer(toJail, milisecondsToJail, "Arrested by police officer.");
			
	    }
	    else return SendClientMessage(playerid, LBLUE, "ERROR: Suspect specified isn't in range of any police precinct.");
	}
	else return SendClientMessage(playerid, LBLUE, "ERROR: YOU aren't in range of any police precinct.");
	return 1;
}

CMD:cuff(playerid, params[])
{
    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");

    new toCuff;

    if(sscanf(params, "i", toCuff)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /cuff <player to cuff>");

    if(!isWanted[toCuff]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");

	Cuff(toCuff);
	
	new msg[128], msg2[128], cuffedName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, copName, sizeof(copName));
	
	GetPlayerName(toCuff, cuffedName, sizeof(cuffedName));
	format(msg, sizeof(msg), "You have been cuffed by officer %s", copName);
	SendClientMessage(toCuff, RED, msg);


	format(msg2, sizeof(msg2), "You have cuffed suspect %s.", cuffedName);
	SendClientMessage(playerid, GREEN, msg2);

	return 1;
}

CMD:uncuff(playerid, params[])
{

    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");

    new toUncuff;

    if(sscanf(params, "i", toUncuff)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /uncuff <player to uncuff>");
    
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
    
    new msg[128], msg2[128], uncuffName[MAX_PLAYER_NAME], copName[MAX_PLAYER_NAME];
    
    GetPlayerName(toUncuff, uncuffName, sizeof(uncuffName));
    GetPlayerName(playerid, copName, sizeof(copName));
    
	Uncuff(toUncuff);

	format(msg, sizeof(msg), "You have uncuffed suspect %s, make sure they don't run away or something.", uncuffName);
	
	format(msg2, sizeof(msg2), "Officer %s uncuffed you. Behave yourself now.", copName);
	
	SendClientMessage(playerid, LBLUE, msg);
    SendClientMessage(toUncuff, LBLUE, msg2);
	return 1;

}

CMD:stats(playerid)
{
	new stats[128];
	
	format(stats, sizeof(stats), "Kills: %i\nDeaths: %i\nFaction: %s\nFaction Rank: %i\nNumber of criminals arrested: %i\nAdmin: %i\nJob: %s\nJail Time(min): %i", PlayerInfo[playerid][pKills], PlayerInfo[playerid][pDeaths], ReturnPlayerFaction(playerid), PlayerInfo[playerid][pFactionRank], PlayerInfo[playerid][pPoliceArrests], PlayerInfo[playerid][pAdmin], ReturnPlayerJob(playerid), PlayerInfo[playerid][pJailTime] / 60000);
	ShowPlayerDialog(playerid, 13434, DIALOG_STYLE_MSGBOX, "Stats", stats, "OK", "");
	return 1;
}

CMD:sanction(playerid, params[])
{
    if(!IsPlayerCop(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a cop.");
    
    new toSanction;

    if(sscanf(params, "i", toSanction)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters, dumbass.\nUsage: /sanction <player to sanction>");

    if(!isWanted[toSanction]) return SendClientMessage(playerid, LBLUE, "ERROR: The player specified isn't any sort of danger to society.");
    
    new msg[128], sanctionName[MAX_PLAYER_NAME];
	GetPlayerName(toSanction, sanctionName, sizeof(sanctionName));
	
	format(msg, sizeof(msg), "Sanction suspect %s (ID: %i)", sanctionName, toSanction);
	
	ShowPlayerDialog(playerid, DIALOG_POL_SANCTION, DIALOG_STYLE_LIST, msg, "Attack on officer(3)\nKilling an officer(5)\nUnpaid Fine(2)", "Sanction", "Cancel");
	
	gToSanction[playerid] = toSanction;
    
    return 1;
}

CMD:enroll(playerid, params[])
{
	if(!IsPlayerFactionLeader(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a faction leader.");
	
	new player, rank, faction;
	
	faction = GetPlayerFaction(playerid);
	
	if(sscanf(params, "ii", player, rank)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters.\nUsage: /enroll <player to enroll into faction> <rank>");
	
	//player already in faction
	
	if(GetPlayerFaction(player) != 0 ) return SendClientMessage(playerid, LBLUE, "ERROR: Player specified is already part of a faction.");
	if(rank >= 7) return SendClientMessage(playerid, LBLUE, "ERROR: Rank is too high(max 6) or you inputted rank 7(leader, and you cannot have 2 leaders at the same time).");
	
	PlayerInfo[player][pFaction] = faction;
	PlayerInfo[player][pFactionRank] = rank;
	
	new msg1[128], leadName[MAX_PLAYER_NAME], playerName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, leadName, sizeof(leadName));
	GetPlayerName(player, playerName, sizeof(playerName));
	
	format(msg1, sizeof(msg1), "Leader %s has enrolled player %s in the faction with the rank %i. Contragulations!", leadName, playerName, rank);

	for(new i = 0; i <=MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    
	    if(GetPlayerFaction(i) == faction)
		{
		    SendClientMessage(i, COLOR_FACT_ENROLL, msg1);
		}
	}

	return 1;
}
CMD:promote(playerid, params[])
{
    if(!IsPlayerFactionLeader(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a faction leader.");
    
    new player, rank, faction;
    
    if(sscanf(params, "ii", player, rank)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters.\nUsage: /promote <player to promote> <new rank>");
    
    faction = GetPlayerFaction(playerid);
    
    if(GetPlayerFaction(player) != faction) return SendClientMessage(playerid, LBLUE, "ERROR: Player specified isn't in the same faction as the leader.");
    
    if(rank >= 7) return SendClientMessage(playerid, LBLUE, "ERROR: Rank is too high.");
    
    PlayerInfo[player][pFactionRank] = rank;
    
    new msg1[128], leadName[MAX_PLAYER_NAME], playerName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, leadName, sizeof(leadName));
	GetPlayerName(player, playerName, sizeof(playerName));

	format(msg1, sizeof(msg1), "Leader %s has promoted player %s with the rank %i. Contragulations!", leadName, playerName, rank);

	for(new i = 0; i <=MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;

	    if(GetPlayerFaction(i) == faction)
		{
		    SendClientMessage(i, COLOR_FACT_ENROLL, msg1);
		}
	}
  
	return 1;

}

CMD:kickout(playerid, params[])
{
    if(!IsPlayerFactionLeader(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a faction leader.");
    //if(!IsPlayerServerAdmin(playerid)) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't a server admin.");

	new player, reason[256];
	
	if(sscanf(params, "is", player, reason)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters.\nUsage: /kickout <player to kick out> <reason(TEXT)>.");
	
	new faction = GetPlayerFaction(playerid);
	
	new msg[128], leadName[MAX_PLAYER_NAME], kickName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, leadName, sizeof(leadName));
	GetPlayerName(player, kickName, sizeof(kickName));
	
	format(msg, sizeof(msg), "Leader %s has kicked out player %s from the faction. Reason: '%s'", leadName, kickName, reason);
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    
		if(GetPlayerFaction(i) == faction)
		{
		    SendClientMessage(i, COLOR_FACT_ENROLL, msg);
		}
	}
	
	PlayerInfo[player][pFaction] = 0;
	PlayerInfo[player][pFactionRank] = 1;
	SpawnPlayer(player);
	
	return 1;
}

CMD:ordertaxi(playerid)
{
    if(gIsLookingForTaxi[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You already called for a taxi, wait for a response or cancer your order.");

	gIsLookingForTaxi[playerid] = true;

	SendClientMessage(playerid, COLOR_VLBLUE, "You have ordered a taxi, please wait for a response.");
	
	new msg[128], orderName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, orderName, sizeof(orderName));
	format(msg, 128, "Player %s is looking for a taxi. Type /acceptorder %i to accept their order.", orderName, playerid);
	
	for(new i = 0; i <= MAX_PLAYERS; ++i)
	{
	    if(!IsPlayerConnected(i)) continue;
	    if(GetPlayerFaction(i) != 4) continue;
	    
	    if(GetPlayerFaction(i) == 4)
	    {
	        SendClientMessage(i, COLOR_VLBLUE, msg);
	    }
	}
	
	return 1;

}

CMD:acceptorder(playerid, params[])
{
    if(GetPlayerFaction(playerid) != 4) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't part of the Taxi faction.");
    
    if(gOnFare[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You've already accepted another fare.");
    
    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't driving a taxi.");
    
    if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
    {
         if(GetVehicleModel(GetPlayerVehicleID(playerid)) != 420) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't driving a proper taxi.");
    }

    new toAccept;
    
    if(sscanf(params, "i", toAccept)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters. Usage: /acceptorder <id of player to accept>");
    
    if(!gIsLookingForTaxi[toAccept]) return SendClientMessage(playerid, LBLUE, "ERROR: Player specified is not looking for a taxi.");

    
    SetCheckpointToPlayer(playerid, toAccept);
    gOnFare[playerid] = true;
    
    new msg1[128], msg2[128], orderName[MAX_PLAYER_NAME], taxiName[MAX_PLAYER_NAME];
    
    GetPlayerName(toAccept, orderName, sizeof(orderName));
    GetPlayerName(playerid, taxiName, sizeof(taxiName));
    
    format(msg1, sizeof(msg1), "Taxi driver %s has accepted your order, maintain your current position until they arrive.", taxiName);
    format(msg2, 128, "Taxi driver %s has accepted the order of client %s(ID: %i).", taxiName, orderName, toAccept);
    
    SendClientMessage(toAccept, COLOR_VLBLUE, msg1);
    
    for(new i = 0; i<= MAX_PLAYERS; ++i)
    {
        if(!IsPlayerConnected(i)) continue;
        if(GetPlayerFaction(i) != 4) continue;
    
        if(GetPlayerFaction(i) == 4)
        {
            SendClientMessage(i, COLOR_VLBLUE, msg2);
        }
    }
    gIsLookingForTaxi[toAccept] = false;
    
    
    new taxiVehID = GetPlayerVehicleID(playerid);
    gTaxiDriverTimerID[playerid] = SetTimerEx("AcceptOrderChecks", 1500, true, "iii", playerid, toAccept, taxiVehID);
    
    return 1;
    
    //do taxing on tickcount before & after
    
    
    

}

CMD:cancelorder(playerid, params[])
{
	if(!gIsLookingForTaxi[playerid]) return SendClientMessage(playerid, LBLUE, "ERROR: You weren't looking for a taxi to begin with.");
	
	new taxi;
	if(sscanf(params, "i", taxi)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters. Usage: /cancerorder <id of taxi driver who accepter your order>");
	
	if(!gOnFare[taxi]) return SendClientMessage(playerid, LBLUE, "ERROR: That player isn't on a fare.");
	
	gIsLookingForTaxi[playerid] = false;
	gOnFare[taxi] = false;
	
	DisableCheckpointToPlayer(taxi);
	
	SendClientMessage(playerid, COLOR_VLBLUE, "You have cancelled your taxi order.");
	
	new msg[128], name[MAX_PLAYER_NAME];
	
	GetPlayerName(playerid, name, sizeof(name));
	
	format(msg, 128, "Player %s has cancelled their taxi order, you're off duty now.", name);
	
	SendClientMessage(taxi, COLOR_VLBLUE, msg);
	
	return 1;
	
	//ADD FOR DISCONNECT

	
}

CMD:endfare(playerid, params[])
{

    if(GetPlayerFaction(playerid) != 4) return SendClientMessage(playerid, LBLUE, "ERROR: You aren't part of the Taxi faction.");
    
    new toEndFare;
    
    if(sscanf(params, "i", toEndFare)) return SendClientMessage(playerid, LBLUE, "ERROR: Missing parameters. Usage: /endfare <player to end fare with>");
    

  
    TaxTaxiFare(toEndFare, gTaxiOldSeconds[playerid], GetSecondsSinceStartup(), playerid);
  
	return 1;
	
}

CMD:employhere(playerid)
{
	if(PlayerInfo[playerid][pJob] != 0) return SendClientMessage(playerid, LBLUE, "ERROR: You are already employed somewhere.");

	
	if(IsPlayerInRangeOfPoint(playerid, 5.0, 2212.4729,-2044.7767,13.5469)) //Drug Dealer LS
	{
	    PlayerInfo[playerid][pJob] = 1;
	    
	    SendClientMessage(playerid, COLOR_JOBBLUE, "You have employed yourself as a drugdealer.");
	
	}
	return 1;

}

CMD:quitjob(playerid)
{
	PlayerInfo[playerid][pJob] = playerJob[JOB_UNEMPLOYED];
    SendClientMessage(playerid, COLOR_JOBBLUE, "You are now jobless.");
	return 1;
}


CMD:work(playerid)
{
	if(OnJob[playerid]) SendClientMessage(playerid, LBLUE, "ERROR: You are already working.");

	switch(GetPlayerJob(playerid))
	{
	    case 0: return SendClientMessage(playerid, LBLUE, "ERROR: You aren't even employed.");
	    case 1:
		{
		    if(IsPlayerInRangeOfJob(playerid, 1))
		    {
				SendClientMessage(playerid, WHITE, "so you're just vibin rn");
				OnJob[playerid] = true;
			}
			
			else
			{
			    SendClientMessage(playerid, WHITE, "You aren't even at the right location. Follow the misterious red dot on your map to get to that right location I was talking about.");
				SetPlayerCheckpoint(playerid, 2212.4729,-2044.7767,13.5469, 5.0);
				workLocCP[playerid] = true;

			    
			}
		}
		
	}
	
	return 1;
}

CMD:copsandrobbers(playerid)
{
	if(isWanted[playerid]) SendClientMessage(playerid, LBLUE, "ERROR: You can't join this minigame while wanted.");
	
	if(onGamemode[playerid]) SendClientMessage(playerid, LBLUE, "ERROR: You are already on a minigame.");
	
	if(IsPlayerInRangeOfPoint(playerid, 5.0, 1310.2595,-1367.2544,13.5261))
	{
	
		SetPlayerInterior(playerid, 11);
		SetPlayerPos(playerid, 501.980987,-69.150199,998.757812);
	
		gOnCPSLobby[playerid] = true;
		onGamemode[playerid] = true;
		gCPSLobbyCount++;
		
		gCPSskin[playerid] = GetPlayerSkin(playerid);
		GetPlayerHealth(playerid, gCPShealth[playerid]);
		GetPlayerArmour(playerid, gCPSarmour[playerid]);
	
		new pName[128];
		GetPlayerName(playerid, pName, 128);
		new msg[128];
		format(msg, 128, "%s has joined the lobby. People in the lobby currently: %i", pName, gCPSLobbyCount);
		SetPlayerHealth(playerid, 999.0);
	
		for(new i = 0; i<= MAX_PLAYERS; i++)
		{
			if(!IsPlayerConnected(i)) continue;

			if(gOnCPSLobby[i])
			{
			   SendClientMessage(i, GREEN, msg);

			}

		}
		ShowPlayerDialog(playerid, DIALOG_CPS_TEAM, DIALOG_STYLE_MSGBOX, "Choose team", "Click on one of the buttons down below to choose a team.", "Team Cops", "Team Robbers");
	
	}
	else SendClientMessage(playerid, LBLUE, "ERROR: You aren't at the right location."); //also set checkpoint to location pls

	return 1;
}

CMD:start(playerid)
{
	if(!onGamemode[playerid])
	{
		SendClientMessage(playerid, LBLUE, "ERROR: You aren't in a gamemode.");
		return 1;
	}
	
	if(gPlayerVotedToStart[playerid])
	{
		SendClientMessage(playerid, LBLUE, "ERROR: You already voted to start.");
		return 1;
	}
	
	if(gCPSLobbyCount < 2)
	{
	    SendClientMessage(playerid, LBLUE, "ERROR: There must be at least 2 players until the game can start.");
	    return 1;
	}
	
	
	
	gPlayerVotedToStart[playerid] = true;
	gPlayersVotedToStart++;

	new startMsg[128];
	new pName[128];
	GetPlayerName(playerid, pName, 128);
	
	format(startMsg, 128, "%s has voted to start the minigame. Votes needed to start the minigame: %i", pName, gCPSLobbyCount - gPlayersVotedToStart); //issue is here
	
	for(new i = 0; i<= MAX_PLAYERS; i++)
	{
		if(!IsPlayerConnected(i)) continue;
		
		if(gOnCPSLobby[i])
		{
		    SendClientMessage(i, GREEN, startMsg);
		
		}
	}
	
	//check if everyone typed start
	//check if number of teams are equal by 0
	
	//old contents of if statement below: gPlayersVotedToStart == gCPSLobbyCount
	if(gCPSLobbyCount - gPlayersVotedToStart == 0)
	{
		LoadCPS();
		
	}

	return 1;

}
CMD:cps(playerid)
{
	SetPlayerPos(playerid, 1310.2595,-1367.2544,13.5261);

	return 1;
}

CMD:exitcps(playerid)
{
	if(!onGamemode[playerid]) SendClientMessage(playerid, LBLUE, "ERROR: You aren't on a gamemode.");
	
	if(onGamemode[playerid])
	{
	    
	    
	    if(gPlayerVotedToStart[playerid])
		{
		 	gPlayersVotedToStart--;
		 	gPlayerVotedToStart[playerid] = false;
		}
	    
	    gCopCPtoBank[playerid] = false;
	    gRobCPtoDropoff[playerid] = false;
	    
	    gOnCPSLobby[playerid] = false;
	    gCPSLobbyCount--;
	    
	    if(gCPSPlayerTeam[playerid] == 0)//cops
	    {
	        gCPSPlayerTeam[playerid] = -1;
	        gCPSCopsCount--;
	        gCPSLiveCops--;
	        
	        if(gCPSCopsCount == 0)
	        {
	            SendMessageToCPS(" * Team Cops is out of players and the game may not continue;", 2, LBLUE);
	            EndCPS();
	            
	        }
	    }
	    
	    if(gCPSPlayerTeam[playerid] == 1)//robbers
	    {
	        gCPSPlayerTeam[playerid] = -1;
	        gCPSRobbersCount--;
	        gCPSLiveRobbers--;
	        
	        if(gCPSRobbersCount == 0)
	        {
	            SendMessageToCPS(" * Team Robbers is out of players and the game may not continue;", 2, LBLUE);
	            EndCPS();
	        }
	    }
	    
	    SetPlayerPos(playerid, 1310.2595,-1367.2544,13.5261);
	    SetPlayerSkin(playerid, gCPSskin[playerid]);
		SetPlayerHealth(playerid, gCPShealth[playerid]);
		SetPlayerArmour(playerid, gCPSarmour[playerid]);
	    SetPlayerInterior(playerid, 0);
	    DisablePlayerCheckpoint(playerid);
	    SetPlayerVirtualWorld(playerid, 0);
	    
	    SendClientMessage(playerid, LBLUE, "You have exited the gamemode.");
	    onGamemode[playerid]= false;
	    
	    new msg[128];
		new pName[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pName, sizeof(pName));
		
		format(msg, sizeof(msg), "Player %s has left the minigame. People in lobby: %i", pName, gCPSLobbyCount);

		for(new k = 0; k <= MAX_PLAYERS; k++)
		{
		    if(!IsPlayerConnected(k)) continue;
		    if(!onGamemode[k]) continue;
		    
		    if(onGamemode[k])
		    {
		        SendClientMessage(k, RED, msg);
		    }
		    
		}
	}

	return 1;
}

CMD:ongamemode(playerid)
{
	if(onGamemode[playerid])
	{
	    SendClientMessage(playerid, WHITE, "true");
	}
	else SendClientMessage(playerid, WHITE, "false");
	
	return 1;
}

CMD:showvw(playerid)
{
	new msg[128];
	format(msg, 128, "Current virtualworld: %i", GetPlayerVirtualWorld(playerid));
	SendClientMessage(playerid, WHITE, msg);
	return 1;
}

CMD:showcpsteam(playerid)
{
	new msg[128];
	
	format(msg, 128, "Current team: %i", GetPlayerCPSTeam(playerid));
	SendClientMessage(playerid, WHITE, msg);
	return 1;
}


CMD:removecp(playerid)
{
	DisablePlayerCheckpoint(playerid);
	return 1;
}
