float DEFAULT_ALPHA = 0.03;
integer DEFAULT_COOLDOWN = 10800; // 3 hours

float current_alpha = 0;
integer cooldown = 0; 

integer visible = TRUE;

string NOTECARD_NAME = "dirty_collect.properties";
key kQuery;
integer iLine = 0;
string collectPhr = "";
string descriptPhr = "";
string timeoutPhr = "";

verbose(string who) {
    collectPhr = replaceString(collectPhr, "%who", who);
    descriptPhr = replaceString(descriptPhr, "%who", who);
    collectPhr = replaceString(collectPhr, "%name", llGetObjectName());
    descriptPhr = replaceString(descriptPhr, "%name", llGetObjectName());
    collectPhr = replaceString(collectPhr, "%desc", llGetObjectDesc());
    descriptPhr = replaceString(descriptPhr, "%desc", llGetObjectDesc());

    if (collectPhr != "") llWhisper(PUBLIC_CHANNEL, collectPhr);
    if (descriptPhr != "") llWhisper(PUBLIC_CHANNEL, descriptPhr);
}

collect(string who) {
    if (visible) {
        if (current_alpha == 0) current_alpha = DEFAULT_ALPHA;
        if (cooldown == 0) cooldown = DEFAULT_COOLDOWN;

        llSetLinkAlpha(LINK_SET, current_alpha, ALL_SIDES);
        verbose(who);
        llSetTimerEvent(cooldown);
        visible = FALSE;
    }
}

reset() {
    timeoutPhr = replaceString(timeoutPhr, "%name", llGetObjectName());
    timeoutPhr = replaceString(timeoutPhr, "%desc", llGetObjectDesc());

    visible = TRUE;
    llSetTimerEvent(0.0);
    llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
    if (timeoutPhr != "") llWhisper(PUBLIC_CHANNEL, timeoutPhr);
}

string replaceString(string source, string pattern, string replace) {
    while (llSubStringIndex(source, pattern) > -1) {
        integer len = llStringLength(pattern);
        integer pos = llSubStringIndex(source, pattern);
        if (llStringLength(source) == len) { source = replace; }
        else if (pos == 0) { source = replace+llGetSubString(source, pos+len, -1); }
        else if (pos == llStringLength(source)-len) { source = llGetSubString(source, 0, pos-1)+replace; }
        else { source = llGetSubString(source, 0, pos-1)+replace+llGetSubString(source, pos+len, -1); }
    }
    return source;
}

float String2Float(string ST)
{
    list nums = ["0","1","2","3","4","5","6","7","8","9",".","-"];
    float FinalNum = 0.0;
    integer idx = llSubStringIndex(ST,".");
    if (idx == -1)
    {
        idx = llStringLength(ST);
    }
    integer Sgn = 1;
    integer j;
    for (j=0;j< llStringLength(ST);j++)
    {
        string Char = llGetSubString(ST,j,j);
        if (~llListFindList(nums,[Char]))
        {
            if((j==0) && (Char == "-"))
            {
                Sgn = -1;
            }
            else if (j < idx)
            {
                FinalNum = FinalNum + (float)Char * llPow(10.0,((idx-j)-1));
            }
            else if (j > idx)
            {
                FinalNum = FinalNum + (float)Char * llPow(10.0,((idx-j)));
            }
        }
    }
    return FinalNum * Sgn;
}

default
{
    state_entry()
    {
        key nc_key = llGetInventoryKey(NOTECARD_NAME);
        if (nc_key != NULL_KEY) kQuery = llGetNotecardLine(NOTECARD_NAME, iLine);
        reset();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) 
        {
            key nc_key = llGetInventoryKey(NOTECARD_NAME);
            if (nc_key != NULL_KEY) kQuery = llGetNotecardLine(NOTECARD_NAME, iLine);
            reset();
        }
    }

    touch_start(integer total_number)
    {
        llResetTime();
        string who = llDetectedName(0);
        collect(who);
    }

    touch_end(integer num)
    {
        // Longer click
        if ( llGetTime() > 0.8 ) {
            reset();
        }
    }

    timer() {
        reset();
        llSetTimerEvent(0.0);
    }

    dataserver(key query_id, string data) 
    {
        if (query_id == kQuery) 
        {
            if (data == EOF || data == "") return;
            else 
            {   
                if (iLine == 0) collectPhr = data;
                if (iLine == 1) descriptPhr = data;
                if (iLine == 2) timeoutPhr = data;
                if (iLine == 3) current_alpha = String2Float(data);
                if (iLine == 4) cooldown = (integer) data;

                iLine++;
                if (iLine < 5) kQuery = llGetNotecardLine(NOTECARD_NAME, iLine);
            }
        }
    }
}
