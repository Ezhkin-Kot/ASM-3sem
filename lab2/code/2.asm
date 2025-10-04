.model tiny
.code
org    100h

start:
	;    Вывод фамилии, имени и номера группы
	mov  DX, offset my_name
	call out_string
	call new_line

	mov AX, 1; Занесение первой цифры в регистр AX
	mov BX, 2; Занесение второй цифры в регистр BX
	;   Перевод цифр в коды соответствующих символов ASCII с помощью команды add
	add AX, 30h
	add BX, 30h

	;    Сохранение значения регистра AX в стек
	;    так как затем в него будут записываться номера функций DOS
	push AX

	;    Вывод первой цифры
	mov  DX, AX
	call out_char

	;    Вывод пробела
	call out_space

	;    Вывод второй цифры
	mov  DX, BX
	call out_char

	pop AX; Восстановление значения регистра AX из стека

	xchg AX, BX; Обмен значениями регистров AX и BX

	call new_line; Переход на новую строку

	;    Вывод первой цифры
	mov  DX, AX
	call out_char

	;    Вывод пробела
	call out_space

	;    Вывод второй цифры
	mov  DX, BX
	call out_char

	;   Завершение программы
	mov AX, 4C00h
	int 21h

	;   Процедура вывода строки
	out_string proc
    mov AH, 09h
    int 21h
    ret
  out_string endp

	;   Процедура вывода символа
	out_char proc
    mov AH, 02h
    int 21h
    ret
  out_char endp

	;   Процедура вывода пробела
	out_space proc
    mov DL, 00h; Код пробела в ASCII
    mov AH, 02h
    int 21h
    ret
  out_space endp

	;   Процедура перехода на новую строку
	new_line proc
    mov DX, offset end_line
    mov AH, 09h
    int 21h
    ret
  new_line endp

;===== Data =====
my_name db 'Tyumentsev Radomir, 251$'
end_line db 0Dh, 0Ah, '$' ; Строка с символами перехода на новую строку
end start
