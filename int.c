#include "bootpack.h"
#include <stdio.h>

void init_pic(void)
/* PIC偺弶婜壔 */
{
	io_out8(PIC0_IMR,  0xff  ); /* 慡偰偺妱傝崬傒傪庴偗晅偗側偄 */
	io_out8(PIC1_IMR,  0xff  ); /* 慡偰偺妱傝崬傒傪庴偗晅偗側偄 */

	io_out8(PIC0_ICW1, 0x11  ); /* 僄僢僕僩儕僈儌乕僪 */
	io_out8(PIC0_ICW2, 0x20  ); /* IRQ0-7偼丄INT20-27偱庴偗傞 */
	io_out8(PIC0_ICW3, 1 << 2); /* PIC1偼IRQ2偵偰愙懕 */
	io_out8(PIC0_ICW4, 0x01  ); /* 僲儞僶僢僼傽儌乕僪 */

	io_out8(PIC1_ICW1, 0x11  ); /* 僄僢僕僩儕僈儌乕僪 */
	io_out8(PIC1_ICW2, 0x28  ); /* IRQ8-15偼丄INT28-2f偱庴偗傞 */
	io_out8(PIC1_ICW3, 2     ); /* PIC1偼IRQ2偵偰愙懕 */
	io_out8(PIC1_ICW4, 0x01  ); /* 僲儞僶僢僼傽儌乕僪 */

	io_out8(PIC0_IMR,  0xfb  ); /* 11111011 PIC1埲奜偼慡偰嬛巭 */
	io_out8(PIC1_IMR,  0xff  ); /* 11111111 慡偰偺妱傝崬傒傪庴偗晅偗側偄 */

	return;
}

void inthandler27(int *esp)
/* PIC0偐傜偺晄姰慡妱傝崬傒懳嶔 */
/* Athlon64X2婡側偳偱偼僠僢僾僙僢僩偺搒崌偵傛傝PIC偺弶婜壔帪偵偙偺妱傝崬傒偑1搙偩偗偍偙傞 */
/* 偙偺妱傝崬傒張棟娭悢偼丄偦偺妱傝崬傒偵懳偟偰壗傕偟側偄偱傗傝夁偛偡 */
/* 側偤壗傕偟側偔偰偄偄偺丠
	仺  偙偺妱傝崬傒偼PIC弶婜壔帪偺揹婥揑側僲僀僘偵傛偭偰敪惗偟偨傕偺側偺偱丄
		傑偠傔偵壗偐張棟偟偰傗傞昁梫偑側偄丅									*/
{
	io_out8(PIC0_OCW2, 0x67); /* 通知PIC的IRQ-07（参考7-1） */
	return;
}
