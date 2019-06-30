include Irvine32.inc

include inc\util.inc

PASSARO_LARGURA = 5

.data
passaros_pos COORDENADA COLUNAS / 3 DUP(<>)
passaros_count BYTE 0
passaro_desenho BYTE "/^v^", 5Ch, 0
passaro_clear BYTE 5 DUP (" "), 0

.code
;------------------------------------------------
resetarPassaros proc
; Limpar array de passaros
;------------------------------------------------
	mov passaros_count, 0
	ret
resetarPassaros endp

;------------------------------------------------
moverPassaros proc
; Move todos os pássaros para a esquerda
;------------------------------------------------
	movzx ecx, passaros_count
	cmp ecx, 0
	je J_EXIT

; // Apagar
	mov ebx, 0
	
LP_0:
	push 0
	call manipularPassaro
	dec (COORDENADA PTR[passaros_pos[ebx]]).X
	
	add ebx, 2
	loop LP_0

; // Desenhar
	movzx ecx, passaros_count
	mov ebx, 0
	
	call GetTextColor
	push eax
	
	mov eax, yellow
	call SetTextColor

LP_1:
	cmp (COORDENADA PTR[passaros_pos[ebx]]).X, -4
	je SKIP_DESENHAR
	
	push 1
	call manipularPassaro

SKIP_DESENHAR:
	add ebx, 2
	loop LP_1
	
	pop eax
	call SetTextColor
	
	cmp (COORDENADA PTR[passaros_pos[0]]).X, -4
	jne J_EXIT
	
	movzx ecx, passaros_count
	dec passaros_count
	mov edi, offset passaros_pos
	mov esi, edi
	add esi, 2
	rep movsw

J_EXIT:
	ret
moverPassaros endp

;----------------------------------------------------
manipularPassaro proc uses edx eax
; Desenha ou apaga um pássaro
;----------------------------------------------------
local passaros_off:BYTE, passaros_len:BYTE	
	mov dl, (COORDENADA PTR [passaros_pos[ebx]]).X
	mov dh, (COORDENADA PTR [passaros_pos[ebx]]).Y
	
	cmp dl, 0
	jle LEAVING_SCREEN_LEFT
	
	mov passaros_off, 0
	
	cmp dl, 120
	jge J_EXIT
	
	cmp dl, 115
	jge ENTERING_SCREEN_RIGHT
	
	mov passaros_len, PASSARO_LARGURA
	
	jmp CONTINUE

LEAVING_SCREEN_LEFT:
	not dl
	add dl, 2
	mov passaros_off, dl
	
	mov dl, 1
	mov passaros_len, PASSARO_LARGURA
	
	jmp CONTINUE
	
ENTERING_SCREEN_RIGHT:
	mov passaros_len, 119
	sub passaros_len, dl

CONTINUE:
	cmp passaros_len, 0
	je J_EXIT
	
	call Gotoxy
	
	cmp DWORD PTR[ebp + 8], 0
	je APAGAR
	
	push offset passaro_desenho
	jmp CONTINUE2

APAGAR:
	push offset passaro_clear

CONTINUE2:
	movzx eax, passaros_len
	push eax
	movzx eax, passaros_off
	push eax
	call manipularSegmentoPassaro

J_EXIT:	
	ret 4
manipularPassaro endp

;----------------------------------------------------
manipularSegmentoPassaro proc uses ecx edx
; Desenha ou apaga um segmento do passaro
; Recebe:
;		Endereço de passaro_desenho ou passaro_clear
;----------------------------------------------------
local write_buffer[6]:BYTE	
	mov ecx, [ebp + 12]
	mov esi, [ebp + 8]
	add esi, [ebp + 16]
	
	lea edi, write_buffer
	rep movsb
	
	mov BYTE PTR [edi], 0
	lea edx, write_buffer
	
	call WriteString

	ret 4
manipularSegmentoPassaro endp

;------------------------------------------------
colisaoPassaros proc
; Calcula a colisão dos pássaros com o helicoptero
;------------------------------------------------
	push ebp
	mov ebp, esp
	
	push dx
	push ax
	push ecx
	push ebx
	
	movzx ecx, passaros_count
	mov ebx, 0

	cmp ecx, 0
	je J_EXIT

LP_0:
	mov dl, (COORDENADA PTR[passaros_pos[ebx]]).Y
	mov dh, (COORDENADA PTR[passaros_pos[ebx]]).X
	
	cmp dh, 17
	jge J_EXIT
	
	mov al, [ebp + 8]
	
	cmp al, dl
	je TOPO_COLIDE
	dec dl
	
	cmp al, dl
	je MEIO_COLIDE
	dec dl
	
	cmp al, dl
	je BAIXO_COLIDE
	
	jmp CONTINUE

TOPO_COLIDE:
	cmp dh, 17
	jge CONTINUE
	cmp dh, 1
	jle CONTINUE
	jmp COLIDE

MEIO_COLIDE:
	cmp dh, 15
	jge CONTINUE
	cmp dh, -2
	jle CONTINUE
	jmp COLIDE
	
BAIXO_COLIDE:
	cmp dh, 14
	jge CONTINUE
	cmp dh, 4
	jle CONTINUE

COLIDE:
	mov esi, [ebp + 12]
	mov BYTE PTR [esi], 1
	jmp J_EXIT
	
CONTINUE:
	add ebx, 2
	loop LP_0
	
J_EXIT:
	pop ebx
	pop ecx
	pop ax
	pop dx
	
	mov esp, ebp
	pop ebp

	ret 8
colisaoPassaros endp

;------------------------------------------------
spawnPassaro proc
; Adiciona um pássaro ao jogo
;------------------------------------------------
	push ebp
	mov ebp, esp
	
	push ebx
	push eax
	push edx
	
	mov eax, 3
	call RandomRange
	
	mov edx, [ebp + 8]
	
	mov BYTE PTR[edx], PASSARO_LARGURA + 1
	add BYTE PTR[edx], al
	
	movzx ebx, passaros_count
	shl ebx, 1
	mov (COORDENADA PTR[passaros_pos[ebx]]).X, 125
	
	mov eax, 16
	call RandomRange
	add eax, 1
	
	mov (COORDENADA PTR[passaros_pos[ebx]]).Y, al
	
	inc passaros_count
	
	pop edx
	pop eax
	pop ebx
	
	mov esp, ebp
	pop ebp
	
	ret 4
spawnPassaro endp

end