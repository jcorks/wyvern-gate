@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');
@:Species = import(module:'game_database.species.mt');
@:Profession = import(module:'game_mutator.profession.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:Item = import(module:'game_mutator.item.mt');

@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


@:TheBeast = class(
    name: 'Wyvern.LandmarkEvent.DungeonEncounters',

    define:::(this) {
        @map_;
        @island_;
        @landmark_;
        @encountersOnFloor = 0;
        @hasBeast = false;

        @:Entity = import(module:'game_class.entity.mt');
        @:Location = import(module:'game_mutator.location.mt');

    
    
        @:addEntity ::{
            @:windowEvent = import(module:'game_singleton.windowevent.mt');

            @ar = map_.getRandomArea();;
            @:tileX = ar.x + (ar.width /2)->floor;
            @:tileY = ar.y + (ar.height/2)->floor;
            
            // only add an entity when not visible. Makes it 
            // feel more alive and unknown
            when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
            

            @:world = import(module:'game_singleton.world.mt');
            @:partyCopy = [];
            
            
            foreach(world.party.members) ::(i, member) {
                @:a = member.save();
                a.stats.SPD -= 1;
                a.name = a.name + ' (clone)';
                partyCopy->push(value:
                    Entity.new(
                        parent:this,
                        state: a
                    )
                )                
            }  
            
            @:inv = Inventory.new();
            inv.add(item:Item.new(base:Item.database.find(name:'Life Crystal'
            ), from:partyCopy[0]));                        
            partyCopy[0].forceDrop = inv;

            
   
            encountersOnFloor += 1;

            @:ref = landmark_.mapEntityController.add(
                x:tileX, 
                y:tileY, 
                symbol:'Ø',
                entities : partyCopy,
                tag : 'themirror'
            );
            ref.addUpkeepTask(name:'thebeast-roam');
            ref.addUpkeepTask(name:'aggressive');
            
        }	
        

    
        this.interface = {
            initialize::(landmark) {
                map_ = landmark.map;
                island_ = landmark.island;
                landmark_ = landmark;	
                hasBeast = if (landmark_.floor > 1 && random.try(percentSuccess:15))
                    true
                else 
                    false
                ;
            	//hasBeast = true;

                return this;
            },
            
            step::{
                @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'themirror');
            
                // add additional entities out of spawn points (stairs)
                //if ((entities->keycount < (if (landmark_.floor == 0) 0 else (2+(landmark_.floor/4)->ceil))) && landmark_.base.peaceful == false && Number.random() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1)) ::<= {
                if (entities->keycount < 1 && hasBeast) ::<= {
                    addEntity();
                    hasBeast = false;
                }
            }
        }
    }
);
return TheBeast;
