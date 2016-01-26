# updatePlexMediaServer script

Automatically updates the Plex Media Server on Ubuntu, Fedora, and CentOS distributions. Automatically detects distribution and architecture type, downloads the correct file and installs it.

Now supports PlexPass versions.

Run script with --plexpass to specify the PlexPass version. 
Will not save password as cleartext. Only saves the returned cookie to be used on subsequent requests from plex
