include Irvine32.inc

include inc\util.inc

PREDIO_ALTURA = 13
PREDIO_LARGURA = 5

.data
predios_pos BYTE COLUNAS / 3 DUP(0FFh)
predios_count BYTE 0
predios_off BYTE 0
predios_len BYTE 0
predio_desenho BYTE " ___ ", 0, "| = |", 0, "|   |", 0, "| | |", 0,
					"|   |", 0, "| | |", 0, "|   |", 0, "| | |", 0,
					"| | |", 0, "|   |", 0, "| | |", 0, "| | |", 0,
					"| | |", 0
predio_clear BYTE 5 DUP (" "), 0

.code
;----------------------------------------------------
manipularSegmentoPredio proc uses ecx eax edx
; Desenha ou apaga um segmento do predio
; Recebe:
;		Endereço de predio_desenho ou de predio_clear
;		Qual a linha de predio_desenho está sendo manipulada
;----------------------------------------------------
local write_buffer[6]:BYTE	
	movzx ecx, predios_len
	
	mov esi, [ebp + 8]
	add esi, [ebp + 12]
	movzx eax, predios_off
	add esi, eax
	
	lea edi, write_buffer
	rep movsb
	
	mov BYTE PTR [edi], 0
	lea edx, write_buffer
	call WriteString
		
	ret 8
manipularSegmentoPredio endp

manipularPredio proc uses edx eax ecx
local desenho_addr:DWORD, offset_gl:DWORD
	cmp DWORD PTR [ebp + 8], 0
	je LIMPAR
	
	mov desenho_addr, offset predio_desenho
	mov DWORD PTR offset_gl, PREDIO_LARGURA + 1
	jmp CONTINUE2
	
LIMPAR:
	mov desenho_addr, offset predio_clear
	mov DWORD PTR offset_gl, 0

CONTINUE2:
	mov dl, predios_pos[ebx]
	
	cmp dl, 0
	jle LEAVING_SCREEN_LEFT
	
	mov predios_off, 0

	cmp dl, 120
	jge J_EXIT
	
	cmp dl, 115
	jge ENTERING_SCREEN_RIGHT
	
	mov predios_len, PREDIO_LARGURA
	
	jmp CONTINUE
	
LEAVING_SCREEN_LEFT:
	not dl
	add dl, 2
	mov predios_off, dl
	
	mov dl, 1
	mov predios_len, PREDIO_LARGURA

	jmp CONTINUE

ENTERING_SCREEN_RIGHT:
	mov predios_len, 119
	sub predios_len, dl
	
CONTINUE:
	cmp predios_len, 0
	je J_EXIT
	
	call GetTextColor
	push eax
	
	mov eax, lightGray
	call SetTextColor
	
	mov dh, LINHAS - 1 - PREDIO_ALTURA
	mov eax, 0
	mov ecx, PREDIO_ALTURA

LP_0:
	call Gotoxy
	
	push eax
	push desenho_addr
	call manipularSegmentoPredio
	
	inc dh
	add eax, offset_gl
	loop LP_0
	
	pop eax
	call SetTextColor

J_EXIT:	
	ret 4
manipularPredio endp

colisaoPredios proc
	push ebp
	mov ebp, esp
	
	push ax
	push ecx
	push ebx
	
	movzx ecx, predios_count
	mov ebx, 0
	
	cmp ecx, 0
	je J_EXIT
	
	mov al, [ebp + 8]
LP_0:
	mov ah, predios_pos[ebx]
	
	cmp ah, 17
	jge J_EXIT
	
	cmp al, 14
	jl CONTINUE
	
	cmp al, 16
	jge TOPO_COLIDE
	
	cmp al, 15
	je MEIO_COLIDE
	
	jmp BAIXO_COLIDE

TOPO_COLIDE:
	cmp ah, 17
	jge CONTINUE
	cmp ah, 1
	jle CONTINUE
	jmp COLIDE

MEIO_COLIDE:
	cmp ah, 15
	jge CONTINUE
	cmp ah, -2
	jle CONTINUE
	jmp COLIDE
	
BAIXO_COLIDE:
	cmp ah, 14
	jge CONTINUE
	cmp ah, 4
	jle CONTINUE
	jmp COLIDE

COLIDE:
	mov esi, [ebp + 12]
	mov BYTE PTR[esi], 1
	jmp J_EXIT
	
CONTINUE:
	inc ebx
	loop LP_0
	
J_EXIT:
	pop ebx
	pop ecx
	pop ax
	
	mov esp, ebp
	pop ebp
	
	ret 8
colisaoPredios endp

moverPredios proc uses ecx ebx esi edi
	movzx ecx, predios_count
	cmp ecx, 0
	je J_EXIT
	
	mov ebx, 0
LP_0:
	push 0
	call manipularPredio
	dec predios_pos[ebx]
	
	cmp predios_pos[ebx], -4
	je SKIP_DESENHAR
	
	push 1
	call manipularPredio
	
SKIP_DESENHAR:
	inc ebx
	loop LP_0

	cmp predios_pos[0], -4
	jne J_EXIT
	
	movzx ecx, predios_count
	dec predios_count
	mov edi, OFFSET predios_pos
	mov esi, edi
	inc esi
	rep movsb

J_EXIT:
	ret
moverPredios endp

spawnPredio proc
	push ebp
	mov ebp, esp
	
	push ebx
	push eax
	push edx
	
	mov eax, 3
	call RandomRange
	
	mov edx, [ebp + 8]
	
	mov BYTE PTR [edx], PREDIO_LARGURA + 1
	add BYTE PTR [edx], al
	
	movzx ebx, predios_count
	mov predios_pos[ebx], 125
	
	inc predios_count
	
	pop edx
	pop eax
	pop ebx
	
	mov esp, ebp
	pop ebp
	
	ret 4
spawnPredio endp

resetarPredios proc
	mov predios_count, 0
	ret
resetarPredios endp

end