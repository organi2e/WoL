# WoL
An implementation to send magick packet for Wake-On-Lan

# Usage
	wol [options] <MAC addresses> …

Example:
	wol --addr 192.168.1.1 EA-10-DE-AD-BE-EF

Options:
	--port <port number>
		Default: 9
	--addr <IPv4 address>
		Default: broadcast
	--verbose
		Verbose flag
