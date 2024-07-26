; Y=3/4*(В−2*C)+4*(А˄С)
; Y=3/4*В−3/2*C+4*(А˄С)
; Y=3*В/4−3*C/2+4*(А˄С)

data segment 

A dw 1000h 
B dw 800h 
C dw 1000h 
Y dw ? 
SUCCESS db ?

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
	jo QUIT ; переполнение - расчет невозможен
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
	jo QUIT ; переполнение - расчет невозможен
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
	add ax, dx ; Y
	jo QUIT ; переполнение
	mov Y, ax 
	jmp LABEL_SUCCESS 

LABEL_SUCCESS: 
	inc SUCCESS 
	
QUIT:
	mov ax, 4c00h; 
	int 21h; 

code ends 

end start
