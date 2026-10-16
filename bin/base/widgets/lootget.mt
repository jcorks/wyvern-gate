@:canvas = import(module:'core/graphics/canvas.mt');
@:correctA = import(module:'base/util/correcta.mt');
@:windowEvent = import(module:'core/windowevent.mt');
@:Item = import(module:'base/item.mt');


return ::(whom, items) {
  if (whom == empty) whom = 'The party';
  
  when(items->size == 1) ::<= {
    windowEvent.queueMessage(
      text: whom + ' found ' + correctA(word:items[0].name) + ' ' + items[0].starsString,
      colorHints : Item.toColorHints(:items)
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
    colorHints : Item.toColorHints(:items),
    lines
  );
}
