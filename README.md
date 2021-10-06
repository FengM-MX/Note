# Note



## 1. Unraid驱动编译

#### 1.1 原文地址

- [rtl8125-driver-for-unraid-6.8.2](https://github.com/fanhuanji/rtl8125-driver-for-unraid-6.8.2/blob/main/compile_drivers.md)



### 2.2 编译流程

> 脚本：[compile_unraid](./shell/compile_unraid) 

- 编译内核

  - 编译时使用的系统为ubuntu18，首先需要安装build-essential bison flex libssl-dev libelf-dev libelf-dev等基本软件包

  - 在unraid上，使用`tar -zcvf linux-$(uname -r).tar.gz -C /usr/src linux-$(uname -r)`将内核文件打包

  - 在ubuntu上，使用`mkdir -p ~/unraid_compile`，并且将打包得到的文件放进去

  - 将脚本上传到ubuntu的~/unraid_compile目录

  - 使用`chmod +x compile_unraid.sh & bash compile_unraid.sh `执行脚本即可

    > 注意：如果脚本执行失败，则到`/usr/src/linux-unraid的内核版本`目录下，看看unraid打包得到的.config文件，是否被正确复制到该目录下

  - 脚本最后会把编译好的bzImage和bzmodules移动到`~/unraid_compile/unraid_target`

  - 可以通过使用编译好的bzImage和bzmodules替换U盘根目录的bzImage和bzmodules，来进行测试，记得将U盘中的bzfirmware.sha256和bzmodules.sha256的内容，用编译好的bzImage和bzmodules重新生成sha256，进行替换

- 编译驱动，以r8168驱动为例

  - 在[Realtek PCIe FE / GBE / 2.5G / Gaming Ethernet Family Controller Software - REALTEK](https://www.realtek.com/en/component/zoo/category/network-interface-controllers-10-100-1000m-gigabit-ethernet-pci-express-software)中下载r8168的驱动，并且在ubuntu上解压

    ```
    tar  -jxvf r8168-8.049.02.tar.bz2
    ```

  - 使用如下的命令进行编译

    ```shell
    make -C /usr/src/linux-5.10.28/ M=/root/r8168-8.049.02/src modules
    ```

    > 注意：其中的`/usr/src/linux-5.10.28`中的5.10.28需要替换成unraid上，通过uname -r 看到的版本号

  - 编译好的驱动在`/root/r8168-8.049.02/src `目录下，将r8168.ko下载下来，上传到unraid上，使用`insmod r8168.ko`，进行安装测试，如果安装失败，可以用`dmesg`查看报错信息，如果正常安装，可以使用`lsmod | grep r8168` 查看是否加载成功，如果一切正常，可以继续下一步

  - 将生成的驱动复制到bzmodules中，首先需要将bzmodules和对应的驱动r8168.ko复制到一个空的临时目录，然后在该目录下进行如下操作

    ```shell
    # 创建挂接点文件夹
    mkdir fm
    # 将squashfs挂接到指定挂接点
    sudo mount bzmodules ./fm/
    # 创建临时工作目录
    mkdir to
    mkdir temp
    mkdir fin
    # 使用overlay fs挂接，指定上下层文件系统与工作目录
    sudo mount -t overlay -o lowerdir=./fm,upperdir=./to,workdir=./temp overlay ./fin
    ```

    挂载好后，将驱动复制到对应的`./fin/5.10.28-Unraid/kernel/drivers/net/ethernet/realtek/`

    ```shell
    # 对驱动进行压缩后，复制到对应的目录 （r8168网卡驱动）
    xz -z ./r8168.ko
    sudo cp ./r8168.ko.xz ./fin/5.10.28-Unraid/kernel/drivers/net/ethernet/realtek/
    ```

    拷贝好之后，执行

    ```shell
    # 重新打包squashfs，起名为bzmodulesnew
    mksquashfs ./fin/ bzmodulesnew
    # 取消挂载并删除临时文件夹
    sudo umount ./fin
    sudo umount ./fm/
    sudo rm -rf ./fm ./fin ./to ./temp
    ```

    将生成的bzmodulesnew复制到对应的U判断根目录，并更新对应的sha256文件的内容，尝试启动unraid，如果一切顺利，系统会加载上你新编译出的驱动，可以在系统里输入`lsmod`查看当前装载的驱动，可通过`dmesg`查看系统启动时驱动加载时的输出

