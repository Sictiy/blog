---
title: Idea插件开发记录
date: 2019-04-18 15:24:47
tags: 
categories: 
---

## 环境

---

- 下载[idea社区版](https://github.com/JetBrains/intellij-community)
- 配置jdk
- 配置IntelliJ Platform Plugin Sdk
  - Project Structure->sdks:
  - 点击+，选择intellij...按提示继续，目录选择社区版安装路径就好
  - 导入idea源码：选择sourcePath->+.
- 创建简单工程
  - create new project -> intellij platform plugin
  - 项目结构：
  > plugin
  >> src
  >> resources
  >>> META_INF
  >>>> plugin.xml
  
  - src为源码目录，plugin.xml为配置文件，需要在这里添加自己实现的action service等

## 插件入口
  
---

- 插件入口即在idea上部分菜单栏加入一个按钮，点击按钮则运行插件
- 继承抽象类AnAction， 实现actionPerformed方法：

    ```java
    public class MyAction extends AnAction {
        @Override
        // start方法，就类似于了平时的main方法
        public void actionPerformed(@NotNull AnActionEvent e) {
            com.myPlugin.Main.start();
        }
    }

    ```

- 配置plugin.xml

    ```xml
    <action class="com.myPlugin.MyAction" text="myPlugin" id="myPlugin">
          <add-to-group group-id="ToolsMenu" anchor="first"/>
    </action>
    <!-- add-to-group 定义插件的入口放在菜单的哪个菜单项下面，anchor定义插入的位置-->

    ```

## 持久化

---

- 需要实现PersistenStateComponent接口

    ```java
    @State(name = "myName", storages = {@Storage("myName.xml")})
    public class MyState implements PersistentStateComponent<Config> {
        private Config config;

        public static MyState getInstance(){
            return ServiceManager.getService(MyState.class);
        }

        @Nullable
        @Override
        // getState获取到的bean会自动保存
        public Config getState() {
            return config;
        }

        @Override
        // 自动从文件中加载bean
        public void loadState(@NotNull Config state) {
            config = state;
        }

        public void setConfig(Config config) {
            this.config = config;
        }
    }

    ```

- plugin.xml中配置：

    ```xml

    <applicationService serviceInterface="com.myPlugin.MyState" serviceImplementation="com.myPlugin.MyState"/>

    ```

## 配置入口

---

- 实现SearchableConfigurable即可在setting中增加一个配置界面，需要实现的方法有：
  - createComponent(): 配置界面的ui，可以使用可使用工具编写
  - isModified(): 影响界面中应用按钮是否可点击
  - apply(): 点击应用按钮时调用
- plugin.xml中配置：

    ```xml

    <applicationConfigurable instance="com.myPlugin.MyConfigurable"/>

    ```

## idea中swing可视化

---

- New -> Gui Form
- 打开myGui.form添加部件，监听等
- 完成后打开同级目录的myGui.java
- 右键 -> generate -> form main，如果提示the form bound to..., 需要回到gui designer 给跟jpanel设置一个名字