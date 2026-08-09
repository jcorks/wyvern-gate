@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'core/data/database.mt');
@:StatSet = import(module:'base/util/statset.mt');
@:windowEvent = import(module:'core/windowevent.mt');
@:Damage = import(module:'base/entity/damage.mt');
@:Item = import(module:'base/item.mt');
@:correctA = import(module:'base/util/correcta.mt');
@:random = import(module:'core/random.mt');
@:canvas = import(module:'core/graphics/canvas.mt');
@:namegen = import(module:'base/namegen.mt');
@:LoadableClass = import(module:'core/data/loadableclass.mt');
@:databaseItemMutatorClass = import(module:'core/data/databaseitemmutatorclass.mt');
@:InteractionMenuEntry = import(module:'base/interaction/menuentry.mt');
@:commonInteractions = import(module:'base/interaction/common.mt');
@:Personality = import(module:'base/entity/personality.mt');
@:g = import(module:'base/util/g.mt');
@:Accolade = import(module:'base/accolade.mt');
@:loading = import(module:'base/widgets/loading.mt');
@:romanNum = import(module:'base/util/romannumerals.mt');
@:ParticleEmitter = import(module:'core/graphics/particle.mt');
@:Landmark = import(module:'base/map/landmark.mt');
@:Island = import(module:'base/map/island.mt');
@:Species = import(module:'base/entity/species.mt');
@:LandmarkEvent = import(module:'base/event/landmark.mt');
@:DungeonMap = import(:'base/map/dungeon.mt');
@:Profession = import(module:'base/entity/profession.mt');
@:Arts = import(module:'base/arts.mt');
@:Entity = import(module:'base/entity.mt');
@:Location = import(module:'base/map/location.mt');
@:State = import(module:'core/data/state.mt');
@:Inventory = import(module:'base/item/inventory.mt');
@:world = import(module:'base/world.mt');
@:pickItem = import(:'base/widgets/pickitem.mt');
@:Interaction = import(module:'base/interaction.mt');

return ::(onDone) {
  windowEvent.queueMessage(
    text: 'Who are you?'
  );
  
  @species = Species.getRandomFiltered(::(value) <- (value.traits & Species.TRAIT.SPECIAL) == 0)
  @profession = Profession.getRandomFiltered(::(value) <- value.learnable)
  @name = namegen.person();
  @arts = [
    Arts.database.getRandomFiltered(::(value) <- (value.traits & Arts.TRAIT.SPECIAL) == 0),
    Arts.database.getRandomFiltered(::(value) <- (value.traits & Arts.TRAIT.SPECIAL) == 0),
    Arts.database.getRandomFiltered(::(value) <- (value.traits & Arts.TRAIT.SPECIAL) == 0)  
  ];

  @:choiceActions = [
    'Choose Name', :: {
      windowEvent.queueMessage(
        text:'Please choose a name.'
      );
      
      windowEvent.queueChoices(
        onGetPrompt::<- 'Name: ' + name,
        choicesMatch : [
          'Choose one for me', ::<- name = namegen.person(),
          'Enter name...', ::<- name = (import(:'base/widgets/name.mt'))()
        ],
        canCancel : true

      );
    
    },


    
    'Choose Species', :: {
      windowEvent.queueMessage(
        text:'Please choose a species.'
      );
      
      @:choices = Species.getAllFiltered(::(value) <- (value.traits & Species.TRAIT.SPECIAL) == 0)
      @:choicesMarked = choices->map(::(value) <-
        if (value == species) 
          '[*]'
        else  
          '   '
      );

      @:choicesColumns = import(:'base/widgets/choicescolumns.mt');
      choicesColumns(
        leftJustified : [true, true],
        onGetPrompt::<- 'Species:' + species.name,
        onGetChoices::<- [
          choices->map(::(value) <- value.name),
          choicesMarked
        ],
        separator : '',
        canCancel: true,
        onChoice::(choice) {
          species = choices[choice-1];
        }
      );      
    },

    // Profession
    'Choose Profession', :: {
      windowEvent.queueMessage(
        text:'Please choose a profession.'
      );
      
      @:choices = Profession.getAllFiltered(::(value) <- value.learnable)
      @:choicesMarked = choices->map(::(value) <-
        if (value == species) 
          '[*]'
        else  
          '   '
      );


      @:choicesColumns = import(:'base/widgets/choicescolumns.mt');
      choicesColumns(
        leftJustified : [true, true],
        onGetPrompt::<- 'Profession:' + profession.name,
        onGetChoices::<- [
          choices->map(::(value) <- value.name),
          choicesMarked
        ],
        separator : '',
        canCancel: true,
        onChoice::(choice) {
          profession = choices[choice-1];
        }
      );      
    },


    /*
    :: {
      windowEvent.queueMessage(
        text:'Select 3 Arts to start with.'
      );
      
      @:choices = Profession.getAllFiltered(::(value) <- (value.traits & Profession.TRAIT.SPECIAL) == 0)
      @:choicesMarked = choices->map(::(value) <-
        if (value == species) 
          '[*]'
        else  
          '   '
      );

     
    }
    */
    
    'Proceed', ::{
      windowEvent.queueAskBoolean(
        prompt: 'Are you ready, ' + name + ', the ' + species.name + ' ' + profession.name + '?',
        onChoice::(which) {
          when(which == true) ::<= {
            windowEvent.jumpToTag(
              name: 'THEROGUESETUP',
              goBeforeTag: true
            );
            onDone(::<={
              @world = import(module:'base/world.mt');
              @:entity = Entity.new(
                professionHint : profession.id,
                speciesHint: species.id,
                levelHint: 6,
                name : name
              );

              entity.autoLevelProfession(:entity.profession);
              entity.autoLevelProfession(:entity.profession);


              entity.equipAllProfessionArts();  
              ::? {
                forever ::{
                  if (entity.calculateDeckSize() >= 35) send();

                  entity.supportArts->push(:
                    Arts.database.getRandomFiltered(::(value) <- 
                      ((value.traits & Arts.TRAIT.SPECIAL) == 0)
                      &&
                      ((value.traits & Arts.TRAIT.SUPPORT) != 0)
                    ).id
                  );
                }
              }
              
              
              return entity;
            });
          }
        }
      );
    }

    
  ]
  
  windowEvent.queueChoices(
    onGetPrompt ::<-  name + ', the ' + species.name + ' ' + profession.name,
    choicesMatch : choiceActions,
    canCancel : false,
    keep:true,
    jumpTag: 'THEROGUESETUP'
  );
}
