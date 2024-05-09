# connect-to-vpn-on-unknown-wifi

All the [talk](https://arstechnica.com/security/2024/05/novel-attack-against-virtually-all-vpn-apps-neuters-their-entire-purpose/) of [TunnelVision](https://www.leviathansecurity.com/blog/tunnelvision) got me thinking about being more diligent about using a VPN when I'm on public Wi-Fi.

This makes it easy for me to do so.

The first time I connect to a Wi-Fi network, this asks me whether I want to enable [Mullvad VPN](https://mullvad.net/en) (my current VPN of choice). If I click **Connect**, it connects me. If I click **Don't Connect** it then asks me if I'd like to save the current Wi-Fi network SSID to a list of known networks. If I say **Yes**, I'm not prompted to connect to Mullvad VPN the next time I connect to this SSID.

I also use Tailscale, so this also disables Tailscale before enabling Mullvad.
