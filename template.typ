#let font-size = 14pt
#let main-font = "Times New Roman"
#let source-text-font = "Courier New"
#let line-height = 18pt
#let right-leadind = line-height - font-size

#let cyr-letters = "абвгдеёжзиклмнопрстуфхцчшщъыьэюя".clusters()

#let attachment-counter = counter("attachment")
#let attachment-letters = "АБВГДЕЖИКЛМНПРСТУФХЦШЩЭЮЯ".clusters()

#let template(body) = [

  // Общие настройки шрифта из 2.1.1
  #set text(
    font: main-font,
    size: font-size,
    top-edge: 1em,      // установка top-edge и bottom-edge 
    bottom-edge: 0em,   // чтобы правильно работал leading

    hyphenate: true,    // переносы

    lang: "ru",
  )

  // weak, чтобы перед первым разделом
  // не было пустой 
  #set pagebreak(
    weak: true,
  )

  // Размер листа из того же 2.1.1
  #set page(
    paper: "a4",
    numbering: "1",

    // поля
    margin: (
      top: 2cm,
      bottom: 2cm,
      right: 1.5cm,
      left: 3cm,
    ),

    // по дефолту номер страницы пишется
    // посередине, тут устанавливается
    // в нужное место
    footer: context {
      place(
        bottom + right,
        dy: -1cm,
        counter(page).display(),
      )
    }
  )

  // абзацы
  #set par(
    justify: true,
  
    leading: right-leadind, 
    spacing: right-leadind,

    // абзацный отступ (красная строка)
    first-line-indent: (
      amount: 1.25cm,
      all: true
    ),
  )



  // TODO сделать остальные варианты перечислений

  // простое перечисление 
  #set list(
    tight: true,
    marker: [--],
  )

  #show list.item: it => {
    par()[-- #it.body]

  }


  
  // Перечисление со ссылками на его элементы

  // нумерация для 2.3.8
  //
  // Почему в typst нет стандартной нумерации
  // "а.1)" только для кириллицы...
  #let refed-enum-numbering(..nums) = {
    let nums = nums.pos()
    let n = nums.last()

    if nums.len() == 1 {
      h(1.25cm, weak: false)
      cyr-letters.at(n - 1)
    } else {
      h(0.65cm, weak: false) 
      // самый худший костыль
      // просто подгон под 2.5см отступ от
      // левого края листа
      //
      // TODO исправить это на что-то адекватное
      str(n)
    }
    [)]         // добавление скобочки после буквы/числa
  }

  #set enum(
//    numbering: refed-enum-numbering,
    numbering: "1",
    full: true,
  )

  #show enum.item: it => {
    par[
    #it.number
    #it.body
    ]
  }




  // Заголовки (названия разделов, подразделов, пунктов)
  // (пункты и подпункты могут быть с пустым заголовком)
  #set heading(
    numbering: "1.1.1.1",
    bookmarked: true,
    outlined: true,
  )

  // Настройки текста для заголовков из 2.1.1, 2.2.1 - 2.2.5
  #show heading: set text(
    font: main-font, 
    size: font-size,
    weight: "bold",
    hyphenate: false,    // отключение переносов
  )

  // добавление к заголовкам пробельной строки
  #show heading: it => {
    v(1.0em, weak: true)      // перед всеми заголовками 1 пробельная строка

    if it.numbering != none {
      pad(left: 1.25cm, it)   // абзацный отступ для нумерованных разделов

    } else {                  // для ненумерованных разделов он не нужен
      it
    }

    if it.level < 3 {
      v(1.0em, weak: true)    // только после названий разделов, подразделов
    }
  } 

  // отдельные настройки для разделов
  #show heading.where(level: 1): it => {

    // сброс нумераций для рисунков, таблиц в разделе
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: table)).update(0)

    // добавление разрыва страницы (2.2.6) 
    pagebreak() + it

  } 

  #show heading.where(numbering: none): it => {
    show: set align(center)

    it

  }

  // настройки для пунктов 
  // 
  // !!!
  // В 2.2.5 сказано: "Пункты, как правило, заголовков не имеют"
  // но вообще ни слова, какие правила оформления этих заголовков,
  // так что для самих заголовков формат названий подразделов. 
  // Если же заголовка нет, то как и в примере остается только номер
  // пункта.
  //
  // upd: в 2.1.1 сказано "Названия разделов и подразделов
  // выделяются полужирным шрифтом" т.е. название пунктов, подпт. 
  // должны быть оформлены обычным шрифтом (?)
  //
  // upd2: в 2.2.7 сказано "В содержании заголовки выравнивают, соподчиняя по
  // разделам, подразделам и пунктам (если последние имеют заголовки)..." 
  // Т.е. в содержании нужно указывать пункты, имеющие заголовки
  //
  //
  //
  // typst не дает нормального способа проверить,
  // пуст ли заголовок, поэтому городим это непотребство
  // 
  // ГПТ не смог до этого додуматься
  #let empty-heading = heading()[]

  // проверка заголовка на отсутствие текста
  #let is-heading-empty(h) = {
    h.body == empty-heading.body
  }

  // пункты не включаются в содержание,
  // если только у них нет заголовка
  #show heading.where(level: 3): set heading(
    outlined: false,
  )

  // в зависимости от того, пуст ли заголовок,
  // разное оформление
  #show heading.where(level: 3): it => {

    // если пуст - заголовка нет => номер пункта
    if is-heading-empty(it) {
      parbreak()
      v(1.0em, weak: true)            // почему-то этот отступ убрался (?)

      counter(heading).display()
      [ ]

      // если заголовок не пуст, но не включен в содержание
    } else if not it.outlined {
      
      // отнимаем от счетчика пунктов 1, т.к.
      // будем рекурсивно делать заголовок из
      // этого заголовка
      //
      // это ужасно, знаю
      counter(heading).update(
        (first, second, third) => (first, second, third - 1)
      )

      // рекурсивный заголовок (уже включаемый в содержание)
      heading(
        level: 3,
        outlined: true,
      )[
        #it.body
      ]
    
      // если уже включен - рекурсивный случай
    } else {
      
      // оформление загловка пункта
      parbreak()
      v(1.0em, weak: true)
      counter(heading).display()
      [ ]

      show text: set text(weight: "regular")
      
      it.body
      parbreak()
    }
  }


  // в самом СТП нумерация подпунктов выполнена
  // обычным шрифтом, но явно это не было сказано,
  // так что примем это как норму
  //
  // Подпункты 
  #show heading.where(level: 4): it => {
    show heading: set heading(
      outlined: false,
    )
    show text: set text(
      weight: "regular",
    )

    parbreak()
    counter(heading).display()
    [ ]

  }

  // содержание
  #set outline(
    title: none,
    depth: 3,
  )
  // автоматическое добавление
  // слова "СОДЕРЖАНИЕ", 
  // потому что я не понял как сделать
  // это через title чтобы оно было
  // по-центру и с 1 пробельной строкой
  #show outline: it => {
    align(center)[*СОДЕРЖАНИЕ*] // слово "СОЖЕРЖАНИЕ" из 2.2.7
    v(1.0em, weak: false)       // пробельная строка
    it                          // собственно содержание
  }


  #set figure(

    // устанавливает нумерацию раздел.номер
    // или буква приложения.номер
    numbering: (..nums) => {

      let n = nums.pos().first()

      if attachment-counter.get().first() == 0 {
        numbering(
          "1.1",
          counter(heading).get().first(),
          n,
        )
      } else {
        attachment-letters.at( 
          attachment-counter.get().first() -1
        )
        [.]
        str(n)
      }
    }
  )

  // разделитель "тире" (которое n-dash) из 2.5.5
  #set figure.caption(
    separator: [ -- ],
  )

  // настройки для рисунков (иллюстраций)
  // положение "подрисуночной подписи"
  #show figure.where(kind: image): set figure.caption(position: bottom)
  // надпись и её отступ от самого рисунка
  #show figure.where(kind: image): set figure(
    supplement: "Рисунок",
    gap: 1.0em,
  )
  // добавление отступов перед рисунком и после подписи
  #show figure.where(kind: image): it => {

    v(1.0em + right-leadind, weak: true)
    it
    v(1.0em, weak: true)

  }

  // настройки для таблиц
  //
  // TODO остальные настройки для таблиц
  #show figure.where(kind: table): set figure.caption(position: top)
  #show figure.caption.where(kind: table): set align(left)
  #show figure.where(kind: table): set figure(
    supplement: "Таблица",
    gap: right-leadind,
  )

  #show figure.where(kind: table): it => {

    v(1.0em + right-leadind, weak: true)
    it
    v(1.0em, weak: true)

  }



  // Сноски 
  //
  // Почему так мало описано, как их делать...

  #set footnote(
    numbering: "1)",
  )

  #set footnote.entry(
    gap: right-leadind,
  )

  #show footnote.entry: it => {

    set text(
      size: font-size,
    )
    set par(
      spacing: right-leadind,
      leading: right-leadind,
    )

    h(1.25cm, weak: false)        // абзацный отступ
    it.note
    [ ] 
    it.note.body
  }

  // Всё ?



  // Библиографический указатель
  //
  // ПОЧЕМУ ТУТ НЕТ НОРМАЛЬНОГО bibliography.entry
  // ?????
  // НИКАК НЕЛЬЗЯ ПО-НОРМАЛЬНОМУ СДЕЛАТЬ
  // АБЗАЦНЫЙ ОТСТУП ДЛЯ ИСТОЧНИКОВ
  //
  // P.s. в стилях тоже нельзя сделать именно
  // абзацный отступ
  //
  // TODO Решить вопрос с абзацным отступом для
  // источников в библ. указателе
  #set bibliography(
    title: "СПИСОК ИСПОЛЬЗОВАННЫХ ИСТОЧНИКОВ",
    style: "gost-7-1-2003.csl",
    full: true,

  )
  


  // Формулы
  #set math.equation(
    // нумерация вида (1.1) из 2.4.6
    numbering: (..nums) => {
      numbering(
        "(1.1)",
        counter(heading).get().first(),
        nums.pos().first(),
      )
    },
    // установка номера в правый нижний угол
    // чтобы на многострочных формулах он стоял
    // справа от последней строки
    number-align: right + bottom,
  )

  // Добавление отступов из 2.4.3 
  // я в душе не чаю, как сделать их 
  // 6 и 8 пт в зависимости от наличия 
  // знаков суммы и т.д., поэтому они 
  // всегда 8, но это "Рекомендуется",
  // так что, наверное, можно
  #show math.equation.where(block: true): it => {
    v(8pt, weak: true)
    it 
    v(8pt, weak: true)
  }
  // остальное по формулам вроде зависит
  // уже от того, кто пишет работу

  #show raw: set text(
    font: source-text-font,
  )

  #show raw.where(block: true): it => {
    v(1.0em, weak: false)
    it
    v(1.0em, weak: false)
  }

  #body

]

#let source-text(path, name) = {
  let file-content = read(path) 

  [
    #text(weight: "bold")[
      #name
    ]
    #raw(
      file-content,
      block: true,
    )
  ]
}



#let attachment(
  type,
  name,
) = {
  heading(
    numbering: none,
  )[
    ПРИЛОЖЕНИЕ #context attachment-letters.at(counter("attachment").get().first())
  ]


  align(center)[
    
    (#type)

    * #name *
  ]
  
}

