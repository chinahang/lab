

#include "bootpack.h"

#define FLAGS_OVERRUN		0x0001

void fifo32_init(struct FIFO32 *fifo,int  size,int *buf,struct TASK *task)
/*初始化FIFO缓冲区*/
{
	fifo->size = size;
	fifo->buf = buf;
	fifo->free = size;/*剩余空间*/
	fifo->flags = 0;
	fifo->p = 0;/*写入位置*/
	fifo->q = 0;/*读取位置*/
	fifo->task = task;
	return;
}

int fifo32_put(struct FIFO32 *fifo, int data)
/*向FIFO传递数据并保存*/
{
    if (fifo->free == 0)  
       /*空余空间没有了，溢出*/
	 {
       fifo->flags |= FLAGS_OVERRUN;
       return -1;
     }
     fifo->buf[fifo->p] = data;
	 fifo->p++;
	 if (fifo->p == fifo->size) {
		 fifo->p = 0;
	 }
	 fifo->free--;
	 if (fifo->task != 0) {/*如果存在的情况下*/
		 if (fifo->task->flags != 2) {
			 task_run(fifo->task);/*将任务开始*/
		 }
	 }
	 return 0;
}

int fifo32_get(struct FIFO32 *fifo)
/*从FIFO取得一个数据*/
{
	int data;
	if (fifo->free == fifo->size) {
		/*如果缓冲区为空，则返回-1*/
		return -1;
	}
	data = fifo->buf[fifo->q];
	fifo->q++;
	if (fifo->q == fifo->size) {
		fifo->q = 0;
	}
	fifo->free++;
	return data;
}

int fifo32_status(struct FIFO32 *fifo)
/*报告一下到底积攒了多少数据*/
{
	return fifo->size - fifo->free;
}