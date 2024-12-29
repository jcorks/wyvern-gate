@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');

return ::(onBooted) {
  @:anims = [
    [
      {
        chance : 0.4,
        lines : [
          'Personal Computer KP-X, Vector Inc. 1993',
          'RAM: 4MB... OK!',
          'CPU Check: X80 - pIII @25 MHz, Compute Systemes LLC.',
          'Checking BIOS integrity...'
        ]
      },
      
      
      {
        chance : 0.2,
        lines : [
          'Checking storage media...',
          '  - /dev/flbmp01...OK (boot? yes)',
          '  - /dev/flbmp02...OK (boot? no)',
          'Checking HIDs',
          '  - /dev/sound01...' + if (Number.random() < 0.5) 'Failed to load driver, ignoring.' else 'Hardware error.',
          '  - /dev/kbd01...OK',
          '  - /dev/joypad01...OK (preload)',
          '  - /dev/modem1...Failed to connect (missing phone bill?)',
          'No pointer device detected. Skipping pointer driver',
          'Loading HRAM state...',
          '  - HRAM state: 256K, BOOT: "tOS v1.3.45"',
          'OS stub header:',
          '    [Welcome to tOS!]',
          'OS stub init:',
          '    Preflight:      OK',
          '    Input devices:  OK',
          '    RAM:            OK',
          '    SSDT:           OK',
          '    Power MGT:      OK[mode: DYN]',
          '    PCI Controller: OK[mode: MEMMAP]',
          '    PnP Extension:  OK',
          '    Clock:          OK[2025, Dec  5th, 13:34]',
          '    Last boot:        [1998, Jan 18th, 17:24]',
          'Loading shell...'
        ]
      },
    ],
    [
      {
        clear : true,
        chance : 1,
        lines : [
          'tOS shell ',
          'Enter "help" for commands.',
        ]
      }, 
      
      {
        chance: 0.1,
        lines : [
          '',
          '::> ▓'
        ]
      },   
      {
        typing : true,
        chance : 0.4,
        header : '::> ',
        lines : [
          'cd ./GAMES/JC-RASA/WYVERN-GATE/'
        ]
      },    
      {
        chance : 0.4,
        lines : [
          '::> ▓'
        ]
      },    
      {
        typing : true,
        chance : 0.2,
        header : '::> ',
        lines : [
          'list-contents'
        ]
      },    
      {
        chance : 1,
        lines : [
          ' mods/         |   --       | 1996, Sep  9th, 08:26',
          ' src/          |   --       | 1996, Sep  9th, 08:26',
          ' README.txt    |   2.2  KB  | 1996, Sep  9th, 08:26',
          ' CATALOG       |   1.3  KB  | 1996, Sep  9th, 08:26',
          ' MAILING       |   0.4  KB  | 1996, Sep  9th, 08:26',
          ' CREDITS       |   0.3  KB  | 1996, Sep  9th, 08:26',
          ' wyvern-gate   | 993.5  KB  | 1996, Sep  9th, 08:26',
          '::> ▓'
        ]
      },    
      {
        typing : true,
        chance : 0.2,
        header : '::> ',
        lines : [
          'run ./wyvern-gate'
        ]
      },    

      {
        chance : 1,
        lines : [
          'This executable requires:',
          ' - Keyboard access',
          ' - PnP External device access',
          ' - Terminal control',
          'Continue?',
          '(Y/N): '
        ]
      },    
      {
        typing : true,
        chance : 0.05,
        header : '(Y/N): ',
        lines : [
          'Y'
        ]
      },    
      {
        clear: true,
        chance : 0.3,
        lines : [
          'Loading',
          '',
          '',
        ]
      }
    ]
  ];
  
  
  @alreadyPrinted = [];
  
  @:drawTerminal:: {
    @:from = if (alreadyPrinted->size < canvas.height) 0 else alreadyPrinted->size - canvas.height
    canvas.penX = 0;
    canvas.penY = 0;
    for(from, alreadyPrinted->size) ::(i) {
      canvas.drawText(:alreadyPrinted[i]);
      canvas.penY += 1;
    }
  }
  
  @:clearTerminal ::<- alreadyPrinted = [];

  @:nextAnim = :: {
    @:anim = anims[0];
    anims->remove(key:0);
    @requestTerm = false;
    
    @currentIter = empty;
    windowEvent.queueCustom(
      isAnimation : true,
      animationFrame ::{
        when((anim->size == 0 && currentIter == empty) || requestTerm) canvas.ANIMATION_FINISHED;
        
        if (currentIter == empty) ::<= {
          currentIter = anim[0];
          if (currentIter.clear == true)
            alreadyPrinted = [];
          anim->remove(key:0)
        }
        
        if (currentIter.typing == true) ::<= {
          if (currentIter.iter == empty)
            currentIter.iter = 0

          @:sub = if (currentIter.iter == 0) '' else currentIter.lines[0]->substr(from:0, to:currentIter.iter-1);
            
          if (Number.random() < currentIter.chance) ::<= {
            alreadyPrinted[alreadyPrinted->size-1] = (if (currentIter.header) currentIter.header else '') + sub + '▓';
            currentIter.iter += 1
            
            if (currentIter.iter > currentIter.lines[0]->length) ::<= {
              alreadyPrinted[alreadyPrinted->size-1] = (if (currentIter.header) currentIter.header else '') + currentIter.lines[0]; 
              currentIter = empty;
            }
          }
        } else ::<= {      
          if (Number.random() < currentIter.chance) ::<= {
            when(currentIter.lines->size == 0)
              currentIter = empty;
              
            @:next = currentIter.lines[0];
            currentIter.lines->remove(key:0);
            alreadyPrinted->push(:next);
          }
        }
        drawTerminal();
      },
      
      onInput ::(input) {
        requestTerm = true;
      },
      
      onLeave ::{
        if (anims->size == 0)
          onBooted()
        else 
          nextAnim();
      }
    );
  }
  nextAnim();

}
