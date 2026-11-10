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
@:Database = import(module:'core/data/database.mt');
@:databaseItemMutatorClass = import(module:'core/data/databaseitemmutatorclass.mt');
@:Landmark = import(module:'base/map/landmark.mt');




@:reset :: {

BiomeCell.database.newEntry(
  data : {
    id: 'base:none',
    overworldSymbol: ' ',
    events : {}
  }
)



BiomeCell.database.newEntry(
  data : {
    id: 'base:cliff',
    overworldSymbol: '_',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:grass = landmark.map.addScenerySymbol(:',');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.1)
              landmark.map.setSceneryIndex( 
                x, y, symbol:grass
              )
          }      
        }

        @:flower = landmark.map.addScenerySymbol(:'y');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.03)
              landmark.map.setSceneryIndex( 
                x, y, symbol:flower
              )
          }      
        }

      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {
        @:landmark = neighborCell.landmark;
        @:grass = landmark.map.addScenerySymbol(:',');
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.003)
              landmark.map.setSceneryIndex( 
                x, y, symbol:grass
              )
          }      
        }
      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
);



BiomeCell.database.newEntry(
  data : {
    id: 'base:plains',
    overworldSymbol: ' ',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:grass = landmark.map.addScenerySymbol(:',');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.1)
              landmark.map.setSceneryIndex( 
                x, y, symbol:grass
              )
          }      
        }

        @:flower = landmark.map.addScenerySymbol(:'y');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.03)
              landmark.map.setSceneryIndex( 
                x, y, symbol:flower
              )
          }      
        }

      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {
        @:landmark = neighborCell.landmark;
        @:grass = landmark.map.addScenerySymbol(:',');
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.003)
              landmark.map.setSceneryIndex( 
                x, y, symbol:grass
              )
          }      
        }
      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
);


BiomeCell.database.newEntry(
  data : {
    id: 'base:road-horizontal',
    overworldSymbol: '─',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:grass = landmark.map.addScenerySymbol(:' ');
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.9)
              landmark.map.setSceneryIndex( 
                x, y, symbol:grass
              )
          }      
        }
      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {
      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
);

BiomeCell.database.newEntry(
  data : {
    id: 'base:road-vertical',
    overworldSymbol: '│',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:grass = landmark.map.addScenerySymbol(:' ');
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.9)
              landmark.map.setSceneryIndex( 
                x, y, symbol:grass
              )
          }      
        }
      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {
      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
);

  
BiomeCell.database.newEntry(
  data : {
    id: 'base:forest',
    overworldSymbol: '╿',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:tree = landmark.map.addScenerySymbol(:'╿');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.6) ::<={
              landmark.map.setSceneryIndex( 
                x, y, symbol:tree
              )
              landmark.map.enableWall(x, y);
            }
          }      
        }

        @:flower = landmark.map.addScenerySymbol(:'y');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.3) ::<= {
              landmark.map.setSceneryIndex( 
                x, y, symbol:flower
              )
              landmark.map.disableWall(x, y);
            }
          }      
        }
      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {
        @:landmark = neighborCell.landmark;
        @:tree = landmark.map.addScenerySymbol(:'╿');
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.1) ::<= {
              landmark.map.setSceneryIndex( 
                x, y, symbol:tree
              )
              landmark.map.enableWall(x, y);
            }
          }      
        }
      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
);

BiomeCell.database.newEntry(
  data : {
    id: 'base:wildflower',
    overworldSymbol: '.',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:grass = landmark.map.addScenerySymbol(:'.');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.3)
              landmark.map.setSceneryIndex( 
                x, y, symbol:grass
              )
          }      
        }

        @:flower = landmark.map.addScenerySymbol(:':');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.1)
              landmark.map.setSceneryIndex( 
                x, y, symbol:flower
              )
          }      
        }

      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {
        @:landmark = neighborCell.landmark;
        @:grass = landmark.map.addScenerySymbol(:'.');
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.08) ::<= {
              landmark.map.setSceneryIndex( 
                x, y, symbol:grass
              )
              landmark.map.enableWall(x, y);
            }
          }      
        }
      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
)



BiomeCell.database.newEntry(
  data : {
    id: 'base:mountains',
    overworldSymbol: '.',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:grass = landmark.map.addScenerySymbol(:'^');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
              landmark.map.setSceneryIndex( 
                x, y, symbol:grass
              )
          }      
        }


      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {
        @:landmark = neighborCell.landmark;
        @:grass = landmark.map.addScenerySymbol(:'^');
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.3)
              landmark.map.setSceneryIndex( 
                x, y, symbol:grass
              )
          }      
        }
      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
)


BiomeCell.database.newEntry(
  data : {
    id: 'base:thick-forest',
    overworldSymbol: 'Y',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:tree = landmark.map.addScenerySymbol(:'Y');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.6) ::<={
              landmark.map.setSceneryIndex( 
                x, y, symbol:tree
              )
              landmark.map.enableWall(x, y);
            }
          }      
        }

        @:flower = landmark.map.addScenerySymbol(:',');
      
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.3) ::<= {
              landmark.map.setSceneryIndex( 
                x, y, symbol:flower
              )
              landmark.map.disableWall(x, y);
            }
          }      
        }
      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {
        @:landmark = neighborCell.landmark;
        @:tree = landmark.map.addScenerySymbol(:'Y');
        for(0, landmark.map.height) ::(y) {
          for(0, landmark.map.width) ::(x) {
            when(Number.random() < 0.1) ::<= {
              landmark.map.setSceneryIndex( 
                x, y, symbol:tree
              )
              landmark.map.enableWall(x, y);
            }
          }      
        }
      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
);



BiomeCell.database.newEntry(
  data : {
    id: 'base:sky-1',
    overworldSymbol: '▓',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:tree = landmark.map.addScenerySymbol(:'▓');
        @:map = landmark.map
        for(0, map.height) ::(y) {
          for(0, map.width) ::(x) {
            map.setSceneryIndex(x, y, symbol:tree);
            map.enableWall(x, y);
          }
        }
      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {

      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
);

BiomeCell.database.newEntry(
  data : {
    id: 'base:sky-2',
    overworldSymbol: '▒',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:tree = landmark.map.addScenerySymbol(:'▒');
        @:map = landmark.map
        for(0, map.height) ::(y) {
          for(0, map.width) ::(x) {
            map.setSceneryIndex(x, y, symbol:tree);
            map.enableWall(x, y);
          }
        }
      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {

      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
);

BiomeCell.database.newEntry(
  data : {
    id: 'base:sky-3',
    overworldSymbol: '░',
    events : {
      onCreate ::(cell, overmap) {
        @:landmark = cell.landmark;
        @:tree = landmark.map.addScenerySymbol(:'░');
        @:map = landmark.map
        for(0, map.height) ::(y) {
          for(0, map.width) ::(x) {
            map.setSceneryIndex(x, y, symbol:tree);
            map.enableWall(x, y);
          }
        }
      },
      
      onNeighborCreated ::(neighborDirection, neighborCell, overmap) {

      },
      
      onDayStart ::(cell) {
      
      }
    }
  }
);

}

@:DIRECTION = {
  N :  0,
  NE : 1,
  E :  2,
  SE : 3,
  S :  4,
  SW : 5,
  W :  6,
  NW : 7,
}

@:BiomeCell = databaseItemMutatorClass.create(
  name : 'Wyvern.BiomeCell',
  
  statics : {
    DIRECTION : DIRECTION
  },

  database: Database.new(
    name : 'Wyvern.BiomeCell.Base',
    attributes : {
      id : String,
      // Symbol used when represented in the overworld
      overworldSymbol: String,

      events : Object
        // Function called when creating the biome
        // Arguments:
        //   cell (self)
        //   overmap,
        //   island
        //onCreate : Function,
        
        // Function called when a neighboring cell is created.
        // These are called on neighboring cells BEFORE the onCreate 
        // function of the cell being created. This helps 
        // Arguments:
        //   neighborDirection
        //   neighborCell
        //   overmap
        //onNeighborCreated : Function,
        
        // Called when the biome cell is loaded for the first time or 
        // its been a day since the cell was last loaded
        //onDayStart : Function
      
    },
    reset
  ),
  
  items : {
    base: empty,
    landmark: empty,
    data : empty,
  },
  
  define ::(state, this) {
    @overmap;
    this.interface = {
      initialize ::(parent) {
        overmap = parent
      },

      defaultLoad::(base, data){
        state.base = base;
        if (data != empty)
          state.data = data
        else
          state.data = {};
      },
      activate ::(x, y) {
        @:l = Landmark.new(base:Landmark.database.find(id:'base:overmap-chunk'), parent:this);
        l.loadContent();
        state.landmark = l;
        l.map.width = 20;
        l.map.height = 20;


        @:space = l.map.addScenerySymbol(:' ');
        for(0, l.map.height) ::(y) {
          for(0, l.map.width) ::(x) {
            l.map.setSceneryIndex( 
              x, y, symbol:space
            )
          }      
        }

        
        @:dirs = [
          [x-1, y-1, DIRECTION.SE],
          [x  , y-1, DIRECTION.S],
          [x+1, y-1, DIRECTION.SW],

          [x-1, y, DIRECTION.E],
          [x+1, y, DIRECTION.W],

          [x-1, y+1, DIRECTION.NE],
          [x  , y+1, DIRECTION.N],
          [x+1, y+1, DIRECTION.NW],


        ]
        foreach(dirs) ::(k, data) {
          @:base = overmap.island.getBiomeCellType(x:data[0], y:data[1]);
          when(base == empty) empty;
          if (base.events.onNeighborCreated)
            base.events.onNeighborCreated(
              neighborDirection : data[2],
              neighborCell : this,
              overmap
            )
          
        }
        
        if (state.base != empty && state.base.events.onCreate)
          state.base.events.onCreate(
            cell: this,
            overmap
          );
      },
      
      landmark: {
        get ::<- state.landmark
      },
      
      data : {
        get ::<- state.data
      },
      
      map : {
        get ::<- state.landmark.map
      }
    
    }
  }
);






return BiomeCell;
