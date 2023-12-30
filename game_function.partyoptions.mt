/*
    Wyvern Gate, a procedural, console-based RPG
    Copyright (C) 2023, Johnathan Corkery (jcorkery@umich.edu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
@:itemmenu = import(module:'game_function.itemmenu.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:world = import(module:'game_singleton.world.mt');
@:canvas = import(module:'game_singleton.canvas.mt');




return ::{

    @:menuRenderable = {
        render ::{
            canvas.blackout();
            // Name (species, class)
            // HP, AP,
            // Weapon
            @:Entity = import(module:'game_class.entity.mt');
            
            @:party = import(module:'game_singleton.world.mt').party;
            @top = 1;
            @:height = 7;
            @:width = canvas.width*(2/3);
            foreach(party.members)::(index, member) {
                @x = (canvas.width - width) / 2;
                canvas.renderFrame(top, left: (canvas.width - width) / 2, width, height);
                
                canvas.movePen(x: x+3, y: top + 2);
                canvas.drawText(text: member.name + ' - (' + member.species.name + ' ' + member.profession.base.name + ')');
                canvas.movePen(x: x+3, y: top + 3);
                canvas.drawText(text: member.renderHP() + 'HP: ' + member.hp + ' / ' + member.stats.HP + '    AP: ' + member.ap + ' / ' + member.stats.AP + '\n');
                canvas.movePen(x: x+3, y: top + 4);
                canvas.drawText(text: 'Weapon: ' + member.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR).name);
                
                top += height;
                
            }
            canvas.movePen(x: ((canvas.width - width) / 2)+1, y: 1);    
            canvas.drawText(text:'Party: (' + party.inventory.gold + 'G, ' + party.inventory.items->keycount + ' items)');     
        
        }
    }

    windowEvent.queueChoices(
        leftWeight: 1,
        topWeight: 1,
        prompt: 'Party Options',
        keep: true,
        canCancel: true,
        renderable : menuRenderable,
        choices: [
            //'Manage',
            'Members',
            'Inventory'
        ],
        
        
        onChoice ::(choice) {

            match(choice-1) {
              
              
              // members
              (0)::<= {
                @:names = [];
                @:party = world.party;
                foreach(party.members)::(i, member) {
                    names->push(value:member.name);
                }

                
                windowEvent.queueChoices(
                    leftWeight: 1,
                    topWeight: 1,
                    choices: names,
                    prompt: 'Whom?',
                    renderable : menuRenderable,
                    keep: true,
                    canCancel: true,
                    onChoice ::(choice) {
                        when(choice == 0) empty;
                        @member = party.members[choice-1];
                        
                        
                        windowEvent.queueChoices(
                            leftWeight: 1,
                            topWeight: 1,
                            choices: [
                                'Describe',
                                'Equip'
                            ],
                            prompt: names[choice-1],
                            keep: true,
                            canCancel: true,
                            renderable : menuRenderable,
                            onChoice ::(choice) {
                                when(choice == 0) empty;
                                
                                
                                match(choice) {

                                  // describe
                                  (1): member.describe(),




                                  // Equip / unequip
                                  (2):::<= {
                                    @Entity = import(module:'game_class.entity.mt');

                                    @slotToName::(slot) {
                                        return match(slot) {
                                          (Entity.EQUIP_SLOTS.HAND_LR-1)  : 'L.Hand  ',
                                          (Entity.EQUIP_SLOTS.HAND_LR)    : 'R.Hand  ',
                                          (Entity.EQUIP_SLOTS.ARMOR)   : 'Armor   ',
                                          (Entity.EQUIP_SLOTS.AMULET)  : 'Amulet  ',
                                          (Entity.EQUIP_SLOTS.RING_L)  : 'L.Ring  ',
                                          (Entity.EQUIP_SLOTS.RING_R)  : 'R.Ring  ',
                                          (Entity.EQUIP_SLOTS.TRINKET) : 'Trinket '
                                        }                                    
                                    }

                                    @:Item = import(module:'game_class.item.mt');
     
                                    windowEvent.queueChoices(
                                        leftWeight: 1,
                                        topWeight: 1,
                                        prompt: member.name + ': Equips',
                                        keep:true,
                                        renderable : menuRenderable,
                                        canCancel: true,
                                        onGetChoices:: {
                                            @:choices = [];
                                            for(-1, Entity.EQUIP_SLOTS.TRINKET+1)::(i) {
                                                @str = slotToName(slot:i);

                                                if (i <= Entity.EQUIP_SLOTS.HAND_LR) ::<= {
                                                    @:item = member.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
                                                    if (i < Entity.EQUIP_SLOTS.HAND_LR) ::<= {     
                                                        str = str +  if (item.name == 'None') ('------') else item.name;
                                                    } else if (item.base.equipType == Item.TYPE.TWOHANDED) ::<= {
                                                        str = str +  if (item.name == 'None') ('') else item.name;                                                    
                                                    }       
                                                
                                                } else ::<= {
                                                    @:item = member.getEquipped(slot:i);
                                                    str = str +  if (item.name == 'None') '------' else item.name;
                                                }
                                                choices->push(value:str);
                                            }
                                            return choices;
                                        },
                                        onChoice:::(choice) {
                                            when(choice == 0) empty;


                                            @slot = choice-2;
                                            if (slot < 0) slot = 0; // left and right hand point to same slot



                                            @equip = ::{

                                                @:items = party.inventory.items->filter(by:::(value) <- member.getSlotsForItem(item:value)->findIndex(value:slot) != -1);
                                                @:itemNames = [...items]->map(to:::(value) <- value.name);
                                                itemNames->push(value:'[Nothing]');
                                            
                                                windowEvent.queueChoices(
                                                    leftWeight: 1,
                                                    topWeight: 1,
                                                    choices:itemNames,
                                                    prompt: member.name + ': ' + slotToName(slot),
                                                    canCancel: true,
                                                    keep:true,
                                                    jumpTag: 'EquipWhich',
                                                    renderable : menuRenderable,
                                                    
                                                    onChoice:::(choice) {
                                                        @:index = choice -1;

                                                        // unequip
                                                        when (index == items->keycount) ::<= {
                                                            @item = member.getEquipped(slot);
                                                            if (item != empty && item.base.name != 'None') ::<= {
                                                                windowEvent.queueMessage(
                                                                    text: member.name + ' has unequipped the ' + item.name
                                                                );
                                                                member.unequipItem(item);
                                                                party.inventory.add(item);
                                                                windowEvent.jumpToTag(name:'EquipWhich', goBeforeTag:true, doResolveNext:true);
                                                            }
                                                        }
                                                        
                                                        @item = items[index];

                                                        windowEvent.queueChoices(
                                                            choices: ['Equip', 'Check', 'Rename', 'Compare'],
                                                            prompt: item.name,
                                                            canCancel: true,
                                                            leftWeight: 1,
                                                            topWeight: 1,
                                                            onChoice::(choice) {
                                                                when (choice == 0) empty;
                                                                when(choice == 1) ::<= {
                                                        
                                                                    // equip 
                                                                    member.equip(
                                                                        item, 
                                                                        slot, 
                                                                        inventory:party.inventory
                                                                    );
                                                                    windowEvent.jumpToTag(name:'EquipWhich', goBeforeTag:true, doResolveNext:true);
                                                                }
                                                                
                                                                when(choice == 2) 
                                                                    item.describe();

                                                                when(choice == 3) ::<= {
                                                                    when (!item.base.canHaveEnchants)
                                                                        windowEvent.queueMessage(text:item.name + ' cannot be renamed.');
                                                                
                                                                
                                                                    @:name = import(module:"game_function.name.mt");
                                                                    name(
                                                                        prompt: 'New item name:',
                                                                        onDone::(name) {
                                                                            item.name = name;
                                                                            windowEvent.jumpToTag(name:'EquipWhich', goBeforeTag:true, doResolveNext:true);
                                                                        }
                                                                    );
                                                                }
                                                                    

                                                                when(choice == 4) ::<= {
                                                                    @slot = member.getSlotsForItem(item)[0];
                                                                    @currentEquip = member.getEquipped(slot);
                                                                    
                                                                    currentEquip.equipMod.printDiffRate(
                                                                        prompt: currentEquip.name + ' -> ' + item.name,
                                                                        other:item.equipMod
                                                                    );                                                                     
                                                                }
                                                            }
                                                        )
                                                    }
                                                );
                                            }

                                            // force equip when nothing equipped yet.
                                            // slightly less confusing
                                            when(member.getEquipped(slot).name == 'None')
                                                equip();

                                            windowEvent.queueChoices(
                                                leftWeight: 1,
                                                topWeight: 1,
                                                onGetChoices:: {
                                                    @choices = ['Equip'];
                                                    return if (member.getEquipped(slot).name != 'None') ::<= {
                                                        choices->push(value:'Check');
                                                        choices->push(value:'Improve');
                                                        choices->push(value:'Rename');
                                                        return choices;
                                                    } else empty;
                                                },
                                                onGetPrompt::{
                                                    return member.name + ': ' + member.getEquipped(slot).name + '';
                                                },
                                                renderable : menuRenderable,
                                                canCancel: true,
                                                keep: true,
                                                onChoice:::(choice) {
                                                    when (choice == 0) empty;
                                                    match(choice) {
                                                        // Equip
                                                        (1):::<= {
                                                            equip();
                                                        },
                                                        // Check
                                                        (2):::<= {
                                                            member.getEquipped(slot).describe();                                                       
                                                        },
                                                        // improve
                                                        (3):::<= {
                                                            (import(module:'game_function.itemimprove.mt'))(inBattle: false, user:member, item:member.getEquipped(slot));
                                                        },
                                                        // Rename 
                                                        (4):::<= {
                                                            when (!member.getEquipped(slot).base.canHaveEnchants)
                                                                windowEvent.queueMessage(text:member.getEquipped(slot).name + ' cannot be renamed.');
                                                            @:name = import(module:"game_function.name.mt");
                                                            name(
                                                                prompt: 'New item name:',
                                                                onDone::(name) {
                                                                    member.getEquipped(slot).name = name;
                                                                }
                                                            );                                                        
                                                        }
                                                    }
                                                }                                                            
                                            );
                                        }
                                    );                                   
                                  }
                                }
                            }
                        );                        
                        
                    }
                );
                

                
                
              },
              
              
              // Inventory
              (1)::<= {
                @:names = [];
                foreach(world.party.members)::(index, member) {
                    names->push(value:member.name);
                }
                windowEvent.queueChoices(
                    leftWeight: 1,
                    topWeight: 1,
                    keep:true,
                    prompt: "Who's looking?",
                    choices: names,
                    canCancel : true,
                    renderable : menuRenderable,
                    onChoice::(choice) {
                        when(choice == 0) empty;
                        
                        itemmenu(
                            inBattle: false,
                            user:world.party.members[choice-1], 
                            party:world.party, 
                            enemies:[],
                            renderable : menuRenderable,
                            onAct::(action) {
                                when(action == empty) empty;
                                world.party.members[choice-1].useAbility(
                                    ability:action.ability,
                                    targets:action.targets,
                                    turnIndex : 0,
                                    extraData : action.extraData
                                );                              
                            
                            }
                        );
                        
                    
                    }
                );
              }
            }        
        }
    );                  
}  
