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
@:g = import(module:'game_function.g.mt');
@:StatSet = import(module:'game_class.statset.mt');



return ::{
  @whom = 0;
  @chosen = false;
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
        @x = (canvas.width - width) / 4;
        canvas.renderFrame(top, left: x, width, height);
        
        if (whom == index) ::<= {
          canvas.movePen(
            x: (canvas.width - width) / 4 - 4,
            y: top + height/2
          );
          canvas.drawText(
            text: '--->'
          );
        }
          
        
        canvas.movePen(x: x+3, y: top + 2);
        canvas.drawText(text: member.name + ' - (' + member.species.name + ' ' + member.profession.name + ')' + (if (party.leader == member) ' - Leader' else ''));
        canvas.movePen(x: x+3, y: top + 3);
        canvas.drawText(text: member.renderHP() + 'HP: ' + member.hp + ' / ' + member.stats.HP + '  AP: ' + member.stats.AP + '\n');
        canvas.movePen(x: x+3, y: top + 4);
        canvas.drawText(text: 'Weapon: ' + member.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR).name);
        
        top += height;
        
        



      }
      canvas.movePen(x: ((canvas.width - width) / 2)+1, y: 1);  
      canvas.drawText(text:'Party: (' + g(g:party.inventory.gold) + ', ' + party.inventory.items->keycount + ' items)');   

      when(!chosen) empty;
      @:member = party.members[whom]

      @:plainStatsState = member.stats.save();
      @:plainStats = StatSet.new();
      plainStats.load(serialized:plainStatsState);
      plainStats.resetMod();
          
      canvas.renderTextFrameGeneral(
        topWeight: 0.1,
        leftWeight: 1,
        title: '(Base -> w/Mods.)',
        lines: StatSet.diffToLines(
          stats:plainStats,
          other:member.stats
            
        )
      );

    
    }
  }
  @:names = [];
  @:party = world.party;
  foreach(party.members)::(i, member) {
    names->push(value:member.name);
  }

  
  @:viewArts::(member) {
    @:deleteDeck ::(name) {
      when (member.getEquippedDeckName() == name)
        windowEvent.queueMessage(
          text:'This deck is currently equipped and cannot be removed. Only unequipped decks can be removed.'
        )

        
      windowEvent.queueMessage(
        text:'If the deck is removed, all of the Support Arts will be sent back to the trunk. This operation cannot be undone.'
      )
      
      windowEvent.queueAskBoolean(
        prompt: 'Remove deck ' + name +'?',
        onChoice::(which) {
          when(which == false) empty;
          
          member.removeDeck(:name);
          windowEvent.jumpToTag(name:'DECKMENU');
        }
      );
    
    }
  
    windowEvent.queueChoices(
      leftWeight: 1,
      topWeight : 1,
      prompt: member.name + 's decks:',
      keep : true,
      jumpTag : 'DECKMENU',
      canCancel: true,
      onGetChoices::<- [
        ...(member.deckTemplateNames->map(::(value) <- 
          if (member.getEquippedDeckName() == value) 
            '* ' + value 
          else 
            '  ' + value
        )), 
        'Make new deck...'
      ],
      onChoice::(choice) {
        when(choice-1 == member.deckTemplateNames->size) ::<= {
          import(:'game_function.name.mt')(
            prompt: 'New deck name:',
            canCancel: true,
            onDone ::(name) {
              member.addDeck(:name);
            }
          );
        }
        @:deckName = member.deckTemplateNames[choice-1];
        windowEvent.queueChoices(
          prompt: 'Deck: ' + deckName,
          choices: ['Equip deck', 'Edit...', 'Remove'],
          leftWeight : 1,
          topWeight : 1,
          keep : true,
          canCancel: true,
          onChoice::(choice) {
            when(choice-1 == 0)
              member.equipDeck(name:deckName);
              
            when(choice-1 == 1)
              member.editDeck(:deckName);            
              
              
            deleteDeck(:deckName);
          }
        );
      }
    );
  }
  
  @:professionMenu ::(member) {
    @:choicesColumns = import(module:'game_function.choicescolumns.mt');
    choicesColumns(
      onGetChoices::<- [
        // equipped
        member.professions->map(::(value) <- if (member.profession == value) '*' else ''),
    
        // name
        member.professions->map(::(value) <- value.name),
        
        // progress
        member.professions->map(::(value) {
          @prof = member.getProfessionProgress(:value);
          when(prof == empty) 
            'Lvl 0';


          when(prof.level >= member.profession.arts->size)
            'Lvl MAX';
            
          return 'Lvl ' + prof.level + ' ' + canvas.renderBarAsString(
            width: 15,
            fillFraction: prof.exp / (prof.expToNext + prof.exp)
          );
        })
      ],
      
      leftJustified : [
        true,
        true,
        true
      ],
      canCancel : true,
      prompt: member.name + '\'s professions',
      keep: true,
      
      onChoice ::(choice) {
        @:prof = member.professions[choice-1];
        windowEvent.queueChoices(
          choices : [
            'Info...',
            'Set as profession'
          ],
          canCancel: true,
          
          onChoice ::(choice) {
            // info
            when(choice == 1) ::<= {
              windowEvent.queueDisplay(
                lines : canvas.columnsToLines(
                  columns : [
                    [
                      'Profession: ',
                      'Level: ',
                      'Exp. to next level: '
                    ],
                    
                    [
                      prof.name,
                      '' + (if (member.getProfessionProgress(:prof).level >= prof.arts->size) 'MAX' else ''+member.getProfessionProgress(:prof).level + ' / ' + prof.arts->size),
                      '' + member.getProfessionProgress(:prof).expToNext
                    ]
                  ],
                  
                  leftJustifieds : [
                    true,
                    true
                  ]
                )
              );
            
            }
          
          
            when (prof == member.profession) 
              windowEvent.queueMessage(
                text: member.name + '\'s current profession is already set to a ' + member.profession.name + '.'
              );
              
              
            member.profession = prof;
            windowEvent.queueMessage(
              text: member.name + ' is now a ' + member.profession.name + '.'
            );

          }
        );  
      }
    );
  }
  
  
  windowEvent.queueCursorMove(
    leftWeight: 1,
    topWeight: 1,
    prompt: 'Choose a member.',
    renderable : menuRenderable,
    canCancel: true,
    onMove ::(choice) {
      chosen = false;
      when(choice == windowEvent.CURSOR_ACTIONS.LEFT ||
         choice == windowEvent.CURSOR_ACTIONS.RIGHT) empty;
         
      if (choice == windowEvent.CURSOR_ACTIONS.UP)
        whom -= 1;

      if (choice == windowEvent.CURSOR_ACTIONS.DOWN)
        whom += 1;

      if(whom < 0) whom = party.members->size-1;
      if(whom > party.members->size-1) whom = 0;
    },
    onMenu :: {
      @member = party.members[whom];
      chosen = true;
      
      
      windowEvent.queueChoices(
        leftWeight: 1,
        topWeight: 1,
        choices: [
          'Make Leader',
          'Describe',
          'Equip',
          'Profession...',
          'Arts...'
        ],
        prompt: names[whom],
        keep: true,
        canCancel: true,
        onCancel ::{
          chosen = false;        
        },
        renderable : menuRenderable,
        onChoice ::(choice) {
          when(choice == 0) empty;
          
          
          match(choice) {

            // make leader 
            (1): ::<= {
              if (member == party.leader) ::<= {
                windowEvent.queueMessage(text: member.name + ' is already the leader.');
              } else ::<= {
                party.leader = member;
                windowEvent.queueMessage(text: member.name + ' is now the leader.');
              }
            },

            // describe
            (2): member.describe(excludeStats:true, showFeelings:true),



            // Equip / unequip
            (3):::<= {
              @Entity = import(module:'game_class.entity.mt');

              @slotToName::(slot) {
                return match(slot) {
                  (Entity.EQUIP_SLOTS.HAND_LR-1)  : 'L.Hand  ',
                  (Entity.EQUIP_SLOTS.HAND_LR)  : 'R.Hand  ',
                  (Entity.EQUIP_SLOTS.ARMOR)   : 'Armor   ',
                  (Entity.EQUIP_SLOTS.AMULET)  : 'Amulet  ',
                  (Entity.EQUIP_SLOTS.RING_L)  : 'L.Ring  ',
                  (Entity.EQUIP_SLOTS.RING_R)  : 'R.Ring  ',
                  (Entity.EQUIP_SLOTS.TRINKET) : 'Trinket '
                }                  
              }

              @:Item = import(module:'game_mutator.item.mt');

              windowEvent.queueChoices(
                leftWeight: 1,
                topWeight: 1,
                prompt: member.name + ': Equips',
                keep:true,
                renderable : menuRenderable,
                canCancel: true,
                pageAfter:15,
                onGetChoices:: {
                  @:choices = [];
                  for(-1, Entity.EQUIP_SLOTS.TRINKET+1)::(i) {
                    @str = slotToName(slot:i);

                    if (i <= Entity.EQUIP_SLOTS.HAND_LR) ::<= {
                      @:item = member.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_LR);
                      if (i < Entity.EQUIP_SLOTS.HAND_LR) ::<= {   
                        str = str +  if (item.base.id == 'base:none') ('------') else item.name;
                      } else if (item.base.equipType == Item.TYPE.TWOHANDED) ::<= {
                        str = str +  if (item.base.id == 'base:none') ('') else item.name;                          
                      }     
                    
                    } else ::<= {
                      @:item = member.getEquipped(slot:i);
                      str = str +  if (item.base.id == 'base:none') '------' else item.name;
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
                    @:pickItem = import(:'game_function.pickitem.mt');

                    @:inv = party.inventory.clone();
                    @:ph = Item.new(base:Item.database.find(id:'base:placeholder'));
                    ph.name = '[Nothing]';
                    inv.add(:ph);
                    @hovered
                    pickItem(
                      leftWeight: 1,
                      topWeight: 0.5,
                      filter: ::(value) <- value.base.id == 'base:placeholder' || member.getSlotsForItem(item:value)->findIndex(value:slot) != -1,
                      inventory : inv,
                      prompt: member.name + ': ' + slotToName(slot),
                      canCancel: true,
                      keep:true,
                      pageAfter: 9,
                      renderable : {
                        render ::{
                          menuRenderable.render();
                          when(hovered == empty) empty;

                          @:currentStats = member.stats.clone();
                          @:withEquip = member.statsIfEquippedInstead(item:hovered, slot);
                          @:lines = StatSet.diffToLines(stats:currentStats, other:withEquip);

                          canvas.renderTextFrameGeneral(
                            title:'If equipped...',
                            lines,
                            leftWeight:0,
                            topWeight:0.5
                          );                        
                          
                        }
                      },
                      onHover ::(item) <- hovered = item,
                      
                      onPick:::(item) {

                        // unequip
                        when (item.base.id == 'base:placeholder') ::<= {
                          @item = member.getEquipped(slot);
                          if (item != empty && item.base.name != 'None') ::<= {
                            when(party.inventory.isFull)
                              windowEvent.queueMessage(
                                text: member.name + ' cannot unequip the ' + item.name + ' because the party\'s inventory is full.'
                              );

                            windowEvent.queueMessage(
                              text: member.name + ' has unequipped the ' + item.name
                            );
                            member.unequipItem(item);
                            party.inventory.add(item);
                          }
                          windowEvent.jumpToTag(name:'pickItem', goBeforeTag:true, doResolveNext:true);
                        }
                        

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
                              windowEvent.jumpToTag(name:'pickItem', goBeforeTag:true, doResolveNext:true);
                            }
                            
                            when(choice == 2) 
                              item.describe();

                            when(choice == 3) ::<= {
                              when (!item.base.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS))
                                windowEvent.queueMessage(text:item.name + ' cannot be renamed.');
                            
                            
                              @:name = import(module:"game_function.name.mt");
                              name(
                                prompt: 'New item name:',
                                onDone::(name) {
                                  item.name = name;
                                  windowEvent.jumpToTag(name:'pickItem', goBeforeTag:true, doResolveNext:true);
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
                  when(member.getEquipped(slot).base.id == 'base:none')
                    equip();
                    
                  @:item = member.getEquipped(slot);
                  @choices = ['Equip'];
                  @choiceActions = [::<- equip()];



                  windowEvent.queueChoices(
                    leftWeight: 1,
                    topWeight: 1,
                    onGetChoices:: {
                      choices = ['Equip'];
                      choiceActions = [::<- equip()];
                      return if (member.getEquipped(slot).base.id != 'base:none') ::<= {
                        choices->push(:'Check');
                        choiceActions->push(::<- item.describe());
                        choices->push(:'Improve');
                        choiceActions->push(::<- (import(module:'game_function.itemimprove.mt'))(inBattle: false, user:member, item));

                        if (member.getEquipped(slot).inletSlotSet != empty) ::<= {
                          choices->push(:'Gems...');                        
                          choiceActions->push(::<- item.inletSlotSet.equip(user:member, item));
                        }
                        choices->push(:'Rename');
                        choiceActions->push(::{
                          when (!member.getEquipped(slot).base.hasTraits(:Item.TRAIT.CAN_HAVE_ENCHANTMENTS))
                            windowEvent.queueMessage(text:member.getEquipped(slot).name + ' cannot be renamed.');
                          @:name = import(module:"game_function.name.mt");
                          name(
                            prompt: 'New item name:',
                            onDone::(name) {
                              member.getEquipped(slot).name = name;
                            }
                          );                        
                        });
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
                      choiceActions[choice-1]();
                    }                              
                  );
                }
              );                   
            },
            
            // profession 
            (4): 
              professionMenu(:member),

            (5): viewArts(:member)            
          }
        }
      );            
      
    }
  );
        
}  
