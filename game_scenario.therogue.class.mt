@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'game_class.database.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Item = import(module:'game_mutator.item.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:namegen = import(module:'game_singleton.namegen.mt');
@:LoadableClass = import(module:'game_singleton.loadableclass.mt');
@:databaseItemMutatorClass = import(module:'game_singleton.databaseitemmutatorclass.mt');
@:InteractionMenuEntry = import(module:'game_struct.interactionmenuentry.mt');
@:commonInteractions = import(module:'game_singleton.commoninteractions.mt');
@:Personality = import(module:'game_database.personality.mt');
@:g = import(module:'game_function.g.mt');
@:Accolade = import(module:'game_struct.accolade.mt');
@:loading = import(module:'game_function.loading.mt');
@:romanNum = import(module:'game_function.romannumerals.mt');
@:ParticleEmitter = import(module:'game_class.particle.mt');
@:Landmark = import(module:'game_mutator.landmark.mt');
@:Island = import(module:'game_mutator.island.mt');
@:Species = import(module:'game_database.species.mt');
@:LandmarkEvent = import(module:'game_mutator.landmarkevent.mt');
@:DungeonMap = import(:'game_singleton.dungeonmap.mt');
@:Profession = import(module:'game_database.profession.mt');
@:Arts = import(module:'game_database.arts.mt');
@:Entity = import(module:'game_class.entity.mt');
@:Location = import(module:'game_mutator.location.mt');
@:State = import(module:'game_class.state.mt');
@:Inventory = import(module:'game_class.inventory.mt');
@:world = import(module:'game_singleton.world.mt');
@:pickItem = import(:'game_function.pickitem.mt');


@UNLOCKS = {
  VAULT     : 1,
  TRAVELLER : 2, // shop at start
}

return LoadableClass.create(
  name : 'TheRogueState',
  items : {
    etherealChestLocation : empty,
    unlocks : 0,
  },
  
  define::(this, state) {
    this.interface = {
      defaultLoad::() {
        
      },
      
      UNLOCKS : {
        get::<- UNLOCKS
      },

      // gets the vault location
      vault : {
        get ::<- (world.island.landmarks[0].locations->filter(::(value) <- value.id == 'therogue:the-vault'))[0]
      },
      
      unlocks : {
        get ::<- state.unlocks,
        set ::(value) <- state.unlocks = value
      }
    }
  }
)
