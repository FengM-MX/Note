# Note



## 1. Unraid驱动编译

#### 1.1 原文地址

- [rtl8125-driver-for-unraid-6.8.2](https://github.com/fanhuanji/rtl8125-driver-for-unraid-6.8.2/blob/main/compile_drivers.md)



### 2.2 编译脚本

> 脚本：[compile_unraid](./shell/compile_unraid) 

- 编译时使用的系统为ubuntu18，首先需要安装build-essential bison flex libssl-dev libelf-dev libelf-dev等基本软件包
- 在unraid上，使用`tar -zcvf linux-$(uname -r).tar.gz -C /usr/src linux-$(uname -r)`将内核文件打包
- 在ubuntu上，使用`mkdir -p ~/unraid_compile`，并且将打包得到的文件放进去
- 将脚本上传到ubuntu的~/unraid_compile目录
- 使用`chmod +x compile_unraid.sh & bash compile_unraid.sh `执行脚本即可



