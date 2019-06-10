INCLUDE Irvine32.inc
INCLUDE macros.inc

.data
linhas = 30
colunas = 120

SELETOR_OFFSET = 12
SELETOR_STEP = 2

PREDIO_ALTURA = 13
PREDIO_LARGURA = 5

opcao_selecionada BYTE 0
tela_atual BYTE 3
tela_base BYTE 201, colunas - 2 DUP(205), 187, 0,
			linhas - 2 DUP(186, colunas - 2 DUP(" "), 186, 0),
			200, colunas - 2 DUP(205), 188, 0
heli_pos BYTE 3
predios_pos BYTE colunas / 3 DUP(0FFh)
predios_count BYTE 0
predios_off BYTE 0
predios_len BYTE 0
predios_write_buffer BYTE 6 DUP(?)

predio_desenho BYTE " ___ ", 0, "| = |", 0, "|   |", 0, "| | |", 0,
					"|   |", 0, "| | |", 0, "|   |", 0, "| | |", 0,
					"| | |", 0, "|   |", 0, "| | |", 0, "| | |", 0,
					"| | |", 0
predio_clear BYTE 5 DUP (" "), 0

timer DWORD ?

.code

;;
;; MACROS
;;

; mWriteChar chr
; Escreve o caractere chr no console
mWriteChar macro chr
	push eax
	mov al, chr
	call WriteChar
	pop eax
endm

; mMovMMB m1, m2
; Move um byte da posição de memória m2 para a posição de memória m1
mMovMMB macro m1, m2
	push eax
	mov al, m2
	mov m1, al
	pop eax
endm

;; FIM: MACROS


;;
;; PROCEDIMENTOS
;;

desenharSegmentoPredio proc uses ecx eax esi edi edx
	movzx ecx, predios_len
	
	mov esi, offset predio_desenho
	add esi, eax
	movzx eax, predios_off
	add esi, eax
	
	mov edi, offset predios_write_buffer
	
	rep movsb
	
	mov BYTE PTR [edi], 0
	mov edx, offset predios_write_buffer
	call WriteString
	
	ret
desenharSegmentoPredio endp

apagarSegmentoPredio proc uses ecx esi edi edx
	movzx ecx, predios_len
	
	movzx esi, predios_off
	add esi, offset predio_clear
	
	mov edi, offset predios_write_buffer
	
	rep movsb
	
	mov BYTE PTR [edi], 0
	mov edx, offset predios_write_buffer
	call WriteString
	
	ret
apagarSegmentoPredio endp

desenharPredio proc uses ebx edx eax ecx
	mov dl, predios_pos[ebx]
	
	cmp dl, 0
	jle J_DESENHAR_PREDIO_0
	mov predios_off, 0

	cmp dl, 120
	jge EXIT_DESENHAR_PREDIO
	
	cmp dl, 115
	jge J_DESENHAR_PREDIO_1
	
	mov predios_len, PREDIO_LARGURA
	
	jmp CONTINUE_DESENHAR_PREDIO_0
	
J_DESENHAR_PREDIO_0:
	not dl
	add dl, 2
	mov predios_off, dl
	mov dl, 1

	jmp CONTINUE_DESENHAR_PREDIO_0

J_DESENHAR_PREDIO_1:
	mov predios_len, 119
	sub predios_len, dl
	
CONTINUE_DESENHAR_PREDIO_0:
	cmp predios_len, 0
	je EXIT_DESENHAR_PREDIO
	
	mov dh, linhas - 1 - PREDIO_ALTURA
	mov eax, 0
	mov ecx, PREDIO_ALTURA

L_DESENHAR_PREDIO:
	call Gotoxy
	call desenharSegmentoPredio
	inc dh
	add eax, PREDIO_LARGURA + 1
	loop L_DESENHAR_PREDIO

EXIT_DESENHAR_PREDIO:
	ret
desenharPredio endp

apagarPredio proc uses edx ecx ebx
	mov dl, predios_pos[ebx]
	
	cmp dl, 0
	jle J_APAGAR_PREDIO_0
	mov predios_off, 0
	
	cmp dl, 120
	jge EXIT_APAGAR_PREDIO
	
	cmp dl, 115
	jge J_APAGAR_PREDIO_1
	mov predios_len, PREDIO_LARGURA
	
	jmp CONTINUE_APAGAR_PREDIO_0
	
J_APAGAR_PREDIO_0:
	not dl
	add dl, 2
	mov predios_off, dl
	mov dl, 1
	
	jmp CONTINUE_APAGAR_PREDIO_0

J_APAGAR_PREDIO_1:
	mov predios_len, 119
	sub predios_len, dl
	
CONTINUE_APAGAR_PREDIO_0:
	cmp predios_len, 0
	je EXIT_APAGAR_PREDIO

	mov dh, linhas - 1 - 13
	mov ecx, 13

L_APAGAR_PREDIO:
	call Gotoxy
	call apagarSegmentoPredio
	inc dh
	loop L_APAGAR_PREDIO

EXIT_APAGAR_PREDIO:
	ret
apagarPredio endp

moverPredios proc uses ecx ebx esi edi
	movzx ecx, predios_count
	cmp ecx, 0
	je END_MOVER_PREDIOS
	
	mov ebx, 0
L_MOVER_PREDIOS:
	call apagarPredio
	dec predios_pos[ebx]
	
	cmp predios_pos[0], -4
	je SKIP_DESENHAR_MOVER_PREDIOS
	
	call desenharPredio
	
SKIP_DESENHAR_MOVER_PREDIOS:
	inc ebx
	loop L_MOVER_PREDIOS

	cmp predios_pos[0], -4
	jne END_MOVER_PREDIOS
	
	movzx ecx, predios_count
	dec predios_count
	mov edi, OFFSET predios_pos
	mov esi, edi
	inc esi
	rep movsb

END_MOVER_PREDIOS:
	ret
moverPredios endp

desenharHelicoptero proc uses edx
	mov dl, 3
	mov dh, heli_pos
	call Gotoxy
	mWrite "   -----|-----"
	
	inc dh
	call Gotoxy
	mWrite "*>=====[_]L)"
	
	inc dh
	call Gotoxy
	mWrite "      -'-`-"
	
	ret
desenharHelicoptero endp

apagarHelicoptero proc uses edx
	mov dl, 3
	mov dh, heli_pos
	call Gotoxy
	mWrite "              "
	
	inc dh
	call Gotoxy
	mWrite "              "
	
	inc dh
	call Gotoxy
	mWrite "              "
	
	ret
apagarHelicoptero endp

;;;
;;; Procedimentos que desenham
;;;


; desenharTelaBase edx, ecx
; Escreve na tela, a partir de (0,0), tela_base
desenharTelaBase proc uses edx ecx eax
	mov edx, OFFSET tela_base
	mov ecx, linhas
	mov al, 0

LtelaBase:
	mGotoxy 0, al
	call WriteString
	add edx, colunas + 1
	inc al
	loop LtelaBase

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
moverParaSeletor proc
	cmp opcao_selecionada, 0
	je seletor0
	cmp opcao_selecionada, 1
	je seletor1

	mGotoxy 51, SELETOR_OFFSET + 2 * SELETOR_STEP
	ret

seletor0 :
	mGotoxy 51, SELETOR_OFFSET
	ret

seletor1 :
	mGotoxy 51, SELETOR_OFFSET + SELETOR_STEP
	ret
moverParaSeletor endp

;;; FIM: Procedimentos que movem o cursor

;;; 
;;; Procedimentos que controlam o seletor do menu
;;;

; incOpcaoSelecionada
; Move o seletor para baixo na memória
incOpcaoSelecionada proc
	cmp opcao_selecionada, 2
	jl incSimplesOS
	mov opcao_selecionada, 0
	ret

incSimplesOS:
	inc opcao_selecionada
	ret
incOpcaoSelecionada endp

; decOpcaoSelecionada
; Move o seletor para cima na memória
decOpcaoSelecionada proc
	cmp opcao_selecionada, 0
	jg decSimplesOS
	mov opcao_selecionada, 2
	ret

decSimplesOS :
	dec opcao_selecionada
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
	jg retIncHeli
	
	call apagarHelicoptero
	
	inc heli_pos
	call desenharHelicoptero

retIncHeli:
	ret
incHelicoptero endp

; incHelicoptero
; Move o helicoptero para cima na tela
decHelicoptero proc
	cmp heli_pos, 2
	jl retDecHeli

	call apagarHelicoptero
	
	dec heli_pos
	call desenharHelicoptero

retDecHeli:
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
	
	mov predios_pos[0], 130
	inc predios_count
	mov ebx, 0
	call desenharPredio

loopTelaPrincipal:
	mov eax, 50
	call Delay

	call ReadKey
	jz T_PRIN_NO_KEY
	
	cmp dx, VK_ESCAPE
	je T_PRIN_TECLA_ESC
	
	cmp dx, VK_DOWN
	je T_PRIN_TECLA_DOWN
	
	cmp dx, 53h
	je T_PRIN_TECLA_DOWN
	
	cmp dx, VK_UP
	je T_PRIN_TECLA_UP
	
	cmp dx, 57h
	je T_PRIN_TECLA_UP
	
T_PRIN_NO_KEY:
	call GetTickCount
	push eax
	sub eax, timer
	cmp eax, 100
	jl loopTelaPrincipal
	
	call moverPredios
	pop timer
	
	jmp loopTelaPrincipal	

T_PRIN_TECLA_DOWN:
	call incHelicoptero
	jmp T_PRIN_NO_KEY
	
T_PRIN_TECLA_UP:
	call decHelicoptero
	jmp T_PRIN_NO_KEY

T_PRIN_TECLA_ESC:
	mov tela_atual, 3
	ret
telaPrincipal endp


; telaInstrucoes eax edx
; Controla a tela de "Como Jogar"
telaInstrucoes proc uses eax edx
	call desenharTelaInstrucoes

loopTelaInstrucoes:
	mov eax, 50
	call Delay

	call ReadKey
	jz loopTelaInstrucoes

	cmp dx, VK_ESCAPE
	je T_INSTR_TECLA_ESC

	jmp loopTelaInstrucoes

T_INSTR_TECLA_ESC:
	mov tela_atual, 3
	ret

telaInstrucoes endp

; telaSobre eax edx
; Controla a tela de "Sobre"
telaSobre proc uses eax edx
	call desenharTelaSobre

loopTelaSobre :
	mov eax, 50
	call Delay

	call ReadKey
	jz loopTelaSobre

	cmp dx, VK_ESCAPE
	je T_SOBRE_TECLA_ESC

	jmp loopTelaSobre

T_SOBRE_TECLA_ESC :
	mov tela_atual, 3
	ret

telaSobre endp

; telaInicial eax edx
; Controla a tela inicial
telaInicial proc uses eax edx
	call desenharTelaInicial
	call desenharSeletor

loopTelaInicial:
	mov eax, 50
	call Delay

	call ReadKey
	jz loopTelaInicial
	
	cmp dx, VK_DOWN
	je T_INI_TECLA_PARA_BAIXO

	cmp dx, 53h
	je T_INI_TECLA_PARA_BAIXO

	cmp dx, VK_UP
	je T_INI_TECLA_PARA_CIMA

	cmp dx, 57h
	je T_INI_TECLA_PARA_CIMA

	cmp dx, VK_RETURN
	je T_INI_TECLA_ENTER

	jmp loopTelaInicial

T_INI_TECLA_PARA_BAIXO :
	call limparSeletor
	call incOpcaoSelecionada
	call desenharSeletor

	jmp loopTelaInicial

T_INI_TECLA_PARA_CIMA :
	call limparSeletor
	call decOpcaoSelecionada
	call desenharSeletor

	jmp loopTelaInicial

T_INI_TECLA_ENTER:
	mMovMMB tela_atual, opcao_selecionada
	ret 
telaInicial endp

;;; FIM: Procedimentos controladores de tela
;; FIM: PROCEDIMENTOS

main proc
mainLp:
	cmp tela_atual, 0
	je tlPrin

	cmp tela_atual, 1
	je tlInstr

	cmp tela_atual, 2
	je tlSobre
	
	cmp tela_atual, 3
	je tlInit

	jmp mainLp

tlInit:
	call telaInicial
	jmp mainLp

tlInstr:
	call telaInstrucoes
	jmp mainLp

tlSobre:
	call telaSobre
	jmp mainLp

tlPrin:
	call telaPrincipal
	jmp mainLp

	exit
main endp

end main