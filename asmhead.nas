; haribote-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; bootpack ���ص�ַ
DSKCAC	EQU		0x00100000		; ���̻����ַ
DSKCAC0	EQU		0x00008000		; ���̻����ַʵģʽ

; BOOT_INFO�M��
CYLS	EQU		0x0ff0			; 10
LEDS	EQU		0x0ff1			; ָʾ��
VMODE	EQU		0x0ff2			; ��ʾģʽ
SCRNX	EQU		0x0ff4			; �ֱ���x
SCRNY	EQU		0x0ff6			; �ֱ���y
VRAM	EQU		0x0ff8			; �Կ������ַ

		ORG		0xc200			; 

; ��ʃ��[�h��ݒ�

		MOV		AL,0x13			; VGA 320*200*8bit
		MOV		AH,0x00
		;MOV 	BX,0x4101 		; VGA 640*480*8bit
		;MOV 	AX,0x4F02
		INT		0x10
		MOV		BYTE [VMODE],8	; �����»���ģʽ
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; �L�[�{�[�h��LED��Ԃ�BIOS�ɋ����Ă��炤

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; 	�h�~PIC�ڎ󏊗L���f
;	AT���e���I?䗁APIC���n��
;	�R�@�V�O��CLI�s���C�����A�k�N
;	PIC�ݓ��Ӎ@���n��
;	?�����m?���v�݁sx86???���t�w?

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; �z??�sout
		OUT		0xa1,AL

		CLI						; CPU??�I���f

; ?���������e�C�ݖ��ȗ��H686?���L??��?
; ?���I��?�gCPU??PS / 2??�T�����?�ś����ې��Z 

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; �v���e�N�g���[�h�ڍs

[INSTRSET "i486p"]				; 486�̖��߂܂Ŏg�������Ƃ����L�q

		LGDT	[GDTR0]			; �b��GDT��ݒ�
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; �g�pbit31�i�֗p��?�j
		OR		EAX,0x00000001	; bit0��1??�i��?�͎�?�n�j
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			;  �꘢�i������8����?
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack�̓]��

		MOV		ESI,bootpack	; ������
		MOV		EDI,BOTPAK		; ��?����
		MOV		ECX,512*1024/4
		CALL	memcpy

; ���łɃf�B�X�N�f�[�^���{���̈ʒu�֓]��

; �܂��̓u�[�g�Z�N�^����

		MOV		ESI,0x7c00		; �]����
		MOV		EDI,DSKCAC		; �]����
		MOV		ECX,512/4
		CALL	memcpy

; �c��S��

		MOV		ESI,DSKCAC0+512	; �]����
		MOV		EDI,DSKCAC+512	; �]����
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; �V�����_������o�C�g��/4�ɕϊ�
		SUB		ECX,512/4		; IPL�̕�������������
		CALL	memcpy

; asmhead�ł��Ȃ���΂����Ȃ����Ƃ͑S�����I������̂ŁA
;	���Ƃ�bootpack�ɔC����

; bootpack�̋N��

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; �]������ׂ����̂��Ȃ�
		MOV		ESI,[EBX+20]	; �]����
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; �]����
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; �X�^�b�N�����l
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		 AL,0x64
		AND		 AL,0x02		; ?��???��?�t��I��?��?�ś���??���� - ��1�i0x2�j .
		JNZ		waitkbdout		; AND�I?�ʕs?��C��?waitkbdout
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
		DW		0xffff,0x0000,0x9a28,0x0047	; 32bit�ibootpack�p�j

		DW		0
GDTR0:
		DW		8*3-1  
		DD		GDT0

		ALIGNB	16
bootpack:
