@:Database = import(module:'game_class.database.mt');
@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@Landmark = import(module:'game_mutator.landmark.mt');
@:Item = import(module:'game_mutator.item.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:Scene = import(module:'game_database.scene.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Battle = import(module:'game_class.battle.mt');

@:traps = [
    // fall down to next floor
    // next floor is NEVER a lost shrine floor
    ::(location, party, whom) {
        if (location.targetLandmark == empty) ::<={
   
            @:Landmark = import(module:'game_mutator.landmark.mt');
            
            location.targetLandmark = 
                location.landmark.island.newLandmark(
                    base:Landmark.database.find(name:location.landmark.base.name),
                    floorHint:location.landmark.floor+1
                )
            ;
            
            location.targetLandmark.name = 'Shrine ('+location.targetLandmark.floor+'F)';
        }

        canvas.clear();
        windowEvent.queueMessage(text:'The party falls through a trap door to the next floor.', renderable:{render::{canvas.blackout();}});

        @:hurt = random.pickArrayItem(list:party.members);
        @:oldStats = StatSet.new();
        oldStats.load(serialized:hurt.stats.save());
        (random.pickArrayItem(list: [
            :: {
                windowEvent.queueMessage(text: hurt.name + ' hurt their head from the fall...', renderable:{render::{canvas.blackout();}});
                hurt.stats.add(stats:StatSet.new(INT:-2));
            },

            :: {
                windowEvent.queueMessage(text: hurt.name + ' injured their legs from the fall...', renderable:{render::{canvas.blackout();}});
                hurt.stats.add(stats:StatSet.new(SPD:-2));
            },

            :: {
                windowEvent.queueMessage(text: hurt.name + ' injured their arms from the fall...', renderable:{render::{canvas.blackout();}});
                hurt.stats.add(stats:StatSet.new(ATK:-2));
            },

            :: {
                windowEvent.queueMessage(text: hurt.name + ' injured their hands from the fall...', renderable:{render::{canvas.blackout();}});
                hurt.stats.add(stats:StatSet.new(DEX:-2));
            }
        
        ]
        ))();
        
        oldStats.printDiff(other:hurt.stats, prompt:'Ouch...', renderable:{render::{canvas.blackout();}});
        @:instance = import(module:'game_singleton.instance.mt');
        
        instance.visitLandmark(landmark:location.targetLandmark);
    },
    
    // basic damage trap
    ::(location, party, whom) {
        windowEvent.queueMessage(text:'A volley of arrows springs form the plate.'); 
        if (Number.random() < 0.5) ::<= {
            windowEvent.queueMessage(text:whom.name + ' narrowly dodges the trap.');                         
        } else ::<= {
            whom.damage(
                from: whom,
                damage: Damage.new(
                    amount:whom.stats.HP * (0.5),
                    damageType : Damage.TYPE.PHYS,
                    damageClass: Damage.CLASS.HP
                ),
                dodgeable: false
            );
        }
    },
    
    
    // teleport to a random area
    ::(location, party, whom) {
        @:landmark = location.landmark;
        landmark.movePointerToRandomArea();
        windowEvent.queueMessage(text:'The party is teleported to another area of the floor.', renderable:{render::{canvas.blackout();}}); 
        
    },    

    // ambush
    ::(location, party, whom) {
        @:landmark = location.landmark;


        windowEvent.queueMessage(
            text: random.pickArrayItem(list:[
                '"You fell for our trap!"',  
                '"We didn\'t think that would work! Get them!"',  
                '"Finally, someone fell for our trap!"',              
            ])
        );



        @:enemies = [
            landmark.island.newAggressor(),
            landmark.island.newAggressor(),
            landmark.island.newAggressor()                        
        ]
        
        foreach(enemies)::(index, e) {
            e.anonymize();
        }
        @:world = import(module:'game_singleton.world.mt');        
        world.battle.start(
            party,
            
            allies: party.members,
            enemies,
            landmark: {},
            onEnd::(result){
                if (!world.battle.partyWon())::<= {
                    windowEvent.jumpToTag(name:'MainMenu', clearResolve:true);
                }            
            }
        );
            

        
    },    
    
    
    // creature nest. probably the deadliest
    ::(location, party, whom) {

        windowEvent.queueMessage(
            text: 'The rest of the party suddenly got caught in a web of some kind!'
        );

        windowEvent.queueMessage(
            text: 'Creatures approach ' + whom.name + '!!'
        );


        @:enemies = [
            location.landmark.island.newHostileCreature(),
            location.landmark.island.newHostileCreature(),
            location.landmark.island.newHostileCreature()                        
        ]
        
        
        @:world = import(module:'game_singleton.world.mt');
        world.battle.start(
            party,
            
            allies: [whom],
            enemies,
            landmark: {},
            onEnd::(result){
                @all = true;      
                foreach(party.members) ::(k, member) {
                    if (!member.isIncapacitated())
                        all = false
                }
                
                if (all)
                    windowEvent.jumpToTag(name:'MainMenu', clearResolve:true)
                else
                    windowEvent.queueMessage(
                        text: 'The rest of the party got free from the web.'
                    );
            }
        );

    
    }


]



return ::(location, party, whom) {
    //traps[3](location, party, whom);
    random.pickArrayItem(list:traps)(location, party, whom);
}
