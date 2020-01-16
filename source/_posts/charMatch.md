---
title: 字符串匹配
date: 2020-01-15 12:46:18
tags: 
categories: algorithm
---

## 问题描述

文本input为一个一定长度的字符串，文本pattern为一个长度小于input的字符串。字符串里面的所有字符都是26个小写字母，求pattern在input中第一次出现的问题，如果没有出现过返回-1。

## 解法

### 暴力法

最容易想到的就是直接从左往右遍历所有字符，没什么好说的，实现代码如下：

```go
// BF算法
func matchBF(bInput []byte, bPattern []byte) int {
    lenP := len(bPattern)
    lenI := len(bInput)
    for i:= 0; i <= lenI - lenP; i++ {
        match := true
        for j := 0; j < lenP; j++ {
            if bInput[i + j] != bPattern[j] {
                match = false
                break
            }
        }
        if match {
            return i
        }
    }
    return -1
}
```

### KR算法

暴击法虽然简单，但主串遍历一遍n次，每一次需要遍历一遍匹配串判断当前位置是否匹配，最差需要n*m次计算才能遍历完，计算量太大。KR算法在暴力法的基础上，对每一个位置上的遍历判断改为计算匹配串与相应子串的hash值，如果hash值相等，再从左到右遍历。假设hash值的计算为 a=1，b=2，c=3 对字符串的值求和得到hash，那么计算如图：

![kmp-kr](https://s2.ax1x.com/2020/01/15/lXA76K.png)

显然该位置主串的子串与匹配串不相同，但hash相同不一定绝对匹配，比如abc与acb 计算的hash相等，但字符串不匹配，所以hash相等时还需要逐字符判断一遍。另外，hash算法的冲突率对整个算法的影响很大，冲突率越高，hash相等时字符串不匹配的几率越高，计算量越大，一个简单的hash算法如下：

```go
func calHashCode(input []byte) int {
    result := 0
    for _, i := range input {
        result += int(i)
        result *= defaultPower
    }
    return result
}
```

这样就ok了吗？并不，因为一般hash的计算同样需要遍历一遍字符串，虽然匹配串是固定的不需要重新计算，但是每个位置对于的子串都不同，如果每个位置都要遍历一遍子串来计算hash，那计算量和暴力法也没什么差别甚至更高。所以在这里需要利用部分字符重叠这个特性，在上图中，第0个位置子串为abc 第1个位置子串为bcd 其中bc是重叠的，计算hash的时候只需要把a去掉，加上d就可以了。具体的做法如以下代码：

```go
var defaultPower = 26

func matchKR(bInput []byte, bPattern []byte) int {
    lenP := len(bPattern)
    lenI := len(bInput)
    hashCodeP := calHashCode(bPattern)
    hashCodeI := calHashCode(bInput[0:lenP])
    // 计算hashcode时每次减去的基数
    subPower := calPower(defaultPower, lenP + 1)
    for i:= 0; i <= lenI - lenP; i++ {
        if hashCodeI == hashCodeP {
            // 粗略匹配
            match := true
            for j := 0; j < lenP ; j++ {
                if bInput[i + j] != bPattern[j] {
                    match = false
                    break
                }
            }
            // 真的匹配
            if match {
                return i
            }
        }
        if i + lenP >= lenI {
            return -1
        }
        // 不匹配时 更新子串的hashCode
        hashCodeI += int(bInput[i +lenP])
        hashCodeI *= defaultPower
        hashCodeI -= subPower * int(bInput[i])
    }
    return -1
}

func calPower(a int, b int) int {
    result := 1
    for i := 0; i< b; i++ {
        result *= a
    }
    return result
}
```

### BM(Boyer-Moore)算法

上述两个算法每次匹配串都只往右移动一个位置，这样显然太慢了些，很多时候是可以一次移动多个位置的。

BM算法就是这样一个算法，其思想是如果子串中有模式串中不存在的字符，那肯定不匹配，可以往后多移动几步。为了更快发现不存在的字符，并且尽量往后多移动几步，BM算法选择从后往前逐字判断。

![kmp-bm1](https://s2.ax1x.com/2020/01/15/lXZ1Y9.png)

如图，先判断c与c相等，再往前，b和c不相等。因为匹配串中不含b，所以匹配串可以直接往后移动两步使匹配串跳过b。

#### 算法细则

##### 坏字符规则

坏字符只是指子串中从后往前遇到的第一个不匹配的字符，在上述的例子中，b就是这个坏字符。坏字符规则是指，当子串中存在坏字符时，匹配串向右移动使坏字符与匹配串中的相同字符对应，如果不存在则使匹配串移动到坏字符后一个位置。如图：

![cm-badChar](https://s2.ax1x.com/2020/01/15/lX3S9U.png)
![cm-badChar2](https://s2.ax1x.com/2020/01/15/lX1R0I.png)

因为匹配串是固定的，每一个字符在匹配串的最后一个位置也是固定的，所以可以提前预处理匹配串，找出匹配串中每一个字符在串中的最后一个位置，组成map，当寻找坏字符在匹配串的位置时只需要去map中寻找，不再需要重复遍历匹配串。代码如下：

```go
//坏字符预处理
//O(n)
func generalBadCharMap(bPattern []byte, bInput []byte) map[byte]int {
    lenP := len(bPattern)
    bCharArray := make(map[byte]int)
    // 这里将主串中所有出现过的字符对应的value提前置为-1，代表坏字符移动到-1的位置
    for _, i := range bInput {
        bCharArray[i] = -1
    }
    // key字符 在pattern里的最后一个位置
    for i := 0; i < lenP; i++{
        bCharArray[bPattern[i]] = i
    }
    return bCharArray
}
```

##### 好后缀规则

好后缀是指坏字符后面已经能够匹配的字符后缀，如上图中的好后缀为 da 和 a。好后缀规则是指，当子串存在好后缀时，匹配串向右移动使长度最长的好后缀与匹配串中的相同子串对应，如果不存在相同的子串，则在其他好后缀中寻找与匹配串中相同前缀匹配的最长者相对应，如果依然不存在，将好后缀移动到匹配串的最前面。所以好后缀规则存在三种情况：

- 最长好后缀在匹配串中存在相同子串

![cm-goodSuffix](https://s2.ax1x.com/2020/01/15/lX8ai6.png)

- 最长好后缀不存在相同子串，但是好后缀中存在与匹配串中相同的前缀

![cm-goodSuffix2](https://s2.ax1x.com/2020/01/15/lX8boq.png)

- 都不存在

![cm-goodSuffix3](https://s2.ax1x.com/2020/01/15/lXGJ1S.png)

好后缀同样可以提前预处理，一个比较暴力的处理方法为：

```go
//好后缀预处理
//返回 map key深度好后缀最后个子串的位置value
//暴力法
func generalGoodSuffix(bPattern []byte) map[int]int {
    lenP := len(bPattern)
    // suffix中保存 key深度的好后缀在匹配串中最后一个相同子串的位置，如果不存在 value为-1
    suffix := make(map[int]int)
    // prefix中保存 key深度的好后缀是否存在相同的前缀，如果存在value为1 否则为-1
    prefix := make(map[int]int)
    // 初始化所有深度 value值
    for i := 1; i < lenP ; i++ {
        suffix[i] = -1
        prefix[i] = -1
    }
    // i 从0往右遍历的深度
    // 找到所有深度为i的好后缀再最后一次出现的位置
    for i := 0; i < lenP - 1; i++ {
        j := i // 深度为i的串最右边开始往左判断
        for j >= 0 && bPattern[j] == bPattern[lenP - 1 - i + j] {
            j--
            suffix[i - j] = j + 1 // 最后一个深度为i - j 的串的位置
        }
        if j == 0 {
            prefix[i] = 1
        }
    }
    // 处理前缀 当深度为i的好后缀 在模式串前没有出现过第二次时 找到这个好后缀的最长前缀子串
    for i := 1; i < lenP; i++ {
        // 当前深度没有匹配的串
        if suffix[i] == -1 {
            for j := i - 1; j > 0; j-- {
                // 找到最长前缀子串
                if prefix[j] == 1 {
                    // 将最长子串移动到最前面 相当于 当前深度串移动到最前面往前i - j个位置 当i=j时理论应该直接移动到0位置
                    suffix[i] = j - i
                    break
                }
            }
        }
    }
    return suffix
}
```

##### 主规则

得到处理后的好后缀与坏字符map后，对于每一个不匹配的位置，都可以通过好后缀规则与坏字符规则计算一个移动步数，取两者较大者对匹配串进行移动，具体实现如下：

```go
// BM算法
func matchBM(bInput []byte, bPattern []byte) int {
    i := 0 // 输入串与匹配串偏移量
    var j int // 输入串与匹配串匹配的第一个字符
    goodSuffix := generalGoodSuffix(bPattern)
    badChar := generalBadCharMap(bPattern, bInput)
    lenI := len(bInput)
    lenP := len(bPattern)
    for i <= lenI -lenP {
        for j = lenP - 1; j >= 0; j-- {
            // 第一个坏字符
            if bInput[i + j] != bPattern[j] {
                break
            }
        }
        // 成功
        if j < 0 {
            return i
        }
        badMove := j - badChar[bInput[i + j]]
        goodMove := 0
        // 不是最后一个字符 有好后缀
        if j < lenP -1 {
            goodMove = j + 1 - goodSuffix[lenP - j]
        }
        if badMove > goodMove{
            i += badMove
        } else {
            i += goodMove
        }
    }
    return -1
}
```

### KMP算法

#### next数组

KMP算法同样尽量使匹配串更快地往右移动，不过利用的是匹配串中的另一个信息。这个信息为：对于每匹配串 t 的每个元素 t j，都存在一个实数 k ，使得匹配串 t 开头的 k 个字符（t 0 t 1…t k-1）依次与 t j 前面的 k（t j-k t j-k+1…t j-1，这里第一个字符 t j-k 最多从 t 1 开始，所以 k < j）个字符相同。如果这样的 k 有多个，则取最大的一个。匹配串中每一个位置j都有这样一个k，通过next数组表示，即 next[j] = max{k}
这个信息是什么意思呢？可以通过下图来理解：

![cm-kmp](https://s2.ax1x.com/2020/01/15/lXtDht.png)

对于j = 5 存在这样一个k = 2, 使 p[j]前面的k个字符，与匹配串开头的k个字符相同，则next[5] = 2。

因为这个信息是每个匹配串都存在的信息，我们可以拿匹配串进行预处理，得到长度与匹配串长度相同的next数组，代码如下：

```go
// 预处理next
func generalNextMap(bPattern []byte) map[int]int {
    next := make(map[int]int)
    j, k := 0, -1
    next[j] = k
    lenP := len(bPattern)
    for j < lenP - 1 {
        // k == -1 时 第一个字符都不匹配，往后移
        // bk == bj 时 匹配 继续往后寻找
        if k == -1 || bPattern[k] == bPattern[j] {
            k++
            j++
            // 优化后的代码，原算法不判断==，直接赋值k
            if bPattern[k] == bPattern[j] {
                next[j] = next[k]
            } else {
                next[j] = k
            }
        } else {
            // bk != bj 时 因为k前面的n个字符 与j前面的n个字符匹配 那么将k 替换为next[k]以后 则j前面next[k]个字符同样与next[k]前面next[k]个字符匹配 达到等价回退的目的
            k = next[k]
        }
    }
    return next
}
```

预处理next的遍历过程分三种情况：

1. k == -1，p[j] 前面0个字符与前缀相同，这时将k与j都加一，继续往后一位判断。

2. p[j] == p[k] 此时，开头k个字符与p[j] 相同，那么开头k+1个字符与p[j+1]前面的k+1个字符相同。

3. p[j] != p[k] 两个字符不相同时，原算法直接令 k = next[k], 这个该怎么理解呢？当两个字符不匹配时，显然是k太大了，需要缩短开头的k个字符的长度，使p[j]的前k\`个字符与开头的k\`个字符相同，因为p[j]的前k个字符与开头的k个字符相同，所以p[j]前面的k个字符 与 p[k] 前面的k个字符相同，而p[k]前面的k\`个字符与开头k\`个字符相同等价于p[j]前面的k\`个字符与开头的k\`个字符相同。前面已经求得next[k] = k\`,所以令 k = k\` = next[k]

![cm-kmpNext](https://s2.ax1x.com/2020/01/15/lXUQRx.png)

#### 主逻辑

两个指针IJ分别代表在主串与匹配串中的位置，IJ从左往右遍历，当IJ所指的字符相等时一起往后移动。当两个字符不相等时，如下图I = 3， J = 3，此时p[j]前面的k = 1个字符与匹配串开头的k 个字符相同，所以I不动，将J移动到K的位置，使两个a对应。

![cm-kmpMove](https://s2.ax1x.com/2020/01/15/lXdzZD.png)

具体代码如下:

```go
// KMP 算法
func matchKMP(bInput []byte, bPattern []byte) int {
    next := generalNextMap(bPattern)
    i, j := 0, 0
    lenI := len(bInput)
    lenP := len(bPattern)
    for i < lenI && j < lenP {
        if j == -1 || bInput[i] == bPattern[j] {
            i++
            j++
        } else {
            j = next[j]
        }
    }
    // 遍历完成 如果j先遍历完则存在匹配
    if j >= lenP {
        return i - lenP
    }
    return -1
}
```

### Sunday算法

Sunday算法与BM算法的坏字符规则相似，BM算法移动到坏字符与匹配串中相同的字符相对应，而Sunday算法找到的不是坏字符，而是子串最后一个字符的下一个字符，该字符的移动规则与BM算法坏字符的移动规则一致， 如下图。

![cm-sunday](https://s2.ax1x.com/2020/01/15/lX0oC9.png)

具体代码如下：

```go
// Sunday算法
func matchSunday(bInput []byte, bPattern []byte) int {
    offset := getOffsetMap(bPattern)
    lenI := len(bInput)
    lenP := len(bPattern)
    i, j := 0, 0
    for i <= lenI - lenP {
        j = 0
        for bInput[i + j] == bPattern[j] {
            j++
            if j >= lenP {
                return i
            }
        }
        if i + lenP >= lenI {
            return -1
        }
        move, ok := offset[bInput[i + lenP]]
        if ok {
            i += move
        } else {
            i += lenP + 1
        }
    }
    return -1
}

// offestmap 存字符到匹配串最后面一个字符的距离
func getOffsetMap(bPattern []byte) map[byte]int {
    offset := make(map[byte]int)
    lenP := len(bPattern)
    for i, c := range bPattern{
        offset[c] = lenP - i
    }
    return offset
}
```
