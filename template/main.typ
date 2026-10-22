#import "@preview/typo-stp:0.1.1": *

#show: template

#outline()

#include "document/example.typ"

#bibliography("sources.bib")

#appendix(
  "обязательное",
  "Секретный DeepSeek API"
)
#include "document/appendix.typ"

// Пока что не работает

#appendix(
  "обязательное",
  "Листинг кода"
)

#source-text(
  "../README.md",
  "README",
)
// #source-text(
//   "document/appendix.typ",
//   "appendix.typ",
// )
// #source-text(
//   "main.typ",
//   "main.typ",
// )

#appendix(
  "рекомендуемое",
  "Самый секретный DeepSeek API"
)
#include "document/appendix.typ"

#appendix(
  "справочное",
  "Наиболее секретный DeepSeek API, никто вообще не в курсе, что это"
)
#include "document/appendix.typ"

