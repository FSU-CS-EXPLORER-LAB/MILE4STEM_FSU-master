// change history:
//   November 2017: created by Raymond Naglieri
//      04/27/18 - updated to support interrupts. Now supports the ability to delay a command.
//      05/05/18 - modified for problem solving lecture
//  
integer num_npc = 8;
integer scenario_offset = 600000;
integer base_npc_control_channel = 31000;
integer npc_para_control_base_channel = 32000;
integer npc_action_control_base_channel = 33000;
integer backdoor_channel=20001;
integer facil_control_channel = 10101;
integer facil_capture_channel = -33156;
integer board_control_channel = 36000;
integer facil_scribe_channel = 17888; // scribe channel captures 

set_offset()
{
    base_npc_control_channel = 31000 + scenario_offset;
    npc_para_control_base_channel = 32000 + scenario_offset; 
    npc_action_control_base_channel = 33000 + scenario_offset;
    backdoor_channel= 20001 + scenario_offset;
    facil_control_channel = 10101 + scenario_offset;
    facil_capture_channel = -33156 + scenario_offset;
    board_control_channel = 36000 + scenario_offset;  
    facil_scribe_channel = 17888 + scenario_offset;

}

string delayed_command = "NULL";
float delay = 0.0;
integer dc_is_action = 0;
integer dc_npc_offset = 0;

interrupt()
{
    delayed_command = "NULL";
    llSetTimerEvent(0.0);
    
    // integer i;
    // for (i=0; i<num_npc; i++)
    //     llSay(base_npc_control_channel+i, "-interrupt");
    //llSleep(2.0); 
}  

reset_to_start() 
{
    integer i;
    for (i=0; i<num_npc; i++)
       llSay(base_npc_control_channel+i, "-reset");
    llSay(facil_control_channel, "-reset");  
    llSay(facil_capture_channel, "-reset");  
    llSay(facil_scribe_channel, "reset~*~");
} 

npc_rnd_pair_all() 
{
    integer i;
    for (i=0; i<num_npc; i++)
       llSay(base_npc_control_channel+i, "npccustsay0");
}

npc_group()
{
    integer i;
    for (i=0; i<num_npc; i++)
       llSay(base_npc_control_channel+i, "-group");    
}

npc_group_return()
{
    integer i;
    for (i=0; i<num_npc; i++)
       llSay(base_npc_control_channel+i, "-groupreturn");    
}

follow_up_resp()
{
    integer i;
    for (i=0; i<num_npc; i++)
       llSay(base_npc_control_channel+i, "-npcfollow");    
}

multi_command(string command, list ignore)
{
    integer i;
    for (i=0; i<num_npc; i++)
    {
        if(~llListFindList(ignore, (list)i))
            llSay(base_npc_control_channel+i, command);
    }
}

default
{
    state_entry()
    {
        set_offset();
        llListen(backdoor_channel, "", NULL_KEY, "");
    }  

    timer()
    {
        if(dc_is_action)
            llSay(npc_action_control_base_channel+dc_npc_offset, delayed_command);
        else    
            llSay(base_npc_control_channel+dc_npc_offset, delayed_command);
        llSetTimerEvent(0.0);    
    } 
    
    listen(integer channel, string name, key id, string message)
    {
        if (message == "-reset")
        {
            reset_to_start();
        } 
        else if(message == "-2default")
        {
            interrupt();
            multi_command("-goto:default", [0,1,2,3,4,5,6,7]);
        }
        ///////////////
        else if (message == "-d_explain")
        {
            interrupt();
            llSay(facil_control_channel, "-d1");
        }
        else if (message == "-ad_drawarray")
        {
            interrupt(); 
            delay = 1.0;
            llSay(base_npc_control_channel+1, "npcsay0");
            llSleep(delay);
            llSay(base_npc_control_channel+2, "npcsay1");
            llSleep(delay);
            llSay(base_npc_control_channel+1, "npcask0");
            llSleep(delay);
            llSay(facil_control_channel, "-d2");
        } 
        else if (message == "-ad_drawarray!")
        {
            interrupt(); 
            llSay(facil_control_channel, "-d2!");
        } 
        else if (message == "-ad_visual")
        {
            interrupt(); 
            delay = 3.0; 
            llSay(base_npc_control_channel+1, "npcask1");
            llSleep(delay);
            llSay(facil_control_channel, "-d3");
        }
        else if (message == "-ad_visual!")
        {
            interrupt(); 
            llSay(facil_control_channel, "-d3!");
        }
        else if (message == "-ad_understood")
        {
            interrupt(); 
            delay = 3.0;
            llSay(base_npc_control_channel+1, "npcsay2");
            llSleep(delay);
            llSay(base_npc_control_channel+3, "npcask2");
            llSleep(delay);
            llSay(facil_control_channel, "-d4");
        }
        else if (message == "-ad_understood!")
        {
            interrupt(); 
            delay = 3.0;
            llSay(facil_control_channel, "-d4!");
        }
        else if (message == "-ad_pointers")
        {
            interrupt(); 
            delay = 3.0;
            llSay(base_npc_control_channel+5, "npcask3");
            llSleep(delay);            
            llSay(facil_control_channel, "-d5");
        }
        else if (message == "-ad_pointers!")
        {
            interrupt(); 
            delay = 3.0;
            llSay(facil_control_channel, "-d5!");
        }
        else if (message == "-ad_differ")
        {
            interrupt(); 
            delay = 3.0;
            llSay(base_npc_control_channel+5, "npcsay3");
            llSleep(delay);
            llSay(base_npc_control_channel+6, "npcask4");
            llSleep(delay);
            llSay(facil_control_channel, "-d6");
        }
        else if (message == "-ad_differ!")
        {
            interrupt(); 
            llSay(facil_control_channel, "-d6!");
        }
        else if (message == "-ad_altrep")
        {
            interrupt(); 
            llSay(base_npc_control_channel+5, "npcsay4");
            llSay(facil_control_channel, "-d7");
        }
    }
}