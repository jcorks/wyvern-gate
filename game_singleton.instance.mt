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

// database loading 



import(module:'game_database.apparelmaterial.mt');
import(module:'game_database.effect.mt');
import(module:'game_database.interaction.mt');
import(module:'game_database.itemcolor.mt');
import(module:'game_database.itemdesign.mt');
import(module:'game_database.itemquality.mt');
import(module:'game_database.material.mt');
import(module:'game_database.personality.mt');
import(module:'game_database.scene.mt');
import(module:'game_database.species.mt');
import(module:'game_database.book.mt');
import(module:'game_database.artsterm.mt');
import(module:'game_function.number.mt');
import(module:'game_function.descriptivelist.mt');

@:Arts = import(module:'game_mutator.arts.mt');
import(module:'game_mutator.entityquality.mt');
import(module:'game_mutator.islandevent.mt');
import(module:'game_mutator.item.mt');
import(module:'game_mutator.itemenchant.mt');
import(module:'game_mutator.landmark.mt');
import(module:'game_mutator.landmarkevent.mt');
import(module:'game_mutator.location.mt');
import(module:'game_mutator.mapentity.mt');
import(module:'game_mutator.quest.mt');
import(module:'game_database.profession.mt');
import(module:'game_mutator.scenario.mt');
import(module:'game_function.trap.mt');
import(module:'game_singleton.commoninteractions.mt');
import(module:'game_function.questguild.mt');
import(module:'game_mutator.island.mt');
import(:'game_class.inletset.mt');
@:hud = import(:'game_singleton.hud.mt');
@:choicesColumns = import(:'game_function.choicescolumns.mt');


@:Database = import(module:'game_class.database.mt');


@:class = import(module:'Matte.Core.Class');
@:Entity = import(module:'game_class.entity.mt');
@:Party = import(module:'game_class.party.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:Battle = import(module:'game_class.battle.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Landmark = import(module:'game_mutator.landmark.mt');
@:Island = import(module:'game_mutator.island.mt');
@:Interaction = import(module:'game_database.interaction.mt');
@:Item = import(module:'game_mutator.item.mt');
@:namegen = import(module:'game_singleton.namegen.mt');
@:LargeMap = import(module:'game_singleton.largemap.mt');
@:Scenario = import(module:'game_mutator.scenario.mt');
@:sound = import(module:'game_singleton.sound.mt');

import(module:'game_function.pickpartyitem.mt');
import(module:'game_function.itemimprove.mt');


/* make sure base loadable classes are available */

import(module:'game_class.statset.mt');
import(module:'game_class.battleai.mt');
import(module:'game_class.inventory.mt');
import(module:'game_class.map.mt');
import(module:'game_class.party.mt');
import(module:'game_class.stateflags.mt');



import(module:'game_class.entity.mt');
import(module:'game_mutator.island.mt');

@:loading = import(module:'game_function.loading.mt');
@:random = import(:'game_singleton.random.mt');


import(module:'game_class.landmarkevent_mobilemushroom.mt');
import(module:'game_class.landmarkevent_flamingskull.mt')
import(module:'game_class.landmarkevent_skeleton.mt')
import(module:'game_class.landmarkevent_goldslime.mt')
import(module:'game_class.landmarkevent_creatureencounters.mt')
import(module:'game_class.landmarkevent_gnome.mt')
import(module:'game_class.landmarkevent_giantflea.mt')
import(module:'game_class.landmarkevent_monolith.mt')

import(module:'game_class.structuremap.mt');
import(:'game_class.item.improvement.mt')

@:distance::(x0, y0, x1, y1) {
  @xd = x1 - x0;
  @yd = y1 - y0;
  return (xd**2 + yd**2)**0.5;
}
@:JSON = import(module:'Matte.Core.JSON');
@:GIT_COMMIT = ::? {
  return import(module:'GIT_COMMIT');
} => {
  onError::(message) {
    return '<unknown>';
  }
}
@:VERSION = '0.4.0a - ' + GIT_COMMIT;
@:QUICK_SAVE_SUFFIX = '-qs';
@world = import(module:'game_singleton.world.mt');
import(module:'game_function.newrecord.mt');


// every game starts or loads PAST this point.
// If a game bounces back to this, the user will be 
// unable to progress.
@:pointOfNoReturn::(do) {
  windowEvent.queueCustom(
    keep : true,
    jumpTag : 'PointOfNoReturn',
    renderable : {
      render :: {
        canvas.fill();
      }
    },
    onEnter : do
  );
}


@:renderKnowledgeStone ::{
  @:stone = world.party.getItem(condition::(value) <- value.base.id == 'base:knowledge-stone');
  when(stone == empty) empty;
  when(stone.data.steps == empty) stone.data.steps = 0;
  if (stone.data.steps < 155) {  
    @:fraction = if (stone.data.steps >= 150) 1 else (stone.data.steps / 150);
    @:bar = canvas.renderBarAsString(
      width:13,
      fillFraction: fraction,
      emptyCharacter : '|'//'░'
    )

    
    canvas.renderTextFrameGeneral(
      leftWeight: 1,
      topWeight: 0,
      lines: [if (stone.data.steps >= 150) 
        'Steps: 150 / 150 ' + '[Ready!]'
       else 
        'Steps: ' + stone.data.steps + ' / 150 ' + bar
       ],
      title: 'Knowledge Stone:'
    );
  }
}

@:renderArtsStatus ::(landmark) {
  when(world.battle.isActive) empty;

  @needsDisplay = [];
  @bars;
  @LIMIT = 3;
  foreach(world.party.members) ::(k, member) {
    @:artsNames = [];
    @:artsBar = [];
    @:artsStatus = [];
    @arts = [];
    
    @preArts = member.arts->filter(::(value) <- value.canUse == false);
    @truncated = false;
    if (preArts->size > LIMIT) ::<= {
      arts = preArts->subset(from:0, to:LIMIT-1);
      truncated = true;
    } else 
      arts = preArts
      
      
    foreach(preArts) ::(k, art) {
      @data = Arts.renderListItem(
        art
      );
      
      artsNames->push(:data[0]);
      artsBar->push(:data[1]);
      artsStatus->push(:data[2]);
    }
    
    
    when(artsNames->size > 0) ::<= {
      needsDisplay->push(:member.name + ':');
      
      needsDisplay = [...needsDisplay, ...canvas.columnsToLines(
        columns : [
          artsStatus,
          artsBar,
          artsNames
        ],
        leftJustifieds : [
          true,
          true,
          true
        ]
      )];
    }
    
    if (truncated == true)
      needsDisplay->push(:'...and ' + (preArts->size - LIMIT) + ' others');
    
  }
  
  if (needsDisplay->size > 0)
    canvas.renderTextFrameGeneral(
      leftWeight: 1,
      topWeight: 1,
      lines: needsDisplay,
      title: 'Charging: ' + (70 - world.party.steps % 70) + ' steps left'
    );
}


@:setupDefaultHud ::{
  hud.clear();
  hud.addRenderer(
    name: 'Wyvern.HUD.knowledgeStone',
    onLandmarkStep ::(landmark, island) {
      renderKnowledgeStone();
    }
  );        

  hud.addRenderer(
    name: 'Wyvern.HUD.artsStatus',
    onLandmarkStep ::(landmark, island) {
      renderArtsStatus(landmark);          
    }
  );        
}
return class(
  name: 'Wyvern.Instance',
  define:::(this) {
    @onSaveState;
    @onLoadState;
    @settings;
    @onSaveSettings_;
    @save = 0;
    
    // the main.mt results of all mods, ordered based on dependency
    @:modMainOrdered = [];




    

    @:loadMods ::(mods) {
      // first we need the proper dep tree;
      @:depends = {};
      @:modsIndexed = {};
      
    
      foreach(mods) ::(i, mod) {
        depends[mod.id] = [...mod.loadFirst];
        modsIndexed[mod.id] = mod;
      }

      
      @:loaded = {}; // by name
      @:loading = {}; // by name, for circ dep
      
      
      // loads a single mod in order, detected circular dependencies.
      @:loadMod ::(mod) {
        when(loaded[mod.id] == true) empty;
        if (loading[mod.id] == true)
          error(detail: 'Circular dependency of mods detected! First circular dependency: ' + mod.id);
          
        loading[mod.id] = true;
        
        // load prereqs
        foreach(mod.loadFirst) ::(i, first) {
          loadMod(mod:modsIndexed[first]);
        }
        
        
        // get entry point.
        @:result = ::? {
          return import(module: mod.id + '/main.mt');
        } => {
          onError::(message) {
            error(detail: 'An error occurred while loading the mod ' + mod.id + ':' + message.summary + '\n\n');
          }
        }

        modMainOrdered->push(value:result);

        loaded[mod.id] = true;
      }
      foreach(mods) ::(i, mod) {
        loadMod(mod);
      }
      
      
      foreach(modMainOrdered) ::(i, modMain) {
        modMain.onGameStartup();
      }
    }
    
    
    @:FEATURES = {
      // whether this instance supports fullscreen or not
      /* 
        "fullscreen" : boolean
      */
      FULLSCREEN : 1,
      
      // whether this instance supports a CRT shader or not
      /* 
        "crtShader" : "Boolean"
      */
      CRT_SHADER : 2,
      
      // Controls how each button should be mapped
      /*
        "inputConfirm" : "PAD_BUTTON_NAME"
        "inputDeny"    : "PAD_BUTTON_NAME"
        "inputLeft"    : "PAD_BUTTON_NAME"
        "inputRight"   : "PAD_BUTTON_NAME"
        "inputUp"      : "PAD_BUTTON_NAME"
        "inputDown"    : "PAD_BUTTON_NAME"
      */
      INPUT_MAPPING : 4,
      
      // whether this instance supports audio
      // provides controls for 
      // BGM, PC noises, SFX
      /*
        "volume"    : Number [0-1]
        "volumeBGM" : Number [0-1]
        "volumeSFX" : Number [0-1]
      */
      AUDIO : 16,
      
      // Whether this instance supports background / foreground 
      // color modification
      /*
        "bgColor" : {"r":[0-1], "g":[0-1], "b":[0-1]},
        "fgColor" : {"r":[0-1], "g":[0-1], "b":[0-1]},
      */
      BGFG : 32,

      // Enables Matte debugging
      DEBUGGING : 64
    };
    @features_ = 0;
    @onLoadSettings_;
    

    
    @:colorMenu::(onChange, prompt, value)  {
      windowEvent.queueChoices(
        prompt,
        onGetChoices ::<- [
          'Red:   ' + (100*value[0]/255)->floor + '%',
          'Green: ' + (100*value[1]/255)->floor + '%',
          'Blue:  ' + (100*value[2]/255)->floor + '%'
        ],
        
        canCancel: true,
        keep : true,
        
        onChoice::(choice) {
          choice = choice-1;
          windowEvent.queueSlider(
            canCancel : true,
            increments : 255,
            defaultValue : value[choice] / 255,
            onChoice ::(fraction){},
            prompt: (match(choice) {
              (0): 'Red',
              (1): 'Green',
              (2): 'Blue'
            }) + ' Amount',
            onHover ::(fraction) {
              value[choice] = (fraction * 255)->round;
              onChange();
            }
          );
        }
      );
    }

    @:init :: {
      settings.fullscreen = true;
      settings.crtShader = true;
      settings.volume = 0.7;
      settings.volumeBGM = 0.3;
      settings.volumeSFX = 0.5;
      settings.bgColor = [33, 33, 58];
      settings.fgColor = [186, 240, 228];
      settings.debugMode = false;
      settings.animations = true;
      settings.effects = true;
      settings.hud = true;
      settings.mods = false;
    }    


    this.interface = {
      FEATURES : {
        get :: <- FEATURES
      },
      
      hasFeatures ::<- features_ != 0,
      
      defaultSettings ::{
        init();
        this.updateSettings();
      },
      
      optionsMenu:: {
        init();
        foreach(JSON.decode(string:onLoadSettings_())) ::(k, v) {
          settings[k] = v;
        }


        @:opts = [
          'Reset to default', ::<-
            windowEvent.queueAskBoolean(
              prompt: 'Reset all settings?',
              onChoice::(which) {
                if (which == true)
                  this.defaultSettings();
              }
            ),

          'Mods', ::<-
            windowEvent.queueAskBoolean(
              onGetPrompt::<- 'Toggle Mod loading? (currently: ' + (if(settings.mods) 'Enabled' else 'Disabled') + ')',
              onChoice::(which) {
                when(which == false) empty;
                settings.mods = !settings.mods;
                this.updateSettings();

                windowEvent.queueMessage(
                  text: 'A restart of the program is required for this to take effect.'
                )
              }
            ),
          

          'Animations', ::<-          
            windowEvent.queueAskBoolean(
              onGetPrompt::<- 'Toggle Animations? (currently: ' + (if(settings.animations) 'Enabled' else 'Disabled') + ')',
              onChoice::(which) {
                when(which == false) empty;
                settings.animations = !settings.animations;
                windowEvent.autoSkipAnimations = !settings.animations;
                this.updateSettings();
              }
            ),
          'HUD', ::<-          
            windowEvent.queueAskBoolean(
              onGetPrompt::<- 'Toggle HUD? (currently: ' + (if(settings.hud) 'Enabled' else 'Disabled') + ')',
              onChoice::(which) {
                when(which == false) empty;
                settings.hud = !settings.hud;
                hud.enable = settings.hud;
              }
            ),

          
          'Effects', ::<-
            windowEvent.queueAskBoolean(
              onGetPrompt::<- 'Toggle Effects? (currently: ' + (if(settings.effects) 'Enabled' else 'Disabled') + ')',
              onChoice::(which) {
                when(which == false) empty;
                settings.effects = !settings.effects;
                canvas.showEffects = settings.effects;
                this.updateSettings();
              }
            )
        ]

        foreach(FEATURES) ::(k, i) <-
          if ((features_ & i) != 0)
            match(i) {


              (FEATURES.DEBUGGING): ::<={
                opts->push(:'Debug Mode');
                opts->push(::<-
                  windowEvent.queueAskBoolean(
                    onGetPrompt::<- 'Toggle Debug Mode? (currently: ' + (if(settings.debugMode) 'Enabled' else 'Disabled') + ')',
                    onChoice::(which) {
                      when(which == false) empty;
                      settings.debugMode = !settings.debugMode;
                      this.updateSettings();

                      windowEvent.queueMessage(
                        text: 'A restart of the program is required for this to take effect. We recommend disabling fullscreen and running a console mode for debugging.'
                      )
                    }
                  )
                )
              },


              (FEATURES.FULLSCREEN): ::<={
                opts->push(:'Fullscreen')
                opts->push(::<-
                  windowEvent.queueAskBoolean(
                    onGetPrompt::<- 'Toggle fullscreen? (currently: ' + (if(settings.fullscreen) 'Enabled' else 'Disabled') + ')',
                    onChoice::(which) {
                      when(which == false) empty;
                      settings.fullscreen = !settings.fullscreen;
                      this.updateSettings();
                    }
                  )
                )
              },


              (FEATURES.CRT_SHADER): ::<={
                opts->push(:'CRT Effect');
                opts->push(::<-
                  windowEvent.queueAskBoolean(
                    onGetPrompt::<- 'Toggle CRT? (currently: ' + (if(settings.crtShader) 'Enabled' else 'Disabled') + ')',
                    onChoice::(which) {
                      when(which == false) empty;
                      settings.crtShader = !settings.crtShader;
                      this.updateSettings();
                    }
                  )
                )
              },
              
              (FEATURES.BGFG): ::<={
                opts->push(:'Background color');
                opts->push(:::<-
                  colorMenu(prompt: 'BG Color', onChange::<- this.updateSettings(), value:settings.bgColor)
                );
                
                opts->push(:'Foreground color');
                opts->push(::<-
                  colorMenu(prompt: 'FG Color', onChange::<- this.updateSettings(), value:settings.fgColor)
                )


              },              

              (FEATURES.AUDIO): ::<={
                opts->push(:'Volume: Game')
                opts->push(::{
                  @frac = settings.volume;
                  windowEvent.queueSlider(
                    onGetPrompt ::<- 'Game Volume :' + (frac * 100)->floor,
                    defaultValue : settings.volume,
                    onChoice::(value){},
                    increments : 100,
                    onHover ::(fraction) {
                      frac = fraction;
                    },
                    onLeave :: {
                      settings.volume = frac;
                      this.updateSettings();
                    },
                    canCancel : true
                  )
                });

                opts->push(:'Volume: SFX')
                opts->push(::{
                  @frac = settings.volumeSFX;
                  windowEvent.queueSlider(
                    onGetPrompt ::<- 'SFX Volume :' + (frac * 100)->floor,
                    defaultValue : settings.volumeSFX,
                    onChoice::(value){},
                    increments : 100,
                    onHover ::(fraction) {
                      frac = fraction;
                    },
                    onLeave :: {
                      settings.volumeSFX = frac;
                      this.updateSettings();
                    },
                    canCancel : true
                  )
                });

                opts->push(:'Volume: BGM');
                opts->push(::{
                  @frac = settings.volumeBGM;
                  windowEvent.queueSlider(
                    onGetPrompt ::<- 'BGM Volume :' + (frac * 100)->floor,
                    defaultValue : settings.volumeBGM,
                    onChoice::(value){},
                    increments : 100,
                    onHover ::(fraction) {
                      frac = fraction;
                    },
                    onLeave :: {
                      settings.volumeBGM = frac;
                      this.updateSettings();
                    },
                    canCancel : true
                  )
                }
              );
            }
          }
          
        windowEvent.queueChoices(
          prompt: 'Settings',
          choicesMatch : opts,
          keep : true,
          canCancel: true
        );
      },
      
      updateSettings::{
        if (settings.animations == empty)
          settings.animations = true;
        if (settings.effects == empty)
          settings.effects = true;
        if (settings.hud == empty)
          settings.hud = true;

        windowEvent.autoSkipAnimations = !settings.animations;
        canvas.showEffects = settings.effects;
        hud.enable = settings.hud;
        onSaveSettings_(data:JSON.encode(object:settings));      
      },

      mainMenu ::(
        canvasWidth => Number,
        canvasHeight=> Number,
        features => Number,
        onSaveState => Function, // for saving,
        onLoadState => Function,
        onListSlots => Function,
        preloadMods => Function,
        preloadJSON => Function, //[name] = Json object in directory
        onSaveSettings => Function,
        onLoadSettings => Function,
        onPlaySFX => Function,
        onPlayBGM => Function, // if name is unrecognized, will halt playing music.
        onQuit => Function
      ) {
      

      
        foreach(preloadJSON()) ::(k, v) {
        
          setModule(name:k, value:v);
        }
      
        sound.setup(
          nativeSFX: onPlaySFX,
          nativeBGM: onPlayBGM
        )
        onLoadSettings_ = onLoadSettings;
        features_ = features;
        canvas.resize(width:canvasWidth, height:canvasHeight);
        this.onSaveState = onSaveState;
        this.onLoadState = onLoadState;    
        
        onSaveSettings_ = onSaveSettings;
        settings = onLoadSettings();
        if (settings == empty) ::<= {
          settings = {}
          this.defaultSettings();
        } else ::<= {
          settings = JSON.decode(string:settings);
          this.updateSettings();
        }





/*
import(:'game_function.tabbedchoices.mt')(
  onGetTabs ::<- [
    'Enemies',
    'Allies',
    'other',
    "otherot"
  ],
  keep : true,
  canCancel : false,
  onGetChoices::(tab) <-
    [
      [
        'the Rat Alchemist',
        'the Hyena Ranger'
      ],

      [
        'Baphy',
        'Herald',
        'Rasa'
      ]
    ]
    
  ,

  onChoice::(tab, choice) {
    windowEvent.queueMessage(
      text: 'Chosen was ' + choice + ' from tab ' + tab
    )
  }
);

windowEvent.queueMessage(
  text: 'hi'
);
*/

/*
@:otherChoices ::{
  windowEvent.queueChoices(
    choices : [
      'A',
      'B'
    ],
    leftWeight : random.number(),
    canCancel : true,
    onChoice::(choice) {
      when (choice == 1)
        otherChoices()
        
        
        
      windowEvent.queueAskBoolean(
        prompt: 'Do it?',
        onChoice ::(which) {
        
        }
      );
      
      
    }
  );  
}

@:doMain :: {
  windowEvent.queueCustom(onEnter::{
    windowEvent.queueInputEvents(:[
      {input:windowEvent.CURSOR_ACTIONS.UP, waitFrames:20},
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:5},
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:5},
      {input:windowEvent.CURSOR_ACTIONS.DOWN, waitFrames:5},
      {input:windowEvent.CURSOR_ACTIONS.CONFIRM, waitFrames:30}
    ])
  });


  windowEvent.queueChoices(
    choices: [
      "1",
      '2',
      '3'
    ],
    keep:true,
    onChoice::(choice) {
      when(choice == 1)
        windowEvent.queueMessage(
          text: 'HIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII'
        );
        
      otherChoices();
    }
  );
  
}

windowEvent.queueCustom(
  keep : true,
  renderable : {
    render :: {
      canvas.fill(with:'.');
    }
  },
  onEnter ::{
    doMain();
  }
  
);


return empty;
*/


/*
@:ParticleEmitter = import(module:'game_class.particle.mt');
@:etherealEmitter = ParticleEmitter.new(
  directionMin : 0,
  directionMax : 360,

  directionDeltaMin : 5,
  directionDeltaMax : 180,

  speedMin : 0.3,
  speedMax : 1.5,
  
  speedDeltaMin : -.01,
  speedDeltaMax : -.03,

  characters : ['O', 'O', 'O', '0', '0', '0', 'o', 'o', 'o', ',' , '.'],
  
  lifeMax : 20,
  lifeMin : 7
);

etherealEmitter.move(x:canvas.width/2, y:canvas.height/2);
etherealEmitter.start();

windowEvent.queueMessage(
  text: 'Particles!',
  topWeight : 1
);
return empty;        
*/

        @:choiceActions = [];
        
        @:genChoices ::{
          choiceActions->setSize(size:0);
          @:choiceNames = [];
          if (onListSlots()->size != 0) ::<= {
            choiceNames->push(value:'Load');
            choiceActions->push(value: ::{
              @choices = onListSlots();
              when (choices->size == 0) ::<= {
                windowEvent.queueMessage(text: 'No save files were found.');
              }


              // wrap in quicksave if exists.
              choices->sort(comparator:::(a, b) {
                when(a < b) -1;
                when(a > b)  1;
                return 0;
              });
              @choicesRaw = [...choices];
              choices = choices->filter(::(value) <- !value->contains(:QUICK_SAVE_SUFFIX));
              @isQS = [];
              
              foreach(choices) ::(k, choice) {
                isQS->push(: (::? {
                  foreach(choicesRaw) ::(k, v) {
                    if (choice+QUICK_SAVE_SUFFIX == v)
                      send(:true);
                    
                  }
                  return false;
                }));
              }


              @:loadTrue ::(name, remove, onDone) {
                loading(
                  message: 'Loading scenario...',
                  do:: {
                    this.resetDatabase();
                    loading(
                      message: 'Loading save...',
                      do :: {
                        @:data = this.getSaveDataRaw(:name);
                        world.load(serialized:data);
                        setupDefaultHud();
                        
                        if (save > 0) ::<= {
                          world.disgruntled = true;
                        }
                        
                        if (remove == true)
                          this.savestate(saveOverride:'', nameOverride:name);
                          
                          
                        pointOfNoReturn(
                          do::{
                            if (onDone) onDone();
                            this.startResume()
                          }
                        );
                      }
                    )
                  }
                );              
              }
              
              @:loadQuickSave ::(name) {
                windowEvent.queueMessage(
                  text: 'This save has a Quick Save available.'
                );
                  
                windowEvent.queueChoices(
                  keep: true,
                  canCancel : true,
                  jumpTag : 'quickSave',
                  prompt: 'Save : ' + name,
                  choices : [
                    'Load Quick Save',
                    'Load normal save'
                  ],
                  
                  onChoice::(choice) {
                    windowEvent.queueMessage(
                      text: 'This will remove the Quick Save.'
                    );
                    windowEvent.queueAskBoolean(
                      prompt: if (choice == 1)
                        'Load Quick Save?'
                      else 
                        'Load normal save?',
                        
                      onChoice::(which) {
                        when(which == true)
                          // quicksave!
                          if (choice == 1) 
                            loadTrue(
                              name: name+QUICK_SAVE_SUFFIX,
                              remove: true
                            )
                          else
                            loadTrue(
                              name,
                              onDone ::{
                                this.savestate(saveOverride:'', nameOverride:name+QUICK_SAVE_SUFFIX);                              
                              }
                            );
                        
                      }
                    );
                  }
                );
              }

              choicesColumns(
                columns : [
                  choices,
                  isQS->map(::(value) <- if (value == true) '(!)' else '')
                ],
                leftJustified : [
                  true, true
                ],
                prompt: 'Load which save?',
                canCancel: true,
                keep:true,
                onChoice::(choice) {
                  when(choice == 0) empty;
                  
                  when (isQS[choice-1] == true)
                    loadQuickSave(:choices[choice-1]);
                  
                  loadTrue(name:choices[choice-1]);
                }
              );          
            });
          }
        
        
        
          choiceNames->push(value:'New');
          choiceActions->push(value:::{
            
            loading(
              message: 'Loading scenarios...',
              do ::{
                
                

                this.resetDatabase();


                @:enterName = import(module:'game_function.name.mt');

                @choices = Scenario.database.getAll();
                choices->sort(comparator:::(a, b) {
                  when(a.name < b.name) -1;
                  when(a.name > b.name)  1;
                  return 0;
                });
                @choiceNames = [...choices]->map(to::(value) <- value.name);
                
                if (settings.unlockedScenarios == false || settings.unlockedScenarios == empty) ::<= {
                  choices = [Scenario.database.find(id:'rasa:thechosen')];
                  choiceNames = ['The Chosen'];
                }
                
                
                windowEvent.queueChoices(
                  prompt: 'Select a scenario:',
                  choices: choiceNames,
                  canCancel: true,
                  renderable : {
                    render :: {
                      canvas.fill();
                    }
                  },
                  onChoice::(choice) {
                    when(choice <= 0) empty;
                    @:scenario = Scenario.new(base:choices[choice-1]);

                    @:startNewWorld = ::(name){
                      
                      when (settings.unlockedSeeds) ::<= {
                        @seed;
                        windowEvent.queueChoices(
                          prompt: 'World ' + name,
                          keep: true,
                          canCancel : false,
                          jumpTag : 'SEEDSETTING',
                          choicesMatch : [
                            'Begin', ::{
                              windowEvent.jumpToTag(name:'SEEDSETTING', goBeforeTag:true);
                              this.startNew(name, scenario, seed);
                            },
                            
                            
                            'Set world seed...', ::{
                              @:enterName = import(module:'game_function.name.mt');

                              windowEvent.queueChoices(
                                onGetPrompt::<- 'Current seed: ' + if (
                                  seed == empty) 'set to random.' else 
                                  '"' + seed + '"',
                                
                                choicesMatch : [
                                  'Enter seed', ::<- enterName(
                                    prompt: 'Enter a seed.',
                                    canCancel: true,
                                    onDone::(name) {
                                      seed = name;
                                    }
                                  ),
                                  'Clear seed', ::<- seed = empty
                                ],
                                canCancel: true,
                                keep : true
                              );                              
                            }
                          ]
                        );
                      }
                      this.startNew(name, scenario);
                      //this.startInstance();              
                    }
                    when(scenario.base.skipName) 
                      startNewWorld(:'');

                    enterName(
                      prompt: 'Enter a file name.',
                      canCancel: true,
                      renderable : {
                        render :: {
                          canvas.fill();
                        }  
                      },
                      onDone ::(name){
                        @:currentFiles = onListSlots();

                        when(name->charAt(:0) == ' ' || name == ' ')
                          windowEvent.queueMessage(
                            text:'That world name is invalid. It cannot start with spaces.',
                            renderable : {
                              render ::{
                                canvas.fill();
                              }
                            }
                          );                        


                        when (currentFiles->findIndex(value:name) != -1) ::<= {
                          windowEvent.queueMessage(
                            text:'There\'s already a file named ' + name,
                            renderable : {
                              render ::{
                                canvas.fill();
                              }
                            }
                          );
                          windowEvent.queueAskBoolean(
                            prompt: 'Overwrite ' + name + '?',
                            renderable : {
                              render ::{
                                canvas.fill();
                              }
                            },
                            onChoice ::(which) {
                              when(!which) empty;
                              pointOfNoReturn(
                                do::{ 
                                  startNewWorld(name)
                                }
                              )
                            }
                          );
                        }
                      
                        pointOfNoReturn(
                          do::{ 
                            startNewWorld(name);
                          }
                        );
                      }
                    )
                  }
                );  
              }  
            )      
          });
          
          
          if (mods->size != 0) ::<= {
            choiceNames->push(value:'Mods...');

            @:modNames = [];
            @:modList = [];
            
            foreach(mods) ::(k, mod) {
              modNames->push(value:mod.name);
              modList->push(value:mod);
            }

            choiceActions->push(value:::{
              windowEvent.queueChoices(
                prompt: 'Loaded mods:',
                keep:true,
                canCancel:true,
                choices: modNames,
                onChoice ::(choice) {
                  @:mod = modList[choice-1];
                  windowEvent.queueMessage(
                    speaker: 'Mod info...',
                    text: 
                      'Name  : ' + mod.name + '\n'+
                      '     (' + mod.id + ')\n' +
                      'Author  : ' + mod.author + '\n' +
                      'Website : ' + mod.website + '\n\n' +
                      mod.description + 
                      '\n\nDepends on ' + mod.loadFirst->size + ' mods:\n' + ::<= {
                        @out = '';
                        foreach(mod.loadFirst) ::(i, depends) {
                          out = out + ' - ' + depends + '\n'
                        }
                        return out;
                      }
                  )
                }
              );
            });
          }

          choiceNames->push(value: 'Settings');
          choiceActions->push(value ::{
            this.optionsMenu();
          });

          
          choiceNames->push(value: 'Credits');
          choiceActions->push(value ::{
            this.queueCredits();
          });
          
          
          choiceNames->push(value: 'Exit');
          choiceActions->push(value ::{
            onQuit()
          });  
          return choiceNames;      
        }
        @mods;

        canvas.reset();
        windowEvent.clearAll(
          onReady ::{

            if (settings.mods == true) ::<= {
              ::? {
                mods = preloadMods();
              } => {
                onError ::(message) {
                  windowEvent.queueMessage(
                    text: "Could not preload mods: " + message.summary
                  )
                  mods = {};
                }
              }
              loadMods(mods);
            } else
              mods = [];

            sound.playBGM(name:'boot', loop:false);
         
            
            (import(:'game_function.boot.mt'))(          
              onBooted :: {
                sound.playBGM(name:"title", loop:false)
                
                windowEvent.queueChoices(
                  onGetChoices ::{
                    return genChoices();
                  },
                  topWeight: 0.75,
                  keep : true,
                  jumpTag : 'MainMenu',
                  renderable : {
                    render ::{
                      @: title = 'Wyvern Gate';
                      @:subtitle = '~ A Tale of Wishes ~';
                      canvas.fill();
                      canvas.movePen(x:
                        canvas.width / 2 - title->length / 2,
                        y: 2
                      );
                        
                      canvas.drawText(
                        text:title
                      );

                      canvas.movePen(x:
                        canvas.width / 2 - subtitle->length / 2,
                        y: 3
                      );
                        
                      canvas.drawText(
                        text:subtitle
                      );
                      
                      
                      
                      @:loc = 'https://github.com/jcorks/wyvern-gate/ (' + VERSION + ')'              
                      canvas.movePen(
                        x: canvas.width / 2 - loc->length / 2,
                        y: canvas.height - 2
                      );
                      
                      canvas.drawText(
                        text:loc
                      );

                    }
                  },
                  onChoice ::(choice) {
                    choiceActions[choice-1]();              
                  }
                );
              }
            )          
          }
        );
      },

      queueCredits :: {
        windowEvent.queueMessage(
          text: 'A game by Johnathan "Rasa" Corkery\n'+
              'https://github.com/jcorks/\n\n' + 
              'Additional Arts Design \n' +
              ' & Game Consultation   : Baph @lovelyabomination\n' +
              'Additional support     : Adrian "Radscale" Hernik\n' +
              'Playtesting            : Baph @lovelyabomination\n' +
              '                         Ashley Dron\n' +
              '                         Clover\n'
        );
        
        windowEvent.queueMessage(
          text: 'Special thanks to:\n' +
                'Pigeon\n' + 
                'Citrus\n' + 
                'Meiyuu\n' +
                'Drassy\n' +
                'Nido\n' +
                'Maztitos\n' +
                'Dr. San\n'+
                'aeotepiia'
        );

        windowEvent.queueMessage(
          text: 'Also a special thanks to Rocco Botte, who personally advised me to stop watching a video of his. As difficult as it is, I continue to heed his advice to this day.'
        );      
      },
      
      startResume ::{        
        when (world.finished)
          (import(module:'game_function.newrecord.mt'))(wish:world.wish);
        setupDefaultHud();


        world.scenario.resume();
      },
    
      startNew ::(name, scenario, seed){
        loading(
          message: 'Creating world...',
          do ::{
            setupDefaultHud();
            this.savestate(saveOverride:{}, nameOverride:name); // overwrite any current iteration and dont use the data
            world.start(name, scenario, seed);
          }
        )
      },
      
      gameOver ::(reason) {


        windowEvent.queueCustom(
          keep : true,
          jumpTag: "GameOver",
          renderable : {
            render :: {
              @:canvas = import(module:'game_singleton.canvas.mt');
              canvas.fill();
              canvas.commit();
            }
          },
          onEnter :: {
              
            windowEvent.queueMessage(
              text: reason
            );

            windowEvent.queueMessage(
              text: 'Game Over'
            );

            this.unlockScenarios();
            this.unlockSeeds();

            
            windowEvent.queueCustom(
              onEnter :: {
                windowEvent.jumpToTag(name:'MainMenu', doResolveNext:true);
              }
            );          
          }
        );

      },
      
      unlockScenarios :: {
        if (settings.unlockedScenarios == false || settings.unlockedScenarios == empty) ::<= {
          settings.unlockedScenarios = true;
          onSaveSettings_(data:JSON.encode(object:settings));
          
          windowEvent.queueMessage(
            text: "Alternate scenarios of gameplay now unlocked. You can start a new game at anytime to try them."
          );
        }      
      },
      
      unlockSeeds :: {
        if (settings.unlockedSeeds == false || settings.unlockedSeeds == empty) ::<= {
          settings.unlockedSeeds = true;
          onSaveSettings_(data:JSON.encode(object:settings));
          
          windowEvent.queueMessage(
            text: "World RNG seeding is now unlocked. You can set seeds on world creation to recreate the conditions for a world. The RNG is used across all gameplay aspects of that world."
          );
        }      
      },      
      x:{ set ::(value) <- save},//+=1},
      y:{get ::<- save},
      

        
      
      onSaveState : {
        set ::(value) <- onSaveState = value
      },
      onLoadState : {
        set ::(value) <- onLoadState = value
      },
      
      quicksave :: {
        this.savestate(
          nameOverride: world.saveName + QUICK_SAVE_SUFFIX
        );
      },
      
      
      savestate ::(nameOverride, saveOverride) {
        when((world.saveName == empty || world.saveName == '') && 
             (nameOverride == empty   || nameOverride == '')) empty;
        onSaveState(
          slot:if (nameOverride) nameOverride else world.saveName, 
          data:if (saveOverride) saveOverride else world.save()
        )
      },

      save ::{  
        @:State = import(module:'game_class.state.mt');
        @:w = world.save();
        return w;
      },
      
      
      resetDatabase :: {
        Database.reset();
        foreach(modMainOrdered) ::(i, modMain) {
          modMain.onDatabaseStartup();
        }
      },
      
      getSaveDataRaw::(slot) <- onLoadState(slot:if (slot) slot else world.saveName),
      
      quitRun ::{
        world.resetAll();
        Database.reset();
        windowEvent.jumpToTag(name:'MainMenu');
      },
    }
  }
).new();
