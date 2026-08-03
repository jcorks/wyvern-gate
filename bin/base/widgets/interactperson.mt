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

@:windowEvent = import(module:'core/windowevent.mt');
@:random = import(module:'core/random.mt');
@:Personality = import(module:'base/entity/personality.mt');
@:correctA = import(module:'base/util/correcta.mt');
@:Battle = import(module:'base/battle.mt');
@:Damage = import(module:'base/entity/damage.mt');

// interacts with this entity
return ::(this, party, location, onDone, skipIntro) {
  @:world = import(module:'base/world.mt');
  
  @:finish ::{
    if (onDone != empty)
      onDone();
    windowEvent.jumpToTag(name:'InteractPerson', goBeforeTag:true, doResolveNext:true);
  }
  
  @:interactions = [...world.scenario.base.interactionsPerson]->filter(
    by::(value) <- value.filter(entity:this)
  );
  
  @:interactionNames = [...interactions]->map(
    to ::(value) <- value.name
  );
  
  
  when (interactions->size == 0) ::<= {
    windowEvent.queueMessage(
      text: 'It appears that you cannot interact with ' + this.name + '.'
    )        
    windowEvent.queueCustom(
      onEnter ::{
        onDone();
      },
      onLeave ::{}
    );
  }  
  
  if (skipIntro == empty) 
    if (this.isIncapacitated())
      if (this.isDead) 
        windowEvent.queueMessage(
          text: this.name + ' appears dead.'
        )        
      else              
        windowEvent.queueMessage(
          text: this.name + ' appears unconscious.'
        )        
    else          
      windowEvent.queueMessage(
        speaker: this.name,
        text: random.pickArrayItem(list:this.personality.phrases[Personality.SPEECH_EVENT.GREET])
      )
  ;        
    
  windowEvent.queueChoices(
    canCancel : true,
    prompt: 'Talking to ' + this.name,
    choices: interactionNames,
    keep: true,
    onLeave :onDone,
    canCancel: true,
    jumpTag: 'InteractPerson',
    onChoice::(choice) {
      when(choice == 0) empty;
      interactions[choice-1].select(
        location,
        entity:this
      );
        
      if (this.overrideInteract) this.overrideInteract(interaction:interactions[choice-1].name);

      if (!interactions[choice-1].keepInteractionMenu && windowEvent.canJumpToTag(name:'InteractPerson')) 
        windowEvent.jumpToTag(name:'InteractPerson', goBeforeTag:true, doResolveNext:true);
    }
  );  
};
