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



import(module:'game_database.arts.mt');
import(module:'game_database.apparelmaterial.mt');
import(module:'game_database.effect.mt');
import(module:'game_database.interaction.mt');
import(module:'game_database.itemcolor.mt');
import(module:'game_database.itemdesign.mt');
import(module:'game_database.itemenchantcondition.mt');
import(module:'game_database.itemquality.mt');
import(module:'game_database.material.mt');
import(module:'game_database.personality.mt');
import(module:'game_database.scene.mt');
import(module:'game_database.species.mt');
import(module:'game_database.book.mt');

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
import(:'game_class.inletset.mt');



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




@:distance::(x0, y0, x1, y1) {
  @xd = x1 - x0;
  @yd = y1 - y0;
  return (xd**2 + yd**2)**0.5;
}
@:JSON = import(module:'Matte.Core.JSON');
@:GIT_COMMIT = import(module:'GIT_COMMIT');
@:VERSION = '0.3.0 - ' + GIT_COMMIT;
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
        canvas.blackout();
      }
    },
    onEnter : do
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
    
    
    this.interface = {
      FEATURES : {
        get :: <- FEATURES
      },
      
      hasFeatures ::<- features_ != 0,
      
      defaultSettings ::{
        settings.fullscreen = true;
        settings.crtShader = true;
        settings.volume = 0.7;
        settings.volumeBGM = 0.3;
        settings.volumeSFX = 0.5;
        settings.bgColor = [33, 33, 58];
        settings.fgColor = [186, 240, 228];
        settings.debugMode = false;
        settings.animations = true;
        this.updateSettings();
      },
      
      optionsMenu:: {
        settings = JSON.decode(string:onLoadSettings_());


        @:opts = ['Reset to default'];
        @:optActs = [::{
          windowEvent.queueAskBoolean(
            prompt: 'Reset all settings?',
            onChoice::(which) {
              if (which == true)
                this.defaultSettings();
            }
          );
        }];
        



        opts->push(:'Animations');
        optActs->push(::{
          windowEvent.queueAskBoolean(
            onGetPrompt::<- 'Toggle Animations? (currently: ' + (if(settings.animations) 'Enabled' else 'Disabled') + ')',
            onChoice::(which) {
              when(which == false) empty;
              settings.animations = !settings.animations;
              windowEvent.autoSkipAnimations = !settings.animations;
              this.updateSettings();
            }
          );
        });


        foreach(FEATURES) ::(k, i) <-
          if ((features_ & i) != 0)
            match(i) {

              (FEATURES.DEBUGGING): ::<={
                opts->push(:'Debug Mode');
                optActs->push(::{
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
                  );
                });
              },


              (FEATURES.FULLSCREEN): ::<={
                opts->push(:'Fullscreen');
                optActs->push(::{
                  windowEvent.queueAskBoolean(
                    onGetPrompt::<- 'Toggle fullscreen? (currently: ' + (if(settings.fullscreen) 'Enabled' else 'Disabled') + ')',
                    onChoice::(which) {
                      when(which == false) empty;
                      settings.fullscreen = !settings.fullscreen;
                      this.updateSettings();
                    }
                  );
                });
              },


              (FEATURES.CRT_SHADER): ::<={
                opts->push(:'CRT Effect');
                optActs->push(::{
                  windowEvent.queueAskBoolean(
                    onGetPrompt::<- 'Toggle CRT? (currently: ' + (if(settings.crtShader) 'Enabled' else 'Disabled') + ')',
                    onChoice::(which) {
                      when(which == false) empty;
                      settings.crtShader = !settings.crtShader;
                      this.updateSettings();
                    }
                  );
                });
              },
              
              (FEATURES.BGFG): ::<={
                opts->push(:'Background color');
                optActs->push(::{
                  colorMenu(prompt: 'BG Color', onChange::<- this.updateSettings(), value:settings.bgColor);
                });

                opts->push(:'Foreground color');
                optActs->push(::{
                  colorMenu(prompt: 'FG Color', onChange::<- this.updateSettings(), value:settings.fgColor);
                });

              },              

              (FEATURES.AUDIO): ::<={
                opts->push(:'Volume: Game');
                optActs->push(::{
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

                opts->push(:'Volume: SFX');
                optActs->push(::{
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
                optActs->push(::{
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
                });
              }
            }
        windowEvent.queueChoices(
          prompt: 'Settings',
          choices : opts,
          onChoice::(choice) {
            optActs[choice-1]();
          },
          keep : true,
          canCancel: true
        );
      },
      
      updateSettings::{
        if (settings.animations == empty)
          settings.animations = true;
        windowEvent.autoSkipAnimations = !settings.animations;
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
        onSaveSettings => Function,
        onLoadSettings => Function,
        onPlaySFX => Function,
        onPlayBGM => Function, // if name is unrecognized, will halt playing music.
        onQuit => Function
      ) {
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
      canvas.blackout(with:'.');
    }
  },
  onEnter ::{
    doMain();
  }
  
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
              @:choices = onListSlots();
              
              choices->sort(comparator:::(a, b) {
                when(a < b) -1;
                when(a > b)  1;
                return 0;
              });
              
              when (choices->size == 0) ::<= {
                windowEvent.queueMessage(text: 'No save files were found.');
              }
              windowEvent.queueChoices(
                choices,
                prompt: 'Load which save?',
                canCancel: true,
                onChoice::(choice) {
                  when(choice == 0) empty;
                  loading(
                    message: 'Loading scenario...',
                    do:: {
                      this.resetDatabase();
                      loading(
                        message: 'Loading save...',
                        do :: {
                          @:data = this.getSaveDataRaw(:choices[choice-1]);
                          world.load(serialized:data);
                          
                          if (save > 0) ::<= {
                            world.disgruntled = true;
                          }
                          
                          if (data.worldlyTether != empty) ::<= {
                            this.savestate(saveOverride:'', nameOverride:'.Quick Save.');
                          }

                          pointOfNoReturn(
                            do::<- this.startResume()
                          );
                        }
                      )
                    }
                  );
                
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
                      canvas.blackout();
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
                          choices : [
                            'Begin',
                            'Set world seed...'
                          ],
                          
                          onChoice::(choice) {
                            when(choice-1 == 0) ::<= {
                              windowEvent.jumpToTag(name:'SEEDSETTING', goBeforeTag:true);
                              this.startNew(name, scenario, seed);
                            }
                            
                            // choose seed.
                            
                            @:enterName = import(module:'game_function.name.mt');

                            windowEvent.queueChoices(
                              onGetPrompt::<- 'Current seed: ' + if (
                                seed == empty) 'set to random.' else 
                                '"' + seed + '"',
                              
                              choices : [
                                'Enter seed',
                                'Clear seed',
                              ],
                              canCancel: true,
                              keep : true,
                              onChoice::(choice) {
                                when(choice-1 == 0) enterName(
                                  prompt: 'Enter a seed.',
                                  canCancel: true,
                                  onDone::(name) {
                                    seed = name;
                                  }
                                );
                                
                                when(choice-1 == 1) 
                                  seed = empty;
                              }
                            );  

                          }
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
                          canvas.blackout();
                        }  
                      },
                      onDone ::(name){
                        @:currentFiles = onListSlots();

                        when(name->charAt(:0) == ' ' || name == ' ')
                          windowEvent.queueMessage(
                            text:'That world name is invalid. It cannot start with spaces.',
                            renderable : {
                              render ::{
                                canvas.blackout();
                              }
                            }
                          );                        


                        when (currentFiles->findIndex(value:name) != -1) ::<= {
                          windowEvent.queueMessage(
                            text:'There\'s already a file named ' + name,
                            renderable : {
                              render ::{
                                canvas.blackout();
                              }
                            }
                          );
                          windowEvent.queueAskBoolean(
                            prompt: 'Overwrite ' + name + '?',
                            renderable : {
                              render ::{
                                canvas.blackout();
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

        windowEvent.clearAll();
        canvas.reset();

        @mods;
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
                  canvas.blackout();
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
      },

      queueCredits :: {
        windowEvent.queueMessage(
          text: 'A game by Johnathan "Rasa" Corkery\n'+
              'https://github.com/jcorks/\n\n' + 
              'Additional Arts Design \n' +
              ' & Game Consultation   : Baph @lovelyabomination\n' +
              'Additional support     : Adrian "Radscale" Hernik\n' +
              'Playtesting            : Baph @lovelyabomination\n' +
              '                         Caleb Dron\n' +
              '                         Cane\n'
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
          
        world.scenario.onResume();
      },
    
      startNew ::(name, scenario, seed){
        loading(
          message: 'Creating world...',
          do ::{
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
              canvas.blackout();
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
                windowEvent.jumpToTag(name:"GameOver", goBeforeTag: true);
              }
            );          
          }
        );

        windowEvent.jumpToTag(name:'MainMenu', doResolveNext:true);
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
      visitCurrentIsland ::(restorePos, atGate, onReady) {  
        
        @:island = world.island;
        

        // check if we're AT a location.
        island.map.title = "(Map of " + island.name + ')';

        if (restorePos == empty) ::<= {
          if (atGate == empty) ::<= {
            @somewhere = LargeMap.getAPosition(map:island.map);
          }
        }

        @hasVisitIsland;
        if (windowEvent.canJumpToTag(name:'VisitIsland'))
          windowEvent.jumpToTag(name:'VisitIsland', goBeforeTag:true, doResolveNext:if(atGate == empty)true else false);
        this.islandTravel();
        hasVisitIsland = true;
        when (restorePos == empty && atGate != empty) ::<= {
          @gate = island.landmarks->filter(by:::(value) <- value.base.id == 'base:wyvern-gate');
          when(gate->size == 0) empty;
          
          gate = gate[0];
          island.map.setPointer(
            x: gate.x,
            y: gate.y
          );         
          
          
          @gategate = gate.locations->filter(by:::(value) <- value.base.id == 'base:gate');
          when(gategate->size == 0) empty;
          
          this.visitLandmark(
            landmark:gate,
            where: ::(landmark)<- gategate[0]
          );        
          
          if (hasVisitIsland && onReady) ::<= {
            windowEvent.onResolveAll(onDone:onReady)
          } else
            if (onReady)
              onReady();
        }
        if (onReady)
          onReady();
      },  

      islandTravel ::{
        @:island = world.island;
        sound.playBGM(name:'world', loop:true);
        when(island == empty)
          error(detail:'No island to make a menu for! Use visitIsland() to set the current island.');
        
        @enteredChoices = false;
        @underFoot;
        @steps = 0;
        @islandTravel = ::{
          windowEvent.queueCursorMove(
            leftWeight: 1,
            topWeight: 1,
            prompt: 'Traveling...',
            jumpTag: 'VisitIsland',
            onMenu :: {
              islandChoices();
            },
            
            renderable : {
              render ::{
                world.landmark = empty;
                island.map.render();
                when(underFoot == empty || underFoot->size == 0) empty;


                
                @:lines = [];
                foreach(underFoot)::(i, arr) {


                  lines->push(value:arr.data.name);

                  //island.map.setPointer(
                  //  x: arr.x,
                  //  y: arr.y
                  //);
                
                }
                canvas.renderTextFrameGeneral(
                  title: 'Nearby:',
                  topWeight : 1,
                  leftWeight : 1,
                  lines
                );
              }
            },
            onMove ::(choice) {
              
              @:target = island.landmarks[choice-1];
              
              
              // move by one unit in that direction
              // or ON it if its within one unit.
              island.map.movePointerFree(
                x: if (choice == windowEvent.CURSOR_ACTIONS.RIGHT) 1 else if (choice == windowEvent.CURSOR_ACTIONS.LEFT) -1 else 0,
                y: if (choice == windowEvent.CURSOR_ACTIONS.DOWN)  1 else if (choice == windowEvent.CURSOR_ACTIONS.UP)   -1 else 0
              );
              island.map.title = island.name + ' : ' + world.timeString + '           ';
              steps += 1;
              
              if (steps%4 == 0)
                world.incrementTime();
              island.step();
              
              // cancel if we've arrived somewhere
              underFoot = island.map.getNamedItemsUnderPointerRadius(radius:5);
              
              foreach(underFoot)::(i, arr) {
                arr.data.discover();
                island.map.discover(data:arr.data);                      
              }
              
            }
          );
        }

        
        
        
        @:islandChoices = ::{   
        
          @islandOptions;
          @choiceActions;
          enteredChoices = true;
          windowEvent.queueChoices(
            leftWeight: 1,
            topWeight: 1,
            prompt: 'What next?',
            renderable: island.map,
            canCancel : true,
            keep: true,
            jumpTag: 'LandmarkInteraction',
            onGetChoices ::{
              islandOptions = [...world.scenario.base.interactionsWalk]->filter(by::(value) <- value.filter(island));
              
              @choices = [];
              choiceActions = [];
              @visitable = island.map.getNamedItemsUnderPointerRadius(radius:5);

              if (visitable != empty) ::<= {
                foreach(visitable)::(i, vis) {
                  choices->push(value:'Visit ' + vis.name); 
                  choiceActions->push(::{
                    @:landmark = vis.data;

                    @where = ::(landmark) <- landmark.gate;

                    when (landmark.base.hasTraits(:Landmark.TRAIT.POINT_OF_NO_RETURN)) ::<= {
                      windowEvent.queueMessage(
                        text: "It may be difficult to return... "
                      );
                      windowEvent.queueAskBoolean(
                        prompt:'Enter?',
                        onChoice::(which) {
                          if (which == true)
                            this.visitLandmark(landmark, where);
                        }
                      )
                    }
                    this.visitLandmark(landmark, where);              
                    if (windowEvent.canJumpToTag(name:'LandmarkInteraction')) ::<= {
                      windowEvent.jumpToTag(name:'LandmarkInteraction', goBeforeTag:true, doResolveNext:true);
                    }                  
                  });       
                }
              }
              
              foreach(islandOptions) ::(k, value) {
                choices->push(:value.name);
                choiceActions->push(::{
                  value.onSelect(island);
                  if (!value.keepInteractionMenu && windowEvent.canJumpToTag(name:'LandmarkInteraction')) ::<= {
                    windowEvent.jumpToTag(name:'LandmarkInteraction', goBeforeTag:true, doResolveNext:true);
                  }              
                })
              }
              choices->push(value: 'Options');
              choiceActions->push(::{
                @:options = [...world.scenario.base.interactionsOptions]->filter(by::(value) <- value.filter(island));
                @:choices = [...options]->map(to::(value) <- value.name);

                windowEvent.queueChoices(
                  leftWeight: 1,
                  topWeight: 1,
                  prompt: 'Options',
                  canCancel : true,
                  keep: true,
                  jumpTag: 'LandmarkInteractionOptions',
                  choices,
                  onChoice::(choice) {
                    when(choice == 0) empty;
                    options[choice-1].onSelect(island);
                    if (!options[choice-1].keepInteractionMenu && windowEvent.canJumpToTag(name:'LandmarkInteractionOptions'))
                      windowEvent.jumpToTag(name:'LandmarkInteractionOptions', goBeforeTag:true, doResolveNext:true);
                  }
                );              
              });
              return choices;
            },
            onChoice::(choice) {
              choiceActions[choice-1]();
            }
          );
        } 
        islandTravel();       
      },

      
      visitLandmark ::(landmark => Landmark.type, where) {
        @:world = import(module:'game_singleton.world.mt');
        when (landmark.base.onVisit(landmark, island:landmark.island) == false) empty;

        world.landmark = landmark;        
        if (where != empty) ::<= {
          where = where(landmark);
          if (where != empty)
            landmark.map.setPointer(
              x:where.x,
              y:where.y
            ); 
        }

        foreach(world.party.members) ::(k, v) {
          v.addOpinion(
            fullName : 'the ' + landmark.name
          );
        }
                    
        
        this.landmarkTravel();
      },
      y:{get ::<- save},
      
      landmarkTravel :: {

        @:windowEvent = import(module:'game_singleton.windowevent.mt');
        @:partyOptions = import(module:'game_function.partyoptions.mt');
        @:Island = import(module:'game_mutator.island.mt');

        @:party = world.party;
        @:landmark = world.landmark;
        landmark.updateTitle();
        @:island = world.island;


        
        @stepCount = 0;
        @choiceActions = [];

        @:landmarkChoices = ::{
          @landmarkOptions;
          windowEvent.queueChoices(
            leftWeight: 1,
            topWeight: 1,
            prompt: 'What next?',
            keep:true,
            canCancel:true,
            onGetChoices ::{
              landmarkOptions = [...world.scenario.base.interactionsWalk]->filter(by::(value) <- value.filter(island, landmark));
              
              choiceActions = [];
              @:choices = [];
              @locationAt = landmark.map.getNamedItemsUnderPointerRadius(:3);
              if (locationAt != empty) ::<= {
                foreach(locationAt)::(i, loc) {
                  if (loc.data.canInteract()) ::<= {
                    choices->push(value:'Check ' + loc.name);
                    choiceActions->push(::{
                      locationAt = loc.data;
                      locationAt.interact();                  
                    });
                  }
                }
              }              
              
              foreach(landmarkOptions) ::(k, value) {
                choices->push(:value.name);
                choiceActions->push(::{
                  value.onSelect(island, landmark);                
                });       
              }
              
              choices->push(value: 'Options');
              choiceActions->push(::{
                @:options = [...world.scenario.base.interactionsOptions]->filter(by::(value) <- value.filter(island, landmark));
                @:choices = [...options]->map(to::(value) <- value.name);

                windowEvent.queueChoices(
                  leftWeight: 1,
                  topWeight: 1,
                  prompt: 'Options',
                  canCancel : true,
                  keep: true,
                  choices,
                  onChoice::(choice) {
                    when(choice == 0) empty;
                    options[choice-1].onSelect(island, landmark);
                  }
                );              
              });
              


              return choices;        
            },
            renderable:landmark.map,
            onChoice::(choice) {
              choiceActions[choice-1]();
            }
          );
        }
        
        @nearby;
        windowEvent.queueCursorMove(
          jumpTag: 'VisitLandmark',
          onMenu ::{
            landmarkChoices()
          },
          renderable:{
            render :: {
              landmark.map.render();
              
              when(nearby == empty || nearby->size == 0) empty;
              
              @:lines = [];
              foreach(nearby)::(index, arr) {
                lines->push(value:arr.name);
              }
              canvas.renderTextFrameGeneral(
                leftWeight: 1,
                topWeight: 1,
                lines,
                title: 'Arrived at:'
              );
            }
          },
          onMove ::(choice) {
          
            // move by one unit in that direction
            // or ON it if its within one unit.
            when(!landmark.map.movePointerAdjacent(
              x: if (choice == windowEvent.CURSOR_ACTIONS.RIGHT) 1 else if (choice == windowEvent.CURSOR_ACTIONS.LEFT) -1 else 0,
              y: if (choice == windowEvent.CURSOR_ACTIONS.DOWN)  1 else if (choice == windowEvent.CURSOR_ACTIONS.UP)   -1 else 0
            )) empty;
            world.incrementTime(isStep:true);
            landmark.step();
            stepCount += 1;

            
            // every 5 steps, heal 1% HP if below 1/5th health
            if (stepCount % 15 == 0) ::<= {
              foreach(party.members)::(i, member) {
                if (member.hp < member.stats.HP * 0.2)
                  member.heal(amount:(member.stats.HP * 0.01)->ceil);
              }
            }
            
            // cancel if we've arrived somewhere
            nearby = landmark.map.getNamedItemsUnderPointerRadius(:3);
            foreach(nearby)::(index, arr) {
              landmark.map.discover(:arr.data);
            }
          }        
        )      
      },
        
      
      onSaveState : {
        set ::(value) <- onSaveState = value
      },
      onLoadState : {
        set ::(value) <- onLoadState = value
      },
      
      quicksave :: {
        @:data = world.save();
        onSaveState(
          slot:'.Quick Save.',
          data
        )
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
