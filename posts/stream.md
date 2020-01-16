---
title:  Java Stream 理解
date: 2020-01-15 08:34:59
tags: 
categories: 
---

## 概述

### 什么叫流

Java 8 中的 Stream 是对集合（Collection）对象功能的增强，它专注于对集合对象进行各种非常便利、高效的聚合操作，或者大批量数据操作 。Stream API 借助于同样新出现的 Lambda 表达式，极大的提高编程效率和程序可读性.

![stream-pipeline](https://s2.ax1x.com/2020/01/15/lLT3Ed.png)

与直接对集合类进行连续的一系列操作不同，使用流并非对集合类的所有元素进行一个操作之后得到中间集合再进行下一步的操作，而是针对流中的每一个元素按流的方向依次执行所有操作，不存在中间集合，所有的这些流式操作都在终端操作(如图中的ForEach)执行时才开始执行。

### 流的特点

- 流管道由数据源、中间操作、终端操作组成。终端操作可以没有也可以有多个，数据源和终端操作只有一个。
- 流不存储数据、流可能是无界的、流是可以被消耗的。流通过数据源不断生成单个元素，当整个流执行完终端操作之后流被标记成已消耗，无法再次执行终段操作。
- 流的操作基本都是函数式接口的实例，中间操作的函数式操作是延迟执行的。
- 流分为顺序执行和并行执行两种方式。并行执行依赖数据源Spliterator体验的并行遍历机制。

## 预备

### Spliterator

Spliterator为Iterator的并行版本，提供对集合数据的并行遍历能力。

![stream-spliterator](https://s2.ax1x.com/2020/01/15/lLqMRI.png)

这里主要依赖三个方法: tryAdvance, forEachRemaining, trySplit。

- tryAdvance 生成一个元素并对该元素执行传入的Consumer操作，返回的boolean值代表是否还可以继续生成下一个元素
- forEachRemaining 顾名思义该方法为对所有剩余生成的元素执行传入到的Consumer操作，该方法的默认实现为循环调用tryAdvance方法，直到其返回值为false。
- trySplit 该方法用于实现并行遍历。调用该方法后该Spliterator会拆分另一个Spliterator并返回，两个Spliterator可在两个线程中进行并行遍历。

### Functor

Functor函子本是范畴论中的一个概念，指范畴间的一类映射。在函数式编程里，主要指对普通对象的封装，相对普通函数对简单对象进行操作映射，函子函数对高阶对象进行操作映射。

可以通过一段示例代码进行理解：

```java
/**
 * 函子
 *
 * @author sictiy.xu
 * @version 2020/01/06 10:03
 **/
public interface Functor<T, F extends Functor<?, ?>>
{
    <R> F map(Function<T, R> f);
}

/**
 * 通用函子
 *
 * @author sictiy.xu
 * @version 2020/01/06 10:05
 **/
public class CommonFunctor<T> implements Functor<T, CommonFunctor<?>>
{
    private T value;

    public CommonFunctor(T value)
    {
        this.value = value;
    }

    @Override
    public <R> CommonFunctor<R> map(Function<T, R> f)
    {
        final R result = f.apply(value);
        return new CommonFunctor<>(result);
    }

    public T getValue()
    {
        return value;
    }

    public static void main(String[] args)
    {
        var functor = new CommonFunctor<>(10);
        LogUtil.info("{}", functor.map(a -> a + 1).map(a -> a * 10).getValue());
    }
}
```

函子接口Functor定义函子函数map，所有的函子都需要实现该接口。在实现类中，函子对象封装了普通对象T，而函子函数接收一个Function操作，该Function操作对普通对象T进行处理，结果为普通对象R。函子函数解析函子中封装的普通对象执行Function操作后将结果封装成新的函子对象。由于函子对象的map方法返回的是一个新的函子对象，所以可以连续的调用链式调用map方法直到调用getValue方法解析最后一个函子对象所封装的普通对象。该Functor虽然形式上与Stream一样，可以链式调用对象的方法，但是每一步调用依然是即时操作的，那如果对传入的操作并不马上操作，而是将传入的函数式接口通过对象属性或者保存在抽象方法的实现中，然后在最后需要获得结果的时候再统一处理所有的操作，是不是就是Stream实现的基本思想呢？

### Stream基本用法

![stream-op](https://s2.ax1x.com/2020/01/15/lO6LO1.png)

Stream中的操作可以分为两大类：中间操作与结束操作，中间操作只是对操作进行了记录，只有结束操作才会触发实际的计算（即惰性求值），这也是Stream在迭代大集合时高效的原因之一。中间操作又可以分为无状态（Stateless）操作与有状态（Stateful）操作，前者是指元素的处理不受之前元素的影响；后者是指该操作只有拿到所有元素之后才能继续下去。结束操作又可以分为短路与非短路操作，这个应该很好理解，前者是指遇到某些符合条件的元素就可以得到最终结果；而后者是指必须处理所有元素才能得到最终结果。

## 流程原理

### 一个小栗子

```java
private static void testStream()
{
    String[] words = {"hello", "my", "world"};
    var strStream = Arrays.stream(words);
    var tempStream = strStream.filter(word -> word.length() > 3)
            .map(word -> word.split(""))
            .flatMap(Arrays::stream)
            .map(String::toUpperCase);
    var result = tempStream.reduce((a, b) -> a + "," + b);
    LogUtil.info(result.orElse("null"));
}
```

结果为：

```txt
[2020-01-15 10:49:56:721] [INFO ] com.sictiy.jserver.Test.testStream(Test.java:44) H,E,L,L,O,W,O,R,L,D
```

先看一下通过Arrays.stream方法创建的Stream是什么样的：

![strStram](https://s2.ax1x.com/2020/01/15/lLxrO1.png)

首先返回的strSteam是个***PipeLine$Head的实例，显然这是一个Stream的实现类，该类有一个属性sourceStage指向自己，有一个属性sourceSpliterator是根据传入的数组生成的一个ArraySpliterator实例。

按Functor的思想，函子函数接收一个函数式接口应该返回另一个函子对象，那stream是怎么样的呢？再看一下filter函数里面是怎么实现的：

![filter](https://s2.ax1x.com/2020/01/15/lOS9vd.png)

filter方法返回了一个叫做StatelessOp的Stream接口的实现，但在方法体内除了对传入的predicate进行空指针判断以外并没有进行其他的处理。返回的StatelessOp类重写了opWarpSink方法，而onWarpSink方法返回一个Sink接口，该Sink接口实现了accept方法，接收一个对象，如果满足predicate，则执行downstream的accept方法，这个sink可以理解为前一个操作调用该sink的accept接口，如果入参满足predicate，那继续调用下一个操作。我们已经知道了传入的predicate存放到的位置，但依然不知道这个sink什么时候使用，怎么使用。

知道了增加一个中间操作做了什么以后，再看一下调用了一堆中间操作后返回到的tempStream是什么样的：

![tempStream](https://s2.ax1x.com/2020/01/15/lO9lNV.png)

该Stream的结构很清晰，就是一个双向链表结构，所有的sourceStage指向最先生成的那个头，previousStage从最后生成的Stream一直往前指向头，而nextStage则从头往后一直指向最后一个Stream，结构是这样的：

![stage](https://s2.ax1x.com/2020/01/15/lLT9jU.png)

到目前为止通过这个栗子把从创建的Head，到调用若干次中间操作后返回的StatelessOp的流程、以及最后返回的实例的整体结构都了解了一遍。

### Stream族谱

![stream-class](https://s2.ax1x.com/2020/01/15/lLTujO.png)

- BaseStream类是所有Stream的基本接口，定义了是否并行，数据源，关闭回调等基本方法，Stream流继承了AutoCloseable接口不需要手动关闭。
- BaseStream有四个分支，其中Stream处理的元素为引用类型而另外三个分别处理int，lang，double三种基本类型的数据。
- AbstractPipeLine 定义了Stream双向链表的管道结构。
- PipeLineHelper 为管道辅助类，主要定义了一些终端操作中与计算相关的一些方法，比如WarpSink、copyInto等。
- ***PipeLine里定义了Head StatelessOp StatefulOp 三种具体的实现类，初始的Stream为Head，中间操作后生成的根据操作的不同分为Stateless和StatefulOp

### 终端操作流程

回到之前的小栗子，看双向链表结构的Pipeline是怎么通过warpSink组合不同的操作再讲操作运用到产生元素的Spliterator的。

![stream-reduce](https://s2.ax1x.com/2020/01/15/lOAkhq.png)

终端操作reduce调用了***PipeLine的evaluate方法，传入了一个ReduceOps的实例。ReduceOps代表了reduce这种终端操作，是TerminalOp接口的一个实现。

![stream-evaluatea](https://s2.ax1x.com/2020/01/15/lOV36K.png)

在evaluate方法里根据条件是否并行分别调用了 TerminalOp的并行计算与顺序计算方法，传入参数为类型为pipelinehelper的this本身，和产生元素的Spliterator。

![stream-seqEvaluate](https://s2.ax1x.com/2020/01/15/lOZ6v6.png "计算过程")
![stream-makeSink](https://s2.ax1x.com/2020/01/15/lOeQsK.png "makeSink")
![stream-warpSink](https://s2.ax1x.com/2020/01/15/lOmmTg.png "warpSink")
![stream-copyInto](https://s2.ax1x.com/2020/01/15/lOm360.png "copyInto")

以顺序执行为例，计算过程分为makeSink warpSink 和 copyInto 三个过程。

- makeSink由终端操作实例提供，生成第一个sink操作，代表整个操作流中的最后一个sink。
- warpSink 由 PipelineHelper提供，根据管道结构从最后一个中间操作开始不断往前调用***Pipeline的opWarpSink方法，将所有中间操作和终端操作进行组合，返回一个组合了所有操作的最终Sink。
- copyInto 同样由PipelineHelper提供，用于将生成的最终Sink应用于传入的Spliterator，使每一个元素依次执行这个Sink方法。

#### Sink

Sink是组合流管道流式操作的媒介，继承至Comsummer接口，可以对传入的元素进行一定的处理，Sink接口主要有以下方法：

![stream-sink](https://s2.ax1x.com/2020/01/15/lO01IJ.png)

Sink有两种状态，初始状态和激活状态begin后进入激活状态，end后重新进入初始状态，accept方法只有在激活状态才能使用。Sink通过终端操作往前封装，后一个sink传入前一个Sink，保存在downStream属性中，每一个PipeLine 通过实现onWarpSink方法实现当前操作与下一步操作的封装，如下图，filter方法返回的Pipeline实现的opWarpSink方法返回当前操作的Sink，该Sink接收一个对象，如果对象满足predicate则将对象传递给downStream继续处理下一个操作：

![filter](https://s2.ax1x.com/2020/01/15/lOS9vd.png)

#### Stream的工作流程总览

![stream-all](https://s2.ax1x.com/2020/01/15/lLogne.png)

### 另一个栗子

```java
private static void testStream()
{
    String[] words = {"hello", "my", "world"};
    var strStream = Arrays.stream(words);
    var tempStream = strStream.filter(word -> word.length() > 3)
            .map(word -> word.split(""))
            .flatMap(Arrays::stream)
            .distinct()
            .map(String::toUpperCase)
            .sorted();
    var result = tempStream.reduce((a, b) -> a + "," + b);
    LogUtil.info(result.orElse("null"));
}
```

输出结果：

```txt
[2020-01-15 14:55:01:444] [INFO ] com.sictiy.jserver.Test.testStream(Test.java:46) D,E,H,L,O,R,W
```

#### 有状态操作

当栗子里面加入了sorted和distinct两个中间操作后，原来的逻辑好像有了点问题。按原来的流程，所有操作组合成一个流式的Sink后，Spliterator生成序列的元素，依次通过Sink处理，各元素之间相互不影响。但是当操作中出现有状态操作时，比如sorted需要依赖各个元素之间的大小关系，显然无法生成一个元素处理一个元素，那这种有状态操作又是如何处理的呢？通过观察第二个栗子的reduce执行步骤发现，整体流程依然没有变化，变化的只是双向链表的单个操作节点由StateleOp替换为了StatefulOp的实现类，比如sorted方法返回的是实现类SortedOps。我们已经知道不同操作节点之间的操作斜街是通过opWarpSink实现的，那有状态操作与无状态操作最大的不同肯定就在于opWarpSink了，来看一下该方法返回的是什么样的Sink：

```java
/**
    * {@link Sink} for implementing sort on reference streams.
    */
private static final class RefSortingSink<T> extends AbstractRefSortingSink<T> {
    private ArrayList<T> list;

    RefSortingSink(Sink<? super T> sink, Comparator<? super T> comparator) {
        super(sink, comparator);
    }

    @Override
    public void begin(long size) {
        if (size >= Nodes.MAX_ARRAY_SIZE)
            throw new IllegalArgumentException(Nodes.BAD_SIZE);
        list = (size >= 0) ? new ArrayList<>((int) size) : new ArrayList<>();
    }

    @Override
    public void end() {
        list.sort(comparator);
        downstream.begin(list.size());
        if (!cancellationRequestedCalled) {
            list.forEach(downstream::accept);
        }
        else {
            for (T t : list) {
                if (downstream.cancellationRequested()) break;
                downstream.accept(t);
            }
        }
        downstream.end();
        list = null;
    }

    @Override
    public void accept(T t) {
        list.add(t);
    }
}
```

该Sink的accept方法接收一个元素后并没有将这个元素继续往下传递，而是存放在list当中，当所有元素都生成完之后，copyInto方法中调用end方法，当end传递到sorted操作这一层的时候，先对list进行排序，然后依次对其中的元素调用downstream的accept方法向下传递，所有元素都处理完之后，再传递end方法的调用。相当于当元素流在操作管道中传递的时候，在这一步截断了，对所有元素排序后，继续依次往后传递。既然排序操作是这样的，那去重操作呢，再看一下：

未排序的stream：

```java
return new Sink.ChainedReference<T, T>(sink) {
    Set<T> seen;

    @Override
    public void begin(long size) {
        seen = new HashSet<>();
        downstream.begin(-1);
    }

    @Override
    public void end() {
        seen = null;
        downstream.end();
    }

    @Override
    public void accept(T t) {
        if (!seen.contains(t)) {
            seen.add(t);
            downstream.accept(t);
        }
    }
};
```

已排序的stream：

```java
return new Sink.ChainedReference<T, T>(sink) {
    boolean seenNull;
    T lastSeen;

    @Override
    public void begin(long size) {
        seenNull = false;
        lastSeen = null;
        downstream.begin(-1);
    }

    @Override
    public void end() {
        seenNull = false;
        lastSeen = null;
        downstream.end();
    }

    @Override
    public void accept(T t) {
        if (t == null) {
            if (!seenNull) {
                seenNull = true;
                downstream.accept(lastSeen = null);
            }
        } else if (lastSeen == null || !t.equals(lastSeen)) {
            downstream.accept(lastSeen = t);
        }
    }
};
```

显然该Sink就可以达到去重的目的，当Stream是已排序的时，重复元素只可能连续出现，只需要与上一次传入的元素对比，如果相同则已处理过重复元素直接丢弃；当Stream时未排序的时，将已处理的元素记录在set中，当下次接收到相同元素时丢弃。所谓有状态，即时在当前操作处理一个元素之后需要记录某些信息，决定后面的元素的操作，而这种机制就是依靠Sink来实现的，不同的操作实现不同的opWarpSink，返回不同的Sink，Sink中可以记录某些信息来实现有状态。
