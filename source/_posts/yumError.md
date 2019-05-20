---
title: rpmdb:DBD0113
date: 2019-05-15 09:47:31
tags: 
categories: 
---

## 问题

```shell
error: rpmdb: BDB0113 Thread/process 13173/139999979816768 failed: BDB1507 Thread died in Berkeley DB library
error: db5 error(-30973) from dbenv->failchk: BDB0087 DB_RUNRECOVERY: Fatal error, run database recovery
error: cannot open Packages index using db5 -  (-30973)
error: cannot open Packages database in /var/lib/rpm
CRITICAL:yum.main:

Error: rpmdb open failed
```

---

## 解决：重建数据库

``` shell
cd /var/lib/rpm
ls
rm -rf __db*
rpm --rebuilddb
```