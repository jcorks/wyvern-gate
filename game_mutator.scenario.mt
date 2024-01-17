/*
    Wyvern Gate, a procedural, console-based RPG
    Copyright (C) 2023, Johnathan Corkery (jcorkery@umich.edu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'game_class.database.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Item = import(module:'game_mutator.item.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:namegen = import(module:'game_singleton.namegen.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:databaseItemMutatorClass = import(module:'game_function.databaseitemmutatorclass.mt');


@:Scenario = databaseItemMutatorClass(
    name: 'Wyvern.Scenario',
    items : {
        data : empty
    },
    database : 
        Database.new(
            name : 'Wyvern.Scenario.Base',
            attributes : {
                name : String,
                // the function to start off the scenario
                begin : Function,
                // provides the options one has when interacting with a person.
                // This is decided by the scenario
                personInteractions : Object
            }
        ),
    define::(this, state) {
        this.interface = {
            defaultLoad ::{
                state.data = {};
            }
        }
    }
);






Scenario.database.newEntry(
    data : {
        name : 'The Chosen',
        begin :: {
            @:instance = import(module:'game_singleton.instance.mt');
            @:story = import(module:'game_singleton.story.mt');
            @world = import(module:'game_singleton.world.mt');
            @:LargeMap = import(module:'game_singleton.largemap.mt');
            @party = world.party;            
        
                //story.tier = 2;
            @:keyhome = Item.new(
                base: Item.database.find(name:'Wyvern Key'),
                creationHint: {
                    nameHint:namegen.island(), levelHint:story.levelHint
                }
            );
            keyhome.name = 'Wyvern Key: Home';
            
            
                
            keyhome.addIslandEntry(world);
            world.island = keyhome.islandEntry;
            @:island = world.island;
            party = world.party;
            party.reset();



            
            // debug
                //party.inventory.addGold(amount:100000);

            
            // since both the party members are from this island, 
            // they will already know all its locations
            foreach(island.landmarks)::(index, landmark) {
                landmark.discover(); 
            }
            
            
            
            @:Species = import(module:'game_database.species.mt');
            @:p0 = island.newInhabitant(speciesHint: island.species[0], levelHint:story.levelHint);
            @:p1 = island.newInhabitant(speciesHint: island.species[1], levelHint:story.levelHint-2);
            // theyre just normal people so theyll have some trouble against 
            // professionals.
            p0.normalizeStats();
            p1.normalizeStats();

            party.inventory.add(item:Item.new(
                base:Item.database.find(name:'Sentimental Box'),
                from:p0
            ));



            // debug
                /*
                //party.inventory.add(item:Item.database.find(name:'Pickaxe'
                //).new(from:island.newInhabitant(),rngEnchantHint:true));
                
                @:story = import(module:'game_singleton.story.mt');
                story.foundFireKey = true;
                story.foundIceKey = true;
                story.foundThunderKey = true;
                story.foundLightKey = true;
                story.tier = 3;
                
                party.inventory.addGold(amount:20000);
                


                
                party.inventory.add(item:Item.new(base:Item.database.find(name:'Wyvern Key of Ice'
                ), from:island.newInhabitant()));
                party.inventory.add(item:Item.new(base:Item.database.find(name:'Wyvern Key of Thunder'
                ), from:island.newInhabitant()));
                party.inventory.add(item:Item.new(base:Item.database.find(name:'Wyvern Key of Light'
                ), from:island.newInhabitant()));

                @:story = import(module:'game_singleton.story.mt');
                

                

                party.inventory.maxItems = 50
                for(0, 20) ::(i) {
                    party.inventory.add(
                        item:Item.new(
                            base:Item.database.getRandomFiltered(
                                    filter:::(value) <- value.isUnique == false && value.hasQuality
                            ),
                            from:island.newInhabitant(),
                            rngEnchantHint:true
                        )
                    )
                };
                */
                
                


                
                /*
                @:sword = Item.new(
                    base: Item.database.find(name:'Glaive'),
                    from:p0,
                    materialHint: 'Ray',
                    qualityHint: 'Null',
                    rngEnchantHint: false
                );

                @:tome = Item.new(
                    base:Item.database.find(name:'Tome'),
                    from:p0,
                    materialHint: 'Ray',
                    qualityHint: 'Null',
                    rngEnchantHint: false,
                    abilityHint: 'Cure'
                );
                party.inventory.add(item:sword);
                party.inventory.add(item:tome);
                
                */


            party.add(member:p0);
            party.add(member:p1);
            
            
            /*
            windowEvent.queueMessage(
                text: '... As it were, today is the beginning of a new adventure.'
            );


            windowEvent.queueMessage(
                text: '' + party.members[0].name + ' and their faithful companion ' + party.members[1].name + ' have decided to leave their long-time home of ' + island.name + '. Emboldened by countless tales of long lost eras, these 2 set out to discover the vast, mysterious, and treacherous world before them.'
            );

            windowEvent.queueMessage(
                text: 'Their first task is to find a way off their island.\nDue to their distances and dangerous winds, travel between sky islands is only done via the Wyvern Gates, ancient portals of seemingly-eternal magick that connect these islands.'
            );
            
            windowEvent.queueMessage(
                text: party.members[0].name + ' has done the hard part and acquired a key to the Gate.\nAll thats left is to go to it and find where it leads.'
            );
            */





            @somewhere = LargeMap.getAPosition(map:island.map);
            island.map.setPointer(
                x: somewhere.x,
                y: somewhere.y
            );               
            instance.savestate();
            @:Scene = import(module:'game_database.scene.mt');
            Scene.start(name:'scene_intro', onDone::{                    
                instance.visitIsland();
                
                /*island.addEvent(
                    event:Event.database.find(name:'Encounter:Non-peaceful').new(
                        island, party, landmark //, currentTime
                    )
                );*/  
            });        
        },
        
        personInteractions : [
            'hire',
            'barter',
            'aggress'
        ]
    }
)   

return Scenario;

