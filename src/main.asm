include Irvine32.inc
include macros.inc

include inc\obstaculos\passaros.inc
include inc\obstaculos\predios.inc
include inc\util.inc

includelib Winmm.lib
includelib Kernel32.lib

PlaySound PROTO, pszSound:PTR BYTE, hmod:DWORD, fdwSound:DWORD
GetModuleFileNameA PROTO, hModule:DWORD, lpFilename:PTR BYTE, nSize:BYTE

SELETOR_OFFSET = 16
SELETOR_STEP = 2

.data
heli_pos BYTE 3
colidiu BYTE 0
spawn_cooldown BYTE 0

opcao_selecionada BYTE 0

tela_atual BYTE 4
tela_base BYTE 201, COLUNAS - 2 DUP(205), 187, 0,
			LINHAS - 2 DUP(186, COLUNAS - 2 DUP(" "), 186, 0),
			200, COLUNAS - 2 DUP(205), 188, 0

pontos DWORD 0
ciclos DWORD 0
freq BYTE 100

SND_ASYNC DWORD 1h
SND_FILENAME_SYNC DWORD 00020000h
SND_FILENAME_ASYNC DWORD 00020001h
SND_FILENAME_LOOP DWORD 00020009h

GAME_PATH BYTE 256 DUP(?)
FILE_GAMEOVER BYTE "rsc\game_over.wav", 0
FILE_MENU BYTE "rsc\menu.wav", 0
FILE_HELI BYTE "rsc\helicoptero.wav", 0

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

;------------------------------------------------
telaConfiguracao proc uses eax
; Controla a tela de configuração
;------------------------------------------------
	call desenharTelaConfiguracao
	call desenharSeletorDificuldade

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
	
	cmp dx, VK_ESCAPE
	je TECLA_ENTER

	jmp LP_0
	
TECLA_DOWN:
	call limparSeletorDificuldade
	call incDificuldadeSelecionada
	call desenharSeletorDificuldade
	
	jmp LP_0

TECLA_UP:
	call limparSeletorDificuldade
	call decDificuldadeSelecionada
	call desenharSeletorDificuldade
	
	jmp LP_0

TECLA_ENTER:
	mov tela_atual, 4
	ret
telaConfiguracao endp

;------------------------------------------------
desenharTelaConfiguracao proc
; Desenha a tela de configuração
;------------------------------------------------
	call desenharTelaBase
	call desenharTitulo
	
	mGotoxy 54, 16
	mWrite "Facil"
	
	mGotoxy 54, 18
	mWrite "Normal"
	
	mGotoxy 54, 20
	mWrite "Dificil"
	
	ret
desenharTelaConfiguracao endp

;------------------------------------------------
desenharSeletorDificuldade proc
; Desenha o seletor de dificuldade
;------------------------------------------------
	call moverParaSeletorDificuldade
	
	mWriteChar 175
	
	ret
desenharSeletorDificuldade endp

;------------------------------------------------
limparSeletorDificuldade proc
; Apaga o seletor de dificuldade
;------------------------------------------------
	call moverParaSeletorDificuldade
	
	mWriteChar 32
	
	ret
limparSeletorDificuldade endp

;------------------------------------------------
moverParaSeletorDificuldade proc uses eax edx
; Move o cursor para a posição do seletor de
;  dificuldade
;------------------------------------------------
	movzx eax, freq
	
	cmp eax, 150
	je FACIL
	
	cmp eax, 100
	je NORMAL
	
	jmp DIFICIL
	
FACIL:
	mov ah, 0
	jmp CONTINUE
	
NORMAL:
	mov ah, 1
	jmp CONTINUE

DIFICIL:
	mov ah, 2
	
CONTINUE:
	mov al, SELETOR_STEP
	mul ah
	add ax, SELETOR_OFFSET
	
	mov dl, 51
	mov dh, al
	call Gotoxy
	
	ret
moverParaSeletorDificuldade endp

;------------------------------------------------
incDificuldadeSelecionada proc
; Aumenta a dificuldade do jogo
;------------------------------------------------
	sub freq, 50
	
	cmp freq, 50
	jge J_EXIT
	
	mov freq, 150

J_EXIT:
	ret
incDificuldadeSelecionada endp

;------------------------------------------------
decDificuldadeSelecionada proc
; Diminui a dificuldade do jogo
;------------------------------------------------
	add freq, 50
	
	cmp freq, 200
	jge J_EXIT
	
	mov freq, 50

J_EXIT:
	ret
decDificuldadeSelecionada endp

;------------------------------------------------
telaFimDeJogo proc
; Controla a tela de fim de jogo
;------------------------------------------------
	call desenharTelaBase
	call desenharTelaFimDeJogo
	
LP_0:
	mov eax, 50
	call Delay

	call ReadKey
	jz LP_0
	
	cmp dx, VK_RETURN
	je TECLA_ENTER
	
	cmp dx, VK_ESCAPE
	je TECLA_ESC
	
	jmp LP_0
	
TECLA_ENTER:
	mov tela_atual, 0
	jmp J_EXIT

TECLA_ESC:
	mov tela_atual, 4
	jmp J_EXIT
	
J_EXIT:
	ret
telaFimDeJogo endp

;------------------------------------------------
desenharTelaFimDeJogo proc
; Desenha a tela do fim de jogo
;------------------------------------------------
	call desenharTelaBase
	call desenharTitulo
	
	mGotoxy 40, 18
	mwrite "Sua pontuacao foi de: "
	
	call GetTextColor
	push eax
	
	mov eax, lightMagenta
    call SetTextColor
	
	mGotoxy 71, 18
	mov eax, pontos
	
	cmp eax, 0
	jge WRITE
	
	mov eax, 0

WRITE:
	call WriteDec
	
	pop eax
	call SetTextColor
	
	mGotoxy 22, 22
	mWrite "Para jogar novamente, aperte ENTER. Para voltar ao Menu Principal, aperte ESC"
	
	ret
desenharTelaFimDeJogo endp

;------------------------------------------------
telaPrincipal proc uses eax edx ebx
; Controla a tela de jogo
local last_moved:DWORD, now:DWORD, sound_gameover[256]:BYTE, sound_game[256]:BYTE
; last_moved e now controlam a velocidade do jogo
; sound_gameover: path do som de colisão
; sound_game: path do som ambiente do jogo 
;------------------------------------------------
	call resetarJogo
	call desenharTelaBase
	call desenharPontuacao
	call desenharHelicoptero
	
	push offset FILE_GAMEOVER
	lea edi, sound_gameover
	push edi
	call fazerPath
	
	push offset FILE_HELI
	lea edi, sound_game
	push edi
	call fazerPath
	
	; Som ambiente
	invoke PlaySound, addr sound_game, 0, SND_FILENAME_LOOP
	
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
	je FIM_DE_JOGO
	
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
	je FIM_DE_JOGO
	
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

FIM_DE_JOGO:
	; Para o som de ambiente
	invoke PlaySound, 0, 0, SND_ASYNC
	; Efeito de colisão
	invoke PlaySound, addr sound_gameover, 0, SND_FILENAME_SYNC
	mov tela_atual, 5
	jmp J_EXIT

TECLA_DOWN:
	call incHelicoptero
	jmp NO_KEY
	
TECLA_UP:
	call decHelicoptero
	jmp NO_KEY

TECLA_ESC:
	mov tela_atual, 5
	jmp J_EXIT

J_EXIT:
	ret
telaPrincipal endp

;------------------------------------------------
resetarJogo proc
; Prepara o jogo para ser jogado
;------------------------------------------------
	mov colidiu, 0
	mov heli_pos, 3
	mov pontos, -10
	
	call resetarPredios
	call resetarPassaros
	
	ret
resetarJogo endp

;------------------------------------------------
desenharPontuacao proc uses eax
; Desenha a pontuação atual no canto superior
;  direito
;------------------------------------------------
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

;------------------------------------------------
desenharHelicoptero proc uses edx eax
; Desenha o helicoptero
;------------------------------------------------
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

;------------------------------------------------
apagarHelicoptero proc uses edx
; Apaga o helicoptero
;------------------------------------------------
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

;------------------------------------------------
spawn proc uses eax
; Adiciona um novo pássaro ou prédio ao jogo
;------------------------------------------------
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

;------------------------------------------------
incHelicoptero proc
; Move o helicoptero para baixo na tela
;------------------------------------------------
	cmp heli_pos, 25
	jg J_EXIT
	
	call apagarHelicoptero
	
	inc heli_pos
	call desenharHelicoptero

J_EXIT:
	ret
incHelicoptero endp

;------------------------------------------------
decHelicoptero proc
; Move o helicoptero para cima na tela
;------------------------------------------------
	cmp heli_pos, 2
	jl J_EXIT

	call apagarHelicoptero
	
	dec heli_pos
	call desenharHelicoptero

J_EXIT:
	ret
decHelicoptero endp

;------------------------------------------------
telaSobre proc uses eax edx
; Controla a tela de "Sobre"
;------------------------------------------------
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
	mov tela_atual, 4
	ret
telaSobre endp

;------------------------------------------------
desenharTelaSobre proc
; Desenha a tela de "Sobre"
;------------------------------------------------
	call desenharTelaBase
	call desenharTitulo
	
	mGotoxy 10, 15
	mWriteChar 175
	mWrite " Desenvolvido por:"

	mGotoxy 12, 17
	mWriteChar 175
	mWriteChar 175
	mWrite " Luiz Arthur Chagas Oliveira - RA: 744344"

	mGotoxy 12, 18
	mWriteChar 175
	mWriteChar 175
	mWrite " Vitor Freitas Xavier Soares - RA: 727358"

	mGotoxy 10, 20
	mWriteChar 175
	mWrite " Desenvolvido para a disciplina de Laboratorio de Arquitetura de Computadores 2, no semestre de 2019-1"

	mGotoxy 10, 21
	mWriteChar 175
	mWrite " Disciplina ministrada pelo Prof. Dr. Luciano de Oliveira Neris"

	ret
desenharTelaSobre endp

;------------------------------------------------
telaInstrucoes proc uses eax edx
; Controla a tela de "Como Jogar"
;------------------------------------------------
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
	mov tela_atual, 4
	ret
telaInstrucoes endp

;------------------------------------------------
desenharTelaInstrucoes proc
; Desenha a tela de "Como Jogar"
;------------------------------------------------
	call desenharTelaBase
	call desenharTitulo

	mGotoxy 20, 16
	mWriteChar 175
	mWrite " O jogador deve mover o helicoptero, para cima ou para baixo, evitando os obstaculos"

	mGotoxy 20, 18
	mWriteChar 175
	mWrite " O jogador deve ir o mais longe possivel"

	mGotoxy 20, 20
	mWriteChar 175
	mWrite " O jogador ganha pontos de acordo com o tempo de jogo"

	mGotoxy 20, 22
	mWriteChar 175
	mWrite " O joga acaba quando o helicoptero colidir com qualquer obstaculo"

	mGotoxy 20, 24
	mWriteChar 175
	mWrite " Para mover o helicoptero para cima, use W ou a seta para cima"

	mGotoxy 20, 26
	mWriteChar 175
	mWrite " Para mover o helicoptero para cima, use S ou a seta para baixo"
	
	ret
desenharTelaInstrucoes endp

;------------------------------------------------
telaInicial proc uses eax edx
; Procedimento controlador da tela de menu
;------------------------------------------------
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

;------------------------------------------------
desenharTelaInicial proc
; Desenha o menu principal
;------------------------------------------------
	call desenharTelaBase
	call desenharTitulo

	mGotoxy 54, 16
	mWrite "Jogar"

	mGotoxy 54, 18
	mWrite "Como Jogar"

	mGotoxy 54, 20
	mWrite "Sobre"
	
	mGotoxy 54, 22
	mWrite "Configuracao"

	ret
desenharTelaInicial endp

;------------------------------------------------
desenharSeletor proc
; Desenha o seletor do menu principal
;------------------------------------------------
	call moverParaSeletor
	
	mWriteChar 175

	ret
desenharSeletor endp

;------------------------------------------------
limparSeletor proc
; Desenha o seletor do menu principal
;------------------------------------------------
	call moverParaSeletor

	mWriteChar 32
	
	ret
limparSeletor endp

;------------------------------------------------
moverParaSeletor proc uses eax edx
; Move o cursor para a posição do seletor do menu
;------------------------------------------------
	mov ah, opcao_selecionada
	mov al, SELETOR_STEP
	mul ah
	add ax, SELETOR_OFFSET
	
	mov dl, 51
	mov dh, al
	call Gotoxy
	
	ret
moverParaSeletor endp

;------------------------------------------------
incOpcaoSelecionada proc
; Move o seletor para baixo
;------------------------------------------------
	inc opcao_selecionada
	
	cmp opcao_selecionada, 3
	jle J_EXIT
	
	mov opcao_selecionada, 0

J_EXIT:
	ret
incOpcaoSelecionada endp

;------------------------------------------------
decOpcaoSelecionada proc
; Move o seletor para cima
;------------------------------------------------
	dec opcao_selecionada
	
	cmp opcao_selecionada, 0
	jge J_EXIT
	
	mov opcao_selecionada, 3

J_EXIT:
	ret
decOpcaoSelecionada endp

;------------------------------------------------
desenharTelaBase proc uses edx ecx eax
; Desenha a borda utilizada na maioria das telas 
;  do jogo
;------------------------------------------------
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

;------------------------------------------------
desenharTitulo proc
; Desenha o título do jogo em ascii art
;------------------------------------------------
	call GetTextColor
	push eax
	
	mov eax, lightRed
	call SetTextColor
	
	mGotoxy 25, 5
	mWrite " _____ _                                   _______" 
	mGotoxy 24, 6
	mWrite " / ____| |                                 |__   __| "
	mGotoxy 23, 7
	mWrite " | |    | |__   ___  _ __  _ __   ___ _ __     | | _____      ___ __  "
	mGotoxy 23, 8
	mWrite " | |    | '_ \ / _ \| '_ \| '_ \ / _ \ '__|    | |/ _ \ \ /\ / / '_ \"
	mGotoxy 23, 9
	mWrite " | |____| | | | (_) | |_) | |_) |  __/ |       | | (_) \ V  V /| | | |"
	mGotoxy 25, 10
	mWrite "\_____|_| |_|\___/| .__/| .__/ \___|_|       |_|\___/ \_/\_/ |_| |_|"
	mGotoxy 43, 11
	mWrite "| |   | | "
	mGotoxy 43, 12
	mWrite "|_|   |_| "
	
	pop eax
	call SetTextColor
	
	ret
desenharTitulo endp

;------------------------------------------------
esconderCursor proc
; Esconde o cursor do console
;
	local outputhandle:DWORD, cursorinfo:CONSOLE_CURSOR_INFO
;-----------------------------------------------
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov outputhandle, eax
	
	invoke GetConsoleCursorInfo, outputhandle, addr cursorinfo
	mov (CONSOLE_CURSOR_INFO PTR[cursorinfo]).bVisible, 0
	
	invoke SetConsoleCursorInfo, outputhandle, addr cursorinfo
	
	ret
esconderCursor endp

;------------------------------------------------
obterPath proc
; Obtem o home path do jogo, que é salvo em
;  GAME_PATH
;------------------------------------------------
	invoke GetModuleFileNameA, 0, offset GAME_PATH, 255

	lea edi, GAME_PATH
	add edi, eax
	dec edi

LP_0:
	cmp BYTE PTR [edi], 92
	je J_EXIT
	
	mov BYTE PTR [edi], 0
	dec edi
	jmp LP_0

J_EXIT:
	ret
obterPath endp

;------------------------------------------------
fazerPath proc
; Constroi path completo de um arquivo
; [ebp + 8]: ponteiro para saida
; [ebp + 12]: path relativo de um arquivo
;------------------------------------------------
	push ebp
	mov ebp, esp
	
	push edx
	push ecx
	push eax
	
	mov edx, offset GAME_PATH
	call StrLength
	
	mov ecx, eax	
	mov edi, [ebp + 8]
	mov esi, offset GAME_PATH
	rep movsb
	
	mov edx, [ebp + 12]
	call StrLength
	
	mov ecx, eax
	mov esi, [ebp + 12]
	rep movsb
	
	mov BYTE PTR [edi], 0
	
	pop eax
	pop ecx
	pop edx
	
	mov esp, ebp
	pop ebp
	
	ret 8
fazerPath endp

;; FIM: PROCEDIMENTOS

;------------------------------------------------
main proc
; Entry point do jogo
	local sound_menu[256]:BYTE
; Path da música dos menus
;------------------------------------------------
	call esconderCursor
	call obterPath
	
	push offset FILE_MENU
	lea edi, sound_menu
	push edi
	call fazerPath
	
	; Toca a musica de menu em loop
	invoke Playsound, addr sound_menu, 0, SND_FILENAME_LOOP
LP_0:
	cmp tela_atual, 0
	je PRINCIPAL

	cmp tela_atual, 1
	je INSTRUCOES

	cmp tela_atual, 2
	je SOBRE
	
	cmp tela_atual, 3
	je CONFIGURAR
	
	cmp tela_atual, 4
	je INICIAL
	
	cmp tela_atual, 5
	je FIM_DE_JOGO

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
	; Interrompe a música de menu
	invoke PlaySound, 0, 0, SND_ASYNC
	
	call telaPrincipal
	
	; Reinicia a música de menu
	invoke Playsound, addr sound_menu, 0, SND_FILENAME_LOOP
	
	jmp LP_0

FIM_DE_JOGO:
	call telaFimDeJogo
	jmp LP_0

CONFIGURAR:
	call telaConfiguracao
	jmp LP_0

	exit
	ret
main endp

end main