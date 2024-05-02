@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');
@:Species = import(module:'game_database.species.mt');
@:Profession = import(module:'game_database.profession.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');





@:TheSnakeSiren = LoadableClass.create(
    name: 'Wyvern.LandmarkEvent.TheSnakeSiren',
    items : {
        encountersOnFloor : 0,
        hasBeast : false
    },
    statics : {
        createEntity ::{
            @:Entity = import(module:'game_class.entity.mt');
            @world = import(module:'game_singleton.world.mt');
            @:beast = world.island.newInhabitant();
            beast.name = 'the Snake Siren';
            beast.species = Species.find(id:'base:beast');
            beast.profession = Profession.new(base:Profession.database.find(id:'base:snake-siren'));               
            beast.clearAbilities();
            foreach(beast.profession.gainSP(amount:10))::(i, ability) {
                beast.learnAbility(id:ability);
            }

            beast.stats.load(serialized:StatSet.new(
                HP:   140,
                AP:   999,
                ATK:  14,
                INT:  30,
                DEF:  10,
                LUK:  6,
                SPD:  100,
                DEX:  7
            ).save());
            
            beast.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
            beast.heal(amount:9999, silent:true); 
            beast.healAP(amount:9999, silent:true);
            beast.aiAbilityChance = 75;
            return beast;        
        }
    },

    define:::(this, state) {
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
            

            @beast = TheSnakeSiren.createEntity();
            state.hasBeast = false;

            
            // who knows whos down here. Can be anything and anyone, regardless of 
            // the inhabitants of the island.
            @ents = [beast]
   
            encountersOnFloor += 1;

            @:ref = landmark_.mapEntityController.add(
                x:tileX, 
                y:tileY, 
                symbol:'S',
                entities : ents,
                tag : 'thesnakesiren'
            );
            ref.addUpkeepTask(id:'base:thesnakesiren-roam');
            ref.addUpkeepTask(id:'base:thesnakesiren-song');
            ref.addUpkeepTask(id:'base:aggressive');
            

        }
        

    
        this.interface = {
            initialize::(parent) {
                @landmark = parent.landmark;
                map_ = landmark.map;
                island_ = landmark.island;
                landmark_ = landmark;
            },
            
            defaultLoad ::{
                state.hasBeast = true;            
            },
            
            step::{
                @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'thesnakesiren');
                if (random.try(percentSuccess:30) == true && state.hasBeast) ::<= {
                    addEntity();
                }
            }
        }
    }
);
return TheSnakeSiren;
