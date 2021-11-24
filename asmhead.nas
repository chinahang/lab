; haribote-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; bootpack ｼﾓﾔﾘｵﾘﾖｷ
DSKCAC	EQU		0x00100000		; ｴﾅﾅﾌｻｺｴ豬ﾘﾖｷ
DSKCAC0	EQU		0x00008000		; ｴﾅﾅﾌｻｺｴ豬ﾘﾖｷﾊｵﾄ｣ﾊｽ

; BOOT_INFO信息
CYLS	EQU		0x0ff0			; 10
LEDS	EQU		0x0ff1			; ﾖｸﾊｾｵﾆ
VMODE	EQU		0x0ff2			; ﾏﾔﾊｾﾄ｣ﾊｽ
SCRNX	EQU		0x0ff4			; ｷﾖｱ貭ﾊx
SCRNY	EQU		0x0ff6			; ｷﾖｱ貭ﾊy
VRAM	EQU		0x0ff8			; ﾏﾔｿｨｻｺｴ豬ﾘﾖｷ

		ORG		0xc200			; 

; 画面モードを設定

		MOV		AL,0x13			; VGA 320*200*8bit
		MOV		AH,0x00
		;MOV 	BX,0x4101 		; VGA 640*480*8bit
		;MOV 	AX,0x4F02
		INT		0x10
		MOV		BYTE [VMODE],8	; ｼﾇﾏﾂﾏﾂｻｭﾃ貽｣ﾊｽ
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; キーボードのLED状態をBIOSに教えてもらう

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; 	防止PIC接受所有中断
;	AT兼容机的?范、PIC初始化
;	然后之前在CLI不做任何事就挂起
;	PIC在同意后初始化
;	?部分知?需要在《x86???言》学?

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; 循??行out
		OUT		0xa1,AL

		CLI						; CPU??的中断

; ?个部分内容，在麻省理工686?程有??代?
; ?里的代?使CPU??PS / 2??控制器以?看它是否正忙 

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; プロテクトモード移行

[INSTRSET "i486p"]				; 486の命令まで使いたいという記述

		LGDT	[GDTR0]			; 暫定GDTを設定
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; 使用bit31（禁用分?）
		OR		EAX,0x00000001	; bit0到1??（保?模式?渡）
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			;  一个段号等于8个字?
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpackの転送

		MOV		ESI,bootpack	; 源文件
		MOV		EDI,BOTPAK		; 目?文件
		MOV		ECX,512*1024/4
		CALL	memcpy

; ついでにディスクデータも本来の位置へ転送

; まずはブートセクタから

		MOV		ESI,0x7c00		; 転送元
		MOV		EDI,DSKCAC		; 転送先
		MOV		ECX,512/4
		CALL	memcpy

; 残り全部

		MOV		ESI,DSKCAC0+512	; 転送元
		MOV		EDI,DSKCAC+512	; 転送先
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; シリンダ数からバイト数/4に変換
		SUB		ECX,512/4		; IPLの分だけ差し引く
		CALL	memcpy

; asmheadでしなければいけないことは全部し終わったので、
;	あとはbootpackに任せる

; bootpackの起動

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; 転送するべきものがない
		MOV		ESI,[EBX+20]	; 転送元
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; 転送先
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; スタック初期値
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		 AL,0x64
		AND		 AL,0x02		; ?里???入?冲区的状?以?看它是??是空 - 位1（0x2） .
		JNZ		waitkbdout		; AND的?果不?零，跳?waitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; 
		RET
; memcpy

		ALIGNB	16
GDT0:
		RESB	8				; 
		DW		0xffff,0x0000,0x9200,0x00cf	;32bit register
		DW		0xffff,0x0000,0x9a28,0x0047	; 32bit（bootpack用）

		DW		0
GDTR0:
		DW		8*3-1  
		DD		GDT0

		ALIGNB	16
bootpack:
