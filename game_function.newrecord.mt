@:world = import(module:'game_singleton.world.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');



// excludes last one
@:accoladesAchievedCount ::{
    @count = 0;
    for(0, accolades->size-1) ::(i) {
        if (accolades[i].condition())
            count += 1
    }
    return count;
}

@: accolades = [
    {
        message : 'The true Chosen.',
        info: 'Accepted the Wyvern of Light\'s quest.',
        condition::<- world.accoladeEnabled(name:'acceptedQuest')
    },
    
    {
        message: 'Let\'s be friends?',
        info: 'Visited at least one of the Wyverns after fighting.',
        condition::<- world.accoladeEnabled(name:'wyvernsRevisited')
    },
    
    {
        message: 'I\'d buy that for a dollar! Barely.',
        info: 'Bought a worthless item.',
        condition ::<- world.accoladeEnabled(name:'boughtWorthlessItem')
    },
    
    {
        message: 'You know, there were some pretty powerful people you didn\'t have in your party that would have made your quest a lot easier. Good job!',
        info: 'Didn\'t recruit an over-powered party member.',
        condition ::<- world.accoladeEnabled(name:'recruitedOPNPC')
    },
    
    {
        message: "Not-so-thrifty spender!",
        info: 'Bought an item worth over 4000G.',
        condition::<- world.accoladeEnabled(name:'boughtItemOver4000G')
    },
    
    {
        message: 'Where did you find that thing?',
        info: 'Sold an item worth over 4000G.',
        condition::<- world.accoladeEnabled(name:'soldItemOver4000')
    },
    
    {
        message: "No really, where did you find that thing?",
        info : 'Sold a worthless item.',
        condition::<- world.accoladeEnabled(name:'soldWorthlessItem')
    },
    
    {
        message: "Lucky, lucky!",
        info : 'Won a gambling game.',
        condition::<- world.accoladeEnabled(name:'wonGamblingGame')
    
    },
    
    {
        message: "Honestly, the Arena is a little brutal...",
        info : 'Won an Arena bet.',
        condition::<- world.accoladeEnabled(name:'wonArenaBet')
    },
    
    {
        message: "My pockets feel lighter...",
        info: 'Stole an item at least once.',
        condition::<- world.accoladeEnabled(name:'hasStolen')
    },
    
    {
        message: "Should have kicked them out a while ago.",
        info: 'Fought a drunkard at the tavern.',
        condition::<- world.accoladeEnabled(name:'foughtDrunkard')
    },
    
    {
        message: "Property destruction is hard sometimes.",
        info: 'Attempted to vandalize a location.',
        condition::<- world.accoladeEnabled(name:'hasVandalized')
    },
    
    {
        message: "I guess it wasn't that important...",
        info: 'Somehow got rid of a Wyvern Key.',
        condition::<- world.accoladeEnabled(name:'gotRidOfWyvernKey')
    },
    
    {
        message: "The traps were kind of fun to setup, to be honest.",
        info: 'Fell for a trap over 5 times.',
        condition::<- world.accoladeCount(name:'trapsFallenFor') > 5
    },
    
    {
        message: "Two's company but three's a crowd! ...Assuming no one died.",
        info: 'Recruited a party member.',
        condition::<- world.accoladeCount(name:'recruitedCount') > 0
    },
    
    {
        message: "Top-notch boxer.",
        info: 'Knocked out over 40 people.',
        condition::<- world.accoladeCount(name:'knockouts') > 40
    },
    
    {
        message: "You're so nice and not murder-y!",
        info: 'Managed to get through without murdering anyone.',
        condition::<- world.accoladeCount(name:'murders') == 0
    },
    
    {
        message: "A trustworthy friend.",
        info: 'Managed to get through without losing a party member.',
        condition::<- world.accoladeCount(name:'deadPartyMembers') == 0
    },
    
    {
        message: "Tinkerer!",
        info: 'Improved an items over 5 times.',
        condition::<- world.accoladeCount(name:'itemImprovements') > 5
    },
    
    {
        message: "Someone was thirsty I guess.",
        info: 'Took over 15 drinks at a tavern.',
        condition::<- world.accoladeCount(name:'drinksTaken') > 15
    },
    
    {
        message: "Goody-two-shoes!",
        info: 'Generally was nice and avoided doing bad stuff too often.',
        condition::<- world.party.karma > 5000
    },
    
    {
        message: "Smart fella.",
        info: 'Gained intuition over 5 times.',
        condition::<- world.accoladeCount(name:'intuitionGained') > 5
    },
    
    {
        message: "Thrifty spender!",
        info: 'Bought over 20 items.',
        condition::<- world.accoladeCount(name:'buyCount') > 20
    },
    
    {
        message: "Easy money.",
        info: 'Sold over 20 items.',
        condition::<- world.accoladeCount(name:'sellCount') > 20
    },
    
    {
        message: "Someone likes Roman numerals.",
        info: 'Enchanted items over 5 times.',
        condition::<- world.accoladeCount(name:'enchantmentsReceived') > 5
    },
    
    {
        message: "Well, that was a waste of time.",
        info: 'Took less than 10 days.',
        condition::<- world.accoladeCount(name:'daysTaken') < 10
    },
    
    {
        message: "Finders, keepers!",
        info: 'Opened more than 15 chests.',
        condition::<- world.accoladeCount(name:'chestsOpened') > 15
    },
    
    {
        message: "Either you've done research, or you're really adventurous. Awesome job!",
        info: 'Earned every accolade.',
        condition::<- accoladesAchievedCount() == accolades->size-1
    }
]






return ::(wish) {

    windowEvent.queueNoDisplay(
        keep : true,
        onEnter ::{

            @initialMessage = ' - Congratulations, Chosen! - \n\n';

            initialMessage = initialMessage + '"I wish for: ' + wish + '"\n\n'

            
            foreach(world.party.members) ::(k, member) {
                initialMessage = initialMessage + member.name + ' - ' + member.species.name + ', ' + member.profession.base.name + '\n'
            }
            
            initialMessage = initialMessage + '\n\nWorld - ' + world.saveName + '\n';

            initialMessage = initialMessage + 'Knockouts:          ' + world.accoladeCount(name:'knockouts') + '\n';
            initialMessage = initialMessage + 'Murders:            ' + world.accoladeCount(name:'murders') + '\n';
            initialMessage = initialMessage + 'Party members lost: ' + world.accoladeCount(name:'deadPartyMembers') + '\n';
            initialMessage = initialMessage + 'Chests opened:      ' + world.accoladeCount(name:'chestsOpened') + '\n';


            windowEvent.queueMessage(
                text:initialMessage,
                pageAfter:20
            )
            
            
            @:displayAccolade::(accolade) {
                @message = 'You\'ve earned the accolade:\n"' + accolade.message + '"\n\n';
                message = message + '(' + accolade.info +")";
                windowEvent.queueMessage(text:message);
            }
            
            foreach(accolades) ::(i, accolade)  {
                if (accolade.condition())
                    displayAccolade(accolade)
            }
            
            windowEvent.queueMessage(
                text: 'Thanks for playing!' + '\n' +
                      'Come suggest stuff at https://github.com/jcorks/wyvern-gate',
                      
                onLeave ::{
                    windowEvent.jumpToTag(name:'MainMenu');        
                }
            );

        },
        renderable : {
            render ::{
                canvas.blackout()
            }
        }
    );

}
