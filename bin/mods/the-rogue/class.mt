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
