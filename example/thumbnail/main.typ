#import "@preview/typo-stp:0.2.0": *

#show: template

= Первый раздел

== Первый подраздел

===
#lorem(20)

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
    table.header([Шаблон Typst], [СТП БГУИР], [Версия шаблона]),
    [Да],
    [Почти],
    [0.2.0],
  ),
)
