#NoEnv
#NoEnv
SendMode Input

/*
Online
==========
AHK script for checking online connectivity

Uses the RoundTripTime section of the SimplePing AHK library
Link to full SimplePing: https://gist.github.com/Uberi/5987142

Only changes made (other than removing unused segments) was changing the response to unable to send a 
packet to a value instead of throwing an exception (line 79)
*/

/*
SimplePing
==========
AHK library providing a variety of ICMP pinging-related functionality.

Example
--------

Ping a Google DNS server:

    MsgBox % "Round trip time: " . RoundTripTime("8.8.8.8")

Overview
--------
### RTT := RoundTripTime(Address,Timeout = 800)
Determines the round trip time (sometimes called the "ping") from the local machine to the address.
Useful for pinging a server to determine latency.

Parameters
----------
RTT:          The round trip time in milliseconds (e.g., 76). If unknown or timed out, this value is -1.
Address:      IPv4 address as a string in dotted number format (e.g., "127.0.0.1").
Timeout:      How long the function should wait, in milliseconds, before giving an error (e.g., 400).
*/

RoundTripTime(Address,Timeout = 800)
{
    If DllCall("LoadLibrary","Str","ws2_32","UPtr") = 0 ;NULL
        throw Exception("Could not load WinSock 2 library.")
    If DllCall("LoadLibrary","Str","icmp","UPtr") = 0 ;NULL
        throw Exception("Could not load ICMP library.")

    NumericAddress := DllCall("ws2_32\inet_addr","AStr",Address,"UInt")
    If NumericAddress = 0xFFFFFFFF ;INADDR_NONE
        throw Exception("Could not convert IP address string to numeric format.")

    hPort := DllCall("icmp\IcmpCreateFile","UPtr") ;open port
    If hPort = -1 ;INVALID_HANDLE_VALUE
        throw Exception("Could not open port.")

    StructLength := 270 + (A_PtrSize * 2) ;ICMP_ECHO_REPLY structure
    VarSetCapacity(Reply,StructLength)
    Count := DllCall("icmp\IcmpSendEcho"
        ,"UPtr",hPort ;ICMP handle
        ,"UInt",NumericAddress ;IP address
        ,"Str","" ;request data
        ,"UShort",0 ;length of request data
        ,"UPtr",0 ;pointer to IP options structure
        ,"UPtr",&Reply ;reply buffer
        ,"UInt",StructLength ;length of reply buffer
        ,"UInt",Timeout) ;ping timeout

    If !DllCall("icmp\IcmpCloseHandle","UInt",hPort) ;close port
        throw Exception("Could not close port.")

    Status := NumGet(Reply,4,"UInt")
    If Status In 11002,11003,11004,11005,11010 ;IP_DEST_NET_UNREACHABLE, IP_DEST_HOST_UNREACHABLE, IP_DEST_PROT_UNREACHABLE, IP_DEST_PORT_UNREACHABLE, IP_REQ_TIMED_OUT
    {
        VarSetCapacity(Result,0)
        Return, -1
    }
    If Status != 0 ;IP_SUCCESS
        Return, -2 ;changed to return a value instead of throw exception

    Return, NumGet(Reply,8,"UInt")
}

while True ;always runs
{
	ping := RoundTripTime("1.1.1.1",4000) ;pings 1.1.1.1 with a timeout of 4 seconds
	if (ping < 0 ) ;if no response
	{
		ping_check := RoundTripTime("1.1.1.1",4000) ;double checks for lost connection
		if (ping_check < 0) ;checks if definitely timed out
		{
			ifWinExist, Warning ;checks if splash text exists already
			{}
			else
			{
				SplashTextOn,150,140,Warning,`n`n`nOffline ;create splash text
				sleep 5000 ;waits 5 seconds
				WinMove, Warning, , A_ScreenWidth-156, A_ScreenHeight-210 ;moves splash text to the bottom right corner
				WinSet, ExStyle, +0x20, Warning ; 0x20 = WS_EX_CLICKTHROUGH
				WinSet, Transparent, 255, Warning ; makes splash text not transparent
			}
		}
	}
	else ;if no timeout
	{
		SplashTextOff ;turns off splash text
	}
	sleep 1000 ;waits 1 second
}