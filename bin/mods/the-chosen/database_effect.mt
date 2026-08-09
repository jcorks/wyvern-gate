@:WyvernGate = import(:'wyvern-gate.mt');
@:Effect = WyvernGate.Entity.Effect

return ::{
  Effect.newEntry(
    data : {
      name : 'Sentimental Box',
      id : 'thechosen:sentimental-box',
      description: 'Opens the box.',
      tier: 99,
      skipTurn : false,
      stackable: true,
      blockPoints : 0,
      stats: WyvernGate.Util.StatSet.new(),
      traits : Effect.TRAIT.SPECIAL,
      
      events : {
        onAffliction ::(user, item, holder) {
          WyvernGate.Scene.start(id:'thechosen:scene_sentimentalbox', onDone::{});      
        }
      }
    }
  )
}
