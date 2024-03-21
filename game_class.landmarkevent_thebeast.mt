@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');
@:Species = import(module:'game_database.species.mt');
@:Profession = import(module:'game_mutator.profession.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


@:TheBeast = LoadableClass.create(
    name: 'Wyvern.LandmarkEvent.TheBeast',
    
    statics : {
        createEntity ::{
            @:Entity = import(module:'game_class.entity.mt');
            @world = import(module:'game_singleton.world.mt');
            @:beast = world.island.newInhabitant();
            beast.name = 'the Dungeon Beast';
            beast.species = Species.find(id:'base:beast');
            beast.profession = Profession.new(base:Profession.database.find(id:'base:beast'));               
            beast.clearAbilities();
            foreach(beast.profession.gainSP(amount:10))::(i, ability) {
                beast.learnAbility(name:ability);
            }

            beast.stats.load(serialized:StatSet.new(
                HP:   75,
                AP:   999,
                ATK:  14,
                INT:  30,
                DEF:  3,
                LUK:  6,
                SPD:  100,
                DEX:  10
            ).save());
            
            beast.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
            beast.heal(amount:9999, silent:true); 
            beast.healAP(amount:9999, silent:true);   
            return beast;        
        }
    },
    
    items : {
        encountersOnFloor : 0,
        hasBeast : false
    },

    define:::(this, state) {
        @map_;
        @island_;
        @landmark_;

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
            

            @beast = TheBeast.createEntity();

            
            // who knows whos down here. Can be anything and anyone, regardless of 
            // the inhabitants of the island.
            @ents = [beast]
   
            state.encountersOnFloor += 1;

            @:ref = landmark_.mapEntityController.add(
                x:tileX, 
                y:tileY, 
                symbol:'B',
                entities : ents,
                tag : 'thebeast'
            );
            ref.addUpkeepTask(id:'base:thebeast-roam');
            ref.addUpkeepTask(id:'base:aggressive');

            if (state.encountersOnFloor == 1)
                windowEvent.queueMessage(
                    text:random.pickArrayItem(list:[
                        'That was definitely a roar or snarl just now. Something\'s near.',
                        'Something heavy is stomping nearby.',
                    ])
                );            

        }
        

    
        this.interface = {
            initialize::(parent) {
                @landmark = parent.landmark;

                map_ = landmark.map;
                island_ = landmark.island;
                landmark_ = landmark;
            },
            
            defaultLoad ::{
                state.hasBeast = if (landmark_.floor > 1 && random.try(percentSuccess:15))
                    true
                else 
                    false
                ;
            
            },
            
            
            
            step::{
                @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'thebeast');
            
                // add additional entities out of spawn points (stairs)
                //if ((entities->keycount < (if (landmark_.floor == 0) 0 else (2+(landmark_.floor/4)->ceil))) && landmark_.base.peaceful == false && Number.random() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1)) ::<= {
                if (entities->keycount < 1 && state.hasBeast) ::<= {
                    addEntity();
                    state.hasBeast = false;
                }
            }
        }
    }
);
return TheBeast;
