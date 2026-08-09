/*
  Wyvern Gate, a procedural, console-based RPG
  Copyright (C) 2026, Johnathan Corkery (jcorkery@umich.edu)

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

@instanceRef = empty;

@:readonly ::(object) {
  @:output = {};
  foreach(object) ::(k, v) {
    when(v->type == String && v == 'INSTANCE_REF')
      output[k] = {get ::<- instanceRef}
    output[k] = {get ::<- v}
  }
  output->setIsInterface(enabled:true);
  return output
}

@:WyvernGate = readonly(:{
  __instance_finished ::(instance) {
    instanceRef = instance;
  },
  Core : readonly(:{
    Data : readonly(:{
      DatabaseItemMutator : import(:'core/data/databaseitemmutatorclass.mt'),
      Database : import(:'core/data/database.mt'),
      LoadableClass : import(:'core/data/loadableclass.mt'),
      State : import(:'core/data/state.mt')
    }),
    
    Graphics : readonly(:{
      Canvas : import(:'core/graphics/canvas.mt'),
      HUD : import(:'core/graphics/hud.mt'),
      Particle : import(:'core/graphics/particle.mt')
    }),
    
    // Not advertised. Just use WyvernGate.Util.Distance
    //Distance : import(:'core/distance.mt'),
    Map : import(:'core/map.mt'),
    Random : import(:'core/random.mt'),
    Sound : import(:'core/sound.mt'),
    Struct : import(:'core/struct.mt'),
    WindowEvent : import(:'core/windowevent.mt')
  }),
  
  Arts : import(:'base/arts.mt'),
  Accolade : import(:'base/accolade.mt'),
  Battle : import(:'base/battle.mt'),
  // Not needed
  //Boot : import(:'base/boot.mt'),
  Entity : import(:'base/entity.mt'),
  Instance : 'INSTANCE_REF',
  Item : import(:'base/item.mt'),
  NameGen : import(:'base/namegen.mt'),
  Party : import(:'base/party.mt'),
  Quest : import(:'base/quest.mt'),
  Scenario : import(:'base/scenario.mt'),
  Scene : import(:'base/scene.mt'),
  Story : import(:'base/story.mt'),
  World : import(:'base/world.mt'),
  Interaction : import(:'base/interaction.mt'),

  Event : readonly(:{
    Island : import(:'base/event/island.mt'),
    Landmark : import(:'base/event/landmark.mt')
  }),
  Util : readonly(:{ 
    Capitalize : import(:'base/util/capitalize.mt'),
    CorrectA : import(:'base/util/correcta.mt'),
    DisplayHP : import(:'base/util/displayhp.mt'),
    Distance : import(:'base/util/distance.mt'),    
    G : import(:'base/util/g.mt'),    
    LogTimer : import(:'base/util/logtimer.mt'),
    RomanNumerals : import(:'base/util/romannumerals.mt'),
    StatSet : import(:'base/util/statset.mt'),
  }),
  Widgets : readonly(:{
    AnimateBar : import(:'base/widgets/animatebar.mt'),
    BattleMenu : import(:'base/widgets/battlemenu.mt'),
    BuyInventory : import(:'base/widgets/buyinventory.mt'),
    ChoicesColumns : import(:'base/widgets/choicescolumns.mt'),
    DescriptiveList : import(:'base/widgets/descriptivelist.mt'),
    InteractPerson : import(:'base/widgets/interactperson.mt'),
    ItemImprove : import(:'base/widgets/itemimprove.mt'),
    ItemMenu : import(:'base/widgets/itemmenu.mt'),
    Loading : import(:'base/widgets/loading.mt'),
    // retired
    //LootGet
    Name : import(:'base/widgets/name.mt'),
    ('Number') : import(:'base/widgets/number.mt'),
    PartyOptions : import(:'base/widgets/partyoptions.mt'),
    PickArt : import(:'base/widgets/pickart.mt'),
    PickItem : import(:'base/widgets/pickitem.mt'),
    PickPartyItem : import(:'base/widgets/pickpartyitem.mt'),
    TabbedChoices : import(:'base/widgets/tabbedchoices.mt')
  }),
  Map : readonly(:{
    Dungeon : import(:'base/map/dungeon.mt'),
    Landmark : import(:'base/map/landmark.mt'),
    Island : import(:'base/map/island.mt'),
    // no need for public
    //Large
    //Structure
    Trap : import(:'base/map/trap.mt'),
    MapEntity : import(:'base/map/mapentity.mt'),
    Location : import(:'base/map/location.mt')
  })
})



// preload others to prevent later errors
WyvernGate.Accolade.NewRecord
WyvernGate.Arts.Term
WyvernGate.Arts.Deck
WyvernGate.Battle.Action
WyvernGate.Battle.AI
WyvernGate.Battle.Tutorial
WyvernGate.Entity.Damage
WyvernGate.Entity.Effect
WyvernGate.Entity.EffectStack
WyvernGate.Entity.Personality
WyvernGate.Entity.Quality
WyvernGate.Entity.Profession
WyvernGate.Entity.Species
WyvernGate.Entity.StateFlags
WyvernGate.Interaction.Common
WyvernGate.Interaction.MenuEntry
WyvernGate.Item.ApparelMaterial
WyvernGate.Item.Book
WyvernGate.Item.Color
WyvernGate.Item.Design 
WyvernGate.Item.Edible 
WyvernGate.Item.Enchant
WyvernGate.Item.Improvement 
WyvernGate.Item.InletSet
WyvernGate.Item.Inventory
WyvernGate.Item.Material
WyvernGate.Item.Quality
WyvernGate.Quest.Guild

return WyvernGate



