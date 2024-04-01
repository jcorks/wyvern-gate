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



    
@:addEntity ::(map, island, landmark, state) {
    @:windowEvent = import(module:'game_singleton.windowevent.mt');

    @ar = map.getRandomArea();;
    @:tileX = ar.x + (ar.width /2)->floor;
    @:tileY = ar.y + (ar.height/2)->floor;
    
    // only add an entity when not visible. Makes it 
    // feel more alive and unknown
    when (map.isLocationVisible(x:tileX, y:tileY)) empty;
    

    @beast = TheBeast.createEntity();

    
    // who knows whos down here. Can be anything and anyone, regardless of 
    // the inhabitants of the island.
    @ents = [beast]

    state.encountersOnFloor += 1;

    @:ref = landmark.mapEntityController.add(
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
                beast.learnAbility(id:ability);
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

    interface : {
        initialize::(parent) {
            @landmark = parent.landmark;

            _.map = landmark.map;
            _.island = landmark.island;
            _.landmark = landmark;
        },
            
        defaultLoad ::{
            _.state.hasBeast = if (_.landmark.floor > 1 && random.try(percentSuccess:15))
                true
            else 
                false
            ;
        
        },
            
            
            
        step::{
            @:state = _.state;
            @:entities = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'thebeast');
        
            // add additional entities out of spawn points (stairs)
            //if ((entities->keycount < (if (landmark_.floor == 0) 0 else (2+(landmark_.floor/4)->ceil))) && landmark_.base.peaceful == false && Number.random() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1)) ::<= {
            if (entities->keycount < 1 && state.hasBeast) ::<= {
                addEntity(
                    landmark: _.landmark,
                    island: _.island,
                    map : _.map,
                    state
                );
                state.hasBeast = false;
            }
        }
    }
);
return TheBeast;
