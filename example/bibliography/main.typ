#import "@preview/typo-stp:0.1.1": *
#show: template

#outline()

#introduction

Данная библиография не окончательный вариант -- стиль навайбкожен клодом, я не
ручаюсь за его полное соответсвие ГОСТ 7.1--2003 и не претендую на это. 
Некоторые источники соответствуют СТП 01-2024, некоторые edge-кейсы я не 
разбирал. Источники пока что лучше оформлять вручную, либо, если шарите в этом
ГОСТе, пишите в issues на GitHub'е что не так, возможные исправления.

// Правила оформления источников
#include "sources-howto-claude-vibecode.typ"

// Примеры использования
#include "text.typ"

// Библиографии:
// в Hayagriva
#bibliography("edge-cases.yml")
// в BibLaTeX
#bibliography("edge-cases.bib")

