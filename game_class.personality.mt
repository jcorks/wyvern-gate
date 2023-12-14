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
@:Random = import(module:'game_singleton.random.mt');
@:StatSet = import(module:'game_class.statset.mt');
@:Database = import(module:'game_class.database.mt');

@:SPEECH_EVENT = {
    HURT : 0,
    DEATH : 1,
    CHAT : 2,
    GREET : 3,
    ADVENTURE_ACCEPT: 4,
    ADVENTURE_DENY: 5,
    INAPPROPRIATE_TIME: 6
}

@:Personality = Database.newBase(
    name : 'Wyvern.Personality',
    attributes : {
        name : String,
        growth : StatSet.type,
        phrases : Object            
    },
    
    statics : {
        SPEECH_EVENT : {get::<-SPEECH_EVENT}    
    },
    
    getInterface::(this) {
        return {
            getPhrase ::(kind => Number) {
                return Random.pickArrayItem(list:this.instance.phrases[kind]);
            }        
        }
    }
)

Personality.new(data: {
    name: 'Calm',
    growth : StatSet.new(
        HP : 0,
        AP : 1,
        ATK: 0,
        DEF: 2,
        INT: 1,
        LUK: 0,
        SPD: -1,
        DEX: 1                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            '..Hrg!',
            '..Hg..',
            '..gah!'
        ],
        
        SPEECH_EVENT.DEATH : [
            'I.. how.. did..',
            'Avenge me...',
            'How did this happen..?'
        ],
        
        SPEECH_EVENT.CHAT : [
            'Tell me, how did we find ourselves here..',
            "You ever visit here before? It's rather lively.",
            '... *Achoo*! Much too right now cold for me..',
            "Well, not every place can be worth a visit",
            'Did you here that joke at the tavern earlier? It was... well. It was something.',
            "Don't forget to take a deep breath every now and then. Breathing is an important part of life! Or so I'm told.",
            "Hmm. I suppose we all do make a good team."
        ],
        
        SPEECH_EVENT.GREET : [
            "How's it goin'?",
            "Quite a fine day today.",
            "Mmmm a nice breeze coming in."
        ],

        
        SPEECH_EVENT.ADVENTURE_ACCEPT : [
            "Sure, why not!",
            "Hmm, could be fun!",
        ],

        SPEECH_EVENT.ADVENTURE_DENY : [
            "Mmm, no thanks.",
            "Sounds nice, but no thanks."
        ],
        
        SPEECH_EVENT.INAPPROPRIATE_TIME : [
            "I don't think nows the right time for that...",
            "Maybe later would be better for this."
        ],


    }

})

Personality.new(data: {
    name: 'Friendly',
    growth : StatSet.new(
        HP : 1,
        AP : 2,
        ATK: 0,
        DEF: 1,
        INT: 2,
        LUK: 0,
        SPD: -2,
        DEX: 1                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            '..Hrg!',
            '..Hg..',
            '..gah!'
        ],
        
        SPEECH_EVENT.DEATH : [
            'I.. how.. did..',
            'Avenge me...',
            'How did this happen..?'
        ],
        
        SPEECH_EVENT.CHAT : [
            'Tell me, how did we find ourselves here..',
            "You ever visit here before? It's rather lively.",
            '... *Achoo*! Much too right now cold for me..',
            "Well, not every place can be worth a visit",
            'Did you here that joke at the tavern earlier? It was... well. It was something.',
            "Don't forget to take a deep breath every now and then. Breathing is an important part of life! Or so I'm told.",
            "Hmm. I suppose we all do make a good team."
        ],
        
        SPEECH_EVENT.GREET : [
            "How's it goin'?",
            "Quite a fine day today.",
            "Mmmm a nice breeze coming in."
        ],

        
        SPEECH_EVENT.ADVENTURE_ACCEPT : [
            "Sure, why not!",
            "Hmm, could be fun!",
        ],

        SPEECH_EVENT.ADVENTURE_DENY : [
            "Mmm, no thanks.",
            "Sounds nice, but no thanks."
        ],
        
        SPEECH_EVENT.INAPPROPRIATE_TIME : [
            "I don't think nows the right time for that...",
            "Maybe later would be better for this."
        ],


    }

})


Personality.new(data:{
    name: 'Short-tempered',
    growth : StatSet.new(
        HP : 2,
        AP : -2,
        ATK: 3,
        DEF: -1,
        INT: 0,
        LUK: -1,
        SPD: 3,
        DEX: -2                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            '..Enough!',
            'Ack.. You will regret that!',
            '..gah!'
        ],
        
        SPEECH_EVENT.DEATH : [
            'You will.. regret that..',
            "Don't just.. stare at me as I die... kill them..!..",
            "I can't.. believe this.."
        ],
        
        SPEECH_EVENT.CHAT : [
            "I don't get paid enough to chit-chat",
            "Listen, don't get me wrong. You're... nice. But don't talk to me.",
            "I don't trust the people here.",
            "...Do you mind."
        ],
        
        SPEECH_EVENT.GREET : [
            "..What do you want?",
            "I don't have time for this.",
            "Do we really have to talk?"
        ],
        
        SPEECH_EVENT.ADVENTURE_DENY : [
            "Don't waste my time.",
            "Why would you ask me that?",
        ],

        SPEECH_EVENT.ADVENTURE_ACCEPT : [
           "Fine, whatever.",
           "Sure okay, just stop talking."
        ],

        SPEECH_EVENT.INAPPROPRIATE_TIME : [
            "What are you doing this now for??",
            "We don't have time for this!"
        ],

          
    }

})

Personality.new(data:{
    name: 'Quiet',
    growth : StatSet.new(
        HP : 1,
        AP : 3,
        ATK: 0,
        DEF: 0,
        INT: 5,
        LUK: -1,
        SPD: -1,
        DEX: 2                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            '...',
            'Hh...'
        ],
        
        SPEECH_EVENT.DEATH : [
            '...No..'
        ],
        
        SPEECH_EVENT.CHAT : [
            "...",
            "...We don't.. have to talk..",
            "..Hope you're well..",
            "...I don't have a good feeling about this place..."
        ],
        
        SPEECH_EVENT.GREET : [
            "Hi...",
            "How are you..",
            "..I... we're you talking to me..?"
        ],
        
        SPEECH_EVENT.ADVENTURE_ACCEPT : [
            "... Okay....",
            "...Alright...",
        ],

        SPEECH_EVENT.ADVENTURE_DENY : [
            "...I'm sorry..",
            "...N-no..."
        ], 
        SPEECH_EVENT.INAPPROPRIATE_TIME : [
            "... I don't think we should do this now.."
        ],
        
    }

})

Personality.new(data:{
    name: 'Charismatic',
    growth : StatSet.new(
        HP : -2,
        AP : 2,
        ATK: -2,
        DEF: 2,
        INT: 5,
        LUK: 6,
        SPD: 0,
        DEX: 0                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            'Try that again; see what happens!',
            'Stop that!'
        ],
        
        SPEECH_EVENT.DEATH : [
            '...Well, that was... bad.',
            '...Lend me a hand here, would ya..'
        ],
        
        SPEECH_EVENT.CHAT : [
            "Remember: if you're not the one dealing, you're the one being dealt.",
            "If you want a good deal, hit me up and let ME do the talking with the merchant.",
            "You ever sing? I swear it's the best thing letting the world hear your voice like that..."
        ],
        SPEECH_EVENT.GREET : [
            "Hey! what can I do ya for?",
            "My my, what a cute smile!"
            
        ],
        
        SPEECH_EVENT.ADVENTURE_ACCEPT : [
            "Sure, why not!",
            "Hmm, could be fun!",
        ],

        SPEECH_EVENT.ADVENTURE_DENY : [
            "Mmm, no thanks.",
            "Sounds nice, but no thanks."
        ],
        SPEECH_EVENT.INAPPROPRIATE_TIME : [
            "If you could find another time to do that, that would be great...",
            "Why now, of all times?!"
        ],
        
    }

})

Personality.new(data:{
    name: 'Caring',
    growth : StatSet.new(
        HP : 1,
        AP : 2,
        ATK: -2,
        DEF: 3,
        INT: 3,
        LUK: 6,
        SPD: -1,
        DEX: 3                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            'Urgh, be careful.'
        ],
        
        SPEECH_EVENT.DEATH : [
            'I need... to survive.. for them..'
        ],
        
        SPEECH_EVENT.CHAT : [
            'Hey, you doing okay? You look a little pale..',
            "Next time we go to the market, we should get something fun for the party. Maybe something sweet?",
            "Don't forget to check in with yourself every now and then. It's easy to get swept up and forget what's really important."
        ],
        SPEECH_EVENT.GREET : [
            "How can I help ya, hon?",
            "Hey, good to see ya."
        ],
        
        SPEECH_EVENT.ADVENTURE_ACCEPT : [
            "Sure thing, sweetie!",
            "Well doesn't that sound fun!"
        ],

        SPEECH_EVENT.ADVENTURE_DENY : [
            "Mmm, thanks for the offer but I got plenty to tend to here. Sorry, hon."
        ],  
        SPEECH_EVENT.INAPPROPRIATE_TIME : [
            "I don't think we should do this right now."
        ],
        
           
    }

})

Personality.new(data:{
    name: 'Cold',
    growth : StatSet.new(
        HP : 0,
        AP : 4,
        ATK: 2,
        DEF: -1,
        INT: 2,
        LUK: -4,
        SPD: 2,
        DEX: 1                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            "Stop that."
        ],
        
        SPEECH_EVENT.DEATH : [
            "..."
        ],
        
        SPEECH_EVENT.CHAT : [
            "I don't understand why we don't just murder the next merchant and take their wares.",
            "Stop. Talking. Your voice is annoying and makes my head hurt.",
            "Your skills leave much to be desired, no offence."
        ],
        SPEECH_EVENT.GREET : [
            "What do you want?",
            "Make it quick.",
            "Do you actually have anything to say or are you just wasting my time?"
        ],
        
        SPEECH_EVENT.ADVENTURE_DENY : [
            "Don't waste my time.",
            "Why would you ask me that?"
        ],

        SPEECH_EVENT.ADVENTURE_ACCEPT : [
           "Fine, whatever.",
           "Sure okay, just stop talking."
        ],
        SPEECH_EVENT.INAPPROPRIATE_TIME : [
            "What are you doing this now for??",
            "We don't have time for this!"
        ],
    }

})

Personality.new(data:{
    name: 'Disconnected',
    growth : StatSet.new(
        HP : -4,
        AP : 6,
        ATK: -3,
        DEF: -2,
        INT: 10,
        LUK: 0,
        SPD: -2,
        DEX: -1                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            "..."
        ],
        
        SPEECH_EVENT.DEATH : [
            "..."
        ],
        
        SPEECH_EVENT.CHAT : [
            "...I don't know.",
            "..."
        ],
        SPEECH_EVENT.GREET : [
            "..."            
        ],
        
        SPEECH_EVENT.ADVENTURE_DENY : [
            "... No."
        ],

        SPEECH_EVENT.ADVENTURE_ACCEPT : [
           "...Yes."
        ],
        SPEECH_EVENT.INAPPROPRIATE_TIME : [
           "...Not now."
        ],
                     
    }

})
/*
Personality.new(data:{
    name: 'Unpredictable',
    growth : StatSet.new(
        HP : 1,
        AP : 2,
        ATK: 2,
        DEF: 4,
        INT: 5,
        LUK: 10,
        SPD: 4,
        DEX: 1                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            "That didn't even hurt!~ Come onnn"
        ],
        
        SPEECH_EVENT.DEATH : [
            "Just... give me a minute here.."
        ],
        
        SPEECH_EVENT.CHAT : [
            "Do you ever think about how the ground is like the opposite of the ceiling, but the ceiling is sometimes the sky...",
            "Gimme a sec, I REALLY need to look at that rock over there.",
            "Hey. Wait. Don't say anything. I know EXACTLY what you're thinking. And yes: I DO like frogs."
        ],
        
        SPEECH_EVENT.GREET : [
            "Is it fate that brought us together?",
            "...Wait what year is it"
        ],

        
        SPEECH_EVENT.ADVENTURE_DENY : [
            "Nope Nooo no no no."
        ],

        SPEECH_EVENT.ADVENTURE_ACCEPT : [
           "YEAH LETS GO"
        ],
        
        SPEECH_EVENT.INAPPROPRIATE_TIME : [
            "What are you doing this now for??",
            "We don't have time for this!"
        ],
        
    }

})
*/

Personality.new(data:{
    name: 'Inquisitive',
    growth : StatSet.new(
        HP : 2,
        AP : 3,
        ATK: 0,
        DEF: 1,
        INT: 8,
        LUK: 1,
        SPD: -2,
        DEX: -3                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            "Interesting."
        ],
        
        SPEECH_EVENT.DEATH : [
            "Nice move..."
        ],
        
        SPEECH_EVENT.CHAT : [
            "My own knowledge is limited by the experience I still lack. Let's push forward",
            "Do you know if they have a library in town?"
        ],
        SPEECH_EVENT.GREET : [
            "How are you on this fine day?"
        ],
        
        
        SPEECH_EVENT.ADVENTURE_DENY : [
            "It doesn't interest me. Sorry!"
        ],

        SPEECH_EVENT.ADVENTURE_ACCEPT : [
           "Could be a good time!"
        ],
        
        SPEECH_EVENT.INAPPROPRIATE_TIME : [
            "Why now, of all times?"
        ],
                         
    }

})

Personality.new(data:{
    name: 'Curious',
    growth : StatSet.new(
        HP : 2,
        AP : 4,
        ATK: 1,
        DEF: 5,
        INT: 4,
        LUK: 1,
        SPD: -4,
        DEX: -1                    
    ),
    phrases : {
        SPEECH_EVENT.HURT : [
            "Ough.."
        ],
        
        SPEECH_EVENT.DEATH : [
            "..How.."
        ],
        
        SPEECH_EVENT.CHAT : [
            "Sometimes you just have to sit back and think about how you got here."
        ],

        SPEECH_EVENT.GREET : [
            "How are you on this fine day?"
        ],            
        
        SPEECH_EVENT.ADVENTURE_DENY : [
            "It doesn't interest me. Sorry!"
        ],

        SPEECH_EVENT.ADVENTURE_ACCEPT : [
           "Could be a good time!"
        ],            
        SPEECH_EVENT.INAPPROPRIATE_TIME : [
            "Why now, of all times?"
        ],
    }

})

return Personality;
