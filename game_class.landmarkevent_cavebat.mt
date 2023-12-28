@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');
@:Species = import(module:'game_class.species.mt');
@:Profession = import(module:'game_class.profession.mt');
@:StatSet = import(module:'game_class.statset.mt');

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
        @:Location = import(module:'game_class.location.mt');

    
    
        @:addEntity ::{
            @:windowEvent = import(module:'game_singleton.windowevent.mt');

            @ar = map_.getRandomArea();;
            @:tileX = ar.x + (ar.width /2)->floor;
            @:tileY = ar.y + (ar.height/2)->floor;
            
            // only add an entity when not visible. Makes it 
            // feel more alive and unknown
            when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
            


            @:beast = island_.newInhabitant();
            beast.name = 'Cave Bat';
            beast.species = Species.database.find(name:'Cave Bat');
            beast.profession = Profession.new(base:Profession.Base.database.find(name:'Cave Bat'));               
            beast.clearAbilities();
            foreach(beast.profession.gainSP(amount:10))::(i, ability) {
                beast.learnAbility(name:ability);
            }

            beast.stats.load(serialized:StatSet.new(
                HP:   7,
                AP:   15,
                ATK:  6,
                INT:  5,
                DEF:  3,
                LUK:  6,
                SPD:  10,
                DEX:  5
            ).save());
            
            beast.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
            beast.heal(amount:9999, silent:true); 
            beast.healAP(amount:9999, silent:true);     

            
            // who knows whos down here. Can be anything and anyone, regardless of 
            // the inhabitants of the island.
            @ents = [beast]
   
            encountersOnFloor += 1;

            @:ref = landmark_.mapEntityController.add(
                x:tileX, 
                y:tileY, 
                symbol:'B',
                entities : ents,
                tag : 'cavebat'
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

                return this;
            },
            
            step::{
                @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'cavebat');
            
                // add additional entities out of spawn points (stairs)
                //if ((entities->keycount < (if (landmark_.floor == 0) 0 else (2+(landmark_.floor/4)->ceil))) && landmark_.base.peaceful == false && Number.random() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1)) ::<= {
                if (hasBeast && entities->keycount < 7 && encountersOnFloor < 20) ::<= {
                    addEntity();
                }
            }
        }
    }
);
return TheBeast;
