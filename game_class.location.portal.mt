@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:Location = import(:'game_mutator.location.mt');
@:Landmark = import(:'game_mutator.location.mt');
// Helper class for Locations that controls
// portal mechanics.
@:Portal = LoadableClass.create(
  name: 'Wyvern.Portal',
  items : {
    // list of chain items or empty.
    chainItems : empty,
    
    // cached linked portal id, used for identifying 
    // a corresponding portal.
    linkedPortalID : '',
        
    destinationWorldID: -1,
    
    // whether this was created by a use() [the initiator] or a linkEnd() [the reactor]
    isPortalExit : false,

    // ID of the landmark database item to link to
    id : '',
    
  },
  define::(this, state) {
    @location;
    
    // used as an intermediate for 
    // loading portals.
    @targetLandmark = empty;
    
      
    @:setupLandmark :: {
      @:island = location.landmark.island;
      if (targetLandmark == empty)
        error(:'Target landmark should never be empty while setting up');

      targetLandmark.loadContent();
      
      // now find corresponding linkedPortalID
      @:targetPortal = ::? {
        foreach(targetLandmark.locations) ::(i, locationIter) {
          if (locationIter.data.linkedPortalID == state.linkedPortalID)
            send(:locationIter);
        }
      }
      
      when(targetPortal == empty)
        error(:'Portal landmark creation encountered an error: target portal in created landmark could not be found. this locations data.linkedPortalID must match one within the newly created landmark that this portal created.')
      

      state.destinationWorldID = targetPortal.worldID;
      
      targetPortal.data.linkedPortalLandmarkID = location.landmark.base.id;
      breakpoint();
      targetPortal.portal.linkEnd(
        locationWorldID : location.worldID
      )
    }          
    
  
    this.interface = {
      initialize ::(parent) {
        location = parent;
      },
      
      // parent -> location that owns this portal 
      // landmarkID -> landmark database id for the id to create
      defaultLoad ::(parent, landmarkID) {
        location = parent; 
        state.id = landmarkID;
        state.linkedPortalID = location.data.linkedPortalID;

        if (state.linkedPortalID == empty || state.linkedPortalID->type != String)
          error(:'Portal.data must contain a linkedPortalID (String) to identify which portal location within the target the party should teleport to when teleporting.');
        
      },


      // adds a location to trigger portal resolving 
      // once it is done for this location.
      // This makes it so that the "other" portal 
      // will point to the same landmark as this portal
      addChainItem::(other => Location.type) {
        if (other.base.id != 'base:portal')
          error(:'This is only relevant for base:portal locations');

          
        if (state.chainItems == empty)
          state.chainItems = [];
          
        state.chainItems->push(:other.worldID);
      },
      
      
      // The location tethered to this portal (the endpoint of the portal)
      destinationWorldID :{
        get ::<-  state.destinationWorldID      
      },
      
      destinationLandmarkDatabaseID : {
        get ::<- state.id
      },


      use ::(skipAnimation, onLoad, onReady) {
        @:Landmark = import(module:'game_mutator.landmark.mt');

        if (targetLandmark == empty) {
          @:landmark = Landmark.new(
            data : location.data.data,
            base : Landmark.database.find(:state.id)
          );  
          location.landmark.island.addLandmark(landmark, unmapped: true);  
          targetLandmark = landmark;
        }
    
        @:world = import(module:'game_singleton.world.mt');
        @:currentLandmark = world.landmark
        
        targetLandmark.visit();
        targetLandmark.travel(
          startAnimationRenderable : currentLandmark.map,
          skipAnimation, 
          onLoad ::(landmark) { 
            if (state.destinationWorldID == -1) ::<= {
              if (state.chainItems != empty) ::<= {
                foreach(state.chainItems) ::(k, v) {
                  @:loc = location.landmark.island.findLocation(:v);
                  loc.portal.linkChain(:landmark);
                }
              }
              setupLandmark();
            }
          
            // find referred to landmark
            @:target = ::? {
              foreach(location.landmark.island.landmarks) ::(k, landmark) {
                foreach(landmark.locations) ::(k, loc) {
                  when(loc == location) empty;
                  if (location.portal.destinationWorldID == loc.worldID)
                    send(:loc);
                }
              }
            }
            
            when(target == empty)
              error(:'Portal\'s target could not be found.');        

            target.landmark.map.setPointer(
              x : target.x,
              y : target.y
            )
                        
            if (onLoad) onLoad();
            

          },
          onReady
        )      
      },
      
      
      
      
      
      
      // non-stable private use 
      
      linkEnd ::(locationWorldID) {
        state.isPortalExit = true;
        @:loc = location.landmark.island.findLocation(:locationWorldID);
        if (loc == empty)
          error(:'linkEnd() received a worldID for a location that either doesnt exist or is not within the island.');
        targetLandmark = loc.landmark;
        state.destinationWorldID = locationWorldID
      },

      linkChain ::(landmark) {
        targetLandmark = landmark;
        setupLandmark();
      },
      
    }
  }
)

return Portal;

