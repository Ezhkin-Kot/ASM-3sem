extrn GetStdHandle: proc,
    lstrlenA: proc,
    WriteConsoleA: proc,
    ReadConsoleA: proc,
    ExitProcess: proc

.data
; Макрозамены для номеров стандартных потоков
STD_OUTPUT_HANDLE equ -11; Номер стандартного потока вывода
STD_INPUT_HANDLE  equ -10; Номер стандартного потока ввода

; Глобальные переменные
hStdInput  dq ? ; Дескриптор стандартного потока ввода
hStdOutput dq ? ; Дескриптор стандартного потока вывода
f_value    dq ? ; Переменная для хранения результата вычисления F
min_value  dq ? ; Переменная для хранения минимального значения из A и B

; Строки пользовательского интерфейса
a_prompt             db 'a = ', 0
b_prompt             db 'b = ', 0
f_message            db 'F = 1Fh - A + B = ', 0
min_message          db 'min(A, B) = ', 0
invalid_char_message db 'Invalid character', 0
out_of_range_message db 'Value is out of range', 0
exit_message         db 'Press any key to exit...', 0
new_line             db 0Dh, 0Ah, 0

.code
; Макросы для работы со стеком
; Макрос для выравнивания стека по 16-байтовой границе и выделения места для аргументов процедур
STACKALLOC macro arg
  push R15
  mov  R15, RSP     ; Сохранение текущего указателя стека (RSP) в R15
  sub  RSP, 8 * 4   ; Выделение места в стеке для 4-х аргументов (RCX, RDX, R8, R9)
  if arg            ; Если макрос вызван с аргументом,
    sub RSP, 8 * arg; то выделяется дополнительное место в стеке
  endif
  and  SPL, 0F0h    ; Выравнивание стека (младший байт, SPL) по 16-байтовой границе
endm

; Макрос для восстановления стека в исходное состояние
STACKFREE macro
  mov RSP, R15
  pop R15
endm

; Макрос для обнуления пятого аргумента в стеке
; Предназначен для функций ReadConsoleA и WriteConsoleA
NULL_FIFTH_ARG macro
  mov qword ptr[RSP + 32], 0
endm

; Процедура вывода строки в консоль
PrintString proc uses RAX RCX RDX R8 R9 R10 R11, string: qword
  local bytesWritten: qword; Число записанных байт
  STACKALLOC 1             ; Выделение места в стеке под 5 аргументов
  mov RCX, string          ; Указатель на строку для определения её длины
  call lstrlenA            ; Определение длины строки
  mov RCX, hStdOutput      ; Дескриптор потока вывода
  mov RDX, string          ; Указатель на строку для вывода
  mov R8, RAX              ; Длина строки
  lea R9, bytesWritten     ; Указатель на число выведенных байт
  NULL_FIFTH_ARG
  call WriteConsoleA       ; Вывод строки
  STACKFREE
  ret 8                    ; Возврат и очистка стека от одного qword аргумента
PrintString endp

; Процедура чтения знакового числа из консоли
ReadNumber proc uses RBX RCX RDX R8 R9
  local readStr[64]: byte, bytesRead: dword; Буфер для строки и количество прочитанных байт
  STACKALLOC 2      ; Выделение места в стеке под 6 аргументов
  mov RCX, hStdInput; hConsoleInput: дескриптор потока ввода
  lea RDX, readStr  ; lpBuffer: адрес буфера для записи строки
  mov R8, 64        ; nNumberOfCharsToRead: максимальный размер буфера
  lea R9, bytesRead ; lpNumberOfCharsRead: адрес переменной для реальной длины строки
  NULL_FIFTH_ARG    ; lpInputControl: для ANSI-строк должен быть 0
  call ReadConsoleA

  ; Парсинг строки в число
  xor RCX, RCX
  mov ECX, bytesRead; Реальная длина строки
  sub ECX, 2        ; Удаление символов переноса строки и возврата каретки
  xor RBX, RBX      ; RBX будет накапливать результат (число)
  mov R8, 1         ; R8 будет использоваться для умножения каждой цифры на 10

  ; Обработка строки по символам
  loopString:
    dec RCX             ; Переход к предыдущему символу
    cmp RCX, -1         ; Проверка на конец строки
    je scanningComplete ; Если дошли до начала строки, цикл завершается
    xor RAX, RAX
    mov AL, readStr[RCX]; Выбор текущего символа
    cmp AL, '-'         ; Проверка на знак минус
    jne eval
    neg RBX             ; Если вначале стоит минус, то меняем знак числа
    cmp RCX, 0          ; Проверка, что минус стоит в начале
    je scanningComplete ; Если да, цикл завершается
    jmp error           ; Иначе, выводится ошибка

    ; Проверка, является ли символ десятичной цифрой
    eval: 
      cmp AL, 30h ; Сравнение символа с кодом '0'
      jl error    ; Если символ меньше '0', выводится ошибка
      cmp AL, 39h ; Сравнение символа с кодом '9'
      jg error    ; Если символ больше '9', выводится ошибка
      sub RAX, 30h; Вычитание кода '0' для преобразования в число
      mul R8      ; Умножение на разряд
      add RBX, RAX; Добавление к итоговому числу в RBX
      ; Обновление множителя для следующего разряда
      mov RAX, 10
      mul R8
      mov R8, RAX
      jmp loopString

    error:
      mov R10, 1; Установка флага ошибки
      STACKFREE
      ret

    scanningComplete:
      mov R10, 0
      mov RAX, RBX; Возвращение числа в RAX
      STACKFREE
      ret
ReadNumber endp

; Процедура вывода числа в консоль
PrintNumber proc uses RAX RCX RDX R8 R9 R10 R11, number: qword
  local numberStr[22]: byte; Локальный буфер для строки
  STACKALLOC 1             ; Выделение места в стеке
  xor R8, R8               ; R8 - счетчик/индекс для строки numberStr
  mov RAX, number          ; Перемещение числа для вывода в RAX
  cmp number, 0            ; Проверка знака числа
  jge positive
  ; Если число отрицательное
  mov numberStr[R8], '-'   ; Добавление знака "минус" в начало строки
  inc R8                   ; Увеличение индекса
  neg RAX                  ; Инвертирование числа для работы с положительным значением

  positive:
    mov RBX, 10 ; Делитель для разделения числа на цифры
    xor RCX, RCX; Счетчик количества цифр

    ; Разделение числа на цифры
    divToDigits:
      xor RDX, RDX; Обнуление RDX (остатка от предыдущего деления)
      div RBX     ; RDX:RAX = RAX / RBX
      add RDX, 30h; Преобразование цифры в ASCII-код
      push RDX    ; Добавление цифры в стек
      inc RCX     ; Увеличение счетчика цифр
      cmp RAX, 0  ; Проверка на окончание деления
      jne divToDigits

    ; Сборка строки из цифр
    createString:
      pop RDX              ; Получение ASCII-кода цифры из стека
      mov numberStr[R8], DL; Добавление цифры в строку
      inc R8               ; Увеличение индекса
      loop createString

    mov numberStr[R8], 0; Добавление нуля в конец строки
    lea RAX, numberStr  ; Перемещение адреса строки в RAX
    push RAX
    call PrintString    ; Вывод строки
    ret 8               ; Возврат и очистка стека от одного qword аргумента 
PrintNumber endp

; Процедура ожидания ввода
WaitEnter proc uses RAX RCX RDX R8 R9 R10 R11
  local readStr:byte, bytesRead:dword
  STACKALLOC 1
  
  ; Вывод сообщения 'Press any key to exit...'
  mov RCX, hStdOutput
  lea RDX, exit_message
  mov R8D, 25; Длина строки 'Press any key to exit...'
  lea R9, bytesRead
  NULL_FIFTH_ARG
  call WriteConsoleA

  ; Ожидание ввода одного символа
  mov RCX, hStdInput
  lea RDX, readStr
  mov R8D, 1
  lea R9, bytesRead
  NULL_FIFTH_ARG
  call ReadConsoleA

  STACKFREE
  ret
WaitEnter endp

; Процедура вывода переноса строки
PrintNewLine proc
  lea RAX, new_line
  push RAX
  call PrintString
  ret
PrintNewLine endp

; Главная процедура
mainCRTStartup proc
  STACKALLOC 0

  ; Инициализация дескрипторов консоли
  mov RCX, STD_OUTPUT_HANDLE
  call GetStdHandle
  mov hStdOutput, RAX

  mov RCX, STD_INPUT_HANDLE
  call GetStdHandle
  mov hStdInput, RAX

  ; Ввод и проверка числа A
  lea RAX, a_prompt        ; Вывод текста "a = "
  push RAX
  call PrintString

  call ReadNumber          ; Чтение числа с консоли
  cmp R10, 1               ; Проверка флага ошибки из ReadNumber
  je invalid_char_exception; Если ошибка, переход к завершению
  ; Проверка на переполнение для знакового 16-битного числа (word)
  cmp RAX, 32767
  jg out_of_range_exception
  cmp RAX, -32768
  jl out_of_range_exception
  mov R8, RAX              ; Сохранение первого числа в R8

  ; Ввод и проверка числа B
  lea RAX, b_prompt        ; Вывод текста "b = "
  push RAX
  call PrintString

  call ReadNumber          ; Чтение числа с консоли
  cmp R10, 1               ; Проверка флага ошибки
  je invalid_char_exception; Если ошибка, переход к завершению
  ; Проверка на переполнение для знакового 16-битного числа (word)
  cmp RAX, 32767
  jg out_of_range_exception
  cmp RAX, -32768
  jl out_of_range_exception
  mov R9, RAX              ; Сохранение второго числа в R9

  ; Поиск min(A, B)
  cmp R8, R9
  jg R9_is_min             ; Если A > B, то B - минимум
  mov min_value, R8        ; Иначе A - минимум
  jmp R8_is_min
  R9_is_min:
  mov min_value, R9
  R8_is_min:
 
  ; Вычисление и вывод F = 1Fh - A + B
  lea RAX, f_message; Выводим сообщение "F = ..."
  push RAX
  call PrintString

  add R8, R9               ; R8 = A + B
  add R8, 1Fh              ; R8 = A + B + 1Fh
  mov f_value, R8
  push f_value             ; Помещение результата в стек для вывода
  call PrintNumber

  call PrintNewLine

  ; Вывод min(A, B)
  lea RAX, min_message     ; Вывод сообщения "min(A, B) = "
  push RAX
  call PrintString

  push min_value           ; Помещение минимального значения в стек для вывода
  call PrintNumber

  ; Переход к завершению программы
  jmp exit_proc

  ; Обработка исключений
  invalid_char_exception:
    lea RAX, invalid_char_message
    push RAX
    call PrintString
    jmp exit_proc

  out_of_range_exception:
    lea RAX, out_of_range_message
    push RAX
    call PrintString

  exit_proc:
    call PrintNewLine
    call WaitEnter; Ожидание нажатия любой клавиши
    STACKFREE
    xor RCX, RCX  ; Код завершения 0
    call ExitProcess
mainCRTStartup endp

end
