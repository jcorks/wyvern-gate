@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');
@:Species = import(module:'game_database.species.mt');
@:Profession = import(module:'game_mutator.profession.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:Item = import(module:'game_mutator.item.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

@:ROOM_MAX_ENTITY = 6;
@:REACHED_DISTANCE = 1.5;
@:AGGRESSIVE_DISTANCE = 5;


    
@:addEntity ::(map, landmark, island, state) {
    @:windowEvent = import(module:'game_singleton.windowevent.mt');

    @ar = map.getRandomArea();;
    @:tileX = ar.x + (ar.width /2)->floor;
    @:tileY = ar.y + (ar.height/2)->floor;
    
    // only add an entity when not visible. Makes it 
    // feel more alive and unknown
    when (map.isLocationVisible(x:tileX, y:tileY)) empty;
    

    @:world = import(module:'game_singleton.world.mt');
    @:partyCopy = [];
    
    
    foreach(world.party.members) ::(i, member) {
        @:a = member.save();
        a.stats.SPD -= 1;
        a.name = a.name + ' (clone)';

        @:ent = Entity.new(
            parent:this,
            state: a
        );
        
        ent.heal(amount:ent.stats.HP, silent:true);


        partyCopy->push(value:ent)                
    }  
    
    @:inv = Inventory.new();
    inv.add(item:Item.new(base:Item.database.find(id:'base:life-crystal'
    )));                        
    partyCopy[0].forceDrop = inv;

    

    state.encountersOnFloor += 1;

    @:ref = landmark.mapEntityController.add(
        x:tileX, 
        y:tileY, 
        symbol:'Ø',
        entities : partyCopy,
        tag : 'themirror'
    );
    ref.addUpkeepTask(id:'base:thebeast-roam');
    ref.addUpkeepTask(id:'base:aggressive');
    
}	




@:TheBeast = LoadableClass.create(
    name: 'Wyvern.LandmarkEvent.DungeonEncounters',
    items : {
        hasBeast : false,
        encountersOnFloor : 0
    },  
    interface : {
        initialize::(parent) {
            @landmark = parent.landmark;
            _.map = landmark.map;
            _.island = landmark.island;
            _.landmark = landmark;
        },
        
        defaultLoad :: {
            state.hasBeast = if (_.landmark.floor > 1 && random.try(percentSuccess:15))
                true
            else 
                false
            ;
        },
        
        step::{
            @:state = _.state;
            @:entities = _.landmark.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'themirror');
        
            // add additional entities out of spawn points (stairs)
            //if ((entities->keycount < (if (landmark_.floor == 0) 0 else (2+(landmark_.floor/4)->ceil))) && landmark_.base.peaceful == false && Number.random() < 0.1 / (encountersOnFloor*(10 / (island_.tier+1))+1)) ::<= {
            if (entities->keycount < 1 && state.hasBeast) ::<= {
                addEntity(
                    landmark: _.landmark,
                    island: _.island,
                    map: _.map,
                    state
                );
                state.hasBeast = false;
            }
        }
    }
);
return TheBeast;
