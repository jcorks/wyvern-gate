@:WyvernGate = import(:'wyvern-gate.mt');
@:class = import(module:'Matte.Core.Class');


@:instance = WyvernGate.Instance;
@:story = WyvernGate.Story
@:world = WyvernGate.World
@:Item = WyvernGate.Item
@:Scenario = WyvernGate.Scenario;





@:TheChosen = {
  name : 'The Chosen',
  id : 'rasa:thechosen',
  skipName : false,
  everyoneIsAFriend : true,
  events : {
    onBegin ::(data) {
      import(:'wyvern-gate.rasa.thechosen/intro.mt')();
    }, 
      
    onResume ::(data) {
      @world = import(module:'base/world.mt');
      @:story = import(module:'base/story.mt');
      @:Scene = import(module:'base/scene.mt');            
      @:instance = import(module:'base/instance.mt');
      // the changeling
      when (world.party.members->size == 0) ::<= {
        Scene.start(id:'thechosen:scene_intro_changeling', onDone::{        
          @:changeling = world.island.newInhabitant(
            professionHint : 'base:adventurer',
            levelHint:story.levelHint*2 // the power of a changeling shouldnt be underestimated
          );
          @:Arts = import(:'base/arts.mt');

          changeling.name = '[   ]';
          
          changeling.supportArts = [
            'base:wyvern-prayer',
            'base:quick-shield',
            'base:bloods-summoning',
            'base:shield-amplifier',
            'base:pebble',
            'base:prismatic-wisp',
            'base:b260',
            'base:b177'
          ]->map(::(value) <- Arts.new(base:Arts.database.find(:value)));
          
          @:keyother = Item.new(
            base: Item.database.find(id:'thechosen:wyvern-key-of-fire')
          );
          world.party.inventory.add(:keyother);

          world.party.add(:changeling);
          instance.savestate();
          
          world.island.travel();       
        });  
      }

      world.island.visit()
      if (world.landmark == empty)
        world.island.travel()     
      else ::<= {
        world.island.travelIntoLandmark(landmark:world.landmark);     
      }
      
      
      
      ///////////////////
      /*
      @:Effect = import(:'base/entity/effect.mt');
      @:dump ::(filter, filename) {
        Effect.dumpCSV(
          filter,
          filename,
        
          titles : [
            'Name', 'ID', 'Battle only?', 'Flags', 'Stackable?', 'Addt. block points', 'HP', 'AP', 'ATK', 'DEF', 'INT', 'SPD', 'LUK', 'DEX', 'Description'
          ],
          
          fieldFormatters : {
            ('Name') ::(item) <- item.name,
            ('ID') ::(item) <- item.id,
            ('Flags') ::(item) {
              @:traits = [];
              @trait = item.flags;
              ::? {
                @iter = 0;
                forever ::{
                  when(iter > 12) send();
                  
                  if (trait & (1 << iter)) ::<= {
                    traits->push(:match(iter) {
                      (0): 'Ailment',
                      (1): 'Buff',
                      (2): 'Debuff'
                    });
                    traits->push(:',');
                  }
                  iter += 1;
                }
              }
              return String.combine(:traits);
            },
            ('Stackable?') ::(item) <- if (item.stackable) 'yes' else 'no',
            ('Addt. block points') ::(item) <- if (item.blockPoints == 0) '--' else ''+item.blockPoints,
            ('HP') ::(item) <- if (item.stats.HP == 0) '--' else '%' + item.stats.HP,
            ('AP') ::(item) <- if (item.stats.AP == 0) '--' else '%' + item.stats.AP,
            ('ATK') ::(item) <- if (item.stats.ATK == 0) '--' else '%' + item.stats.ATK,
            ('DEF') ::(item) <- if (item.stats.DEF == 0) '--' else '%' + item.stats.DEF,
            ('INT') ::(item) <- if (item.stats.INT == 0) '--' else '%' + item.stats.INT,
            ('SPD') ::(item) <- if (item.stats.SPD == 0) '--' else '%' + item.stats.SPD,
            ('LUK') ::(item) <- if (item.stats.LUK == 0) '--' else '%' + item.stats.LUK,
            ('DEX') ::(item) <- if (item.stats.DEX == 0) '--' else '%' + item.stats.DEX,
            ('Description') ::(item) <- item.description
          }
        );
      }
      
      dump(filename: 'effects.csv', filter::(value) <- true)
      */



      /*
      @:Arts = import(:'base/arts.mt');
      @:dump ::(filter, filename) {
        Arts.database.dumpCSV(
          filter,
          filename,
          //sort      
          titles : [
            'Name', 'ID', 'Kind', 'Traits', 'Rarity',  'Target mode', 'AI Usage Hint', 'Description', 'Art Specs', 'Deck Role', 'Keywords', 'Keyword Definitions'
          ],
          
          fieldFormatters : {
            ('Description') ::(item) <- item.description,
            ('Keywords') ::(item) <- 
              if (item.keywords->size == 0)
                ''
              else
                item.keywords->reduce(::(previous, value) <- (if (previous == empty) '' else previous) + value +', '),


            ('Keyword Definitions') ::(item) {
              return String.combine(:Arts.generateKeywordDefinitionLines(:item))
            },


            ('Rarity')::(item) <- 
              match(item.rarity) {
                (Arts.RARITY.COMMON): 'Common',
                (Arts.RARITY.UNCOMMON): 'Uncommon',
                (Arts.RARITY.RARE): 'Rare',
                (Arts.RARITY.EPIC): 'Epic'
              },
            ('Art Specs')::(item) <- '',
            ('Deck Role')::(item) <- '',
                        
            ('AI Usage Hint') ::(item) <- 
              match(item.usageHintAI) {
                (Arts.USAGE_HINT.OFFENSIVE): 'Offensive',
                (Arts.USAGE_HINT.HEAL): 'Heal',
                (Arts.USAGE_HINT.BUFF): 'Buff',
                (Arts.USAGE_HINT.DEBUFF): 'Debuff',
                (Arts.USAGE_HINT.DONTUSE): 'Don\'t use'
              },
              
            ('Target mode') ::(item) <- 
              match(item.targetMode) {
                (Arts.TARGET_MODE.ONE): 'One',
                (Arts.TARGET_MODE.ONEPART): 'One (body part)',
                (Arts.TARGET_MODE.ALLALLY): 'All ally',
                (Arts.TARGET_MODE.RANDOM): 'Random',
                (Arts.TARGET_MODE.NONE): 'None',
                (Arts.TARGET_MODE.ALLENEMY): 'All enemy',
                (Arts.TARGET_MODE.ALL): 'Everyone'
              },
          
          
            ('Name') :: (item) <- item.name,
            ('ID') ::(item) <- item.id,
            ('Kind') ::(item) <-
              match(item.kind) {
                (Arts.KIND.ABILITY): 'Ability',
                (Arts.KIND.REACTION): 'Reaction',
                (Arts.KIND.EFFECT): 'Effect',
                (Arts.KIND.FIELD): 'Field'
              },
              
            ('Traits') ::(item) {
              @:traits = [];
              @trait = item.traits;
              ::? {
                @iter = 1;
                forever ::{
                  when(Arts.TRAIT->values->findIndex(:iter) == -1) send();
                  if (trait & iter) ::<= {
                    @name = ::? {
                      foreach(Arts.TRAIT) ::(k, v) {
                        if (v == iter) ::<= {
                          send(:k);
                        }
                      }
                    }
                    
                    if (name) 
                      traits->push(:name + ',' ); 
                  }
                  iter = iter << 1;
                }
              }
              
              return String.combine(:traits);
            }
          }
        );
      }

      dump(filename: 'arts.csv', filter::(value) <- true);
      */
      
      
      
      ///////////////////
      
      
      ///////////////////
      /*
      for(0, 4) ::(i) {
        @:world = import(module:'base/world.mt');
        world.party.queueCollectSupportArt();    
      } 
      */     
      
      
      ////////////////////
      
      /*
      @:world = import(module:'base/world.mt');
      @:enemies = [
        world.island.newInhabitant(),
        world.island.newInhabitant()    
      ];
      
      foreach(enemies) ::(k, v) {
        v.anonymize();
      }
      world.battle.start(
        party: world.party,

        allies: world.party.members,
        enemies,
        landmark: {},
        onStart :: {
        },
        onEnd ::(result) {
          when(world.battle.partyWon()) ::<= { 
          };
            
          @:instance = import(module:'base/instance.mt');
          instance.gameOver(reason:'The party was wiped out.');
        }
      );
      */
      
      
      //////////////////////
      
    },
    
    onDeath ::(data, entity) {
      @:world = import(module:'base/world.mt');
      world.party.remove(member:entity);    
    }
  },
  ignoreHunger : false,
  interactionsPerson : import(:'wyvern-gate.rasa.thechosen/interactionsperson.mt'),
  interactionsLocation : [],
  interactionsLandmark : [],
  interactionsWalk : [
    WyvernGate.Interaction.Common.walk.check,
    WyvernGate.Interaction.Common.walk.party,
    WyvernGate.Interaction.Common.walk.quests,
    WyvernGate.Interaction.Common.walk.inventory,
    WyvernGate.Interaction.Common.walk.eatAMeal,
    WyvernGate.Interaction.Common.walk.wait
  ],
  interactionsBattle : [
    WyvernGate.Interaction.Common.battle.attack,
    WyvernGate.Interaction.Common.battle.arts,
    WyvernGate.Interaction.Common.battle.check,
    WyvernGate.Interaction.Common.battle.item,
    WyvernGate.Interaction.Common.battle.wait,
    WyvernGate.Interaction.Common.battle.log
  ],
  interactionsOptions : [
    WyvernGate.Interaction.Common.options.save,
    WyvernGate.Interaction.Common.options.quickSave,
    WyvernGate.Interaction.Common.options.system,
    WyvernGate.Interaction.Common.options.quit,    
  ],
  
  accolades : import(:'wyvern-gate.rasa.thechosen/accolades.mt'),
  
  reportCard :: {
    @:world = import(module:'base/world.mt');
    return 
      'Knockouts:          ' + world.accoladeCount(name:'knockouts') + '\n' +
      'Murders:            ' + world.accoladeCount(name:'murders') + '\n' +
      'Party members lost: ' + world.accoladeCount(name:'deadPartyMembers') + '\n' +
      'Chests opened:      ' + world.accoladeCount(name:'chestsOpened') + '\n';
    
  },
  
  databaseOverrides ::{
    import(:'wyvern-gate.rasa.thechosen/database_interaction.mt')();
    import(:'wyvern-gate.rasa.thechosen/database_landmark.mt')();
    import(:'wyvern-gate.rasa.thechosen/database_location.mt')();
    import(:'wyvern-gate.rasa.thechosen/database_effect.mt')();
    import(:'wyvern-gate.rasa.thechosen/database_item.mt')();
    import(:'wyvern-gate.rasa.thechosen/database_scene.mt')();
    import(:'wyvern-gate.rasa.thechosen/database_island.mt')();
    import(:'wyvern-gate.rasa.thechosen/database_species.mt')();
    import(:'wyvern-gate.rasa.thechosen/database_profession.mt')();
  }
}


return { 
  onGameStartup ::{
  },

  onDatabaseStartup :: {
    Scenario.database.newEntry(data:TheChosen);
  }
}
