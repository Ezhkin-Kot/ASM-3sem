.model small
.stack 100h
.186

.data
	my_name db "Tyumentsev Radomir, 251$"
	simple dw 20 dup (?) ; Массив из 20 слов (неинициализированный)
	result db 5 dup (' '), '$' ; Буфер для вывода одного числа: 5 символов + '$'
	nl     db 0AH, 0Dh, '$' ; Символы перехода на новую строку

.code
start:
	mov AX, @data
	mov DS, AX

	;   Вывод фамилии, имени и номера группы
	lea DX, my_name
	mov AH, 09h
	int 21h

	call print_new_line

	mov CX, 2; Количество строк
	mov SI, 0; Смещение в байтах (0)

  ; Заполнение массива
  ; Первые 10 элементов - чётные числа, следующие 10 - их квадраты
  fill_rows:
    mov BX, 2; Первое число

    fill_cols:
      mov AX, BX
      cmp CX, 2
      je even
      mul AX; AX = AX * AX (возведение в квадрат)
      even:
      mov simple[SI], AX; Занесение числа в массив
      add SI, 2
      add BX, 2
      cmp SI, 20
      je fill_rows_loop
      cmp SI, 40
      je fill_rows_loop
      jl fill_cols
      fill_rows_loop:
        loop fill_rows

	mov CX, 2; Количество строк
	mov SI, 0; Смещение в байтах (0)

  ; Вывод массива в две строки
  print_rows:
    print_cols:
      mov AX, simple[SI]; Занесение числа из массива в AX
      call word_asc; Перевод числа в строку ASCII
      lea DX, result
      call print_string; Вывод строки
      add SI, 2
      cmp SI, 20
      je print_rows_loop
      cmp SI, 40
      je print_rows_end
      jl print_cols
      print_rows_loop:
        call print_new_line
        loop print_rows
      print_rows_end: 

	; завершение программы
	mov AX, 4C00h
	int 21h

  ; Процедура перевода числа в строку ASCII фиксированной длины
  word_asc proc
    pusha
    mov BX, 10; Основание системы счисления
    mov SI, 0; Смещение в байтах, изначально 0, затем увеличивается до 5
    mov CX, 5; Длина строки result (5 символов)

    ; Заполнение буфера result пробелами для его очистки
    fill_spaces:
      mov  result[SI], ' '
      inc  SI
      loop fill_spaces

    ; SI = 5
    ; Заполнение буфера result символами
    convert_loop:
      dec SI
      mov DX, 0; Обнуление прошлого остатка от деления
      div BX; AX = частное, DX = остаток
      add DL, '0' ; Добавление кода символа 0 в ASCII
      mov result[SI], DL; Занесение символа в буфер
      cmp AX, 0
      jne convert_loop

    popa
    ret
  word_asc endp

  ; Процедура вывода строки, хранящейся в DX
  print_string proc
    push AX

    mov AH, 09h
    int 21h

    pop AX
    ret
  print_string endp

  ; Процедура переноса строки
  print_new_line proc
    push AX
    push DX

    lea DX, nl
    mov AH, 09h
    int 21h

    pop DX
    pop AX
    ret
  print_new_line endp

end start
