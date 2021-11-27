; haribote-os boot asm
; TAB=4

[INSTRSET "i486p"]
VBEMODE	EQU		0x105
;	0x100:640*400*8bit
;	0x101:640*480*8
;	0x103:800*600*8
;	0x105:1024*768*8
;	0x107:1280*1024*8

BOTPAK	EQU		0x00280000		; bootpack 加载地址
DSKCAC	EQU		0x00100000		; 磁盘缓存地址
DSKCAC0	EQU		0x00008000		; 磁盘缓存地址实模式

; BOOT_INFO怣懅
CYLS	EQU		0x0ff0			; 10
LEDS	EQU		0x0ff1			; 指示灯
VMODE	EQU		0x0ff2			; 显示模式
SCRNX	EQU		0x0ff4			; 分辨率x
SCRNY	EQU		0x0ff6			; 分辨率y
VRAM	EQU		0x0ff8			; 显卡缓存地址

		ORG		0xc200			; 

;VBE是否存在
		MOV		AX,0x9000
		MOV		ES,AX
		MOV		DI,0
		MOV		AX,0x4f00
		INT		0x10
		CMP		AX,0x004f
		JNE		scrn320

;检查VBE的版本
		MOV		AX,[ES:DI+4]
		CMP		AX,0x0200
		JB		scrn320			; if (AX < 0x0200) goto scrn320

;取得画面模式信息
		MOV		CX,VBEMODE
		MOV		AX,0x4f01
		INT		0x10
		CMP		AX,0x004f
		JNE		scrn320

;设定画面模式的参数
		CMP		BYTE [ES:DI+0x19],8		;8为颜色数
		JNE		scrn320
		CMP		BYTE [ES:DI+0x1b],4		;4为调色板
		JNE		scrn320
		MOV		AX,[ES:DI+0x00]
		AND		AX,0x0080
		JZ		scrn320
		
;画面模式的切换
		MOV		BX,VBEMODE+0x4000
		MOV		AX,0x4f02
		INT		0x10
		MOV		BYTE [VMODE],8
		MOV		AX,[ES:DI+0x12]
		MOV		[SCRNX],AX
		MOV		AX,[ES:DI+0x14]
		MOV		[SCRNY],AX
		MOV		EAX,[ES:DI+0x28]
		MOV		[VRAM],EAX
		JMP		keystatus

;设置显示参数
;scrn320:
		MOV		AL,0x13
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; 僉乕儃乕僪偺LED忬懺傪BIOS偵嫵偊偰傕傜偆

keystatus:
		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; 	杊巭PIC愙庴強桳拞抐
;	AT寭梕婘揑?錀丄PIC弶巒壔
;	慠岪擵慜嵼CLI晄橍擟壗帠廇漦婲
;	PIC嵼摨堄岪弶巒壔
;	?晹暘抦?廀梫嵼乻x86???尵乼妛?

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; 循环执行out
		OUT		0xa1,AL

		CLI						; CPU再次中断

; ?槩晹暘撪梕丆嵼杻徣棟岺686?掱桳??戙?
; ?棦揑戙?巊CPU??PS / 2??峊惂婍埲?娕泙惀斲惓朲 

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; 僾儘僥僋僩儌乕僪堏峴

		LGDT	[GDTR0]			; 巄掕GDT傪愝掕
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; 巊梡bit31乮嬛梡暘?乯
		OR		EAX,0x00000001	; bit0摓1??乮曐?柾幃?搉乯
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			;  堦槩抜崋摍槹8槩帤?
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack偺揮憲

		MOV		ESI,bootpack	; 尮暥審
		MOV		EDI,BOTPAK		; 栚?暥審
		MOV		ECX,512*1024/4
		CALL	memcpy

; 偮偄偱偵僨傿僗僋僨乕僞傕杮棃偺埵抲傊揮憲

; 傑偢偼僽乕僩僙僋僞偐傜

		MOV		ESI,0x7c00		; 揮憲尦
		MOV		EDI,DSKCAC		; 揮憲愭
		MOV		ECX,512/4
		CALL	memcpy

; 巆傝慡晹

		MOV		ESI,DSKCAC0+512	; 揮憲尦
		MOV		EDI,DSKCAC+512	; 揮憲愭
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; 僔儕儞僟悢偐傜僶僀僩悢/4偵曄姺
		SUB		ECX,512/4		; IPL偺暘偩偗嵎偟堷偔
		CALL	memcpy

; asmhead偱偟側偗傟偽偄偗側偄偙偲偼慡晹偟廔傢偭偨偺偱丄
;	偁偲偼bootpack偵擟偣傞

; bootpack偺婲摦

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; 揮憲偡傞傋偒傕偺偑側偄
		MOV		ESI,[EBX+20]	; 揮憲尦
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; 揮憲愭
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; 僗僞僢僋弶婜抣
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		 AL,0x64
		AND		 AL,0x02		; ?棦???擖?檛嬫揑忬?埲?娕泙惀??惀嬻 - 埵1乮0x2乯 .
		JNZ		waitkbdout		; AND揑?壥晄?楇丆挼?waitkbdout
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
		DW		0xffff,0x0000,0x9a28,0x0047	; 32bit乮bootpack梡乯

		DW		0
GDTR0:
		DW		8*3-1  
		DD		GDT0

		ALIGNB	16
bootpack:
