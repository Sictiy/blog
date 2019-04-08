---
title: go学习笔记
date: 2019-04-08 18:09:58
tags: 
categories: 
---

## 环境

---

- windows + goland
  - 官网下载go、goland
  - 安装后在goland中 settings->go->goroot gopath 设置环境变量
- 导入第三方包
  - go get -u github.com/golang/protobuf/protoc-gen-go (protobuf)
  - go get -u github.com/google/flatbuffers/go (flatbuffer)

## 基本语法

---

- 基本结构
  - package 当前包
  - import 导入包 (不允许循环导包，如a import b、b import a，设计包时需确定每个包的作用，包与包之间低耦合)
- 基本语法
  - 函数与方法：

    ``` go
        func (this* StructName) functionName(paramLists ...) returnList ... {
      }
      \\ 关键字 (接受者) 函数名 (参数列表) 返回值列表 { 函数体}

    ```

  - 变量与初始化：

    ``` go
        var varName uint32
        varName := 21

    ```

  - 常量：const
  - 数据结构初始化： make()
  - 可见性： 首字母大写pulic， 小写private
  - 指针与实例：与c++相似，但都通过点访问成员

## 数据结构

---

- 数组：定长
- 切片：不定长，需要
- map
- range：主要用在for循环中
- 结构体指针与数组指针转换：

``` go
    pBytes := (*[size]byte)(unsafe.Pointer(&myStruct))
```

## 接口与类

---

- 类与实例
  - 类用struct实现
  - 没有继承，只有组合，类似于继承：

  ``` go
  type extendStruct struct{
      baseStruct
  }

  ```

  - 类方法需要修改类成员时，方法接收者需要是指针

- 接口
  - interface , 通过实现接口中的方法实现接口，不显式通过关键字声明实现

- 类与接口指针
  - 结构的方法集只包含接收者为结构类型的方法，结构体指针的方法集同时包含接受者为结构体类型与结构体指针类型的方法
  - 结构体的方法，只能通过结构体指针访问，但是如果结构是可被寻址的，那通过结构体访问方式将转化为通过结构体指针访问
  - 接口的内部实现为type加value，type为value的类型，value为结构体指针。所以通过接口访问方法实际就是通过结构体指针访问
  - 接口判等：需要type与value都相等，value通过指针对于的地址的值判断
  - 接口内的指针可以直接与对于的结构体指针判等

## 协程与chan

---

- 基本用法
  - go func 新建一个协程运行函数func，运行完func后协程结束
  - var myChan chan type 一个可传输type的管道
  - <- myChan 从myChan中读取一个值，如果myChan未写入过值则阻塞
  - myChan <- 写入一个值到myChan，如果myChan空间不足（上个写入的值未被读取）则阻塞
  - chan<- chan<- int <-符号优先和左边的结合
  - chan type 需要make后使用，可通过make(chan type, size) 指定容量

- select语句：从所有case语句中的chan中读取一个值，都不能读取则阻塞
  - 可以使用time.after()设置超时，该函数返回一个 <-chan Time 类型的变量，一定时间后该管道可读
  - ticker 定时触发器，以一定间隔往chan中写入值

- range遍历chan：不断从chan中读，直到chan关闭

## 错误与异常

---

- 错误与异常
  - 错误是程序的一部分，异常不是
  - 有错误时程序正常运行，相当于操作的错误码，逐层返回直到被处理即可
  - 异常标志着程序运行在非正常状态，需要特殊处理

- 错误处理
  - 将错误放在返回值的最后返回，由调用方判断是否有出错

- 异常处理
  - defer 类似于trycatch中的final，会在函数执行完之后马上调用，可以再defer函数中写资源释放代码，存在多个defer时，按程序执行顺序的反顺序执行
  - panic 程序运行到panic说明程序异常，当前函数马上停止执行，如果有defer函数，则执行defer
  - recover 恢复函数，go中用于处理panic的函数，recover的返回值未panic的传入值，如果panic不被处理将网上转递，如果一直不被处理，程序将停止运行

## 包管理

---

- 待更新...