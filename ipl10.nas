;启动程序
;TAB=4
CYLS	EQU	10
		ORG		0x7c00
	
;格式为FAT12软盘,查找这方面的资料--硬盘格式如何编码
;80字节
		JMP		entry
		DB		0X90
		DB		"HELLOIPL"		;启动扇区八个字节
		DW		512				;每个扇区大小为512
		DB		1				; 簇（cluster）大小（必须为1个扇区）
		DW		1				; FAT起始位置（一般为第一个扇区）
		DB		2				; FAT个数（必须为2）
		DW		224				; 根目录大小（一般为224项）
		DW		2880			; 该磁盘大小（必须为2880扇区80柱面*18扇区*2磁头）
		DB		0xf0			; 磁盘类型（必须为0xf0）
		DW		9				; FAT的长度（必9扇区）
		DW		18				; 一个磁道（track）有几个扇区（必须为18）
		DW		2				; 磁头数（必是2）
		DD		0				; 不使用分区，必须是0
		DD		2880			; 重写一次磁盘大小
		DB		0,0,0x29		; 意义不明（固定）
		DD		0xffffffff		; （可能是）卷标号码
		DB		"HELLO-OS   "	; 磁盘的名称（必须为11字节，不足填空格）
		DB		"FAT12   "		; 磁盘格式名称（必8字节，不足填空格）
		RESB	18		
		
;程序主体



entry:;
		mov 	ax,0
		mov 	ss,ax
		mov 	sp,0x7c00
		mov		ds,ax
		mov		es,ax
		
;读取磁盘内容，写入内存起始地址0x8200
		mov 	ax,0x0820
		mov 	es,ax
		mov		ch,0		;柱0
		mov 	dh,0		;磁头0
		mov 	cl,2		;扇区2
readloop:
		mov 	si,0		;记录失败次数，超过5次退出
		
retry:
		mov 	ah,0x02		;读取指令
		mov 	al,1		;扇区号
		mov 	bx,0		
		mov		dl,0x00		;A驱动器，0x80硬盘
		int 	0x13		;调用bios磁盘中断
		jnc		next		;没问题跳转到next，进位标志为0
		add 	si,1		
		cmp		si,5		
		jae		error		;大于等于5
		mov		ah,0x00		;重置软盘
		mov 	dl,0x00
		int 	0x13
		jmp		retry
		
next:
		mov 	ax,es		;一个扇区512字节，等于0x200
		add 	ax,0x0020
		mov  	es,ax
		add 	cl,1		;下一个扇区
		cmp		cl,18		;一共有18个扇区
		jbe		readloop
		mov 	cl,1
		add 	dh,1		;下一个磁头
		cmp		dh,2
		jb 		readloop
		mov 	dh,0
		add 	ch,1		;下一个柱面
		cmp 	ch,CYLS
		jb		readloop
		
;读取完毕，跳转到 haribote.img执行
		MOV 	[0X0FF0],ch
		jmp 	0xc200
		
		
error:		
		mov 	si,msg
		
putloop:
		mov 	al,[si]		;将字符打印在启动时候的屏幕上
		add		si,1
		cmp 	al,0
		je		fin
		mov 	ah,0x0e		;参考BIOS中断例程
		mov 	bx,15
		int		0x10		;调用bios屏幕中断
		jmp		putloop
fin:
		hlt		
		jmp		fin
		
msg:
		db		0x0a,0x0a
		db 		"load error"
		db 		0x0a
		db  	0
		resb	0x7dfe-$ 	;填写0x001fe(=7dfe-7c00) 个0x00
 		
		db 		0x55,0xaa	;结束格式