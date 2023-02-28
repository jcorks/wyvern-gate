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
@:itemmenu = import(module:'function.itemmenu.mt');
@:dialogue = import(module:'singleton.dialogue.mt');
@:world = import(module:'singleton.world.mt');
@:canvas = import(module:'singleton.canvas.mt');


@:renderPartyOverview :: {
    // Name (species, class)
    // HP, MP,
    // Weapon
    @:Entity = import(module:'class.entity.mt');
    
    @:party = import(module:'singleton.world.mt').party;
    @top = 1;
    @:height = 7;
    @:width = canvas.width*(2/3);
    party.members->foreach(do:::(index, member) {
        @x = (canvas.width - width) / 2;
        canvas.renderFrame(top, left: (canvas.width - width) / 2, width, height);
        
        canvas.movePen(x: x+3, y: top + 2);
        canvas.drawText(text: member.name + ' - Lv ' + member.level + ' (' + member.species.name + ' ' + member.profession.base.name + ')');
        canvas.movePen(x: x+3, y: top + 3);
        canvas.drawText(text: member.renderHP() + 'HP: ' + member.hp + ' / ' + member.stats.HP + '    MP: ' + member.mp + ' / ' + member.stats.MP + '\n');
        canvas.movePen(x: x+3, y: top + 4);
        canvas.drawText(text: 'Weapon: ' + member.getEquipped(slot:Entity.EQUIP_SLOTS.HAND_L).name);
        
        top += height;
        
    });
    canvas.movePen(x: ((canvas.width - width) / 2)+1, y: 1);    
    canvas.drawText(text:'Party: (' + party.inventory.gold + 'G, ' + party.inventory.items->keycount + ' items)');     
   
};



return ::{
    canvas.pushState();
    
    renderPartyOverview();
    

    @choice = dialogue.choicesNow(
        leftWeight: 1,
        topWeight: 1,
        prompt: 'Party Options',
        choices: [
            'Manage',
            'Members',
            'Inventory'
        ],
        canCancel: true
    );                  

    match(choice-1) {
      // status
      (0)::<= {
        @:lines = [];
        @:party = world.party;
        
        party.members->foreach(do:::(i, member) {
            lines->push(value:member.renderHP() + ' ' + member.hp + ' / ' + member.stats.HP + ' HP ' + member.name + '(Lv' + member.level + ')');
        });
        
        lines->push(value:'');
        lines->push(value:': ' + party.inventory.gold);
        lines->push(value:'');
        lines->push(value:'inventory (' + party.inventory.items->keycount + ' items)');
        party.inventory.items->foreach(do:::(i, item) {
            lines->push(value:item.name);
        });


        dialogue.display(
            prompt:'Party status',
            lines,
            pageAfter: canvas.height-4
        );
      
      },
      
      
      // members
      (1)::<= {
        @:names = [];
        @:party = world.party;
        party.members->foreach(do:::(i, member) {
            names->push(value:member.name);
        });
        
        @:choice = dialogue.choicesNow(
            leftWeight: 1,
            topWeight: 1,
            choices: names,
            prompt: 'Check whom?',
            canCancel: true
        );
        
        when(choice == 0) empty;
        party.members[choice-1].describe();

        
        
      },
      
      
      // Inventory
      (2)::<= {
        @:names = [];
        world.party.members->foreach(do:::(index, member) {
            names->push(value:member.name);
        });
        choice = dialogue.choicesNow(
            leftWeight: 1,
            topWeight: 1,
            prompt: "Who's looking?",
            choices: names,
            canCancel : true
        );
        when(choice == 0) empty;
      
        @:itemAction = itemmenu(
            user:world.party.members[choice-1], 
            party:world.party, 
            enemies:[]
        );
        
        when(itemAction == empty) empty;
        world.party.members[choice-1].useAbility(
            ability:itemAction.ability,
            targets:itemAction.targets,
            turnIndex : 0,
            extraData : itemAction.extraData
        );                              
      }
    };
    
    canvas.popState();
};  
