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

	lea DX, nl
	mov AH, 09h
	int 21h

	mov CX, 10; Количество чисел
	mov BX, 2; Первое число
	mov SI, 0; Смещение в байтах (0)

fill_even_loop:
	mov  simple[SI], BX
	add  SI, 2
	add  BX, 2
	loop fill_even_loop

	;   Заполнение второй половины массива квадратами
	mov CX, 10
	mov BX, 2
	mov SI, 20; Смещение к 11-му элементу (10 слов * 2 байта)

fill_sq_loop:
	mov  AX, BX
	mul  BX; AX = BX*BX
	mov  simple[SI], AX
	add  SI, 2
	add  BX, 2
	loop fill_sq_loop

	;   Вывод первой строки (чётные числа)
	mov CX, 10
	mov SI, 0; Начинаем с первого элемента

print_first_row:
	mov  AX, simple[SI]
	mov  BX, 10
	call word_asc
	mov  AH, 9
	lea  DX, result
	int  21h
	add  SI, 2
	loop print_first_row

	;   Перенос строки
	mov AH, 9
	lea DX, nl
	int 21h

	;   Вывод второй строки (квадраты)
	mov CX, 10
	mov SI, 20; Начинаем с 11-го элемента

print_second_row:
	mov  AX, simple[SI]
	mov  BX, 10
	call word_asc
	mov  AH, 9
	lea  DX, result
	int  21h
	add  SI, 2
	loop print_second_row

	;   Перевод строки
	mov AH, 9
	lea DX, nl
	int 21h

	;   Завершение программы
	mov AX, 4C00h
	int 21h

  word_asc proc
    pusha
    mov SI, 0; Смещение в байтах, изначально 0, затем увеличивается до 5
    mov CX, 5; Длина строки result (5 символов)

  ; Заполняем буфер пробелами для очистки
  fill_spaces:
    mov  result[SI], ' '
    inc  SI
    loop fill_spaces

  convert_loop:
    dec SI
    mov DX, 0
    div BX; AL = частное, AH = остаток
    add DL, '0'
    mov result[SI], DL
    cmp AX, 0
    jne convert_loop

    popa
    ret
  word_asc endp

end start
