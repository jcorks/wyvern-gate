@:WyvernGate = import(:'wyvern-gate.mt');
@:Item = WyvernGate.Item
@:world = WyvernGate.World
@:story = WyvernGate.Story
@:StatSet = WyvernGate.Util.StatSet
@:windowEvent = WyvernGate.Core.WindowEvent
@:loading = WyvernGate.Widgets.Loading
@:random = WyvernGate.Core.Random
@:instance = WyvernGate.Instance
@:canvas = WyvernGate.Core.Graphics.Canvas
@:namegen = WyvernGate.NameGen

@:party = world.party

return ::{
  @:keyhome = Item.new(
    base: Item.database.find(id:'base:wyvern-key')
  );
  keyhome.name = 'Key: Home (rusty)';
  keyhome.price = 30;
  

  // Whether the initial box has been opened.
  world.scenario.data.openedSentimentalBox = false;

  // Whether the wyvern of fire was defeated in combat
  world.scenario.data.fireWyvernDefeated = false;

  // Whether the wyvern of ice was defeated in combat
  world.scenario.data.iceWyvernDefeated = false;

  // Whether the wyvern of thunder was defeated in combat
  world.scenario.data.thunderWyvernDefeated = false;

  // Whether the wyvern of light was defeated in combat
  world.scenario.data.lightWyvernDefeated = false;



  @:onMapLoad ::(island) {
    party.reset();
    @:island = world.island;

    party.inventory.add(:keyhome);


    @:keyother = Item.new(
      base: Item.database.find(id:'thechosen:wyvern-key-of-fire')
    );
    party.inventory.add(:keyother);

/*
for(0, 10) ::(i) {
  @:test = Item.new(
    base: Item.database.getRandomFiltered(::(value) <- value.hasTraits(:Item.TRAIT.CAN_BE_APPRAISED))
  );
  test.setInletSlots(:6);
  party.inventory.add(:test);
}

for(0, 10) ::(i) {
  @:test = Item.new(
    base: Item.database.find(:'base:inlet-gem')
  );
  party.inventory.add(:test);
}
*/
    


/*
for(0, 4) ::(i) {
  @:key = Item.new(
    base: Item.database.find(id:'base:wyvern-key')
  );
  @:name = namegen.island();
  key.setIslandGenTraits(
    nameHint:name, 
    levelHint:story.levelHint,
    extraLandmarks : [
      'thechosen:shrine-of-fire'
    ],
    tierHint: 0  
  )  
  key.name = 'Key of ' + name;
  party.inventory.add(:key);  
}
*/


// debug


/*
island.tier = 10;
party.inventory.maxItems = 300;
for(0, 10) ::(i) {
  @:test = Item.new(
    base: Item.database.getRandomFiltered(::(value) <- value.hasTraits(:Item.TRAIT.CAN_BE_APPRAISED))
  );

  party.inventory.add(:test.appraise());
}
for(0, 70) ::(i) {
  @:test = Item.new(
    base: Item.database.getRandom()
  );

  party.inventory.add(:test);
}
*/

//party.inventory.addGold(amount:100000);



    
    // since both the party members are from this island, 
    // they will already know all its locations
    foreach(island.landmarks)::(index, landmark) {
      landmark.discover(); 
    }
    
    
    
    @:Species = import(module:'base/entity/species.mt');
    @:Profession = import(module:'base/entity/profession.mt');
    @:choices = [];
    @:chosenProfs = []
    
    for(0, 5) ::(i) {
      @:prof = Profession.getRandomFiltered(::(value) <- 
        ((value.traits & Profession.TRAIT.NON_COMBAT) == 0) && 
        value.learnable &&
        chosenProfs[value.id] != true
      ).id;
      
      chosenProfs[prof] = true;
      @:p0 = island.newInhabitant(
        levelHint:story.levelHint-1,
        professionHint: prof
      );
      p0.stats.load(:p0.stats.add(:StatSet.new(
      )).save());



      
      if (p0.stats.HP < 10) ::<= {
        @:stats = p0.stats.save();
        stats.HP = 10;
        p0.stats.load(:stats);
      }
      p0.heal(amount:999999, silent:true);
      choices->push(value:p0);
    }



    // debug
      /*
      party.inventory.add(item:Item.new(
        base:Item.database.find(id:'base:knowledge-stone')
      ));

      //party.inventory.add(item:Item.database.find(id:'Pickaxe'
      //).new(from:island.newInhabitant(),rngEnchantHint:true));
      
      @:story = import(module:'base/story.mt');
      
      party.inventory.addGold(amount:20000);
      


      

      @:story = import(module:'base/story.mt');
      

      

      party.inventory.maxItems = 50
      */
      
      


      
      /*
      @:sword = Item.new(
        base: Item.database.find(id:'Glaive'),
        materialHint: 'Ray',
        qualityHint: '[  ]',
        rngEnchantHint: false
      );

      @:tome = Item.new(
        base:Item.database.find(id:'Tome'),
        materialHint: 'Ray',
        qualityHint: '[  ]',
        rngEnchantHint: false,
        abilityHint: 'Cure'
      );
      party.inventory.add(item:sword);
      party.inventory.add(item:tome);
      */
      

      /*
      @:pan = Item.new(
        base:Item.database.find(id:'Frying Pan'),
        materialHint: 'Crystal',
        qualityHint: 'Divine',
        rngEnchantHint: true
      );
      party.inventory.add(item:pan);
      */


    
    
    /*
    windowEvent.queueMessage(
      text: '... As it were, today is the beginning of a new adventure.'
    );


    windowEvent.queueMessage(
      text: '' + party.members[0].name + ' and their faithful companion ' + party.members[1].name + ' have decided to leave their long-time home of ' + island.name + '. Emboldened by countless tales of long lost eras, these 2 set out to discover the vast, mysterious, and treacherous world before them.'
    );

    windowEvent.queueMessage(
      text: 'Their first task is to find a way off their island.\nDue to their distances and dangerous winds, travel between sky islands is only done via the Wyvern Gates, ancient portals of seemingly-eternal magick that connect these islands.'
    );
    
    windowEvent.queueMessage(
      text: party.members[0].name + ' has done the hard part and acquired a key to the Gate.\nAll thats left is to go to it and find where it leads.'
    );
    */


    windowEvent.queueMessage(
      text: 'Before it begins, we must decide who will be venturing on their journey.'
    )

    windowEvent.queueMessage(
      text: 'Who will it be?'
    );
    

    
    @:extendedName::(entity) {
      return 'the ' + entity.species.name + ' ' + entity.profession.name
    }
    
    @:finish ::{
      windowEvent.queueMessage(
        text: 'Upon certain events, the game will save automatically. However, it is encouraged to save often.'
      );
    
    
      loading(
        message: 'Saving...',
        do :: {
          /*
          @:basicArts = [
            'base:pebble',
            'base:parry',
            'base:block'
            
            //////////////

            //////////////
          ];

          party.members->foreach(::(k, v) {
            v.supportArts = basicArts->map(::(value) <- Arts.new(base:Arts.database.find(:value)))
          });
          */
          @town
          foreach(island.landmarks) ::(k, v) {
            if (v.base.id == 'base:town-start')
              town = v;
          }
        
          @somewhere = random.scrambled(:island.map.areas)[0]
          
     
          
          instance.savestate();

          @:Scene = import(module:'base/scene.mt');
          Scene.start(id:'thechosen:scene_intro', onDone::{          
          //Scene.start(id:'thechosen:scene_wyvernlight1_quest', onDone ::{
            canvas.freeze();
            world.island.visit()
            world.island.travel(onReady::{
              
              world.island.map.setPointer(x:town.x, y:town.y);
              town.visit();
              town.travel(
                skipAnimation: true,
                onReady ::(landmark) {
                  @:which = town.locations->filter(::(value) <- value.portal != empty && value.portal.destinationLandmarkDatabaseID == 'base:home-inside-start')[0];
                  town.map.setPointer(x: which.x, y: which.y);
                  which.portal.use(
                    skipAnimation : true,
                    onLoad::{
                      ::? {
                        foreach(world.landmark.locations) ::(k, loc) {
                          if (loc.base.id == 'base:bed') {
                            world.landmark.map.setPointer(
                              x: loc.x,
                              y: loc.y
                            );
                          }
                        }
                      }
                    },
                    onReady :: {
                      windowEvent.queueCustom(
                        onEnter ::{
                          canvas.thaw();
                        }
                      );

                      
                      windowEvent.queueMessage(
                        speaker: party.members[0].name,
                        text: '"..."'
                      );

                      windowEvent.queueMessage(
                        speaker: party.members[0].name,
                        text: '"I must have dozed off... What a strange dream..."'
                      );

                      windowEvent.queueMessage(
                        speaker: party.members[0].name,
                        text: '"..."'
                      );

                      windowEvent.queueMessage(
                        speaker: party.members[0].name,
                        text: '"...Huh? A Key? Maybe it wasn\'t a dream..."'
                      );


                      windowEvent.queueMessage(
                        speaker: party.members[0].name,
                        text: '"Maybe now is the time to open that box in storage... Right, I can get to the bank from the other room."'
                      );  
                    }
                  );
  
                }
              )
            
            });            
          });    
        }
      )
    }
  
    @:confirmParty ::{
      windowEvent.queueAskBoolean(
        renderable : {
          render ::{
            canvas.renderTextFrameGeneral(
              topWeight: 0.2,
              leftWeight: 0.5,
              lines : [
                'Current party:',
                '',              
                extendedName(entity:p0)
              ]
            )
          }
        },
        topWeight: 0.65,
        leftWeight: 0.5,
        prompt: 'Continue with this party?',
        onChoice::(which) {
          when(which == false) ::<= {
            p0 = empty;
            chooseMember();
            windowEvent.jumpToTag(name:'ChooseMember', goBeforeTag:true, doResolveNext:true);
          }
                    
          party.add(member:p0);
          finish();
          windowEvent.jumpToTag(name:'ChooseMember', goBeforeTag:true, doResolveNext:true);
        }
        
      );
    }



    // choose party members
    @hovered;
    @p0;
    
    @whatDoStatsMean ::{
      windowEvent.queueReader(
        prompt: 'What are stats?',
        lines: [
          "Stats are the basic qualities that everyone has. They determine the person's ability to face a variety of challenges.",
          "",
          "HP - This stat indicates how much a person can withstand before succumbing to a knockout. The higher this stat, the more damage they can withstand.",
          "",
          "AP - This stat indicates how often a person can use special abilities. The higher this stat, the more a person can do outside of normal actions.",
          "",
          "ATK - This stat measures the physical strength a person possesses. The higher this stat, the more physical damage this person can do to foes",
          "",
          "DEF - This stat measures how likely a person's will be able to avoid harm. The higher this stat, the more likely a person will be able to shrug off an attack entirely.",
          "",
          "INT - This stat measures the intellect and intuition of a person. The higher this stat, the more a user is aware of the world around them. Certain abilities, such as spells, will benefit from this as well.",
          "",
          "SPD - This stat measures how fast a person can move. The higher this stat, the more apt they are at acting before others.",
          "",
          "LUK - This stat measures how lucky a person is. The higher this stat, the more a person may get out of difficult situations.",
          "",
          "DEX - This stat measures the precision and grace with which a person acts. The higher this stat, the more likely an attack will pierce through defenses.",
          "",
          "All stats are important, but some stats may be more important at times than others."          
        ]
      );
    };
    

    @:chooseMember ::{
      @:choicesMod = [...choices]->filter(by::(value) <- value != p0);

      @:choiceNames = [...choicesMod]->map(to:::(value) {
        return value.name;
      });

      @:choiceTitles = [...choicesMod]->map(to:::(value) {
        return extendedName(entity:value);  
      });

      if (p0 != empty) ::<= {
        choiceNames->push(value:'No one.');
        choiceTitles->push(value:'');
      }
      @:choicesColumns = import(module:'base/widgets/choicescolumns.mt');
    
      
      choicesColumns(
        canCancel : true,
        columns : [
          choiceNames,
          choiceTitles
        ],
        leftJustified: [
          true,
          true
        ],
        topWeight: 0.5,
        leftWeight: 0.5,
        keep:true,
        disableFrame: true,
        skipAnimation: true,
        jumpTag: 'ChooseMember',        
        onCancel ::{
          if (p0 != empty) p0 = empty;
          chooseMember();
        },
        
        renderable : {
          render :: {
            when(hovered == empty) empty;
            when (hovered == choicesMod->size) empty

            canvas.renderTextFrameGeneral(
              topWeight: 0.5,
              leftWeight: 1,
              title: 'Stats',
              lines: choicesMod[hovered].stats.description->split(token:'\n')
            );          
          }
        },
        onHover::(choice) {
          hovered = choice-1;
        },
        onChoice::(choice) {
          when (choice-1 == choicesMod->size) ::<= {
            windowEvent.queueMessage(
              text: 'Continuing with only one party member is a bold move. You may find others to join them later, but the journey may be more difficult.'
            );
            
            windowEvent.queueAskBoolean(
              prompt: 'Continue with just one party member?',
              onChoice::(which) {
                when(which == false) empty;
                confirmParty();
              }
            );
          }
        
          @:next = choicesMod[choice-1];
          windowEvent.queueChoices(
            prompt: extendedName(entity:next),
            choicesMatch : [
              'Describe', ::<- next.describe(excludeStats:true),
              'What do the stats mean?', ::<- whatDoStatsMean(),
              'Choose', ::<- windowEvent.queueAskBoolean(
                prompt: 'Add ' + next.name + ' to the party?',
                onChoice::(which) {
                  when(which == false) empty;
                  p0 = next;
                  confirmParty();
                }
              )
            ],
            canCancel:true
          );
        }    
      )
    }
    chooseMember();
  }


  keyhome.setIslandGenTraits(
    nameHint:namegen.island(), 
    levelHint:story.levelHint,
    idHint: 'base:starting-island',
    tierHint: 0  
  )
  world.loadIsland(key:keyhome, onDone:onMapLoad);
}
