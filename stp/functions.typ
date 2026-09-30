// функция листинга файла
#let source-text(path, name) = {
  // чтение содержимого файла

  // TODO: исправить это, если возможно.
  // я сделал это в надежде, что никто 
  // не додумается прописывать полный путь 
  let real-path = "../" + path

  let file-content = read(real-path)
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

#let introduction = {
  heading(numbering: none)[
    Введение
  ]
}

#let abstract = {
  heading(numbering: none)[
    Реферат
  ]
}

#let conclusion = {
  heading(numbering: none)[
    Заключение
  ]
}


