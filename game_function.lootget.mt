@:canvas = import(module:'game_singleton.canvas.mt');
@:correctA = import(module:'game_function.correcta.mt');
@:windowEvent = import(module:'game_singleton.windowevent.mt');


return ::(whom, items) {
  if (whom == empty) whom = 'The party';
  
  when(items->size == 1) ::<= {
    windowEvent.queueMessage(
      text: whom + ' found ' + correctA(word:items[0].name) + ' ' + items[0].starsString
    );
  }
  
  @lines = [
    whom+ ' found: ',
    ...(canvas.columnsToLines(
      columns : [
        items->map(::(value) <- '- ' + correctA(word:value.name)),
        items->map(::(value) <- value.starsString)
      ]
    ))
  ]

  windowEvent.queueDisplay(
    lines
  );
}
