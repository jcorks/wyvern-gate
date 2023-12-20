@:class = import(module:'Matte.Core.Class');
@:random = import(module:'game_singleton.random.mt');
@:distance = import(module:'game_function.distance.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Species = import(module:'game_class.species.mt');
@:Profession = import(module:'game_class.profession.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:Battle = import(module:'game_class.battle.mt');

@:ROOM_SPECTER_COUNT = 3;
@:ItemSpecter = class(
    define::(this) {
        @:Entity = import(module:'game_class.entity.mt');
        @:Location = import(module:'game_class.location.mt');

        @map_;
        @island_;
        @landmark_;
        @addedSpecters = false;
        
        
        @:addSpecter ::{
            @:windowEvent = import(module:'game_singleton.windowevent.mt');
            @ar = map_.getRandomArea();;
            @:tileX = ar.x + (ar.width /2)->floor;
            @:tileY = ar.y + (ar.height/2)->floor;
            
            // only add an entity when not visible. Makes it 
            // feel more alive and unknown
            when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
            



            @:specter = island_.newInhabitant();
            specter.name = 'the Wyvern Specter';
            specter.species = Species.database.find(name:'Wyvern Specter');
            specter.profession = Profession.new(base:Profession.Base.database.find(name:'Wyvern Specter'));               
            specter.clearAbilities();
            foreach(specter.profession.gainSP(amount:10))::(i, ability) {
                specter.learnAbility(name:ability);
            }

            specter.stats.load(serialized:StatSet.new(
                HP:   120,
                AP:   999,
                ATK:  25,
                INT:  30,
                DEF:  3,
                LUK:  6,
                SPD:  100,
                DEX:  100
            ).save());
            
            specter.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
            specter.heal(amount:9999, silent:true); 
            specter.healAP(amount:9999, silent:true);     




            @ent = landmark_.mapEntityController.add(
                x:tileX,
                y:tileY,
                symbol: 'x',
                entities : [specter],
                tag : 'specter'
            );
            ent.addUpkeepTask(name:'specter');
            
            @ent = {
                targetX:tileX, 
                targetY:tileY
            }
            if (addedSpecters == false)
                windowEvent.queueMessage(
                    text:random.pickArrayItem(list:[
                        'Something\'s off... It\'s not safe here.',
                        'Do you feel that? Something... different... is here.',
                    ])
                );
            addedSpecters = true;
                
        }        


        this.interface = {
            initialize::(landmark) {
                map_ = landmark.map;
                island_ = landmark.island;
                landmark_ = landmark;
                return this;
            },
            
            step::{ 
                @:specters = landmark_.mapEntityController.mapEntities->filter(by::(value) <- value.tag == 'specter');
                
                // the specters have been appeased. They leave now
                when(addedSpecters == true && specters->size == 0) empty;
                when(landmark_.floor < 1 || (landmark_.floor%3 != 0)) empty;

            
                if (specters->size < ROOM_SPECTER_COUNT)
                    addSpecter();
            
            }
        }        
    }   
);

return ItemSpecter;
