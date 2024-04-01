@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Species = import(module:'game_database.species.mt');
@:Profession = import(module:'game_mutator.profession.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:Battle = import(module:'game_class.battle.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:Item = import(module:'game_mutator.item.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');

@:ROOM_SPECTER_COUNT = 3;


@:addSpecter ::(map, landmark, island, state) {
    @:Entity = import(module:'game_class.entity.mt');
    @:Location = import(module:'game_mutator.location.mt');


    @:windowEvent = import(module:'game_singleton.windowevent.mt');
    @ar = map.getRandomArea();;
    @:tileX = ar.x + (ar.width /2)->floor;
    @:tileY = ar.y + (ar.height/2)->floor;
    
    // only add an entity when not visible. Makes it 
    // feel more alive and unknown
    when (map.isLocationVisible(x:tileX, y:tileY)) empty;
    



    @:specter = ItemSpecter.createEntity();



    @ent = landmark.mapEntityController.add(
        x:tileX,
        y:tileY,
        symbol: 'x',
        entities : [specter],
        tag : 'specter'
    );
    ent.addUpkeepTask(id:'base:specter');
    
    @ent = {
        targetX:tileX, 
        targetY:tileY
    }
    if (state.addedSpecters == false)
        windowEvent.queueMessage(
            text:random.pickArrayItem(list:[
                'Something\'s off... It\'s not safe here.',
                'Do you feel that? Something... different... is here.',
            ])
        );
    state.addedSpecters = true;
        
}        





@:ItemSpecter = LoadableClass.create(
    name : 'Wyvern.LandmarkEvent.ItemSpecter',
    items : {
        addedSpecters : false
    },
    
    statics : {
        createEntity ::{
            @:Entity = import(module:'game_class.entity.mt');
            @world = import(module:'game_singleton.world.mt');


            @:specter = world.island.newInhabitant();
            specter.name = 'the Wyvern Specter';
            specter.species = Species.find(id:'base:wyvern-specter');
            specter.profession = Profession.new(base:Profession.database.find(id:'base:wyvern-specter'));               

            @:inv = Inventory.new();
            inv.add(item:Item.new(base:Item.database.find(id:'base:life-crystal'
            )));            
            specter.forceDrop = inv;
            
            specter.clearAbilities();
            foreach(specter.profession.gainSP(amount:10))::(i, ability) {
                specter.learnAbility(id:ability);
            }

            specter.stats.load(serialized:StatSet.new(
                HP:   120,
                AP:   999,
                ATK:  25,
                INT:  30,
                DEF:  3,
                LUK:  6,
                SPD:  100,
                DEX:  10
            ).save());
            
            specter.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
            specter.heal(amount:9999, silent:true); 
            specter.healAP(amount:9999, silent:true);     
            return specter;
        }
    },
        


    interface : {
        initialize::(parent) {
            @landmark = parent.landmark;
            _.map = landmark.map;
            _.island = landmark.island;
            _.landmark = landmark;
        },
        
        defaultLoad ::{
            _.state.addedSpecters = false;
        },
        
        step::{ 
            @:state = _.state;
            @:specters = _.landmark.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'specter');
            
            // the specters have been appeased. They leave now
            when(state.addedSpecters == true && specters->size == 0) empty;
            when(_landmark.floor < 1 || (_landmark.floor%3 != 0)) empty;

        
            if (specters->size < ROOM_SPECTER_COUNT)
                addSpecter(
                    map: _.map,
                    island: _.island,
                    landmark: _.landmark,
                    state
                );
        
        }
    }   
);

return ItemSpecter;
