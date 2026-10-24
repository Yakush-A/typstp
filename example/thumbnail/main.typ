#import "@preview/typo-stp:0.1.1": *

#show: template

= Первый раздел

== Первый подраздел

===
#lorem(30)

===
#lorem(20)

+ #lorem(20)
+ #lorem(10)
+ #lorem(5)

#figure(
  caption: [Секретный DeepSeek API],
  image(
    "секретный-deepseek-API.png",
    width: 60%,
  ),
)

== Второй подраздел

===
#lorem(22)

$ K = F C^2 $

#lorem(14)

#figure(
  caption: [Допустим, таблица],
  table(
    columns: (1fr, 1fr, 1fr),
    inset: (y: 3pt),
    table.header([Шаблон Typst], [СТП БГУИР], [Версия шаблона]),
    [Да],
    [Почти],
    [0.1.1],
  ),
)
