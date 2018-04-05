# DemoRec
Garry's Mod addon that allows to request clientside demos, which are sent by the client to a web Flask server.

## Purpose
This addon was created for use on my server, to compensate for the broken serverside demos in the game. It allows a serveradmin / admin to request a clientside demo of a certain length from a specific player, which is recorded without him being aware and then sent to a web server where it is stored. Due to the demo being sent using HTTP, the upload is quite fast and no lag is noticed by the client.

## Current State
This addon is fully functional, but perfect behavior is not guaranteed, nor is support for this addon.
A random key is given to the client for each requested demo, and all client data is checked when uploading, but a full security check was not done on this system, so be careful when using it.

Feel free to edit this addon, and re-distribute it under the same license.

## Install

- Copy the *demorec* folder into your server's *addons* folder.
- Copy *demorec/web* to your desired location for the web server.
- Install dependencies using `pip3 -r requirements.txt` from the *web* folder (or whatever your Python3 pip executable is).
- **Important** : change the server key to a custom one in *lua/demorec_settings.lua* and *web/key.txt*.
- Done, now just start the web server using `python3 api.py`, or for a long-term solution find how to use Flask in your preferred web server (apache2 / nginx).

## Usage

Simply run the console command `demorec [SteamID64] [length(seconds)]` to request a demo. The server console can also request a demo, allowing to automate their recording while no admin is present.
