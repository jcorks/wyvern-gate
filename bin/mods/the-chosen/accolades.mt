@:WyvernGate = import(:'wyvern-gate.mt');
@:Accolade = WyvernGate.Accolade

return [
  Accolade.new(
    message : 'The true Chosen.',
    info: 'Accepted the Wyvern of Light\'s quest.',
    condition::(world)<- world.accoladeEnabled(name:'acceptedQuest')
  ),
  
  Accolade.new(
    message: 'Let\'s be friends?',
    info: 'Visited at least one of the Wyverns after fighting.',
    condition::(world)<- world.accoladeEnabled(name:'wyvernsRevisited')
  ),
  
  Accolade.new(
    message: 'I\'d buy that for a dollar! Barely.',
    info: 'Bought a worthless item.',
    condition ::(world)<- world.accoladeEnabled(name:'boughtWorthlessItem')
  ),
  
  Accolade.new(
    message: 'You know, there were some pretty powerful people you didn\'t have in your party that would have made your quest a lot easier. Good job!',
    info: 'Didn\'t recruit an over-powered party member.',
    condition ::(world)<- world.accoladeEnabled(name:'recruitedOPNPC') == false
  ),
  
  Accolade.new(
    message: "Not-so-thrifty spender!",
    info: 'Bought an item worth over 2000G.',
    condition::(world)<- world.accoladeEnabled(name:'boughtItemOver2000G')
  ),
  
  Accolade.new(
    message: 'Where did you find that thing?',
    info: 'Sold an item worth over 500G.',
    condition::(world)<- world.accoladeEnabled(name:'soldItemOver500')
  ),
  
  Accolade.new(
    message: "No really, where did you find that thing?",
    info : 'Sold a worthless item.',
    condition::(world)<- world.accoladeEnabled(name:'soldWorthlessItem')
  ),
  
  Accolade.new(
    message: "Lucky, lucky!",
    info : 'Won a gambling game.',
    condition::(world)<- world.accoladeEnabled(name:'wonGamblingGame')    
  ),
  
  Accolade.new(
    message: "Honestly, the Arena is a little brutal...",
    info : 'Won an Arena bet.',
    condition::(world)<- world.accoladeEnabled(name:'wonArenaBet')
  ),
  
  Accolade.new(
    message: "My pockets feel lighter...",
    info: 'Stole an item at least once.',
    condition::(world)<- world.accoladeEnabled(name:'hasStolen')
  ),
  
  Accolade.new(
    message: "Should have kicked them out a while ago.",
    info: 'Fought a drunkard at the tavern.',
    condition::(world)<- world.accoladeEnabled(name:'foughtDrunkard')
  ),
  
  Accolade.new(
    message: "Property destruction is hard sometimes.",
    info: 'Attempted to vandalize a location.',
    condition::(world)<- world.accoladeEnabled(name:'hasVandalized')
  ),
  
  Accolade.new(
    message: "I guess it wasn't that important...",
    info: 'Somehow got rid of a Wyvern Key.',
    condition::(world)<- world.accoladeEnabled(name:'gotRidOfWyvernKey')
  ),
  
  Accolade.new(
    message: "The traps were kind of fun to setup, to be honest.",
    info: 'Fell for traps over 5 times.',
    condition::(world)<- world.accoladeCount(name:'trapsFallenFor') > 5
  ),
  
  Accolade.new(
    message: "Two's company but three's a crowd! ...Assuming no one died.",
    info: 'Recruited a party member.',
    condition::(world)<- world.accoladeCount(name:'recruitedCount') > 0
  ),
  
  Accolade.new(
    message: "Top-notch boxer.",
    info: 'Knocked out over 40 people.',
    condition::(world)<- world.accoladeCount(name:'knockouts') > 40
  ),
  
  Accolade.new(
    message: "You're so nice and not murder-y!",
    info: 'Managed to get through without murdering anyone.',
    condition::(world)<- world.accoladeCount(name:'murders') == 0
  ),
  
  Accolade.new(
    message: "A trustworthy friend.",
    info: 'Managed to get through without losing a party member.',
    condition::(world)<- world.accoladeCount(name:'deadPartyMembers') == 0
  ),
  
  Accolade.new(
    message: "Tinkerer!",
    info: 'Improved an items over 5 times.',
    condition::(world)<- world.accoladeCount(name:'itemImprovements') > 5
  ),
  
  Accolade.new(
    message: "Someone was thirsty I guess.",
    info: 'Took over 15 drinks at a tavern.',
    condition::(world)<- world.accoladeCount(name:'drinksTaken') > 15
  ),
  
  Accolade.new(
    message: "Goody-two-shoes!",
    info: 'Generally was nice and avoided doing bad stuff too often.',
    condition::(world)<- world.party.karma > 5000
  ),
  
  Accolade.new(
    message: "I think it\'s vibrating...",
    info: 'Unlocked additional power of weapons over 5 times.',
    condition::(world)<- world.accoladeCount(name:'intuitionGained') > 5
  ),
  
  Accolade.new(
    message: "I know exactly what I'm going to do with my 20 dollars...",
    info: 'Bought over 20 items.',
    condition::(world)<- world.accoladeCount(name:'buyCount') > 20
  ),
  
  Accolade.new(
    message: "Easy money.",
    info: 'Sold over 40 items.',
    condition::(world)<- world.accoladeCount(name:'sellCount') > 40
  ),
  
  Accolade.new(
    message: "Someone likes Roman numerals.",
    info: 'Enchanted items over 5 times.',
    condition::(world)<- world.accoladeCount(name:'enchantmentsReceived') > 5
  ),
  
  Accolade.new(
    message: "Well, that was a waste of time.",
    info: 'Took less than 10 days.',
    condition::(world)<- world.accoladeCount(name:'daysTaken') < 10
  ),
  
  Accolade.new(
    message: "Finders, keepers!",
    info: 'Opened more than 15 chests.',
    condition::(world)<- world.accoladeCount(name:'chestsOpened') > 15
  ),
  
  Accolade.new(
    message: "We're all sentimental creatures, really...",
    info: 'Kept the Sentimental Box.',
    condition::(world) <- world.party.inventory.items->filter(by:
      ::(value) <- value.base.name == 'Sentimental Box'
    )->size > 0
  )
]
