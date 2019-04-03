---
title: NOMINMAX问题
date: 2019-03-19 18:00:00
tags: 
categories: "c++"
---
# 问题

---
更新代码后发现flatbuffer编译不过，flatbuff.h等出现大量报错。

## 解决过程

---

### 配置NOMINMAX

- 咨询组内服务器大佬，需要在vs修改宏定义，增加NOMINMAX定义，原因是std的minmax定义与windows的有冲突。修改位置为：

> project property pages
  >> configuration properties
    >>> c/c++
      >>>> preprocessor
        >>>>> preprocessor definitions

尝试重新编译：flatbuffer部分成功编译，但出现了第二个问题，gdiplustypes.h出现编译出错，提示min，max未定义。

### 夏继尔尝试

- 在stdafx.h最后面定义宏min与max：

```cpp
#ifndef min
#define min(a,b) (((a) < (b)) ? (a) : (b))
#endif

#ifndef max
#define max(a,b) (((a) > (b)) ? (a) : (b))
#endif
```

 尝试重新编译：并没有卵用，gdi报错还是在。

- 在stdafx.h中取消定义宏，去掉原来配置的NOMINMAX宏：

```cpp
#ifdef min
#undef min
#endif

#ifdef max
#undef max
#endif
```

结果还是一样，flatbuffer报错。

### 整理思路

经过上面的尝试及百度google一番搜索先整理一下思路：

- flatbuffer需要std的宏，所以需要定义NOMINMAX宏取消windows的宏
- gdiplus需要windows的宏，不能取消windows的宏
- stdafx.h会预编译mfc标准头文件，所以gdiplus在编译stdafx.h期间编译，这段时间需要windows的宏
- flatbuffer在预编译之后编译，不需要windows的宏
- 只需要保持windows的宏定义仅仅在编译stdafx.h期间存在就可以解决问题

### 继续尝试

- 配置NOMINMAX
- 在stdafx.h中将定义minmax的宏放到最前面，确保gdi编译时存在minmax的宏
编译：部分flatbuffer报错，gdi没有报错，说明stdafx.h中定义的宏影响达到了flatbuffer的编译
- 在stdafx.h最后面取消定义宏，确保不影响gdi的前提下使flatbuffer编译时不存在minmax宏。
再编译：ok。

### 最后尝试

去掉NOMINMAX的宏，stdafx.h保持上面的修改
编译：flatbuffers依然报错。

### 学习