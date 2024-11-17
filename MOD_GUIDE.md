Guide to making mods
====================

This document describes information that is helpful for making mods 
for Wyvern Gate. This document is largely dedicated to going over 
Wyvern Gate's building blocks and architecture to help modders 
better understand what they have to do to get their idea 
working.


About the code 
--------------

Because Wyvern Gate is purely text, most of making a mod will 
just be code. Wyvern Gate is written in a language I developed, Matte,
which behaves similarly to Lua and Javascript with some simplifications and extensions.

[Here is a rundown on language concepts](https://jcorks.github.io/matte/doc-quick.html).
It is C-like and follows many common programming conventions, so basic operation 
should be possible without too much research if youre already familiar with programming.
Either way, I highly recommend looking at the mod examples provided and seeing how code is 
managed there. Simple mods should still be possible with relatively little coding experience 
if the templates are followed in the mod examples.

Wyvern Gate is also equipped with debugging tools. All versions of the game are capable 
to give backtraces when an uncaught error is thrown, and the command line and OpenGL 
versions are equipped with a step-wise debugger, allowing for breakpoints and in-scope 
variable printing.

To utilize debugging, the command line version of the program is recommended, which 
is provided here. By default, breakpoints are ignored. To activate breakpoints and 
the debugger in the command line version of the game, pass in the `--debug` argument 
when running.

Adding breakpoints is done by calling the function `breakpoint()`, which is automatically 
understood in the language. If debugging is inactive, the `breakpoint()` function is ignored.

Major concepts / Architecture
=============================

1. Windowing
------------

Wyvern Gate is a completely text-based game. It renders all characters 
to a canvas (see game_singleton.canvas.mt for the lower-level implementation), which 
is a simple collection of lines of text before delivering it to the 
host environment, whether thats a terminal, a webpage renderer, or 
an OpenGL text renderer.


While the canvas handles that at the lower level, actual operations in the 
game are done with the windowEvent singleton (see game_singleton.windowevent.mt).
windowEvent provides the basic mechanism to introduce windowed visuals that 
react to user input. windowEvent will cover most of your interaction and display needs. When desired,
windowEvent windows allow for custom graphics, which is when the lower-level 
canvas is used.


windowEvents are used for all interactive structures in the game. This includes 
when roaming around towns or the island your on. When you do roam around, what youre 
seeing is a rendered visual while in a menu being provided from a Map.


windowEvent is primarily asynchronous and provides 3 basic mechanisms: a queueing 
architecture, an event system (responding to entering and leaving windows), and an active window stack.

Every time you use windowEvent to make a window, you are actually placing a request to spawn 
a window when it is that windows turn to appear. Once a window appears, most windows will react 
to user input to decide whether to display alternate graphics, close the window to provide 
the next window, or to layer a new window on top of it. 

When using windowEvent, there are common window types that you queue:

- `windowEvent.queueMessage()` can queue a message for display. This is the most elementary window 
  and will simply display the text with a speaker or prompt on the top left of the window.
  If the text is too large to fit on the window, it will automatically enter a paging mode 
  to allow a user to see its entirety.
  
- `windowEvent.queueAskBoolean()` can queue a yes / no style question and allow a callback 
  in response. The callback will often queue requests for additional windows.
  
- `windowEvent.queueChoices()` can queue a window that allows a user to choose among a scrollable 
  list of choices. Like queueAskBoolean(), the response function will often queue additional window requests

- `windowEvent.queueNoDisplay()` is a special window that doesnt, by default, do anything. It is meant to be 
  a way to provide custom windowing features and even things such as animations. queueNoDisplay provides an empty 
  window that can, optionally, immediately go to the next window. This can be convenient to introduce callbacks 
  that happen in order after certain windows.
  
Most window types accept the following arguments:

- `topWeight / leftWeight`: from 0 to 1, defines where the window should be placed on the screen.

- `renderable`: provides an object with a render() function, which can use the canvas singleton to draw 
  directly on the canvas and have that visual saved to the screen for that queued window.

- `keep`: defines whether to keep this window. This means that after additional windows are made and 
  left, this window will come back. This can form a hierarchy of active windows, which is most common 
  when working in menus. Kept windows will still have their graphics shown at the time input was received.

- `canCancel`: defines whether a user can "back out" of a window. Important at times.

- `jumpTag`: when using a kept window, jump tags are used to back out of windows until a specific window is reached.
  this is handy for more complex window setups. `windowEvent.jumpToTag()` and `window.canJumpToTag()` use 
  the jump tags to accomplish this.
  

The flexibility of windowEvent, queue + layering system, and the 
possibility for custom graphics make windowEvent very powerful; however, 
the asynchronous nature of windowEvent can make some bugs hard to fix. You can follow 
mod examples or in-game code to see how problems with this were dealt with, but know that 
complex setups will be harder to debug. Try to keep your windowing systems as simple as possible.


2. Maps and the information tree
--------------------------------


Maps (game_class.map.mt) are the classes the provide the backbone of the movement mechanics, allowing for 
tile-based character graphics, movement and storage of elements in a grid structure,
dynamic changing of viewing within this grid, and even wall-sensitive path finding. 
Any time a player is able to move, it is displayed on a map.


Because maps are used ubiquitously throughout the program for the dungeon crawling aspect,
walking around in towns, and other times, multiple Map instances will exist throughout the program.
The combined usage of Map and windowEvent naturally lead toward a tree-based hierarchy of information
within the game. This structure of the major active game components is as follows:

`(instance) -> (world) -> (island + map) -> (landmark + map) -> location`

In this tree structure, the following rules hold true.
- A world (game_singleton.world.mt) can hold information for multiple islands. Only one island is "active" at a time, and there exists only one world in the game at a time.
- An island (game_class.island.mt) has its own map that is displayed when relevant. It can hold many landmarks, and each landmark is displayed as a tile on the island's map.
- A landmark (game_mutator.landmark.mt has its own map this is displayed when relevant. It can hold many locations, and each location is displayed as a tile on the landmark's map.
- A location (game_mutator.landmark.mt)

In this tree structure, islands, landmarks, and locations are able to reference their 
parent. instance and world do not need such structures, as worlds and instances are singletons, and only one exists at a time.


3. Databases
------------

Throughout the game, many things require repetitive structures because many different instances of them exist.
These are controlled by Databases. Many database instances are used throughout the program. Each file containing 
a database is prefixed with `game_database.` so databases are clearly visible.

When created, Databases contain a name and a set of typed traits that database entries must follow.
Consider this database from game_database.material.mt:

```
@:Material = Database.new(
    name : 'Wyvern.Material',
    traits : {
        name : String,
        rarity : Number,
        tier : Number,
        description : String,
        statMod : StatSet.type, // percentages
        pricePercentMod : Number
    },
    reset            
);
```


In this database, entries can have a name, rarity, tier, description, stats, and a price modifier. Each 
traits is checked against the type that is labeled, so if a new material is defined and the rarity is 
not set, or is set to be something other than a Number, an error is thrown.

Here is an example database entry:

```
Material.newEntry(
    data : {
        name : 'Iron',
        description : 'The iron used gives it a solid grey color.',
        rarity : 13,
        tier : 0,
        statMod : StatSet.new(
            DEF: 10,
            ATK: 20,
            SPD: -5
        ),
        pricePercentMod: 35
    }
)
```

The data argument is populated with the static data that the database entry will have. Database entries are 
intended to be "static" in that their contents will not change. Database entries, however, can be removed 
and added to as needed.


**NOTE:** take caution when adding and removing database entries, as saving / loading are sensitive to 
them. If loading a save with an unknown database entry, this will throw an error, as the game 
will not know what to do with it. As such, mods are encouraged to use the databaseMutator function to safely 
add and remove database entries in the game, as the game does this before loading a save and before starting a new 
scenario.


In addition to databases, there are instances that extend databases. Often, it is useful to utilize the static and 
repetitive information access that Databases provide, but with certain mutations from this base item. These exist 
in Wyvern Gate as "Mutators". 


Mutators always have a "base" Database item associated with it, along with some custom data that is intended 
to change per-instance on its own. One example of this is an Item (game_mutator.item.mt) which has a base 
and additional data.

Consider a common example of an item: A `Durable Iron Shortsword`. For this item, it contains the Database Item 
entry for Shortswords, but extends this by adding the material "Iron" and the itemquality "Durable". In this sense 
the Item inherits the properties of the Database Entry, but contains its own differences that extend it.

4. Scenarios
------------

Scenarios are the decided way that a player plays the game. The scenario defines:
- The conditions for completing the game. It is responsible for triggering the end game result.
- The accolades (achievements) for when the game is complete.
- Per-scenario menu interactions at different levels of the game.
- Upkeep-related functions at certain parts of the game, such as when a day is ended, or when a party member experiences a death.
- A dedicated function for overriding database entries. This one is distinct from the mod-provided one.

Scenarios are important to understand because some mods may provide a scenario as a specific game mode alternative 
to the base scenarios provided. This is in contrast to mods that provide content (usually through database entries)
that can affect all scenarios, even the base ones.


5. State
--------

When saving and loading data, the program has designated what content gets stored naturally through its construction
using State (game_class.state.mt) instances. Usually states are not made directly, but are part of LoadableClasses, which 
(game_singleton.loadableclass.mt) use States to define exactly what data gets saved and where. Loadable classes 
also allow for default or custom save / load behavior.


LoadableClasses follow a tree hierarchy, where, if a LoadableClass is part of the State of something,
it will also dump its state as a child when saving. This conveniently provides an automatic saving and loading 
feature. All Mutators are LoadableClasses, so you can follow any mutator to get a feel for LoadableClass.

The key features are 
- The inclusion of a `state` when defining a class. This is the State belonging to the instance.
- The existence of a `load()`, `save()`, and `defaultLoad()` member function. `load()` is the function 
  that reads the state from a JSON-parsed object. `save()` returns the state as an Object to then, eventually, 
  be dumped into a JSON string. `defaultLoad()` provides behavior to do when first creating an instance that 
  does not come directly from a JSON-parsed object, so its only called when `load()` is never called.

States may take some getting used to, so definitely refer to mod examples and the existing game code to 
get a feel for how they work.


6. Additional concept reference 
-------------------------------

These are small notes that might help you understand some aspects better:

- Tiers (part of island) are referenced throughout the code. Tiers are meant to be a way to introduce progression 
  into the game. Every game starts at tier 0, and as a play progresses, the tier should increase at major points.
  Tiers primarily are used in the default scenarios for items, dungeon layouts, and dangerousness of encounters. For built in 
  things such as chests and shopkeeps, they will be sensitive to the tier upon creation.

- Entities (game_class.entity.mt) are the individuals of the world. They are typically associated with a location 
  which they may own, or they may be freely created and destroyed, such as normal encounters. Entities follow the same 
  rules for player characters and world characters. Even the Wyverns are entities. Look at the file for the 
  aspects of entities 
  
- The party instance governs what the party has access to, mainly its members and the inventory. Its a class 
  (game_class.party.mt), but the world instance contains the single party instance for the entire game.
  

  
