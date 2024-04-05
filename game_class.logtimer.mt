@:class = import(module:'Matte.Core.Class');
@:time = import(module:'Matte.System.Time');

return class(
    define:::(this) {
        @currentTrial;
        @trials = [];
    
        this.interface = {
            start:: {
                currentTrial = {delta : time.getTicks()}
            },
            
            end::(note => String) {
                currentTrial.note  = note;
                currentTrial.delta = time.getTicks() - currentTrial.delta;
                trials->push(value:currentTrial);
                currentTrial = empty;
            },
                        
            clearTrials ::{
                trials = [];
            },

            trials : {
                get :: {
                    @out = [];
                    foreach(trials)::(i, trial) {
                        out->push(value:'{['+trial.note+'] -> ' + trial.delta + '}');
                    }
                    return out;
                }
            }

        }    
    }
);
