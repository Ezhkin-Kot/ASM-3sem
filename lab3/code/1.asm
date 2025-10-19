.model small
.stack 100h

.data
my_name db 'Tyumentsev Radomir, 251', 0Dh, 0Ah, '$'

.386 ; Разрешение трансляции команд процессора 386
.code

start:
	mov AX, @data; Помещение указателя на сегмент данных в AX
	mov DS, AX; Помещение указателя на сегмент данных в DS

	;   Вывод фамилии, имени и номера группы
	mov DX, offset my_name
	mov AH, 09h
	int 21h

	mov AX, 3456; Занесение числа
	mov BX, 10; Занесение основания системы счисления (делителя)
	mov CX, 0; Обнуление счётчика

  loop_first: ; Занесение в стек цифр числа
    inc  CX; Увеличение счётчика
    mov  DX, 0; Обнуление остатка от деления в DX
    div  BX; Деление AX на BX
    push DX; Занесение остатка от деления в стек
    cmp  AX, 0; Сравнение частного с нулём
    jne  loop_first; Если AX != 0, то возвращаемся к loop_first

  mov AH, 02h ; Занесение в AH кода команды вывода символа

  loop_second: ; Вывод цифр числа из стека
    pop  DX
    call out_digit
    loop loop_second

  ; Завершение программы
  mov AX, 4C00h
  int 21h

  ; Процедура вывода цифры
  out_digit proc
    add DX, 30h; Перевод цифры в ASCII
    int 21h
    ret
  out_digit endp

end start
