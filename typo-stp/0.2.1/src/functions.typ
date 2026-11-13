#import "constants.typ" : *

// функция листинга файла
#let source-text(path, name) = {
  // чтение содержимого файла

  let file-content = read(path)
    // обрезка переносов строк в файле 
    .trim(at: end, "\n")
    .trim(at: start, "\n")

  [
    // отображаемое название файла
    #text[
      #name
    ]

    // исходный текст файла
    #raw(
      file-content,
      block: true,
    )
  ]
}

#let introduction = heading(numbering: none)[Введение]

#let abstract = heading(numbering: none)[Реферат]

#let conclusion = heading(numbering: none)[Заключение]


// функция создания приложения
// UPD: функция теперь создает фигуру с кастомным kind
// "appendix" - "приложение" что позволяет давать ссылки
// на него, боже почему я так плохо знаю этот язык, что
// только сейчас это смог сделать...
#let appendix(type, name) = figure(
  kind: "appendix",
  // Нумерация - буква приложения
  numbering: (..nums) => {
    appendix-letters.at(
      appendix-counter.get().first()
    )
  },
  supplement: [Приложение], 
  // Никто этим не будет пользоваться, но это нужно для
  // ссылки на приложения

  // Тут идет тело приложения, как было до этого 
  {

    // увеличение счетчика приложений (номер в массиве с буквами)
    appendix-counter.step()

    // сброс счетчиков для рисунков, таблиц в приложениях
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: table)).update(0)
    counter(math.equation).update(0)


    // Полу-костыль, чтобы название приложения 
    // отличалось от того, что в содержании
    show heading: it => {
      align(center)[
        ПРИЛОЖЕНИЕ #context appendix-letters.at(appendix-counter.get().first() - 1)
      ]
    }

    // Формирование приложения как заголовка 1-го уровня,
    // но со специальной нумерацией вида "Приложение Я".
    // Да, именно со всем словом "Приложение"
    heading(
      numbering: appendix-numbering,
    )[(#type) #name]

    // Добавление подписи типа приложения и его названия 
    align(center)[ * (#type) \ #name * ]

    v(1.0em, weak: true)
  }
)

// двухуровневая нумерация для перечислений
// взято из проекта https://github.com/artemious3/bsuir_typst
//
// TODO: если это получится, сделать возможность
// ссылаться на элементы перечислений
#let abclist(..a) = {
  set enum(indent: 25mm, numbering: "1)")

  let items = a.pos().enumerate().map(
    ((idx,item)) => cyr-letters.at(idx) + ") " + item + parbreak()
  )
  parbreak()+items.join()
}

// Функция создания перечня из 2.4.7
//
// terms - Typst Term List для перечня
// supplement - слово, которое будет указано перед перечнем, по дефолту "где",
//              также возможны свои, условно [Здесь], либо none - без слова,
//              каждый символ будет писаться с красной строки
#let explanation(terms, supplement : [где]) = {
  
  // Если есть supplement строится grid 
  if supplement != none {
    set grid(
      columns: (auto, 1fr),
      column-gutter: 0.3em,
    )

    // внешний grid для слова перед перечнем 
    grid(
      // "слово" ну блин я не знаю как это нормально назвать
      // в СТП буквально пишут "Перечень начинают со слова "где"
      supplement, 

      // Правая ячейка grid - список символов
      {
        // Каждый символ преобразуется в внутренний grid
        // из собственно себя, тире и его расшифровки
        // типа [символ] [ -- расшифровка как абзац]
        // "[]" - клетка grid
        terms.children
          .filter(x => x != [ ])
          .map(x => grid(
            { x.term + [ -- ] },
            par(first-line-indent: 0pt)[#x.description]
          )).join()
      }
    )
    // Если нет слова - тупо оформляем как абзацы
    // TODO: понять, что они имели в виду под 
    // "Разрешается расшифровку начинать с обобщающих слов, после которых
    // следует ставить двоеточие, а каждый поясняемый символ начинать с красной
    // строки."
    // Каждый символ делать абзацем или делать как в случае со словом,
    // но с отступом 1.25см?
  } else {
    // символы опять мапятся только в сплошной абзац
    terms.children
      .filter(x => x != [ ])
      .map(x => par(x.term + [ -- ] + x.description))
      .join()
  }
}

// Функция создания grid'а из нескольких рисунков, пронумерованных "а", "б", ...
//
// TODO: если получится, сделать возможность ссылаться на элементы
#let abc-images(multiimages) = grid(
  // Количество столбцов - длина переданного массива 
  columns: multiimages.len(),
  column-gutter: 0.5em,

  // Собственно переданный массив
  ..multiimages,

  // Нумерация каждого элемента "а", "б", ...
  ..multiimages.enumerate()
    .map(x => x.first())
    .map(x => [#cyr-letters.at(x)]),
  )
)

