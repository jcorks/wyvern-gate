/*
  Wyvern Gate, a procedural, console-based RPG
  Copyright (C) 2023, Johnathan Corkery (jcorkery@umich.edu)

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
@:class = import(module:'Matte.Core.Class');
@:Database = import(module:'game_class.database.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');




@:reset :: {
@:StatSet = import(module:'game_class.statset.mt');
@:Damage = import(module:'game_class.damage.mt');
@:Item = import(module:'game_mutator.item.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:random = import(module:'game_singleton.random.mt');
@:canvas = import(module:'game_singleton.canvas.mt');




Scene.newEntry(
  data : {
    id: 'base:scene_guards0',
    script: [
      ['', 'Several guards approach you with haste'],
      ::(location, landmark, doNext) {
        @:world = import(module:'game_singleton.world.mt');
        @chance = random.number(); 
        @:island = landmark.island;   
        @:party = world.party;
        
        @:Entity = import(module:'game_class.entity.mt');

        @enemies = if (landmark == empty) ::<= {
          @:out = [
            island.newAggressor(),
            island.newAggressor(),
            island.newAggressor()            
          ];
          foreach(out) ::(i, e) <- e.anonymize();
          return out;
        } else (if (landmark.base.guarded) ::<= {
            
            // not only do these places have guards, but the guards are 
            // equipped with standard gear.
            
            
            
            @:e = [
              island.newInhabitant(professionHint:'base:guard'),
              island.newInhabitant(professionHint:'base:guard'),
              island.newInhabitant(professionHint:'base:guard')            
            ];
            
            foreach(e)::(index, guard) {
              guard.equip(
                item:Item.new(
                  base:Item.database.find(
                    id:'base:halberd'
                  ),
                  qualityHint:'base:standard',
                  materialHint: 'base:mythril',
                  rngEnchantHint: true
                ),
                slot: Entity.EQUIP_SLOTS.HAND_R,
                silent:true, 
                inventory:guard.inventory
              );

              guard.equip(
                item:Item.new(
                  base: Item.database.find(
                    id:'base:plate-armor'
                  ),
                  qualityHint:'base:standard',
                  materialHint: 'base:mythril',
                  rngEnchantHint: true
                ),
                slot: Entity.EQUIP_SLOTS.ARMOR,
                silent:true, 
                inventory:guard.inventory
              );
              guard.anonymize();
            }
            
            windowEvent.queueMessage(speaker:e.name, text:'"There they are!"');
            
            
            return e;
            } else empty);/*,
            
            
            default: match(true) {
            (random.number() > 0.9):
              [
                island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.01)->floor),
                island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.01)->floor),
                island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.01)->floor)            
              ],
              
            (random.number() > 0.8):
              [
                island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.10)->floor)
              ],
              
            default:
              [
                island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.05)->floor),
                island.newHostileCreature(levelMaxHint:((island.levelMax+landmark.floor/2)*1.05)->floor)                            
              ]
            }*/
          
        when(enemies == empty) 0;


        
        world.battle.start(
          party,
          
          allies: party.members,
          enemies,
          landmark: landmark,
          loot : true,
          onEnd::(result){
          
            if (!world.battle.partyWon())::<= {
              @:instance = import(module:'game_singleton.instance.mt');
              instance.gameOver(reason:'The party was wiped out.');
            }

          }
        );
      
        
        
      
        return 0; // number of timesteps active      
      }
    ]
  }
)





}

@:Scene = class(
  inherits:[Database],
  define::(this) {
    this.interface = {
      start::(id, onDone => Function, location, landmark) {
        @:scene = this.find(id);
        if (scene == empty)
          error(detail:'No such scene ' + id);
          
        @:left = [...scene.script];
        
        @:doNext ::{
          when(left->keycount == 0) onDone();
          @:action = left[0];
          left->remove(key:0);
          match(action->type) {
            (Function):
              action(location, landmark, doNext),
            
            (Object): ::<= {
              windowEvent.queueMessage(speaker: action[0], text: action[1]);
              windowEvent.queueCustom(onEnter:doNext);
            },
            default:
              error(detail:'Scene scripts only accept arrays or functions')
          }
        }
        
        doNext();
      }  
    }
  }
).new(
  name : 'Wyvern.Scene',
  attributes : {
    id : String,
    script : Object
  },
  reset
);



return Scene;
