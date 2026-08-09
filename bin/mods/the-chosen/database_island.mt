
@:WyvernGate = import(:'wyvern-gate.mt');
@:Island = WyvernGate.Map.Island

return ::{
  Island.database.newEntry(
    data : {
      id : 'thechosen:island-of-fire',
      requiredLandmarks : [
        'thechosen:shrine-of-fire',
        'base:wyvern-gate',
      ],
      possibleLandmarks : [
        
      ],
      minAdditionalLandmarkCount : 0,
      maxAdditionalLandmarkCount : 0,
      minSize : 20,//80,
      maxSize : 20, //130,
      events : [
        
      ],
      possibleSceneryCharacters : [
        '^', '^', '^', '^', '^'
      ],
      
      traits : Island.TRAIT.DIVERSE | Island.TRAIT.SPECIAL,
      
      overrideSpecies : empty,
      overrideNativeCreatures : empty,
      overridePossibleEvents : empty,
      overrideClimate : empty,  
    }
  )    
  
  Island.database.newEntry(
    data : {
      id : 'thechosen:island-of-ice',
      requiredLandmarks : [
        'thechosen:shrine-of-ice',
        'base:wyvern-gate',
      ],
      possibleLandmarks : [
        
      ],
      minAdditionalLandmarkCount : 0,
      maxAdditionalLandmarkCount : 0,
      minSize : 30,//80,
      maxSize : 40, //130,
      events : [
        
      ],
      possibleSceneryCharacters : [
        '_', '-', '~', '-', '-'
      ],
      
      traits : Island.TRAIT.DIVERSE | Island.TRAIT.SPECIAL,
      
      overrideSpecies : empty,
      overrideNativeCreatures : empty,
      overridePossibleEvents : empty,
      overrideClimate : empty,  
    }
  )    


  Island.database.newEntry(
    data : {
      id : 'thechosen:island-of-thunder',
      requiredLandmarks : [
        'thechosen:shrine-of-thunder',
        'base:wyvern-gate',
      ],
      possibleLandmarks : [
        
      ],
      minAdditionalLandmarkCount : 0,
      maxAdditionalLandmarkCount : 0,
      minSize : 30,//80,
      maxSize : 40, //130,
      events : [
        
      ],
      possibleSceneryCharacters : [
        '.', '.', '.', '.', '.'
      ],
      
      traits : Island.TRAIT.DIVERSE | Island.TRAIT.SPECIAL,
      
      overrideSpecies : empty,
      overrideNativeCreatures : empty,
      overridePossibleEvents : empty,
      overrideClimate : empty,  
    }
  )

  Island.database.newEntry(
    data : {
      id : 'thechosen:island-of-light',
      requiredLandmarks : [
        'thechosen:shrine-of-light',
        'base:wyvern-gate',
      ],
      possibleLandmarks : [
        
      ],
      minAdditionalLandmarkCount : 0,
      maxAdditionalLandmarkCount : 0,
      minSize : 30,//80,
      maxSize : 40, //130,
      events : [
        
      ],
      possibleSceneryCharacters : [
        '^', '^', '^', '^', '^'
      ],
      
      traits : Island.TRAIT.DIVERSE | Island.TRAIT.SPECIAL,
      
      overrideSpecies : empty,
      overrideNativeCreatures : empty,
      overridePossibleEvents : empty,
      overrideClimate : empty,  
    }
  )    
  


}
