/*
 * clangd_compat.h
 * 
 * SDCC 编译器关键字兼容层，用于 clangd 语言服务器
 * 将 SDCC 特定的关键字定义为空宏，避免 clangd 报错
 */
#ifndef __CLANGD_COMPAT_H__
#define __CLANGD_COMPAT_H__

#ifdef __CLANGD_SDCC__

#define __data
#define __idata
#define __xdata
#define __pdata
#define __code
#define __near
#define __far
#define __interrupt(...)
#define __using(...)
#define __critical
#define __reentrant
#define __naked
#define __at(...)
#define __bit unsigned char
#define __sfr volatile unsigned char
#define __sbit volatile unsigned char

#endif

#endif
