![](https://img.shields.io/github/downloads/git-kinetix/kinetix-fivem/total?logo=github&link=https%3A%2F%2Fgithub.com%2Fgit-kinetix%2Fkinetix-fivem%2Freleases)
![](https://img.shields.io/github/downloads/git-kinetix/kinetix-fivem/total?logo=github&link=https%3A%2F%2Fgithub.com%2Fgit-kinetix%2Fkinetix-fivem%2Freleases%2Flatest)
![](https://img.shields.io/github/v/release/git-kinetix/kinetix-fivem?logo=github)

  # kinetix-fivem

A FiveM resource integrating user generated emotes in game through to the Kinetix powerful ML motion capture system.

> [!WARNING]  
> This is still an early version that is not bug free.

> [!CAUTION]  
> Kinetix emotes creation is a paid service.


### Prerequisite

This mod requires : 
- [ox_lib](https://github.com/overextended/ox_lib)
- [fivem_webbed](https://github.com/overextended/ox_lib)

### Installation

Download the [latest release](https://github.com/git-kinetix/kinetix-fivem/releases/latest).

Extract the zip file into your server's resource folder.

### Configuration

- Create an account on Kinetix's [Developer Portal](https://portal.kinetix.tech).

- Select "Get our SDK"
  - In the webhook field, set your server's public IP / Domain name with '/kinetix_mod/webhook/updates' (eg. https://my-server.com/kinetix_mod/webhook/updates)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![](game_creation.png)

- Enable the GTA V pipeline in your app settings

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![](settings.png)

- Create an API Key

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;![](key_creation.png)

- Set this API Key in kinetix_mod/server/core.lua

- Add these ACE rules in your server config
  ```
  add_ace resource.kinetix_mod command.restart allow
  add_ace resource.kinetix_mod command.start allow
  add_ace resource.kinetix_mod command.stop allow
  add_ace resource.kinetix_mod command.refresh allow
  ```

- Restart the server

### Usage

The default key to open the animation creation menu is `F5`. This can be changed in kinetix_mod/client/core.lua

The default key to open the emote wheel is `Z`, the default ox_lib's radial menu shortcut. 