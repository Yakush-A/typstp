#import "template.typ": *

#show: template

#outline()

#include "test/example.typ"

#bibliography("sources.bib")

#attachment(
  "обязательное",
  "Секретный DeepSeek API"
)
#include "test/attachment.typ"

#attachment(
  "обязательное",
  "Листинг кода"
)
#source-text(
  "main.typ",
  "main.typ",
)

#attachment(
  "рекомендуемое",
  "Самый секретный DeepSeek API"
)
#include "test/attachment.typ"

#attachment(
  "справочное",
  "Наиболее секретный DeepSeek API, никто вообще не в курсе, что это"
)
#include "test/attachment.typ"

