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

        @specters = [];
        @stepCount = 0;
        @map_;
        @island_;
        @landmark_;
        
        @:fetchAllPartyItems ::{
            @:party = island_.world.party;
            @:items = [...party.inventory.items];
            
            foreach(party.members) ::(i, member) {
                foreach(Entity.EQUIP_SLOTS) ::(k, slot) {
                    when(slot == Entity.EQUIP_SLOTS.HAND_R) empty;
                    @:item = member.getEquipped(slot);
                    when(item == empty) empty;
                    when(item.name == 'None') empty;
                    
                    items->push(value:item);
                }                
            }
            return items;
        }
        
        
        @:encounterSpecter ::{
        
            windowEvent.queueMessage(
                text: 'An apparition comes before the party. Its voice bellows around you.'
            );
        
            windowEvent.queueMessage(
                speaker: '???',
                text: '....Mortal...'
            );

            @:items = fetchAllPartyItems();
            when (items->size == empty) ::<= {
                windowEvent.queueMessage(
                    speaker: '???',
                    text: '...These Shrines are sacred ground...'
                );

                windowEvent.queueMessage(
                    speaker: '???',
                    text: '...Take care not to take anything from it, or you shall face the consequences...'
                );
            }
            items->sort(comparator::(a, b) {
                when(a.price < b.price) -1;
                when(a.price > b.price)  1;
                return 0;
            });


            windowEvent.queueMessage(
                speaker: '???',
                text: '...You have something I desire...'
            );

            
            @:theDesired = items[items->size-1];
            windowEvent.queueMessage(
                text: '... The ' + theDesired.name + (if (theDesired.equippedBy != empty) " that " + theDesired.equippedBy.name + " holds" else '') + "... It belongs to the Shrines..."
            );

            windowEvent.queueMessage(
                speaker: '???',
                text: '...You will give it to me, or you will face the consequences...'
            );


            windowEvent.queueAskBoolean(
                prompt: 'Hand over the ' + theDesired.name + '?',
                onChoice::(which) {
                    when(which == false) ::<= {
                        windowEvent.queueMessage(
                            speaker: '???',
                            text: '...Then you shall perish...!'
                        );

                        @:specter = island_.newInhabitant();
                        specter.name = 'Wyvern Specter';
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
                        

                        island_.world.battle.start(
                            party:island_.world.party,                            
                            allies: island_.world.party.members,
                            enemies: [specter],
                            landmark: landmark_,
                            loot: false,
                            onAct ::{
                                this.step();
                            },
                            
                            onEnd::(result) {
                                match(result) {
                                  (Battle.RESULTS.ALLIES_WIN):::<= {
                                    windowEvent.queueMessage(
                                        text: 'The apparitions vanished...'
                                    );
                                  },
                                  
                                  (Battle.RESULTS.ENEMIES_WIN): ::<= {
                                    @:windowEvent = import(module:'game_singleton.windowevent.mt');
                                    windowEvent.queueMessage(text:'The Wyvern Specter claims back the Shrine\'s possessions.',
                                        renderable : {
                                            render :: {
                                                @:canvas = import(module:'game_singleton.canvas.mt');
                                                canvas.blackout();
                                                canvas.commit();
                                            }
                                        }
                                    );
                                    
                                    windowEvent.queueNoDisplay(
                                        onEnter :: {                                        
                                            windowEvent.jumpToTag(name:'MainMenu');                                        
                                        }
                                    );
                                  }
                                }
                            }
                        );
                        
                        
                    }
                    
                    
                    // else you agree to fork it over and live another day 
                    if (theDesired.equippedBy != empty) ::<= {
                        windowEvent.queueMessage(
                            text: 'The ' + theDesired.name + ' vanished from ' + theDesired.equippedBy.name + '!'
                        );
                        theDesired.equippedBy.unequipItem(item:theDesired);
                    } else 
                        windowEvent.queueMessage(
                            text: 'The ' + theDesired.name + ' vanished from the party\'s inventory!'
                        );


                    theDesired.throwOut();


                    windowEvent.queueMessage(
                        speaker: '???',
                        text: '...A reasonable choice...'
                    );

                    windowEvent.queueMessage(
                        speaker: '???',
                        text: '...These treasures are not for you...'
                    );

                    windowEvent.queueMessage(
                        text: 'The apparitions vanished...'
                    );

                }
            )

        

        }
        
        
        @:addSpecter ::{
            @:windowEvent = import(module:'game_singleton.windowevent.mt');

            @ar = map_.getRandomArea();;
            @:tileX = ar.x + (ar.width /2)->floor;
            @:tileY = ar.y + (ar.height/2)->floor;
            
            // only add an entity when not visible. Makes it 
            // feel more alive and unknown
            when (map_.isLocationVisible(x:tileX, y:tileY)) empty;
            
            
            @ent = {
                targetX:tileX, 
                targetY:tileY
            }
            
            specters->push(value:ent);
            map_.setItem(data:ent, x:tileX, y:tileY, discovered:true, symbol:'x');
            if (specters->keycount == 1)
                windowEvent.queueMessage(
                    text:random.pickArrayItem(list:[
                        'Something\'s off... It\'s not safe here.',
                        'Do you feel that? Something... different... is here.',
                    ])
                );
        }        


        this.interface = {
            initialize::(landmark) {
                map_ = landmark.map;
                island_ = landmark.island;
                landmark_ = landmark;
                return this;
            },
            
            step::{
                // the specters have been appeased. They leave now
                when(specters == empty) empty;
                when(landmark_.floor < 1 || (landmark_.floor%3 != 0)) empty;
                stepCount += 1;
                // update movement of entity
                @encountered = false;
                foreach(specters)::(i, ent) {
                    @:item = map_.getItem(data:ent);
                    when (map_.getDistanceFromItem(data:ent) <= 1) ::<= {
                        encountered = true;
                    }
                    
                    if (stepCount % 3 == 0)
                        map_.moveTowardPointer(data:ent);
                }
                
                when (encountered) ::<= {
                    encounterSpecter();
                    foreach(specters) ::(i, ent) {
                        map_.removeItem(data:ent);
                        specters = empty;
                    }                
                }
                
                // if a specter overlaps with another, they will 
                // maintain the same path to the player, so just remove one of them.
                // you can passively do this one frame at a time, its pretty lax
                {:::} {
                    
                    @:items = [];
                    foreach(specters) ::(i, ent) {
                        items->push(value:map_.getItem(data:ent));
                    }
                    
                    foreach(items) ::(i, item) {
                        foreach(items) ::(n, other) {
                            if (item != other &&
                                distance(x0:item.x, y0:item.y, 
                                         x1:other.x, y1:other.y) <= 3
                                ) ::<= {
                                @which = specters[i];
                                
                                map_.removeItem(data:item.data);
                                specters->remove(key:i);
                                send();
                            }
                        }
                    }
                }                
            
                if (specters->size < ROOM_SPECTER_COUNT)
                    addSpecter();
            
            }
        }        
    }   
);

return ItemSpecter;
