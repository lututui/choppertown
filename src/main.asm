include Irvine32.inc
include macros.inc

include inc\obstaculos\passaros.inc
include inc\obstaculos\predios.inc
include inc\util.inc

SELETOR_OFFSET = 12
SELETOR_STEP = 2

.data
heli_pos BYTE 3
colidiu BYTE 0
spawn_cooldown BYTE 0

opcao_selecionada BYTE 0

tela_atual BYTE 3
tela_base BYTE 201, COLUNAS - 2 DUP(205), 187, 0,
			LINHAS - 2 DUP(186, COLUNAS - 2 DUP(" "), 186, 0),
			200, COLUNAS - 2 DUP(205), 188, 0

pontos DWORD 0
ciclos DWORD 0

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

spawn proc uses eax
	cmp spawn_cooldown, 0
	je SORTEAR_SPAWN
	
	dec spawn_cooldown
	jmp J_EXIT

SORTEAR_SPAWN:
	call Random32
	cmp eax, 7FFFFFFFh
	push offset spawn_cooldown
	jb SPAWN_PREDIO
	jmp SPAWN_PASSARO

SPAWN_PREDIO:
	call spawnPredio
	jmp J_EXIT

SPAWN_PASSARO:
	call spawnPassaro

J_EXIT:
	ret
spawn endp

desenharHelicoptero proc uses edx eax
	call GetTextColor
	push eax
	
	mov eax, lightRed
	call SetTextColor
	
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
	
	pop eax
	call SetTextColor
	
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

desenharPontuacao proc uses eax
	mGotoxy 110, 1
	mWrite "PONTUACAO"
	
	mGotoxy 110, 2
	cmp pontos, 0
	jl ZERO
	mov eax, pontos
	jmp CONTINUE

ZERO:
	mov eax, 0

CONTINUE:
	call WriteDec
	
	ret
desenharPontuacao endp

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

resetarJogo proc
	mov colidiu, 0
	mov tela_atual, 3
	mov heli_pos, 3
	mov pontos, -10
	
	call resetarPredios
	call resetarPassaros
	
	ret
resetarJogo endp

; telaPrincipal eax edx
; Controla a tela de jogo
telaPrincipal proc uses eax edx ebx
local last_moved:DWORD, now:DWORD
	call resetarJogo
	call desenharTelaBase
	call desenharPontuacao
	call desenharHelicoptero
	
	call GetMseconds
	mov last_moved, eax

LP_0:
	mov eax, 10
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
	
	call GetMseconds
	mov now, eax
	sub eax, last_moved
	
	cmp eax, 100
	jl LP_0
	
	call moverPredios
	call moverPassaros
	
	lea esi, now
	lea edi, last_moved
	movsd
	
	push offset colidiu
	movzx eax, heli_pos
	push eax
	call colisaoPredios
	
	push offset colidiu
	movzx eax, heli_pos
	push eax
	call colisaoPassaros
	
	call desenharPontuacao
	inc ciclos
	cmp ciclos, 10
	jl CONTINUE
	mov ciclos, 0
	inc pontos

CONTINUE:
	call spawn
	
	jmp LP_0	

TECLA_DOWN:
	call incHelicoptero
	jmp NO_KEY
	
TECLA_UP:
	call decHelicoptero
	jmp NO_KEY

TECLA_ESC:
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

esconderCursor proc
	local outputhandle:DWORD, cursorinfo:CONSOLE_CURSOR_INFO

	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov outputhandle, eax
	
	invoke GetConsoleCursorInfo, outputhandle, addr cursorinfo
	mov (CONSOLE_CURSOR_INFO PTR[cursorinfo]).bVisible, 0
	
	invoke SetConsoleCursorInfo, outputhandle, addr cursorinfo
	
	ret
esconderCursor endp

main proc
	call esconderCursor
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