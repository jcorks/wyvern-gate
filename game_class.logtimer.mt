@:lclass = import(module:'game_function.lclass.mt');
@:time = import(module:'Matte.System.Time');

return lclass(
    constructor ::{
        _.trials = [];
    },
    interface : {
        start:: {
            _.currentTrial = {delta : time.getTicks()}
        },
        
        end::(note => String) {
            _.currentTrial.note  = note;
            _.currentTrial.delta = time.getTicks() - _.currentTrial.delta;
            _.trials->push(value:_.currentTrial);
            _.currentTrial = empty;
        },
                    
        clearTrials ::{
            _.trials = [];
        },

        trials : {
            get :: {
                @out = [];
                foreach(_.trials)::(i, trial) {
                    out->push(value:'{['+trial.note+'] -> ' + trial.delta + '}');
                }
                return out;
            }
        }
    }    
);
