#import "@preview/typo-stp:0.1.1": *

#show: template

#outline()

#include "example.typ"

// Экспериментальная библиография
#bibliography("sources.yml")

#appendix(
  "обязательное",
  "Секретный DeepSeek API"
)
#include "appendix.typ"


#appendix(
  "обязательное",
  "Листинг кода"
)

#source-text(
  // ОБЯЗАТЕЛЬНО НУЖНО ПИСАТЬ path("путь")
  // т.к. в ином случае Typst будет считать 
  // путь от пакета, что Вам явно не нужно
  path("appendix.typ"),
  "appendix.typ",
)
#source-text(
  path("main.typ"),
  "main.typ",
)

#appendix(
  "рекомендуемое",
  "Самый секретный DeepSeek API"
)
#include "appendix.typ"

#appendix(
  "справочное",
  "Наиболее секретный DeepSeek API, никто вообще не в курсе, что это"
)
#include "appendix.typ"

