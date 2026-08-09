@:WyvernGate = import(:'wyvern-gate.mt');

@:Location = WyvernGate.Map.Location
@:world = WyvernGate.World
@:Arts = WyvernGate.Arts
@:windowEvent = WyvernGate.Core.WindowEvent

return ::{
  Location.database.newEntry(data:{
    name: 'Next Floor?',
    id: 'thechosen:final-stairs',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '/',

    descriptions: [
      "Significant-looking stairs.",
    ],
    interactions : [
      'thechosen:final-stairs',
    ],
    
    aggressiveInteractions : [
    ],
    traits : Location.TRAIT.ONE_PER_LANDMARK | Location.TRAIT.EXIT_HINT,

    
    events : {
      onInteract ::(location) {
        @:world = import(module:'base/world.mt');
        return true;
      },
      
      onCreate ::(location) {
        location.contested = true;
      }
    }
  })   


  Location.database.newEntry(data:{
    name: 'Wyvern Throne of Fire',
    id: 'thechosen:throne-fire',
    rarity: 1,
    ownVerb : 'owned',
    symbol: 'W',

    descriptions: [
      "What seems to be a stone throne",
    ],
    interactions : [
      'base:talk',
      'base:examine'
    ],
    
    aggressiveInteractions : [
    ],

    traits : Location.TRAIT.ONE_PER_LANDMARK,
    
    events : {
      
      onCreate ::(location) {
        location.name = 'Wyvern Throne';
        @:Profession = import(module:'base/entity/profession.mt');
        @:Species = import(module:'base/entity/species.mt');
        @:Story = import(module:'base/story.mt');
        @:Scene = import(module:'base/scene.mt');
        @:StatSet = import(module:'base/util/statset.mt');
        location.ownedBy = location.landmark.island.newInhabitant(
          speciesHint : 'thechosen:wyvern-of-fire',
          professionHint: 'thechosen:wyvern-of-fire'
        );
        location.ownedBy.supportArts = [
          'base:bloods-summoning',
          'base:banishing-light'
        ]->map(::(value) <- Arts.new(base:Arts.database.find(:value)));
        location.ownedBy.name = 'Wyvern of Fire';
        location.ownedBy.removeAllProfessionArts();
        for(0, location.ownedBy.profession.arts->size) ::(i) {
          location.ownedBy.autoLevelProfession(:location.ownedBy.profession);                      
        }
        location.ownedBy.equipAllProfessionArts();


        location.ownedBy.overrideInteractID = 'thechosen:wyvern-of-fire';
        location.ownedBy.heal(amount:9999, silent:true); 
        location.ownedBy.healAP(amount:9999, silent:true); 
      }
    }
  })

  Location.database.newEntry(data:{
    name: 'Stairs Down',
    id: 'thechosen:stairs-down',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '\\',
    traits : Location.TRAIT.ONE_PER_LANDMARK,

    descriptions: [
      "Decrepit stairs",
    ],
    interactions : [
      'thechosen:next-floor',
    ],
    
    aggressiveInteractions : [
    ],
    onStep ::(entities, location){},

    events : {
    
      onInteract ::(location) {
        @open = location.isUnlockedWithPlate();
        if (!open)  
          windowEvent.queueMessage(text: 'The entry to the stairway is locked. Perhaps some lever or plate nearby can unlock it.');
        return open;      
      }
    }
  })


  Location.database.newEntry(data:{
    name: 'Wyvern Throne of Ice',
    id: 'thechosen:throne-ice',
    rarity: 1,
    ownVerb : 'owned',
    symbol: 'W',
    traits : Location.TRAIT.ONE_PER_LANDMARK,

    descriptions: [
      "What seems to be a stone throne",
    ],
    interactions : [
      'base:talk',
      'base:examine'
    ],
    
    aggressiveInteractions : [
    ],

    
    events : {
      
      onCreate ::(location) {
        location.name = 'Wyvern Throne';
        @:Profession = import(module:'base/entity/profession.mt');
        @:Species = import(module:'base/entity/species.mt');
        @:Story = import(module:'base/story.mt');
        @:Scene = import(module:'base/scene.mt');
        @:StatSet = import(module:'base/util/statset.mt');
        location.ownedBy = location.landmark.island.newInhabitant(
          speciesHint : 'thechosen:wyvern-of-ice',
          professionHint: 'thechosen:wyvern-of-ice'
        );
        
        location.ownedBy.supportArts = [
          'base:bloods-shield',                  
          'base:bloods-exaltation',                  
          'base:bloods-summoning',
          'base:banishing-light'
        ]->map(::(value) <- Arts.new(base:Arts.database.find(:value)));  
        location.ownedBy.name = 'Wyvern of Ice';
        location.ownedBy.removeAllProfessionArts();
        for(0, location.ownedBy.profession.arts->size) ::(i) {
          location.ownedBy.autoLevelProfession(:location.ownedBy.profession);                      
        }
        location.ownedBy.equipAllProfessionArts();

        
        location.ownedBy.overrideInteractID = 'thechosen:wyvern-of-ice';
        location.ownedBy.heal(amount:9999, silent:true); 
        location.ownedBy.healAP(amount:9999, silent:true); 

        



      }
    }
  })


  Location.database.newEntry(data:{
    name: 'Wyvern Throne of Thunder',
    id: 'thechosen:throne-thunder',
    rarity: 1,
    ownVerb : 'owned',
    symbol: 'W',
    traits : Location.TRAIT.ONE_PER_LANDMARK,

    descriptions: [
      "What seems to be a stone throne",
    ],
    interactions : [
      'base:talk',
      'base:examine'
    ],
    
    aggressiveInteractions : [
    ],

    
    events : {
      
      
      onCreate ::(location) {
        location.name = 'Wyvern Throne';
        @:Profession = import(module:'base/entity/profession.mt');
        @:Species = import(module:'base/entity/species.mt');
        @:Story = import(module:'base/story.mt');
        @:Scene = import(module:'base/scene.mt');
        @:StatSet = import(module:'base/util/statset.mt');
        @:Entity = import(module:'base/entity.mt');
        location.ownedBy = location.landmark.island.newInhabitant(
          speciesHint : 'thechosen:wyvern-of-thunder',
          professionHint: 'thechosen:wyvern-of-thunder'
        );
        
        location.ownedBy.name = 'Wyvern of Thunder';
        location.ownedBy.supportArts = [
          'base:bloods-shield',                  
          'base:bloods-exaltation',                  
          'base:bloods-summoning',
          'base:banishing-light'
        ]->map(::(value) <- Arts.new(base:Arts.database.find(:value))); 
        location.ownedBy.removeAllProfessionArts();
        for(0, location.ownedBy.profession.arts->size) ::(i) {
          location.ownedBy.autoLevelProfession(:location.ownedBy.profession);                      
        }
        location.ownedBy.equipAllProfessionArts();

        
        location.ownedBy.overrideInteractID = 'thechosen:wyvern-of-thunder';
        location.ownedBy.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
        location.ownedBy.heal(amount:9999, silent:true); 
        location.ownedBy.healAP(amount:9999, silent:true); 

        



      }
    }
  })

  Location.database.newEntry(data:{
    name: 'Wyvern Throne of Light',
    id: 'thechosen:throne-light',
    rarity: 1,
    ownVerb : 'owned',
    symbol: 'W',
    traits : Location.TRAIT.ONE_PER_LANDMARK,

    descriptions: [
      "What seems to be a stone throne",
    ],
    interactions : [
      'base:talk',
      'base:examine'
    ],
    
    aggressiveInteractions : [
    ],


    
    events : {        
      onCreate ::(location) {
        location.name = 'Wyvern Throne';
        @:Profession = import(module:'base/entity/profession.mt');
        @:Entity = import(module:'base/entity.mt');
        @:Species = import(module:'base/entity/species.mt');
        @:Story = import(module:'base/story.mt');
        @:Scene = import(module:'base/scene.mt');
        @:StatSet = import(module:'base/util/statset.mt');
        location.ownedBy = location.landmark.island.newInhabitant(
          speciesHint : 'thechosen:wyvern-of-light',
          professionHint: 'thechosen:wyvern-of-light'
        );
        
        location.ownedBy.supportArts = [
          'base:bloods-shield',                  
          'base:bloods-exaltation',                  
        ]->map(::(value) <- Arts.new(base:Arts.database.find(:value)));  
        location.ownedBy.name = 'Wyvern of Light';
        location.ownedBy.removeAllProfessionArts();
        for(0, location.ownedBy.profession.arts->size) ::(i) {
          location.ownedBy.autoLevelProfession(:location.ownedBy.profession);                      
        }
        location.ownedBy.equipAllProfessionArts();

        
        location.ownedBy.overrideInteractID = 'thechosen:wyvern-of-light'
        
        location.ownedBy.unequip(slot:Entity.EQUIP_SLOTS.HAND_LR, silent:true);
        location.ownedBy.heal(amount:9999, silent:true); 
        location.ownedBy.healAP(amount:9999, silent:true); 

        



      }
    }
  })




  Location.database.newEntry(data:{
    name: 'Stairs Up',
    id: 'thechosen:stairs-up',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: '\\',
    traits : Location.TRAIT.ONE_PER_LANDMARK | Location.TRAIT.EXIT_HINT,

    descriptions: [
      "Decrepit stairs",
    ],
    interactions : [
      'thechosen:darklair-up',
    ],
    
    aggressiveInteractions : [
    ],

    
    events : {
      onInteract ::(location) {
        @open = location.isUnlockedWithPlate();
        if (!open)  
          windowEvent.queueMessage(text: 'The entry to the stairway is locked. Perhaps some lever or plate nearby can unlock it.');
        return open;      
      }
    }
  })


  Location.database.newEntry(data:{
    name: 'Foreboding Entrance',
    id: 'thechosen:foreboding-entrance',
    rarity: 1000000000000,
    ownVerb : '',
    symbol: ' ',
    traits : Location.TRAIT.ONE_PER_LANDMARK | Location.TRAIT.ENTRANCE_HINT,

    descriptions: [
      "An entrance to a place that seems to welcome you eerily. It makes you feel uneasy.",
    ],
    interactions : [
      'next floor',
    ],
    
    aggressiveInteractions : [
    ],

    
    events : {
    }
  })
}

