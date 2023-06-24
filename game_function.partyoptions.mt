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
    windowEvent.choices(
        leftWeight: 1,
        topWeight: 1,
        prompt: 'Party Options',
        keep: true,
        canCancel: true,
        renderable : {
            render ::{
                canvas.clear();
                // Name (species, class)
                // HP, AP,
                // Weapon
                @:Entity = import(module:'game_class.entity.mt');
                
                @:party = import(module:'game_singleton.world.mt').party;
                @top = 1;
                @:height = 7;
                @:width = canvas.width*(2/3);
                party.members->foreach(do:::(index, member) {
                    @x = (canvas.width - width) / 2;
                    canvas.renderFrame(top, left: (canvas.width - width) / 2, width, height);
                    
                    canvas.movePen(x: x+3, y: top + 2);
                    canvas.drawText(text: member.name + ' - (' + member.species.name + ' ' + member.profession.base.name + ')');
                    canvas.movePen(x: x+3, y: top + 3);
                    canvas.drawText(text: member.renderHP() + 'HP: ' + member.hp + ' / ' + member.stats.HP + '    AP: ' + member.ap + ' / ' + member.stats.AP + '\n');
                    canvas.movePen(x: x+3, y: top + 4);
                    canvas.drawText(text: 'Weapon: ' + member.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L).name);
                    
                    top += height;
                    
                });
                canvas.movePen(x: ((canvas.width - width) / 2)+1, y: 1);    
                canvas.drawText(text:'Party: (' + party.inventory.gold + 'G, ' + party.inventory.items->keycount + ' items)');     
            
            }
        },
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
                party.members->foreach(do:::(i, member) {
                    names->push(value:member.name);
                });
                
                @:choice = windowEvent.choices(
                    leftWeight: 1,
                    topWeight: 1,
                    choices: names,
                    prompt: 'Check whom?',
                    keep: true,
                    canCancel: true,
                    onChoice ::(choice) {
                        when(choice == 0) empty;
                        party.members[choice-1].describe();                    
                    }
                );
                

                
                
              },
              
              
              // Inventory
              (1)::<= {
                @:names = [];
                world.party.members->foreach(do:::(index, member) {
                    names->push(value:member.name);
                });
                windowEvent.choices(
                    leftWeight: 1,
                    topWeight: 1,
                    keep:true,
                    prompt: "Who's looking?",
                    choices: names,
                    canCancel : true,
                    onChoice::(choice) {
                        when(choice == 0) empty;
                        
                        itemmenu(
                            user:world.party.members[choice-1], 
                            party:world.party, 
                            enemies:[],
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
            };        
        }
    );                  
};  
