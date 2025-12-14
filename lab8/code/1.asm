extrn GetStdHandle: proc,
    lstrlenA: proc,
    WriteConsoleA: proc,
    ReadConsoleA: proc,
    ExitProcess: proc

.data
STD_OUTPUT_HANDLE equ -11
STD_INPUT_HANDLE equ -10

hStdInput dq ?
hStdOutput dq ?
f_value dq ?
min_value dq ?
a_prompt db 'a = ', 0
b_prompt db 'b = ', 0
f_message db 'F = 1Fh - A + B = ', 0
min_message db 'min(A, B) = ', 0
invalid_char_message db 'Invalid character', 0
out_of_range_message db 'Value is out of range', 0
exit_message db 'Press any key to exit...', 0
new_line db 0Dh, 0Ah, 0

.code
STACKALLOC macro arg
  push R15
  mov R15, RSP
  sub RSP, 8 * 4
  if arg
    sub RSP, 8 * arg
  endif
  and SPL, 0F0h
endm

STACKFREE macro
  mov RSP, R15
  pop R15
endm

NULL_FIFTH_ARG macro
  mov qword ptr[RSP + 32], 0
endm

PrintString proc uses RAX RCX RDX R8 R9 R10 R11, string: qword
  local bytesWritten: qword
  STACKALLOC 1
  mov RCX, string
  call lstrlenA
  mov RCX, hStdOutput
  mov RDX, string
  mov R8, RAX
  lea R9, bytesWritten
  NULL_FIFTH_ARG
  call WriteConsoleA
  STACKFREE
  ret 8
PrintString endp

ReadNumber proc uses RBX RCX RDX R8 R9
  local readStr[64]: byte, bytesRead: dword
  STACKALLOC 2
  mov RCX, hStdInput
  lea RDX, readStr
  mov R8, 64
  lea R9, bytesRead
  NULL_FIFTH_ARG
  call ReadConsoleA
  xor RCX, RCX
  mov ECX, bytesRead
  sub ECX, 2; Удаление символов переноса строки и возврата каретки
  xor RBX, RBX
  mov R8, 1

  loopString:
    dec RCX
    cmp RCX, -1
    je scanningComplete
    xor RAX, RAX
    mov AL, readStr[RCX]
    cmp AL, '-'
    jne eval
    ; Если вначале стоит -, то меняем знак числа
    neg RBX
    cmp RCX, 0
    je scanningComplete
    jmp error

    eval: 
      ; Проверка, является ли символ десятичной цифрой
      cmp AL, 30h
      jl error
      cmp AL, 39h
      jg error
      sub RAX, 30h
      mul R8
      add RBX, RAX
      mov RAX, 10
      mul R8
      mov R8, RAX
      jmp loopString

    error:
      mov R10, 1
      STACKFREE
      ret

    scanningComplete:
      mov R10, 0
      mov RAX, RBX
      STACKFREE
      ret
ReadNumber endp

PrintNumber proc uses RAX RCX RDX R8 R9 R10 R11, number: qword
  local numberStr[22]: byte
  STACKALLOC 1
  xor R8, R8
  mov RAX, number
  cmp number, 0
  jge positive
  ; Число отрицательное
  mov numberStr[R8], '-'
  inc R8
  neg RAX

  positive:
    mov RBX, 10
    xor RCX, RCX

    divToDigits:
      xor RDX, RDX
      div RBX; RDX:RAX = RAX / RBX
      add RDX, 30h
      push RDX
      inc RCX
      cmp RAX, 0
      jne divToDigits

    createString:
      pop RDX
      mov numberStr[R8], DL
      inc R8
      loop createString

    mov numberStr[R8], 0
    lea RAX, numberStr
    push RAX
    call PrintString
    ret 8
PrintNumber endp


WaitEnter proc uses RAX RCX RDX R8 R9 R10 R11
  local readStr:byte, bytesRead:dword
  STACKALLOC 1
  
  ; Вывод сообщения 'Press any key to exit...'
  mov RCX, hStdOutput
  lea RDX, exit_message
  mov R8D, 25 ; Длина строки 'Press any key to exit...'
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

PrintNewLine proc
  lea RAX, new_line
  push RAX
  call PrintString
  ret
PrintNewLine endp

mainCRTStartup proc
  STACKALLOC 0

  mov RCX, STD_OUTPUT_HANDLE
  call GetStdHandle
  mov hStdOutput, RAX

  mov RCX, STD_INPUT_HANDLE
  call GetStdHandle
  mov hStdInput, RAX

  lea RAX, a_prompt
  push RAX
  call PrintString

  call ReadNumber
  cmp R10, 1; Проверка флага ошибки из ReadNumber
  je invalid_char_exception; Если ошибка, переход к завершению
  cmp RAX, 32767
  jg out_of_range_exception
  cmp RAX, -32768
  jl out_of_range_exception
  mov R8, RAX; Сохранение первого числа в R8

  lea RAX, b_prompt
  push RAX
  call PrintString

  call ReadNumber
  cmp R10, 1; Проверка флага ошибки
  je invalid_char_exception; Если ошибка, переход к завершению
  cmp RAX, 32767
  jg out_of_range_exception
  cmp RAX, -32768
  jl out_of_range_exception
  mov R9, RAX; Сохранение второго числа в R9

  cmp R8, R9
  jg R9_is_min
  mov min_value, R8
  jmp R8_is_min
  R9_is_min:
  mov min_value, R9
  R8_is_min:
 
  lea RAX, f_message
  push RAX
  call PrintString

  add R8, R9
  add R8, 1Fh
  mov f_value, R8; Перемещение суммы в RAX для вывода
  push f_value
  call PrintNumber

  call PrintNewLine

  lea RAX, min_message
  push RAX
  call PrintString

  push min_value
  call PrintNumber

  jmp exit_proc

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
    call WaitEnter
    STACKFREE
    xor RCX, RCX; Код завершения 0
    call ExitProcess
mainCRTStartup endp

end
