// ---------------- КОНСТАНТЫ И ФУНКЦИИ -----------------------

// Размер шрифта основного текста
#let font-size = 14pt

// Шрифт основного текста
#let main-font = "Times New Roman"

// Шрифт исходного текста
#let source-text-font = "Courier New"

// Межстрочный интервал
#let line-height = 18pt

// в typst "leading" это не как расстояние между 
// базовыми линиями текста, а их расстояние типа 
// между верхней и нижней границами строки, которые
// указываются в параметрах текста, так что вычисляем
// разницу между межстрочным интервалом и высотой шрифта
#let right-leadind = line-height - font-size


// функция проверки заголовка на отсутствие текста
#let is-heading-empty(h) = {
  // typst не дает нормального способа проверить,
  // пуст ли заголовок, поэтому городим это непотребство
  //
  // (это понадобится для пунктов с заголовками)
  let empty-heading = heading()[]
  
  h.body == empty-heading.body
}

// просто буквы кириллического алфавита для перечислений
#let cyr-letters = "абвгдеёжзиклмнопрстуфхцчшщъыьэюя".clusters()

// счетчик приложений
#let attachment-counter = counter("attachment")

// буквы, доступные для приложений 
// (ну за исключением тех, что в п. 2.7.2)
#let attachment-letters = "АБВГДЕЖИКЛМНПРСТУФХЦШЩЭЮЯ".clusters()

// специальная нумерация для приложений
// (объяснено в создании приложения)
#let attachment-numbering = (..nums) => {
  // получение буквы из массива по счетчику
  let letter = attachment-letters.at(
    attachment-counter.get().first() - 1
  )
  // добавление слова "Приложение"
  [
    Приложение
  ]
  // добавление полученной буквы 
  letter
}

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
}



// специальная нумерация для 2.3.8
// Почему в typst нет стандартной нумерации
// "а.1)" только для кириллицы...
#let refed-enum-numbering(..nums) = {
  let nums = nums.pos()
  let n = nums.last()

  // если уровень перечисления 1 - самый верхний
  // то кириллические буквы
  if nums.len() == 1 {
    h(1.25cm, weak: false)
    cyr-letters.at(n - 1)
  
  // если 2, то число 
  } else {
    h(0.65cm, weak: false) 
    // самый худший костыль
    // просто подгон под 2.5см отступ от
    // левого края листа
    //
    // TODO: исправить это на что-то адекватное
    // Ну, если это возможно, я пока что не знаю как
    str(n)
  }
  [)]
  // добавление скобочки после буквы/числa
}


#let table-headers-counter = counter("table-headers")



// функция листинга файла
#let source-text(path, name) = {
  // чтение содержимого файла 
  let file-content = read(path) 

  [
    // отображаемое название файла
    #text(weight: "bold")[
      #v(1.0em, weak: true)
      #name
    ]
    // исходный текст файла
    #raw(
      file-content,
      block: true,
    )
  ]
}


// TODO: мб разбить это на несколько файлов вообще,
// если это так и будет разрастаться




// -------------------- НАСТРОЙКИ ЭЛЕМЕНТОВ -----------------------

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
  
    // тот самый leading
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
  //
  // Как адекватно сделать выбор типа перечисления...
  // TODO: решить это
  

  // по-дефолту будет нумерация просто 1, 2 и т.д.
  #set enum(
    numbering: "1",
    full: true,
  )

  // TODO: 
  // сделать для автоматической нумерации
  #show enum.item: it => {
    if enum.numbering == "1" {
      str(it.number)
      [ ] 
      it.body
      parbreak()
    } else {
      it
    }
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
    hyphenate: false,         // отключение переносов
  )

  // добавление к заголовкам пробельной строки
  #show heading: it => {
    v(1.0em, weak: true)      // перед всеми заголовками 1 пробельная строка

    // не добавлять абзацный отступ к заголовкам,
    // которые располагаются по-центру
    if it.numbering != none and it.numbering != attachment-numbering {
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
    // 
    // upper т.к. в тексте название д.б.
    // в верхнем регистре, а в содержании
    // в как обычный текст
    // т.е. в документе названия разделов писать по 
    // правилам, условно "Введение", "Обзор литературы"
    // будут отображаться как "ВВЕДЕНИЕ", "ОБЗОР ЛИТЕРАТУРЫ",
    // а в содержании все еще будут в исходном виде
    pagebreak() + upper(it)

  } 

  // Настройка для ненумерованных разделов, чтобы они
  // отображались по-центру
  //
  // Возможно, сделаю отдельные функции для 
  // создания введения, заключения и т.д. 
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

  // пункты не включаются в содержание,
  // если только у них нет заголовка
  #show heading.where(level: 3): set heading(
    outlined: false,
  )


  // TODO: если есть вариант это сделать по-нормальному без
  // ручного прописывания outlined
  //
  // или забить, оно же работает :)

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
    indent: 1em,
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

  #show outline.entry: it => {
    show: set text(
      hyphenate: false,
    )
    it
  }


  #set figure(

    // устанавливает нумерацию раздел.номер
    // или буква приложения.номер
    numbering: (..nums) => {

      // просто номер фигуры
      let n = nums.pos().first()

      // если на данный момент нет приложений 
      // (т.е. фигура в обычном разделе)
      if attachment-counter.get().first() == 0 {
        numbering(
          "1.1",
          counter(heading).get().first(),
          n,
        )

      // если приложение уже обнаружено
      // (т.е. фигура в приложении т.к.
      // откуда взяться разделу после приложения)
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

  // добавление к таблице номера в специальном формате
  #show figure.where(kind: table): it => {
    v(1.0em, weak: true)

    // обнуление счетчика шапок таблиц
    table-headers-counter.update(0)



    // разная нумерация в разделах и приложениях
    // 
    // впринципе, такое уже было в рисунках, еще
    // раз пояснять смысла не вижу
    let table-numbering = [
      #if attachment-counter.get().first() == 0 {
        context counter(figure.where(kind: table)).display()
      } else {
        context attachment-letters.at(attachment-counter.get().first() - 1)
        [.]
        context counter(figure.where(kind: table)).get().first()
      }
    ]

    // Название таблицы (Таблица X -- название)
    //
    // TODO: сделать чтобы название таблицы 
    // не вылазило за пределы таблицы
    show figure.caption: cap => {
      // grid т.к. название д.б. выравнено по левому краю
      // независимо от номера таблицы
      grid(
        columns: (auto, auto),
        column-gutter: 0.3em,

        // Таблица и ее номер
        box({
          cap.supplement
          [ ]
          table-numbering
          cap.separator
        }),
        
        // собственно текст названия таблицы
        align(left)[ 
          #cap.body
        ]
      )
    } 

    // отключение абзацных отступов для названия таблицы
    set par(first-line-indent: 0pt)

    // создание новой таблицы со спец. header'ом
    table(
      fill: none,
      inset: 0pt,
      stroke: 0pt,



      // Просто заберите у меня typst, это закончится плохо
      //
      // Т.к. хедер у таблицы просчитывается только при создании,
      // разные хедеры в начале таблицы и в ее продолжении сделать
      // нельзя. По-факту мы сейчас делаем так, чтобы у таблицы 
      // сверху хедера на ее продолжении писалось "Продолжение таблицы X".
      // Я это делаю через счетчик со своим .display() 
      table.header(
        [
          // при создании этого хедера увеличиваем счетчик:
          // 1 = первый хедер => начало таблицы
          // 2 => продолжение
          #context table-headers-counter.step()

          // вот тут я не понимаю, почему оно не работает, 
          // если это убрать
          // TODO: исправить это недоразумение
          #if table-headers-counter.get().first() == 1 {
            [
              // довавление текста "Продолжение таблицы X"
              #context table-headers-counter.display((..nums) => {
                if table-headers-counter.get().first() > 1 {
                  align(left)[Продолжение таблицы #table-numbering]
                  v(right-leadind)
                }
              })
            ]
          }
        ],
        // TODO: сделать чтобы можно было добавить повторяющийся
        // хедер с нумерованными столбцами, а не только текстом
      ),


      // отступ, т.к. таблица не текст, поэтому тут надо 
      // добавить leading (?)
      v(right-leadind),

      // оставляем старый хедер
      it
    )
    
    // просто отступ 
    v(1.0em, weak: true)
  }

  // делает таблицу разрываемой
  #show figure.where(kind: table): set block(breakable: true)

  // Просто ширина линий
  #set table(
    stroke: 0.75pt + black,

  )

  // шапки таблицы повторяются
  #set table.header(
    repeat: true,
  )


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
    title: none,
    style: "gost-7-1-2003.csl",
    full: true,

  )

  #show bibliography: it => {
    heading(
      numbering: none,
    )[
      Список использованных источников
    ]
    it
  }
  


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

