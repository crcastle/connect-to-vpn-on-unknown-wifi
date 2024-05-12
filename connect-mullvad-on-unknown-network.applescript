#!/usr/bin/env osascript

-- Set this string to where you want the known networks file to be stored.
-- The below script will create the file if it doesn't exist.
set knownNetworksFilePath to POSIX file "/Users/crcastle/bin/known-wifi-networks.txt"

-- Don't do anything if Mullvad VPN is already connected.
set mullvadStatus to do shell script "/usr/local/bin/mullvad status"
if mullvadStatus starts with "Connected" then
	return
end if

-- Get Wi-Fi SSID that computer is currently connected to
try
	set ssid to do shell script "networksetup -getairportnetwork en0 | sed -n 's/^.* Network: //p'"
on error errStr number errorNumber
	display dialog "Error getting currently connected Wi-Fi network's SSID." with icon stop buttons {"Ok"}
	return
end try

-- Get known networks from known-wifi-networks.txt file
-- Path to this script is passed as first argument by launchd
-- Create known-wifi-networks.txt if it doesn't exist
tell application "Finder"
	if exists knownNetworksFilePath then
		set knownNetworks to paragraphs of (read knownNetworksFilePath)
	else
		try
			do shell script "echo > " & (quoted form of POSIX path of knownNetworksFilePath)
			set knownNetworks to {""}
		on error errStr number errorNumber
			display dialog "Error creating known-wifi-networks.txt. " & errStr with icon stop buttons {"Ok"}
			return
		end try
	end if
end tell

-- Don't do anything if connected to a known Wi-Fi network.
if ssid is in knownNetworks then
	return
end if

-- Display dialog and get user input
set msg to "Connected to unknown Wi-Fi network:\r\r" & ssid & "\r\n\nEnable Mullvad VPN?"
tell application "Mullvad VPN" to (display dialog msg with icon caution buttons {"Don't Connect", "Connect"} default button "Connect" giving up after 10)

-- Connect to Mullvad if "Connect" clicked or no response after specified time
if button returned of result = "Connect" or gave up of result then
	-- Configure pf packet filter so that outgoing connections to Tailscale 100.64.0.0/10 IPv4 addresses are permitted
	try
		do shell script "echo 'pass out quick inet from any to { 100.64.0.0/10, !100.64.0.7 }' | sudo pfctl -a com.apple/mullvad-tailscale -f -"
	on error errStr number errorNumber
		display dialog "Error configuring pf packet filter to allow Tailscale: " & errStr & " (" & errorNumber & ")" with icon stop buttons {"Ok"}
	end try
	
	-- Enable Mullvad VPN
	try
		delay 2 --wait for changes from Tailscale disabling to settle down
		set mullvadConnectStatus to do shell script "/usr/local/bin/mullvad connect"
	on error errStr number errorNumber
		display dialog "Mullvad VPN error: " & errStr & " (" & errorNumber & ")" with icon stop buttons {"Ok"}
		return
	end try

	-- Route DNS requests to 100.64.0.7 to go to Mullvad (not Tailscale) while Mullvad VPN is connected
	-- They get sucked up by the Tailscale route becuase that IP address overlaps with Tailscale's 100.64.0.0/10 IP range
	-- It looks like this route is automatically deleted when Mullvad is disconnected because 10.65.0.1 is no longer accessible
	try
		do shell script "sudo route -q -n add 100.64.0.7 default"
	on error errStr number errorNumber
		display dialog "Error configuring route sending DNS to Mullvad: " & errStr & " (" & errorNumber & ")" with icon stop buttons {"Ok"}
	end try
	
	delay 1 --display the below notification *after* Mullvad's native "connected" notification because this one is persistent
	display notification with title "'" & ssid & "' is unknown Wi-Fi network" subtitle "Connecting to Mullvad"
else
	-- Ask whether to save current Wi-Fi network to list of known networks
	set msg to "Save '" & ssid & "' to list of known networks?"
	tell application "Mullvad VPN" to (display dialog msg with icon caution buttons {"No", "Yes"} default button "Yes" giving up after 10)
	
	if button returned of result = "Yes" then
		try
			set updateKnownNetworksStatus to do shell script "echo '" & ssid & "' >> " & (quoted form of POSIX path of knownNetworksFilePath)
		on error errStr number errorNumber
			display dialog "Error writing to know networks file: " & errStr & " (" & errorNumber & ")"
			return
		end try
	end if
end if
