@:Topaz   = import(module:'Topaz');

return ::(terminal, onBoot => Function) {
    @:preflight = [
        'CX Systems, 2023',
        'RAM: 512K... OK!',
        'CPU Check: X80 - pIII, Compute Systemes LLC.',
        'Checking BIOS integrity...',
    ];
    @:messages = [
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
        '  - HRAM state: 256K, "tOS v1.3.45"',
        'Welcome to tOS!',
        'Loading shell...'
    ];


    @:printer = Topaz.Entity.create(
        attributes: {
            onStep ::{
                if (Topaz.Input.getState(input:Topaz.Key.space)) ::<= {
                    terminal.clear();
                    printer.remove();
                    onBoot();
                }
                if (preflight->keycount) ::<= {
                    if (Number.random() < 0.2) ::<= {
                        @:next = preflight[0];
                        preflight->remove(key:0);
                        terminal.print(line:next);
                    }
                } else ::<= {
                    if (Number.random() < 0.06) ::<= {
                        @:next = messages[0];
                        messages->remove(key:0);
                        terminal.print(line:next);
                    }
                    if (messages->keycount == 0) ::<= {
                        terminal.clear();
                        printer.remove();
                        onBoot();
                    }
                }
            }
        }
    );
    terminal.attach(child:printer);
}
