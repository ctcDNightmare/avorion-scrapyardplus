# ScrapyardPlus

___
Your salvaging ops are longer then 60 minutes?  
You want to get something in return for grinding all the precious reputation?  

With ScrapyardPlus you can:
* buy up to 8 hours total (depending on your reputation)
* increment your current license in variable intervals from 5 minutes all the way up to 3 hours per order
* get discounts for bulk orders and your current standing with the owner of the scrapyard

## Installation
1. download & extract the [mod](https://github.com/ctcDNightmare/avorion-scrapyardplus/releases) into your Avorion folder

2. insert the following code:  
```Lua
if not pcall(require, "mods/ScrapyardPlus/scripts/entity/merchants/scrapyard") then print("Failed to load ScrapyardPlus") end -- DNightmare/ScrapyardPlus
```  
at the end of the original scrapyard file:  
``data/scripts/entity/merchants/scrapyard.lua``  
**(in case you are using the MoveUI-Mod as well, insert it above that!)**
 
3. done

## Screenshots
*Solo player with good reputation*
![Lone wolf with good relations](https://i.imgur.com/hp9nsGU.jpg)  

*Alliance player with normal reputation*  
![Alliance player with normal relations](https://i.imgur.com/KU8JH3A.jpg)

## Roadmap
- ~~extend your current license instead of overwriting it~~
- ~~longer maximum duration for your license~~
- ~~reputation based benefits (max duration and discount)~~
- ~~split the license system into private & alliance so you can buy a personal one even if you are in an alliance~~
- ~~flexible duration selection via slider~~
- lifetime license

## Feedback & Discussion
http://www.avorion.net/forum/index.php/topic,3850.0.html

## Mentions & shoutouts
- [Dirtyredz](https://github.com/dirtyredz) - He got me into modding for Avorion with his [MoveUI-Mod](http://www.avorion.net/forum/index.php/topic,3834.0.html) and now we are even working together on each others mods to further improve our knowledge