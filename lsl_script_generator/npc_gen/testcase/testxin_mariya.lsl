// This script is automatically generated by Andrew M. Yuan's LSL automatic
// generation tool kit. The tool reads an interactive NPC description
// file and outputs the NPC script. You might wan to modify some
// variables that control NPC behavor such my myid. The control variables
// are exactly the same as the hand-coded NPC scripts for the MILE4STEM project
// (mostly by Raymond Naglieri).

//      
// NPC Variables
integer tc = 0; 
key npc;         // the key for the NPC 
key TA_trainee;
integer myid = 0;  // myid 0 from 7
integer num_npcs = 8;  // total number of npcs in this lab.
string myname; 
string lower_firstname;
string lower_lastname;
rotation myrotation;
integer wait_time = 20;
integer local_timer;
string to_say = "NULL";
string currentquestion = "";
string currentanimation = "";
string currentsound = "";
string currentNPCresponse = "";
list currentNPCkeys;
string say_this = "";

//also add dynamic path wait times

list firstname = ["John", "Michael", "Kevin", "Robert", "Linda", "Thomas",
                   "Steven", "Karen", 
                   "Sarah", "David", 
                   "Joey", "Kimberly", "Mark", "Paul", "Jessica", "Cynthia", 
                   "Angela", "Goerge", "Rebecca", "Amanda", "Susan", "Mary", 
                   "Christine"];
                   
list lastname = ["Smith", "Johnson", "Williams", "Brown", "Jones", 
                  "Miller", "Davis", "Anderson", "Taylor", "Moore",
                  "White", "Lee", "Harris", "Lewis", "Young", 
                  "Gonzalez", "Wang", "Nelson", "Allen", "Baker",
                  "Green", "Kumar", "Campbell", "Sanchez"];   

list lab_animations = ["writing_at_desk", "avatar_no_unhappy", 
                       "avatar_express_wink", "Okay_nodding", "Well"];

list npc_lab_sounds = ["you_did_something_wrong_male","talking_too_fast_female", "what's_wrong_male", 
                        "what's_wrong_female", "is_it_correct_male", "extra_time_male", 
                        "am_i_doing_wrong_female", "am_i_doing_everything_correctly_male"];

string string_ani;    

//other globals
integer attention_span = 40;
integer reminder_interval = 180;
integer localcount;

//DO NOT MODIFY, these are the constants used for all scripts
integer facil_state_control_channel = 10101;
integer auto_facil_control_channel = 10102;

integer npc_state_control_base_channel = 31000;
integer npc_para_control_base_channel = 32000;
integer npc_action_control_base_channel = 33000;
integer scenario_send_base_channel = 41000;
integer scenario_recieve_base_channel = 42000;

integer npc_state_control_channel;  // chat channel for human control shared by all scripts
integer npc_para_control_channel;   // para control
integer npc_action_control_channel; // action control chaneel = base_channel + myid;
integer scenario_to_npc;

integer alert_message_channel = 0;
integer green_button_channel = 11500;   // chat channel from green button to npc, to start the lab
integer fire_alarm_channel = 101;
integer backdoor_channel = 20001;    // channel to talk to backdoor script
integer relay_msg_channel = 29000;
integer local_dialog_channel = 11001; // chat channel for feedbacks from the dialog box
integer interact_with_lab_channel = 101; // for interactive items in lab

// integer npc_state_control_channel = 10100; // channel for facilitator to control npcs

// some utility variables
integer debug_level = 0;  // debug_level to control messages
string state_name;         // name of the current state
integer internal_state;    // working storage to store the status within a state
                        
list current_interaction;
integer curr_int_index;
integer saved_curr_int_index;
integer curr_action_index;
integer next_action_index;

list I_default_A0 = [1, 3, 52,
0, 1, "Hi, I think I need your help. This digital multimeter is broken", 0, 1, "", 1, "", 1, "", "",
2, 19, 37, 38, 52,
0, 4, 1, "wire", "connect", "wires", "conn",
0, 1, "Yes, I misconnected the wires.", 0, 1, "", 1, "", 1, "", "", 
0,
0, 0, 0,  0, 1, "I have tried that!", 0, 1, "", 1, "", 1, "", "",
-1];
list I_default_A1 = [1, 3, 51,
0, 1, "Can you take a look at my digital multimeter? I might have broken it.", 0, 1, "", 1, "am_I_correct_male", 1, "", "",
2, 19, 36, 37, 51,
0, 3, 1, "connect", "wire", "ABCDE",
0, 1, "Yes, I probably messed up the wires.", 0, 1, "", 1, "", 1, "", "", 
0,
0, 0, 0,  0, 1, "I have tried that!", 0, 1, "", 1, "", 1, "", "",
-1];
list I_default_T = [1, 3, 15, 0, 1, "", 0, 1, "", 1, "", 1, "", ""];
//helper functions
reset_all() 
{  // resets all globals  
    llSetRot(myrotation);
    attention_span = 40; 
    currentquestion = "";
    
}

backdoor_reset() 
{   // delete npc and reset script
    remove_npc();
    llResetScript();
    return;   
}  

ask_question() 
{   // standard ask question animation sequence  
    llSleep(5);
    llPlaySound("question", 5.0);
    osNpcStopAnimation(npc, currentanimation);
    currentanimation = "raisingahand";
    osNpcPlayAnimation(npc, currentanimation);
    osNpcSay(npc, "Excuse me.");
    return;   
} 

// check is name is in checkname string
// use substring to make it more flexible
integer name_called(string checkname)
{
    string lower_msg = llToLower(checkname);
    if ((llSubStringIndex(lower_msg, lower_firstname) != -1) ||
        (llSubStringIndex(lower_msg, lower_lastname) != -1))    
    {
        return TRUE;
    }
    return FALSE;
} 

integer keyword_match_xy(string msg, list q_key_words) 
{   // matches keywords in string message, return 1 if found
    string lower_msg = llToLower(msg); 
    integer i;
    string key_word;    
    for(i = 0; i < llGetListLength(q_key_words); i++) 
    {
        key_word = llList2String(q_key_words, i);
        if (llSubStringIndex(lower_msg, key_word) != -1) return 1;
    }
    return 0;   
}    

// count the number of key words matched
integer keyword_match_count_xy(string msg, list q_key_words) 
{   // matches keywords in string message, return 1 if found
    string lower_msg = llToLower(msg); 
    integer i;
    string key_word;    
    integer count = 0;
    
    for(i = 0; i < llGetListLength(q_key_words); i++) 
    {
        key_word = llList2String(q_key_words, i);
        if (llSubStringIndex(lower_msg, key_word) != -1) count++;
    }
    return count;   
}    

integer random_integer(integer min, integer max)
{
    return min + (integer)(llFrand(max - min + 1));
}

integer spawn_npc() 
{ // spawn procedure for NPC
    if (tc == 0) 
    {    
        npc = osNpcCreate(llList2String(firstname, myid), llList2String(lastname, myid),llGetPos(),"app");
        myname = llKey2Name(npc);
        lower_firstname  = llToLower(llList2String(firstname, myid));
        lower_lastname = llToLower(llList2String(lastname, myid));
        if(debug_level)
            osNpcSay(npc, 0, myname);
        osNpcSit(npc,llGetKey(),OS_NPC_SIT_NOW);
        tc = 1;
        return 1;
    } 
    else 
    { 
        reset_all();
        tc = 0;
        osNpcRemove(npc);
        return 0;     
    }
} 

// this routine only create npc, if npc is already there, do nothing.
integer create_npc() 
{   // spawn procedure for NPC
    if (tc == 0) 
    {    
        npc = osNpcCreate(llList2String(firstname, myid), llList2String(lastname, myid),llGetPos(),"app");
        myname = llKey2Name(npc);
        lower_firstname  = llToLower(llList2String(firstname, myid));
        lower_lastname = llToLower(llList2String(lastname, myid));
        if(debug_level)
            osNpcSay(npc, 0, myname);
        osNpcSit(npc,llGetKey(),OS_NPC_SIT_NOW);
        tc = 1;
        return 1;
    } 
    return 0;
} 

// this routine only delete npc, if npc is not there, do nothing.
integer remove_npc() 
{ // spawn procedure for NPC
    if (tc == 1)
    { 
        reset_all();
        tc = 0;
        osNpcRemove(npc);
        return 1;     
    }
    return 0;
} 

register_common_channel()
{
    llListen(npc_state_control_channel, "", NULL_KEY, "");
    llListen(npc_para_control_channel, "", NULL_KEY, "");
    llListen(npc_action_control_channel, "", NULL_KEY, "");
    llListen(scenario_to_npc, "", NULL_KEY, "");
} 

remove_common_channel()
{
    llListenRemove(npc_state_control_channel);
    llListenRemove(npc_para_control_channel);
    llListenRemove(npc_action_control_channel);
}

register_common_channel_timer(integer t)
{
    llListen(npc_state_control_channel, "", NULL_KEY, "");
    llListen(npc_para_control_channel, "", NULL_KEY, "");
    llListen(npc_action_control_channel, "", NULL_KEY, "");
    llListen(scenario_to_npc, "", NULL_KEY, "");  
    llSetTimerEvent(t);
}

process_common_listen_port_msg(integer c, string n, key ID, string msg)
{ 
    process_common_state_control_msg(c, n, ID, msg);
    process_common_para_control_msg(c, n, ID, msg);
    process_common_action_control_msg(c, n, ID, msg);
    process_state_specific_control_msg(c, n, ID, msg);
}

process_common_para_control_msg(integer c, string n, key ID, string msg)    
{
    if (c == npc_para_control_channel) 
    { // change script parameters
        list tmplist = llParseString2List(msg, [" "], []);
        string ss = llList2String(tmplist, 0);
        integer val = llList2Integer(tmplist, 1);
        if (ss == "@Querydebug_level") 
        {
            osNpcSay(npc, "debuy_level = " + debug_level);
        }
        else if (ss == "@Querystate") 
        {
            osNpcSay(npc, "state = " + state_name);
        } 
        else if (ss == "@Queryreminder_interval") 
        {
            osNpcSay(npc, "reminder_interval = " + reminder_interval);
        } 
        else if (ss == "@Queryrepeat_interval") 
        {
            //osNpcSay(npc, "repeat_interval = " + repeat_interval);
        } 
        else if (ss == "@Querymyid") {
            osNpcSay(npc, "myid = " + myid);
        }
        else if (ss == "@Setdebug_level") 
        {
            debug_level = val;
        } 
        else if  (ss == "@Setreminder_interval") 
        {
            reminder_interval = val;
        } 
        else if  (ss == "@Setrepeat_interval") 
        {
        } 
        else if (ss == "@Setmyid") 
        {
            myid = val;
            spawn_npc(); // keep
            spawn_npc();
            reset_all();
            remove_common_channel();
            npc_state_control_channel = npc_state_control_base_channel + myid;
            npc_para_control_channel = npc_para_control_base_channel + myid;
            npc_action_control_channel = npc_action_control_base_channel + myid;
            register_common_channel_timer(reminder_interval);
            state Idle;
        }
        else if (ss == "@Setwait_talk")
        {

        }
        else if(ss == "@SetAsk")
        {
            currentquestion = ss;
        }
        else if (ss == "@Resetscript") 
        {
            llResetScript();
        }
    }
}

process_common_action_control_msg(integer c, string n, key ID, string msg)
{    
    if (c == npc_action_control_channel) 
    { // perform action when needed
        list tmplist = llParseString2List(msg, ["-"], []);
        string action_spec = llList2String(tmplist, 0);
        string action = llList2String(tmplist, 1);
        if (action_spec == "@Speak") 
        {
		   llSleep(1);
		   osNpcSay(npc, action);
		   llSleep(1);
        } 
        else if (action_spec == "@SpeakAnim")
        {
          //
        }
        else if (msg == "@LookAt") {
           list a = llGetObjectDetails(TA_trainee, [OBJECT_POS]);
           llStopLookAt();
           llRotLookAt( llRotBetween( <1.0,0.0,0.0>, llVecNorm( llList2Vector(a, 0) - llGetPos() ) ), 1.0, 0.4 );  
        } else if (msg == "@NoRotation") {
          llSetRot(myrotation);
        }
        else if (action_spec == "@Hand_up")
        {   
            
            osNpcStopAnimation(npc, currentanimation);
            currentanimation = "raisingahand";
            osNpcPlayAnimation(npc, currentanimation);
        }
        else if (action_spec == "@Stop_ani")
        {
            osNpcStopAnimation(npc, currentanimation);
        } 
        else if(action_spec == "@Perform")
        {
            osNpcStopAnimation(npc, currentanimation);
            currentanimation = action;
            osNpcPlayAnimation(npc, currentanimation);
        }
        else if (action_spec = "@Rotate")
        {
            string lower_action = llToLower(action);
            rotation rot_npc = osNpcGetRot(npc); 
            vector xyz_angles = <0,0.0,0>;
            vector angles_in_radians = xyz_angles*DEG_TO_RAD;
            rotation rot_xyzq = llEuler2Rot(angles_in_radians); 
            if (lower_action == "north" || lower_action == "n")
            {
                xyz_angles = <0,0,90.0>;

            }
            else if (lower_action == "south" || lower_action == "s")
            {
                 xyz_angles = <0,0,180.0>;

            }
            else if (lower_action == "east" || lower_action == "e")
            {
                 xyz_angles = <0,0,270.0>;

            }
            else if (lower_action == "west" || lower_action == "w")
            {
                 xyz_angles = <0,0,360.0>;

            }
            else 
            {
                if(debug_level)
                    llSay(0, "Invalid @Rotate command: Not a valid direction.");
                return;
            }

            angles_in_radians = xyz_angles*DEG_TO_RAD;
            rot_xyzq = llEuler2Rot(angles_in_radians); 
            osNpcSetRot(npc, rot_xyzq);
         }   
    } 
}

integer do_ask_action(integer ii)
{
    integer channel1;
    integer num_q1;
    list qq1;
    integer channel2;
    integer num_q2;
    list qq2;
     integer num_a;
    list aa;
    integer num_s;
    list ss;                
    string cust;
    string anim;
    string sound;
    string ques;

    next_action_index = ii;
    
    channel1 = llList2Integer(current_interaction, 0+ii);
    num_q1 = llList2Integer(current_interaction, 1+ii);
    qq1 = llList2List(current_interaction, 2+ii, 
    2+ii+num_q1-1);
    channel2 = llList2Integer(current_interaction, 2+ii+num_q1);
    num_q2 = llList2Integer(current_interaction, 2+ii+num_q1+1);
    qq2 = llList2List(current_interaction, 
          2+ii+num_q1+2, 
          2+ii+num_q1+num_q2+1);
    num_s = llList2Integer(current_interaction, 
            2+ii+num_q1+num_q2+2);
    ss = llList2List(current_interaction, 
         2+ii+num_q1+num_q2+3, 
         2+ii+num_q1+num_q2+num_s+2);
    num_a = llList2Integer(current_interaction, 
        2+ii+num_q1+num_q2+num_s+3);
    aa = llList2List(current_interaction, 
         2+ii+num_q1+num_q2+num_s+4, 
         2+ii+num_q1+num_q2+num_s+num_a+3);
    cust = llList2String(current_interaction, 
        2+ii+num_q1+num_q2+num_a+num_s+4);

    if (num_q1 <= 1) {
        ques = llList2String(qq1, 0);
    } else ques = llList2String(qq1, random_integer(0, num_q1-1));
    if (ques != "") {
      currentquestion = ques;
      if (channel1 == -1) 
        llSay(relay_msg_channel, npc_state_control_base_channel+" "+ currentquestion);
      if (channel1 != 0) llSay(channel1, currentquestion);
      else osNpcSay(npc, currentquestion);
    }
    if (num_q2 <= 1) {
        ques = llList2String(qq2, 0);
    } else ques = llList2String(qq2, random_integer(0, num_q2-1));
    if (ques != "") {
      currentquestion = ques;
      if (channel2 == -1) 
        llSay(relay_msg_channel, npc_state_control_base_channel+" "+ques);
      if (channel2 != 0) llSay(channel2, ques);
      else osNpcSay(npc, ques);
    }
    if (num_a <=1) {
        anim = llList2String(aa, 0);
    } else anim = llList2String(aa, random_integer(0, num_a-1));
    
    if (anim != "") {
        osNpcStopAnimation(npc, currentanimation);
        currentanimation = anim;
        osNpcPlayAnimation(npc, currentanimation);
        llSleep(4);
    }
        
    if (num_s <=1) 
        sound = llList2String(ss, 0);
     else sound = llList2String(ss, random_integer(0, num_s-1));
    if (sound != "") {
        currentsound = sound;
        llTriggerSound(sound, 1.0);
    }
    
    if (cust != "") run_routine(cust);
    if (debug_level > 10) {
        osNpcSay(npc, "qq1 = " + llDumpList2String(qq1, ", "));        
        osNpcSay(npc, "qq2 = " + llDumpList2String(qq2, ", "));    
        osNpcSay(npc, "aa = " + llDumpList2String(aa, ", "));    
        osNpcSay(npc, "ss = " + llDumpList2String(ss, ", "));    
        osNpcSay(npc, "currentquestion = " + currentquestion);
        osNpcSay(npc, "ques = " + ques);
        osNpcSay(npc, "anim = " + anim);
        osNpcSay(npc, "sound = " + sound);
    }
    
    return 2+ii+num_q1+num_q2+num_a+num_s+4+1;
    
}

// check the responses, do the corresponding action, 
// set curr_int_index to the right value
do_response_action(string msg)
{
    integer num_res;
    list beg_end = [];
    integer channel;
    integer num_key;
    integer accept_key;
    list keys;
    integer ind;
    integer i;
    integer beg;
    integer end;
    integer ii;
    
    num_res = llList2Integer(current_interaction, curr_int_index);
    if (debug_level) osNpcSay(npc, "curr_index = " + curr_int_index + ", num_res = " + num_res);
    if (num_res == 0) goto_idle_state(); // done
    else if (num_res < 0) {
      curr_int_index = saved_curr_int_index;return; // do nothing, looping back to the original state
    } else {
        beg_end = llList2List(current_interaction, curr_int_index+1,
                                curr_int_index+1+2*num_res);
        for (i=0; i<num_res; i++) {
            beg = llList2Integer(beg_end, i*2);
            end = llList2Integer(beg_end, i*2+1);
            ind = beg;
              channel = llList2Integer(current_interaction, ind);
            num_key = llList2Integer(current_interaction, ind+1);
            accept_key = llList2Integer(current_interaction, ind+2);
            if (num_key > 0) {
                keys = llList2List(current_interaction, ind+3, 
                       ind+3+num_key-1);
                if (debug_level > 10) {       
                     osNpcSay(npc, "keys = " + llDumpList2String(keys, ", "));         
                    osNpcSay(npc, "beg= " + beg);
                    osNpcSay(npc, "end= " + end);
                    osNpcSay(npc, "num_key= " + num_key);
                    osNpcSay(npc, "accept_key= " + accept_key);
                    osNpcSay(npc, "tree = " + 
                     llDumpList2String(llList2List(current_interaction, beg, end), ", "));
                }                    
                if (keyword_match_count_xy(msg, keys) >= accept_key) {
                    curr_int_index = do_ask_action(ind+3+num_key);
                    ii = llList2Integer(current_interaction, curr_int_index);        
                    if (ii== 0) goto_idle_state();
                    else if (ii < 0) {curr_int_index = saved_curr_int_index; return;}
                    response_exit_state();
                }
            } else {
                curr_int_index = do_ask_action(ind+3);
                ii = llList2Integer(current_interaction, curr_int_index);        
                if (ii== 0) goto_idle_state();
                else if (ii < 0) {curr_int_index = saved_curr_int_index;return;}
                response_exit_state();
            }
        }
    }
}


run_routine(string s)
{
  if (s=="reset_all") reset_all();
  else osNpcSay(npc, "routine "+ s + " is not supported.");
}

goto_idle_state()
{
  if (llSubStringIndex(state_name, "_") == -1) state Idle_default;
  else if (llSubStringIndex(state_name, "_default") != -1) state Idle_default;
  else osNpcSay(npc, "DEBUG: wrong state_name="+state_name);
}

response_exit_state()
{
  if (state_name == "Respond") state Respond1;
  else if (state_name == "Respond1") state Respond;
  else if (state_name == "Respond_default") state Respond1_default;
  else if (state_name == "Respond1_default") state Respond_default;
  else osNpcSay(npc, "DEBUG: wrong1 state_name="+state_name);
}

process_state_specific_msg_default(integer c, string n, key ID, string msg)
{
  integer ii;
  if (c == npc_state_control_channel) {
    if (msg == "-npcask") {
      current_interaction = I_default_A0;
      state Ask_default;
    }
    else if (msg == "-npcask2") {
      current_interaction = I_default_A1;
      state Ask_default;
    }
    else osNpcSay(npc, "Unknown command in state control channel.");
  }
}

process_state_specific_control_msg(integer c, string n, key ID, string msg)
{
  if (0) state default;
  else if (llSubStringIndex(state_name, "_default") != -1)
    process_state_specific_msg_default(c, n, ID, msg);
}

process_common_state_control_msg(integer c, string n, key ID, string msg)
{
  if (c == npc_state_control_channel) { // change state include restart
    if (msg == "-repeat") {
      //not yet supported
    } else if (msg == "-reset")
      backdoor_reset();

    else if (msg == "-goto:default")
      state Idle_default;
  }
}

default 
{
    state_entry() 
    {
        state_name = "default";
        npc_state_control_channel = npc_state_control_base_channel + myid;
        npc_para_control_channel = npc_para_control_base_channel + myid;
        npc_action_control_channel = npc_action_control_base_channel + myid;
        scenario_to_npc = scenario_recieve_base_channel + myid;
        llListen(green_button_channel, "", NULL_KEY, "");
    }
    
    touch_start( integer num) 
    {
        spawn_npc();
        TA_trainee = llDetectedKey(0);
        state Idle_default;  
    }
    
    listen(integer channel, string name, key id, string message) 
    {
        if(channel == green_button_channel) // talk between channels was causing an inital unwanted re-spawn.
        {                                   //need to find exactly what is causing it.
            TA_trainee = message;
            myrotation = llGetRot();
            spawn_npc(); 
            state Idle_default; 
        }
    }      
}


// when an npc is not engaged in a scenario
state Idle_default
{
    state_entry()
     {
        if(debug_level)
            llSay(0,"Idle");
        state_name = "Idle_default";
	current_interaction = I_default_T;
	do_ask_action(3);
        register_common_channel_timer(random_integer(20, attention_span));
    }    
    
    touch_start(integer num_detected) 
    {
        backdoor_reset();
    }
  
    timer()
    {  
        if(debug_level)
            osNpcSay(npc, "Idle for " + reminder_interval + " seconds, ready to take command."); //send message to alert_user
	current_interaction = I_default_T;
	do_ask_action(3);
        llSetTimerEvent(random_integer(20, attention_span));
    }  

    listen(integer c, string n, key ID, string msg)
    {
        llSetTimerEvent(30);       
        process_common_listen_port_msg(c, n, ID, msg);
    }
}  
    
// state Ask/Respond/Respond1 handles all interactions

state Ask_default
{
    state_entry()
    {
        localcount = 0;    
        state_name="Ask_default";
        if (debug_level) osNpcSay(npc, "ask state");
        ask_question();
        local_timer = 30;
        register_common_channel_timer(local_timer);
        llListen(PUBLIC_CHANNEL, "", NULL_KEY, "");
    }

    touch_start(integer num_detected)
    { 
        backdoor_reset();
    }

    timer()
    {
        ask_question();
        localcount++;
        if (localcount >=3) state Idle_default;
        else llSetTimerEvent(local_timer);
    }

    listen(integer c, string n, key ID, string msg)
    {
        integer ii;
        if ((c == PUBLIC_CHANNEL) && (ID == TA_trainee))
        {
            if(name_called(msg)) 
            {
                curr_int_index = do_ask_action(3);
                ii = llList2Integer(current_interaction, curr_int_index);
		if (debug_level >= 10) 
		  osNpcSay(npc, "XXX" + ii);
                if (ii == 0) {state Idle_default; llSetTimerEvent(15);}
                else state Respond_default;
            }
        }  else process_common_listen_port_msg(c, n, ID, msg);   
    }
} 

// this implements the interaction

state Respond_default
{
    state_entry()
    {
        //ask_question();
        state_name = "Respond_default";
        curr_action_index = next_action_index;
        localcount = 0; saved_curr_int_index = curr_int_index;
        if (debug_level) osNpcSay(npc, "respond state");
        local_timer = 30;
        register_common_channel_timer(local_timer);
        llListen(PUBLIC_CHANNEL, "", NULL_KEY, "");
    }

    touch_start(integer num_detected)
    { 
        backdoor_reset();
    }

    timer()
    {
//        osNpcSay(npc, currentquestion);
//        if (say_this != "")                
//          llTriggerSound(say_this, 3.0);      
        do_ask_action(curr_action_index);
        localcount++;
        if (localcount >=4) {
            osNpcSay(npc, "OK, I still do not get you, but I will stop."); 
            reset_all(); state Idle_default;
        }
        else llSetTimerEvent(local_timer);
    }
    
    listen(integer c, string n, key ID, string msg)
    {
        if ((c == PUBLIC_CHANNEL) && (ID == TA_trainee))
        {
           do_response_action(msg);
        }  else process_common_listen_port_msg(c, n, ID, msg);   
    }
}

// State Respond1 has exact the same action of state Respond 
// so that the two states
// can go back and forth to process iterative interactions

state Respond1_default
{
    state_entry()
    {
        state_name = "Respond1_default";
        localcount = 0; saved_curr_int_index = curr_int_index;
        curr_action_index = next_action_index;
        local_timer = 30;
        if (debug_level) osNpcSay(npc, "respond1 state");
        register_common_channel_timer(local_timer);
        llListen(PUBLIC_CHANNEL, "", NULL_KEY, "");
    }

    touch_start(integer num_detected)
    { 
        backdoor_reset();
    }

    timer()
    {
//        osNpcSay(npc, currentquestion);
//        if (say_this != "")                
//          llTriggerSound(say_this, 3.0);      
        do_ask_action(curr_action_index); 
        localcount++;
        if (localcount >=4) {
            osNpcSay(npc, "OK, I still do not understand but I will stop"); 
            reset_all(); state Idle_default;
        }
        else llSetTimerEvent(local_timer);
    }
    
    listen(integer c, string n, key ID, string msg)
    {
        if ((c == PUBLIC_CHANNEL) && (ID == TA_trainee))
        {
           do_response_action(msg);
        }  else process_common_listen_port_msg(c, n, ID, msg);   
    }
}

