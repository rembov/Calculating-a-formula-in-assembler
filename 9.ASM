; Y=(3/4*(В−2*C)+4*(А˄С))*B/(3*С)
; Y=(3/4*В−3/2*C+4*(А˄С))*B/(3*С)
; Y=(3*В/4−3*C/2+4*(А˄С))*B/(3*С)

data segment 

A dw 123h 
B dw 222h 
C dw 321h 
Y1 dw ? 
Y2 dw ? 
QUOT dw ? 
REMNDR dw ? 
SUCCESS db ?
SMASK dw 8000h
DIVDR dw ? 
NEG_DIVDR dw ? 

data ends 

code segment 

assume cs: code, ds: data, ss: nothing 

start: 
	mov ax, data ; load address 
	mov ds, ax ; data segment 
	mov SUCCESS, 0 ; флаг нормального завершения 

	mov ax, A
	mov dx, C
	and ax, dx ; А˄С
	sal ax, 2 ; 4*(А˄С)
	jo OVERFLOW ; переполнение - расчет невозможен
	push ax

	mov ax, C
	sal ax, 1 ; 2*C
	jo DIV_2
	add ax, C ; 3*C
	jo DIV_2
	sar ax, 1 ; 3*C/2
	push ax
	jmp L_3B4

DIV_2:
	mov ax, C
	sar ax, 1 ; C/2
	add ax, C ; 3*C/2
	jo OVERFLOW ; переполнение - расчет невозможен
	push ax

L_3B4:
	mov ax, B
	sal ax, 1 ; 2*B
	jo DIV_4
	add ax, B ; 3*B
	jo DIV_4
	sar ax, 2 ; 3*B/4
	jmp RESULT

DIV_4:
	mov ax, B
	sar ax, 2 ; B/4
	mov dx, ax
	sal ax, 1 ; 2*B/4
	add ax, dx ; 3*B/4

RESULT:
	pop dx ; 3*C/2
	sub ax, dx ; 3*В/4−3*C/2 - вычитание, нет переполнения
	pop dx ; 4*(А˄С)
	add ax, dx ; 3/4*(В−2*C)+4*(А˄С)
	jo OVERFLOW ; переполнение
	jmp MUL_B

OVERFLOW:
	jmp QUIT
	
MUL_B:
	mov bx, B

	; проверка знаков 
	mov dx, SMASK 
	mov cx, dx
	
	; определение знака ax
	and dx, ax
	jz PLUS_SUM 
	not ax  ;инверсия и +1 (след. шаг), если число отрицательное 
	inc ax 
	mov dx, 1 

PLUS_SUM: 
	and cx, bx ; определение знака B
	jz PLUS_B 
	not bx ; инверсия и инкремент, если число отрицательное 
	inc bx 
	mov cx, 1 

PLUS_B: 
	xor dx, cx
	push dx ; сохранение знака произведения в стек 

	; выполнение умножения 
	xor dx, dx 
	mov cx, 15

LOOP_MUL: 
	rcr bx,1 ; сдвиг регистра множителя 
	jnc LBL_1 ; если бит равен 0, то сдвиг 
	add dx, ax ; иначе сложение 
LBL_1:  
	rcr dx, 1 ; сдвиг сумматора 
	loop LOOP_MUL ; уменьшение счетчика на 1 

	rcr bx, 1 ; дополнительный сдвиг регистра множителя 
	rcr dx, 1 ; дополнительный сдвиг регистра сумматора 
	rcr bx, 1 ; дополнительный сдвиг регистра множителя 

	pop cx ; извлечение знака 
	test cl, 1
	jz LABEL_SUCCESS
	not dx 
	not bx 
	inc bx 

LABEL_SUCCESS: 
	mov Y1, dx ; загрузка старшей части в память 
	mov Y2, bx ; загрузка младшей части в память

	; вычисление делителя 
	mov dx, C 
	add dx, C ; 2*C
	add dx, C ; 3*C
	cmp dx, 0 ; проверка делителя на равенство 0 
	jne CHECKED_NON_ZERO 
	jmp QUIT 

CHECKED_NON_ZERO: 
	; проверяем на отрицательность делимое 
	xor si, si ; регистры для сохранения знаков 
	xor di, di 
	mov ax, Y1 ; старший разряд делимого
	mov bx, Y2 ; младший разряд делимого
	test ax, 8000h 
	jz DIV_SIGN 
	xor ax, 0FFFFh ; инверсия 
	xor bx, 0FFFFh 
	add bx, 1
	adc ax, 0 
	add si, 1 ; делимое отрицательное
DIV_SIGN: 
	test dx, 8000h ; проверка делителя на знак 
	jz PRE_DIV ; если положительное, то предварительное деление 
	neg dx ; иначе переводим его в дополнительный код 
	add si, 2 ; сохраняем знак 
	;если si = 1, то отрицательно делимое 
	;если si = 2, то отрицателен делитель 
	;если si = 3, то отрицательны и делитель, и делимое 
PRE_DIV: 
	mov cx, 16 ; цикл 10h = 10000h = 16, число в цикле одинаковое 
	mov DIVDR, dx ; делитель 
	neg dx ; инверсия делителя 
	mov NEG_DIVDR, dx ; отрицательный делитель 
	add ax, NEG_DIVDR ; пробное деление 
	jc QUIT ; аварийное завершение 
	neg dx  
	jmp DIVISION  

SAVE_FLAGS: 
	popf ; восстановление из стека значения флагов 

DIVISION: 
	rcl bx, 1 ; циклический сдвиг влево младших разрядов и флага СF на 1 бит 
	rcl ax, 1 ; циклический сдвиг влево старших разрядов и флага СF на 1 бит 
	jc ADD_DIVDR ; если CF=1 (полученный остаток отрицательный), то к старшим разрядам делимого прибавляется содержимое делителя 
	add ax, NEG_DIVDR ; иначе из старших разрядов делимого вычитается делитель  
	jmp LBL_2  

ADD_DIVDR: 
	add ax, DIVDR  

LBL_2: 
	pushf ; сохраняем в стек значения флагов 
	loop SAVE_FLAGS 

	popf  
	rcl bx, 1  
	test ax, 8000h ; проверяем остаток на знак 
	jz REMAINDER ; если положительное, то восстанавливаем знак делителя 
	add ax, DIVDR ; иначе восстанавливаем остаток 

REMAINDER: 
	test si, 1 ; восстанавливаем знак делимого 
	jz POS_REMAINDER ; если положительное
	neg ax ; инверсия остатка 
	add di, 1 ; флаг того, что результат отрицателен 

POS_REMAINDER: 
	test si, 2 ; восстанавливаем знак делителя 
	jz POS_QUOT 
	add di, 1 ; флаг того, что результат отрицателен 

POS_QUOT: 
	cmp di, 1 
	jne RESULT_2 
	neg bx 

RESULT_2: 
	mov QUOT, bx ; загрузка частного в память 
	mov REMNDR, ax ; загрузка остатка в память

	inc SUCCESS 

QUIT:
	mov ax, 4c00h; 
	int 21h; 

code ends 

end start
