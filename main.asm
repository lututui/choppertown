INCLUDE Irvine32.inc
INCLUDE macros.inc

.data
linhas = 30
colunas = 120
seletor_offset = 12
seletor_step = 2

opcao_selecionada BYTE 0
tela_atual BYTE 0
tela_base BYTE 201, colunas - 2 DUP(205), 187, 0,
			linhas - 2 DUP(186, colunas - 2 DUP(" "), 186, 0),
			200, colunas - 2 DUP(205), 188, 0

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

;; FIM: MACROS


;;
;; PROCEDIMENTOS
;;

;;;
;;; Procedimentos que desenham
;;;


; desenharTelaBase edx, ecx
; Escreve na tela, a partir de (0,0), tela_base
desenharTelaBase proc uses edx ecx
	mGotoxy 0, 0
	mov edx, OFFSET tela_base
	mov ecx, linhas

LtelaBase:
	call WriteString
	add edx, colunas + 1
	loop LtelaBase

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
desenhaTelaInicial proc
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
desenhaTelaInicial endp

; desenharSeletor
; Desenha o seletor do menu
desenharSeletor proc
	call moverParaSeletor
	
	mWriteChar 175
	call WriteChar

	ret
desenharSeletor endp

; limparSeletor
; Apaga o seletor do menu
limparSeletor proc
	call moverParaSeletor

	mWriteChar 32
	call WriteChar
	
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

	mGotoxy 51, seletor_offset + 2 * seletor_step
	ret

seletor0 :
	mGotoxy 51, seletor_offset
	ret

seletor1 :
	mGotoxy 51, seletor_offset + seletor_step
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

; decpcaoSelecionada
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
;;; Procedimentos controladores de tela
;;;

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
	mov tela_atual, 0
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
	mov tela_atual, 0
	ret

telaSobre endp

; telaInicial eax edx
; Controla a tela inicial
telaInicial proc uses eax edx
	call desenhaTelaInicial
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

T_INI_TECLA_ENTER :
	cmp opcao_selecionada, 1
	je telaAtual1

	cmp opcao_selecionada, 2
	je telaAtual2

	jmp loopTelaInicial

	telaAtual1:
		mov tela_atual, 1
		ret

	telaAtual2:
		mov tela_atual, 2
		ret
	
	ret 
telaInicial endp

;;; FIM: Procedimentos controladores de tela
;; FIM: PROCEDIMENTOS

main proc
mainLp:
	cmp tela_atual, 0
	je tlInit

	cmp tela_atual, 1
	je tlInstr

	cmp tela_atual, 2
	je tlSobre

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

	exit
main endp

end main