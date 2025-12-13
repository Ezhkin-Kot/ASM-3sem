#import "conf.typ": conf
#import "@preview/zebraw:0.5.5": zebraw, zebraw-init, zebraw-themes
#show: conf.with(
  title: [Лабораторная работа №6],
  type: "pract",
  info: (
    author: (
      name: [Тюменцева Радомира Александровича],
      faculty: [КНиИТ],
      group: "251",
      sex: "male",
    ),
    inspector: (
      degree: "Старший преподаватель",
      name: "Е. М. Черноусова",
    ),
  ),
  settings: (
    title_page: (
      enabled: true,
    ),
    contents_page: (
      enabled: false,
    ),
  ),
)

= Задание 6

```asm
; Подключение внешних функций WinAPI
extrn ExitProcess :proc,
      MessageBoxW :proc

.data
; Строки для вывода в MessageBox 
; в hex кодировке UTF-16 LE для отображения кириллицы
; Заголовок окна: "Инфо"
caption dw 0418h,043Dh,0444h,043Eh,0
; Текст сообщения: "Тюменцев Радомир"
message dw 0422h,044Eh,043Ch,0435h,043Dh,0446h,0435h,0432h,0020h,0420h,0430h,0434h,043Eh,043Ch,0438h,0440h,0

.code
mainCRTStartup proc
  ; Выравнивание стека по 16 байтовой границе
  ; 32 байта для параметров MessageBoxW при вызове + 8 байтов для установки смещения
  sub RSP, 8*5

  ; Передача параметров для MessageBoxW
  xor RCX, RCX ; hWnd окно-предок (значение 0 соответствует рабочему столу)
  lea RDX, message ; указатель на текст сообщения в теле окна
  lea R8, caption ; указатель на заголовок окна
  xor R9, R9 ; тип окна и содержащиеся в нём кнопки (Ok)

  ; Вызов MessageBoxW (вариант окна, поддерживаюший UTF-16 LE) 
  call MessageBoxW

  ; Завершение программы с кодом 0
  xor RCX, RCX
  call ExitProcess
mainCRTStartup endp
end
```
#text(size: 12pt, align(center)[Текст программы])

== Скриншот запуска программы
#figure(
  image("1.png"),
  caption: [Запуск программы],
)
