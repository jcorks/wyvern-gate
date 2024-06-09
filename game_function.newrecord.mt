@:world = import(module:'game_singleton.world.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');
@:canvas = import(module:'game_singleton.canvas.mt');
@:Accolade = import(module:'game_struct.accolade.mt');







return ::(wish) {

  windowEvent.queueCustom(
    keep : true,
    onEnter ::{

      @initialMessage = ' - Congratulations, Chosen! - \n\n';

      initialMessage = initialMessage + '"I wish for: ' + wish + '"\n\n'

      
      foreach(world.party.members) ::(k, member) {
        initialMessage = initialMessage + member.name + ' - ' + member.species.name + ', ' + member.profession.name + '\n'
      }
      
      initialMessage = initialMessage + '\n\nWorld - ' + world.saveName + '\n';

      initialMessage = initialMessage + world.scenario.base.reportCard();

      windowEvent.queueMessage(
        text:initialMessage,
        pageAfter:20
      )
      
      
      @:displayAccolade::(accolade) {
        @message = 'You\'ve earned the accolade:\n"' + accolade.message + '"\n\n';
        message = message + '(' + accolade.info +")";
        windowEvent.queueMessage(text:message);
      }

      @:accolades = [...world.scenario.base.accolades];
      

      // excludes last one
      @:accoladesAchievedCount ::{
        @count = 0;
        for(0, accolades->size-1) ::(i) {
          if (accolades[i].condition(world))
            count += 1
        }
        return count;
      }
      
      
      accolades->push(value:    
        Accolade.new(
          message: "Either you've done research, or you're really adventurous. Awesome job!",
          info: 'Earned every accolade.',
          condition::(world)<- accoladesAchievedCount() == accolades->size-1
        )
      )
      
      foreach(world.scenario.base.accolades) ::(i, accolade)  {
        if (accolade.condition(world))
          displayAccolade(accolade)
      }

      windowEvent.queueMessage(
        text: 'Thanks for playing!' + '\n' +
            'Come suggest stuff at https://github.com/jcorks/wyvern-gate'
      );

      
      @:instance = import(module:'game_singleton.instance.mt');
      instance.queueCredits();
      
      
      windowEvent.queueCustom(
        onEnter ::{},
        onLeave ::{
          windowEvent.jumpToTag(name:'MainMenu');    
          instance.unlockScenarios();
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
