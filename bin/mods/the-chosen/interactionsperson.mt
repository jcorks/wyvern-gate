@:WyvernGate = import(:'wyvern-gate.mt');
@:windowEvent = WyvernGate.Core.WindowEvent
@:InteractionMenuEntry = WyvernGate.Interaction.MenuEntry
@:random = WyvernGate.Core.Random
@:Personality = WyvernGate.Entity.Personality
@:g = WyvernGate.Util.G
@:Damage = WyvernGate.Entity.Damage
@:correctA = WyvernGate.Util.CorrectA

return [
  WyvernGate.Interaction.Common.person.barter,
  WyvernGate.Interaction.Common.person.fetchQuestStart,
  WyvernGate.Interaction.Common.person.fetchQuestEnd,

  InteractionMenuEntry.new(
    name: 'Hire',
    keepInteractionMenu: true,
    filter ::(entity)<- true, // everyone can barter,
    select ::(entity, location) {
      @:this = entity;
      when(this.isIncapacitated())
        windowEvent.queueMessage(
          text: this.name + ' is not currently able to talk.'
        );                            
      @:world = import(module:'base/world.mt');
      @:party = world.party;


      when(party.isMember(entity:this))
        windowEvent.queueMessage(
          text: this.name + ' is already a party member.'
        );        
      
      when (party.members->keycount >= 3 || !this.adventurous)
        windowEvent.queueMessage(
          speaker: this.name,
          text: random.pickArrayItem(list:this.personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_DENY])
        );        
        
      windowEvent.queueMessage(
        speaker: this.name,
        text: random.pickArrayItem(list:this.personality.phrases[Personality.SPEECH_EVENT.ADVENTURE_ACCEPT])
      );        

      @highestStat = 0;
      if (this.stats.ATK > highestStat) highestStat = this.stats.ATK;
      if (this.stats.DEF > highestStat) highestStat = this.stats.DEF;
      if (this.stats.INT > highestStat) highestStat = this.stats.INT;
      if (this.stats.SPD > highestStat) highestStat = this.stats.SPD;
      if (this.stats.LUK > highestStat) highestStat = this.stats.LUK;
      if (this.stats.DEX > highestStat) highestStat = this.stats.DEX;



      @cost;
      
      if (highestStat <= 10)
        cost = 50+((this.stats.sum/3 + this.level)*2.5)->ceil
      else
        cost = 200 + this.stats.sum*13; // bigger and better stats come at a premium
      this.describe();

      windowEvent.queueAskBoolean(
        prompt: 'Hire for ' + g(g:cost) + '?',
        onChoice::(which) {
          when(which == false) empty;
          when(party.inventory.gold < cost)
            windowEvent.queueMessage(
              text: 'The party cannot afford to hire ' + this.name
            );        
            
          party.inventory.subtractGold(amount:cost);
          party.add(member:this);
            windowEvent.queueMessage(
              text: this.name + ' joins the party!'
            );   
          world.accoladeIncrement(name:'recruitedCount');                    
          // the location is the one that has ownership over this...
          if (this.owns != empty)
            this.owns.ownedBy = empty;
            

        }
      );  
    }
  ),

  InteractionMenuEntry.new(
    name: 'Aggress',
    keepInteractionMenu: true,
    filter ::(entity)<- true, // everyone can barter,
    select::(entity, location) {
      @:this = entity;
      @whom;

      @:world = import(module:'base/world.mt');
      @:party = world.party;


        
      // some actions result in a confrontation    
      @:confront ::{
        windowEvent.queueMessage(
          speaker: this.name,
          text:'"What are you doing??"'
        );

        if (location != empty) ::<= {
          location.landmark.peaceful = false;
          windowEvent.queueMessage(text:'The people here are now aware of your aggression.');
        }
        
        world.battle.start(
          party,              
          allies: [whom],
          enemies: [this],
          landmark: {},
          onEnd::(result) {
            when(world.battle.partyWon()) empty;
              
            @:instance = import(module:'base/instance.mt');
            instance.gameOver(reason:'The party was wiped out.');
          }
        );          
      }
      
      
      @:aggress = ::{
        windowEvent.queueChoices(
          prompt: whom.name + ' - Aggressing ' + this.name,
          choices: ['Attack', 'Steal'],
          canCancel: true,
          onChoice::(choice) {
            when(choice == 0) empty;
            @:aggressChoice = choice;
            
            
            // when fighting the person
            @:aggressAttack :: {
              windowEvent.queueMessage(
                text: whom.name + ' attacks ' + this.name + '!'
              );

              @hp = this.hp;
              whom.attack(
                target:this,
                damage: Damage.new(
                  amount:whom.stats.ATK * (0.5),
                  damageType : Damage.TYPE.PHYS,
                  damageClass: Damage.CLASS.HP
                )
              );            
              
              when (hp > 0 && this.isIncapacitated()) ::<= {
                windowEvent.queueMessage(
                  text:this.name + ' silently went down without anyone noticing.'
                );
              };
              
              when(this.isIncapacitated())
                empty
            
              confront();                     
            }


            // when fighting the person
            @:aggressSteal :: {
              windowEvent.queueMessage(
                text: whom.name + ' attempts to steal from ' + this.name + '.'
              );
              
              @:stealSuccess ::{
                when (this.inventory.isEmpty) ::<= {
                  windowEvent.queueMessage(
                    text: this.name + ' had nothing on their person.'
                  );        
                }

                @:item = this.inventory.items[0];
                windowEvent.queueMessage(
                  text: whom.name + ' steals ' + correctA(word:item.name) + ' from ' + this.name + '.'
                );                                                 
                world.accoladeEnable(name:'hasStolen');
                world.party.karma -= 100;
                this.inventory.remove(item);
                party.inventory.add(item);                
              }

              // whoops always successful
              when (this.isIncapacitated()) ::<= {
                stealSuccess();
              }


              @success;                      
              @diffpercent = (whom.stats.DEX - this.stats.DEX) / this.stats.DEX;
              
              if (diffpercent > 0) ::<= {
                if (diffpercent > .9)
                  diffpercent = 0.95;
                
              } else ::<= {
                diffpercent = 1 - diffpercent->abs;
                if (diffpercent < 0.2)
                  diffpercent = 0.2;
              }
              success = random.try(percentSuccess:diffpercent*100);
              
              
              
              if (success) ::<= {                
                stealSuccess();
                windowEvent.queueMessage(
                  text: whom.name + ' went unnoticed.'
                );
              } else ::<= {
                windowEvent.queueMessage(
                  text: this.name + ' noticed ' + whom.name + '\'s actions!'
                );
                confront();
              }        
            }
            
            match(choice-1) {
              (0): aggressAttack(),
              (1): aggressSteal()
            }
          }
        )
      }
      
      windowEvent.queueMessage(text:'Who will be aggressing?');
      @:choices = [...world.party.members]->map(to:::(value) <- value.name);
      windowEvent.queueChoices(
        choices,
        prompt: 'Pick someone.',
        canCancel: true,
        onChoice::(choice) {
          when(choice == 0) empty;
          whom = world.party.members[choice-1];
          
          aggress();
        }
      )              
    }
  )          
];

