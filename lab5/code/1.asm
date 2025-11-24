.model small
.stack 100h
.186
.code
start:
  mov AX, @data
  mov DS, AX
   
  ; Настраиваем запись данных в видеопамять на страницу 0
  mov AX, 0B800h             
  mov ES, AX        

  mov AH, 0Fh
  int 10h 
  push AX; Сохранение текущего видеорежима и активной страницы

  ; Установка видеорежима 03h (80x25, 16 цветов)
  mov AH, 00h
  mov AL, 03h
  int 10h

  ; Установка активной страницы 0
  mov AH, 05h
  mov AL, 00h
  int 10h

  call B10DISPLAY

  ; Ожидание нажатия любой клавиши
  mov AH, 00h 
  int 16h

  ; Восстановление исходного видеорежима и страницы
  pop AX
  mov AH, 00h
  int 10h

  ; Завершение программы
  mov AX, 4C00h
  int 21h

  ; Процедура вывода изображения в видеопамять
  B10DISPLAY proc
    pusha

    ; Начальные координаты:
    mov CX, 5; Строка
    mov BP, 10; Столбец

    mov AL, 41h; ASCII-код символа A
    mov AH, 09h; Атрибут светло-синего цвета

    mov SI, 6; Счётчик строк
    rows_loop:
      ; Вычисление адреса в видеопамяти для текущей позиции
      ; Адрес = ((строка * 80) + столбец) * 2
      push AX
      mov AX, CX      ; AX = строка
      mov BX, 80
      mul BX          ; AX = строка * 80
      add AX, BP      ; AX = (строка * 80) + столбец
      mov BX, 2
      mul BX          ; AX = ((строка * 80) + столбец) * 2

      mov DI, AX      ; DI = указатель на начало строки в видеопамяти
      pop AX

      ; Количество символов в текущей строке = 7 - SI
      mov BX, 7
      sub BX, SI
      cols_loop:
        mov ES:word ptr[DI], AX; Запись символа и атрибута в видеопамять
        add DI, 2; Сдвиг на следующую позицию
        dec BX
        cmp BX, 0
        jne cols_loop

      ; Изменение символа и атрибута
      inc AL 
      inc AH

      ; Сдвиг на следующую строку
      inc CX

      ; Уменьшение счётчика строк
      dec SI
      cmp SI, 0
      jne rows_loop

    popa
    ret
  B10DISPLAY endp

end start              
