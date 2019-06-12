INCLUDE Irvine32.inc
INCLUDE macros.inc

.data
LINHAS = 30
COLUNAS = 120

SELETOR_OFFSET = 12
SELETOR_STEP = 2

PREDIO_ALTURA = 13
PREDIO_LARGURA = 5

PASSARO_LARGURA = 5

COORDENADA STRUCT
	X BYTE 0FFh
	Y BYTE 0FFh
COORDENADA ENDS



opcao_selecionada BYTE 0

tela_atual BYTE 3
tela_base BYTE 201, COLUNAS - 2 DUP(205), 187, 0,
			LINHAS - 2 DUP(186, COLUNAS - 2 DUP(" "), 186, 0),
			200, COLUNAS - 2 DUP(205), 188, 0

heli_pos BYTE 3

predios_pos BYTE COLUNAS / 3 DUP(0FFh)
predios_count BYTE 0
predios_off BYTE 0
predios_len BYTE 0
predios_write_buffer BYTE 6 DUP(?)
predio_desenho BYTE " ___ ", 0, "| = |", 0, "|   |", 0, "| | |", 0,
					"|   |", 0, "| | |", 0, "|   |", 0, "| | |", 0,
					"| | |", 0, "|   |", 0, "| | |", 0, "| | |", 0,
					"| | |", 0
predio_clear BYTE 5 DUP (" "), 0

passaros_pos COORDENADA COLUNAS / 3 DUP(<>)
passaros_count BYTE 0
passaros_off BYTE 0
passaros_len BYTE 0
passaros_write_buffer BYTE 6 DUP(?)
passaro_desenho BYTE "/^v^", 5Ch, 0
passaro_clear BYTE 5 DUP (" "), 0

colidiu BYTE 0

timer DWORD ?

.code

;;
;; MACROS
;;

;----------------------------------------------------
mWriteChar macro chr:REQ
;
; Escreve um caractere no console
;	Recebe: caractere chr (do tipo BYTE)
;----------------------------------------------------
	push eax
	mov al, chr
	call WriteChar
	pop eax
endm

;; FIM: MACROS


;;
;; PROCEDIMENTOS
;;

;----------------------------------------------------
manipularSegmentoPredio proc
; Desenha ou apaga um segmento do predio
;----------------------------------------------------
	push ebp
	mov ebp, esp
	
	push ecx
	push eax
	push edx
	
	movzx ecx, predios_len
	
	mov esi, [ebp + 8]
	add esi, [ebp + 12]
	movzx eax, predios_off
	add esi, eax
	
	mov edi, offset predios_write_buffer
	rep movsb
	
	mov BYTE PTR [edi], 0
	mov edx, offset predios_write_buffer
	call WriteString
	
	pop edx
	pop eax
	pop ecx
	
	mov esp, ebp
	pop ebp
	
	ret 8
manipularSegmentoPredio endp

manipularSegmentoPassaro proc
	push ebp
	mov ebp, esp
	
	push ecx
	push esi
	push edx
	
	movzx ecx, passaros_len
	movzx esi, passaros_off
	add esi, [ebp + 8]
	
	mov edi, offset passaros_write_buffer
	rep movsb
	
	mov BYTE PTR [edi], 0
	mov edx, offset passaros_write_buffer
	call WriteString
	
	pop edx
	pop esi
	pop ecx
	
	mov esp, ebp
	pop ebp
	
	ret 4
manipularSegmentoPassaro endp

desenharPassaro proc uses edx ebx
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
	
	push offset passaro_desenho
	call manipularSegmentoPassaro

J_EXIT:
	ret
desenharPassaro endp

apagarPassaro proc uses edx ebx
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
	
	push offset passaro_clear
	call manipularSegmentoPassaro

J_EXIT:
	ret
apagarPassaro endp

desenharPredio proc uses ebx edx eax ecx
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
	
	mov dh, LINHAS - 1 - PREDIO_ALTURA
	mov eax, 0
	mov ecx, PREDIO_ALTURA

LP_0:
	call Gotoxy
	
	push eax
	push offset predio_desenho
	call manipularSegmentoPredio
	
	inc dh
	add eax, PREDIO_LARGURA + 1
	loop LP_0

J_EXIT:
	ret
desenharPredio endp

apagarPredio proc uses edx ecx ebx
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

	mov dh, LINHAS - 1 - PREDIO_ALTURA
	mov ecx, PREDIO_ALTURA

LP_0:
	call Gotoxy
	
	push 0
	push offset predio_clear
	call manipularSegmentoPredio
	
	inc dh
	loop LP_0

J_EXIT:
	ret
apagarPredio endp

colisaoPredios proc
	cmp heli_pos, 14
	jl J_EXIT
	
	cmp heli_pos, 16
	jge TOPO_COLIDE
	
	cmp heli_pos, 15
	je MEIO_COLIDE
	
	jmp BAIXO_COLIDE

TOPO_COLIDE:
	cmp predios_pos[0], 17
	jge J_EXIT
	cmp predios_pos[0], 1
	jle J_EXIT
	jmp COLIDE

MEIO_COLIDE:
	cmp predios_pos[0], 15
	jge J_EXIT
	cmp predios_pos[0], -2
	jle J_EXIT
	jmp COLIDE
	
BAIXO_COLIDE:
	cmp predios_pos[0], 14
	jge J_EXIT
	cmp predios_pos[0], 4
	jle J_EXIT

COLIDE:
	mov colidiu, 1
	
J_EXIT:
	ret
colisaoPredios endp

moverPassaros proc
	movzx ecx, passaros_count
	cmp ecx, 0
	je J_EXIT
	
	mov ebx, 0
	
LP_0:
	call apagarPassaro
	dec (COORDENADA PTR[passaros_pos[ebx]]).X
	
	cmp (COORDENADA PTR[passaros_pos[ebx]]).X, -4
	je SKIP_DESENHAR
	
	call desenharPassaro

SKIP_DESENHAR:
	add ebx, 2
	loop LP_0
	
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

moverPredios proc uses ecx ebx esi edi
	movzx ecx, predios_count
	cmp ecx, 0
	je J_EXIT
	
	mov ebx, 0
LP_0:
	call apagarPredio
	dec predios_pos[ebx]
	
	cmp predios_pos[ebx], -4
	je SKIP_DESENHAR
	
	call desenharPredio
	
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

desenharHelicoptero proc uses edx
	mov dl, 6
	mov dh, heli_pos
	call Gotoxy
	mWrite "-----|-----"
	
	mov dl, 3
	add dh, 1
	call Gotoxy
	mWrite "*>=====[_]L)"
	
	mov dl, 9
	add dh, 1
	call Gotoxy
	mWrite "-'-`-"
	
	ret
desenharHelicoptero endp

apagarHelicoptero proc uses edx
	mov dl, 6
	mov dh, heli_pos
	call Gotoxy
	mWrite "           "
	
	mov dl, 3
	add dh, 1
	call Gotoxy
	mWrite "            "
	
	mov dl, 9
	add dh, 1
	call Gotoxy
	mWrite "     "
	
	ret
apagarHelicoptero endp

;;;
;;; Procedimentos que desenham
;;;


; desenharTelaBase edx, ecx
; Escreve na tela, a partir de (0,0), tela_base
desenharTelaBase proc uses edx ecx eax
	mov edx, OFFSET tela_base
	mov ecx, LINHAS
	mov al, 0

LP_0:
	mGotoxy 0, al
	call WriteString
	add edx, COLUNAS + 1
	inc al
	loop LP_0

	mGotoxy 0, 0

	ret
desenharTelaBase endp

; desenharTelaSobre
; Desenha a tela acessável pelo menu "Sobre" no console
desenharTelaSobre proc
	call desenharTelaBase

	mGotoxy 53, 5
	mWrite "CHOPPER TOWN"
	
	mGotoxy 13, 12
	mWriteChar 175
	mWrite " Desenvolvido por:"

	mGotoxy 15, 13
	mWriteChar 175
	mWriteChar 175
	mWrite " Luiz Arthur Chagas Oliveira - RA: 744344"

	mGotoxy 15, 14
	mWriteChar 175
	mWriteChar 175
	mWrite " Vitor Freitas Xavier Soares - RA: 727358"

	mGotoxy 13, 16
	mWriteChar 175
	mWrite " Desenvolvido para a disciplina de Laboratorio de Arquitetura de Computadores 2, no semestre de 2019-1"

	mGotoxy 13, 18
	mWriteChar 175
	mWrite " Disciplina ministrada pelo Prof. Dr. Luciano de Oliveira Neris"

	ret
desenharTelaSobre endp

; desenharTelaInstrucoes
; Desenha a tela acessável pelo menu "Como Jogar" no console
desenharTelaInstrucoes proc
	call desenharTelaBase
	
	mGotoxy 53, 5
	mWrite "CHOPPER TOWN"

	mGotoxy 20, 12
	mWriteChar 175
	mWrite " O jogador deve mover o helicoptero, para cima ou para baixo, evitando os obstaculos"

	mGotoxy 20, 14
	mWriteChar 175
	mWrite " O jogador deve ir o mais longe possivel"

	mGotoxy 20, 16
	mWriteChar 175
	mWrite " O jogador ganha pontos de acordo com o tempo de jogo"

	mGotoxy 20, 18
	mWriteChar 175
	mWrite " O joga acaba quando o helicoptero colidir com qualquer obstaculo"

	mGotoxy 20, 20
	mWriteChar 175
	mWrite " Para mover o helicoptero para cima, use W ou a seta para cima"

	mGotoxy 20, 22
	mWriteChar 175
	mWrite " Para mover o helicoptero para cima, use S ou a seta para baixo"
	
	ret
desenharTelaInstrucoes endp

; desenharTelaInicial
; Desenha a tela exibida quando o jogo é iniciado
desenharTelaInicial proc
	call desenharTelaBase
	
	mGotoxy 53, 5
	mWrite "CHOPPER TOWN"

	mGotoxy 54, 12
	mWrite "Jogar"

	mGotoxy 54, 14
	mWrite "Como Jogar"

	mGotoxy 54, 16
	mWrite "Sobre"

	ret
desenharTelaInicial endp

; desenharSeletor
; Desenha o seletor do menu
desenharSeletor proc
	call moverParaSeletor
	
	mWriteChar 175

	ret
desenharSeletor endp

; limparSeletor
; Apaga o seletor do menu
limparSeletor proc
	call moverParaSeletor

	mWriteChar 32
	
	ret
limparSeletor endp

;;; FIM: Procedimentos que desenham

;;;
;;; Procedimentos que movem o cursor
;;;

; moverParaSeletor
; Move o cursor para a posição do seletor do menu
moverParaSeletor proc uses eax edx
	mov ah, opcao_selecionada
	mov al, SELETOR_STEP
	mul ah
	add ax, SELETOR_OFFSET
	
	mov dl, 51
	mov dh, al
	call Gotoxy
	
	ret
moverParaSeletor endp

;;; FIM: Procedimentos que movem o cursor

;;; 
;;; Procedimentos que controlam o seletor do menu
;;;

; incOpcaoSelecionada
; Move o seletor para baixo na memória
incOpcaoSelecionada proc
	inc opcao_selecionada
	
	cmp opcao_selecionada, 2
	jle J_EXIT
	
	mov opcao_selecionada, 0

J_EXIT:
	ret
incOpcaoSelecionada endp

; decOpcaoSelecionada
; Move o seletor para cima na memória
decOpcaoSelecionada proc
	dec opcao_selecionada
	
	cmp opcao_selecionada, 0
	jge J_EXIT
	
	mov opcao_selecionada, 2

J_EXIT:
	ret
decOpcaoSelecionada endp

;;; FIM: Procedimentos que controlam o seletor do menu

;;; 
;;; Procedimentos que controlam o helicóptero verticalmente
;;;

; incHelicoptero
; Move o helicoptero para baixo na tela
incHelicoptero proc
	cmp heli_pos, 25
	jg J_EXIT
	
	call apagarHelicoptero
	
	inc heli_pos
	call desenharHelicoptero

J_EXIT:
	ret
incHelicoptero endp

; incHelicoptero
; Move o helicoptero para cima na tela
decHelicoptero proc
	cmp heli_pos, 2
	jl J_EXIT

	call apagarHelicoptero
	
	dec heli_pos
	call desenharHelicoptero

J_EXIT:
	ret
decHelicoptero endp


;;;
;;; Procedimentos controladores de tela
;;;


; telaPrincipal eax edx
; Controla a tela de jogo
telaPrincipal proc uses eax edx ebx
	call desenharTelaBase
	call desenharHelicoptero
	
	call GetTickCount
	mov timer, eax
	
	mov predios_pos[0], 16
	inc predios_count
	mov ebx, 0
	call desenharPredio
	
	mov (COORDENADA PTR [passaros_pos[0]]).X, 125
	mov (COORDENADA PTR [passaros_pos[0]]).Y, 5
	inc passaros_count
	mov ebx, 0
	call desenharPassaro

LP_0:
	mov eax, 50
	call Delay

	call ReadKey
	jz NO_KEY
	
	cmp dx, VK_ESCAPE
	je TECLA_ESC
	
	cmp colidiu, 1
	je LP_0
	
	cmp dx, VK_DOWN
	je TECLA_DOWN
	
	cmp dx, 53h
	je TECLA_DOWN
	
	cmp dx, VK_UP
	je TECLA_UP
	
	cmp dx, 57h
	je TECLA_UP
	
NO_KEY:
	cmp colidiu, 1
	je LP_0
	
	call GetTickCount
	push eax
	sub eax, timer
	cmp eax, 100
	jl LP_0
	
	call moverPredios
	call colisaoPredios
	call moverPassaros
	
	pop timer
	
	jmp LP_0	

TECLA_DOWN:
	call incHelicoptero
	jmp NO_KEY
	
TECLA_UP:
	call decHelicoptero
	jmp NO_KEY

TECLA_ESC:
	mov tela_atual, 3
	ret
telaPrincipal endp


; telaInstrucoes eax edx
; Controla a tela de "Como Jogar"
telaInstrucoes proc uses eax edx
	call desenharTelaInstrucoes

LP_0:
	mov eax, 50
	call Delay

	call ReadKey
	jz LP_0

	cmp dx, VK_ESCAPE
	je TECLA_ESC

	jmp LP_0

TECLA_ESC:
	mov tela_atual, 3
	ret

telaInstrucoes endp

; telaSobre eax edx
; Controla a tela de "Sobre"
telaSobre proc uses eax edx
	call desenharTelaSobre

LP_0:
	mov eax, 50
	call Delay

	call ReadKey
	jz LP_0

	cmp dx, VK_ESCAPE
	je TECLA_ESC

	jmp LP_0

TECLA_ESC:
	mov tela_atual, 3
	ret

telaSobre endp

; telaInicial eax edx
; Controla a tela inicial
telaInicial proc uses eax edx
	call desenharTelaInicial
	call desenharSeletor

LP_0:
	mov eax, 50
	call Delay

	call ReadKey
	jz LP_0
	
	cmp dx, VK_DOWN
	je TECLA_DOWN

	cmp dx, 53h
	je TECLA_DOWN

	cmp dx, VK_UP
	je TECLA_UP

	cmp dx, 57h
	je TECLA_UP

	cmp dx, VK_RETURN
	je TECLA_ENTER

	jmp LP_0

TECLA_DOWN:
	call limparSeletor
	call incOpcaoSelecionada
	call desenharSeletor

	jmp LP_0

TECLA_UP:
	call limparSeletor
	call decOpcaoSelecionada
	call desenharSeletor

	jmp LP_0

TECLA_ENTER:
	mov edi, offset tela_atual
	mov esi, offset opcao_selecionada
	movsb
	ret 
telaInicial endp

;;; FIM: Procedimentos controladores de tela
;; FIM: PROCEDIMENTOS

main proc
LP_0:
	cmp tela_atual, 0
	je PRINCIPAL

	cmp tela_atual, 1
	je INSTRUCOES

	cmp tela_atual, 2
	je SOBRE
	
	cmp tela_atual, 3
	je INICIAL

	jmp LP_0

INICIAL:
	call telaInicial
	jmp LP_0

INSTRUCOES:
	call telaInstrucoes
	jmp LP_0

SOBRE:
	call telaSobre
	jmp LP_0

PRINCIPAL:
	call telaPrincipal
	jmp LP_0

	exit
main endp

end main