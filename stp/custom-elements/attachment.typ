#import "../constants.typ" : *

// функция создания приложения
#let attachment(type, name) = {
  // увеличение счетчика приложений (номер в массиве с буквами)
  attachment-counter.step()

  // сброс счетчиков для рисунков, таблиц в приложениях
  counter(figure.where(kind: image)).update(0)
  counter(figure.where(kind: table)).update(0)


  // Полу-костыль, чтобы название приложения 
  // отличалось от того, что в содержании
  show heading: it => {
    align(center)[
      #pagebreak()
      ПРИЛОЖЕНИЕ #context attachment-letters.at(attachment-counter.get().first() - 1)
    ]
  }

  // Формирование приложения как заголовка 1-го уровня,
  // но со специальной нумерацией вида "Приложение Я".
  // Да, именно со всем словом "Приложение"
  heading(
    numbering: attachment-numbering,
  )[(#type) #name]

  // Добавление подписи типа приложения и его названия 
  align(center)[ (#type) \ * #name * ]

  v(1.0em, weak: true)
}


