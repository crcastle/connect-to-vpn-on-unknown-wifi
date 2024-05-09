set ssid to do shell script POSIX path of ((path to me as text) & "::" & "get-connected-wifi-ssid.sh")

set knownNetworksFilePath to POSIX path of ((path to me as text) & "::" & "known-wifi-networks.txt")
set knownNetworks to paragraphs of (read POSIX file knownNetworksFilePath)
-- set knownNetworks to {"Turtles!"}


-- Don't do anything if connected to a known Wi-Fi network.
if ssid is in knownNetworks then
	return
end if

-- Don't do anything if Mullvad VPN is already connected.
set mullvadStatus to do shell script "/usr/local/bin/mullvad status"
if mullvadStatus starts with "Connected" then
	return
end if

-- Display dialog and get user input
set msg to "Connected to unknown Wi-Fi network:\r\r" & ssid & "\r\n\nEnable Mullvad VPN?"
tell application "Mullvad VPN" to (display dialog msg with icon caution buttons {"Don't Connect", "Connect"} default button "Connect" giving up after 10)

-- Connect to Mullvad if "Connect" clicked or no response after specified time
if button returned of result = "Connect" or gave up of result then
	-- Disable Tailscale
	try
		set tailscaleStatus to do shell script "/Applications/Tailscale.app/Contents/MacOS/Tailscale down"
	on error errStr number errorNumber
		display dialog "Tailscale error: " & errStr & " (" & errorNumber & ")" with icon stop buttons {"Ok"}
	end try
	
	-- Enable Mullvad VPN
	try
		
		delay 1
		set mullvadConnectStatus to do shell script "/usr/local/bin/mullvad connect"
	on error errStr number errorNumber
		display dialog "Mullvad VPN error: " & errStr & " (" & errorNumber & ")" with icon stop buttons {"Ok"}
		return
	end try
	
	delay 1
	display notification with title "'" & ssid & "' is unknown Wi-Fi network" subtitle "Connecting to Mullvad"
else
	-- Ask whether to save current Wi-Fi network to list of known networks
	set msg to "Save '" & ssid & "' to list of known networks?"
	tell application "Mullvad VPN" to (display dialog msg with icon caution buttons {"No", "Yes"} default button "Yes" giving up after 10)
	
	if button returned of result = "Yes" then
		try
			set updateKnownNetworksStatus to do shell script "echo '" & ssid & "' >> " & knownNetworksFilePath
		on error errStr number errorNumber
			display dialog "Error writing to know networks file: " & errStr & " (" & errorNumber & ")"
			return
		end try
	end if
end if
