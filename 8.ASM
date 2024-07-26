; Y=(3/4*(В−2*C)+4*(А˄С))*B
; Y=(3/4*В−3/2*C+4*(А˄С))*B
; Y=(3*В/4−3*C/2+4*(А˄С))*B

data segment 

A dw 123h 
B dw 222h 
C dw 321h 
Y1 dw ? 
Y2 dw ? 
SUCCESS db ?
SMASK dw 8000h

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
	jo QUIT_1 ; переполнение - расчет невозможен
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
	jo QUIT_1 ; переполнение - расчет невозможен
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
	jo QUIT_1 ; переполнение
	
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
	jmp PLUS_SUM

QUIT_1:
	jmp QUIT
	
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
	inc SUCCESS 

QUIT:
	mov ax, 4c00h; 
	int 21h; 

code ends 

end start
