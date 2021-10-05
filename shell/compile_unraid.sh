set_config_file(){
    # 创建工作文件夹
    mkdir -p ~/unraid_compile
    work_folder=$(cd ~/unraid_compile;pwd)

    # 设置linux kernel 的源码目录
    linux_kernel_src="/usr/src"

    cd ${work_folder}
    echo "请输入unraid的内核版本:"
    echo "注：例如:5.10.28,unraid上可以使用uname -r可以查询"
    read kernel_version

    # 内核文件解压路径
    kernel_folder="${linux_kernel_src}/linux-${kernel_version}"
    # unraid的内核问价文件夹名称
    unraid_kernel_folder="linux-${kernel_version}-Unraid"
    # unraid 内核文件所在位置
    unraid_kernel_file="${work_folder}/${unraid_kernel_folder}.tar.gz"

}

clean_compile(){
    echo "是否清理上次编译的文件(y/n)："
    read user_select
    if [ "${user_select}" == "y" ]
    then
        rm -rf ${kernel_folder}
        rm -rf ${work_folder}/${unraid_kernel_folder}
    fi
}

config_compile_env() {

    if [ ! -f "${unraid_kernel_file}" ]; then
        echo "unraid内核文件${unraid_kernel_file}不存在！"
        echo '可以使用 tar -zcvf linux-$(uname -r).tar.gz -C /usr/src linux-$(uname -r) 在unraid上打包,然后放到${work_folder}文件夹'
        exit
    fi

    if [ ! -f "linux-${kernel_version}.tar.gz" ]; then
        echo "内核文件不存在，开始下载！"
        wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${kernel_version}.tar.gz -O linux-${kernel_version}.tar.gz
    else
        echo "内核文件已经存在！"
    fi

    if [ ! -d "${kernel_folder}" ]; then
        echo "开始解压内核文件！"
        tar -C ${linux_kernel_src} -xf linux-${kernel_version}.tar.gz
    else
        echo "内核文件已经解压！是否重新解压(y/n)"
        read user_selects
        if [ "${user_selects}" == "y" ]; then
            rm -rf ${kernel_folder}
            tar -C ${linux_kernel_src} -xf linux-${kernel_version}.tar.gz
        fi
    fi

    if [ ! -d ${kernel_folder} ]; then
        echo "解压失败，请尝试以root用户运行该脚本！"
        exit
    fi

    # 复制unraid到linux内核目录
    echo "复制unraid到linux内核目录!"
    tar -zxvf ${unraid_kernel_file} -C ${work_folder}
    # 此处必须使用.，否则.config不会被复制
    cp -r ${work_folder}/${unraid_kernel_folder}/. ${kernel_folder}

}

comppile_kernel() {
    # 进入内核文件夹
    cd ${kernel_folder}
    
    echo "应用补丁"
    find . -type f -iname '*.patch' -print0 | xargs -n1 -0 patch -p 1 -i

    echo "编译内核"
    # make clean all
    # 使用原先配置准备编译环境
    make oldconfig

    # 将.config中CONFIG_SYSTEM_TRUSTED_KEYS设置为空
    sed -i 's/CONFIG_SYSTEM_TRUSTED_KEYS.*/CONFIG_SYSTEM_TRUSTED_KEYS=""/' ${kernel_folder}/.config

    # 准备编译内核modules（驱动）的环境
    echo "准备编译内核modules（驱动）的环境"
    make -j10 modules_prepare

    # 编译bzImage（内核映像） 编译驱动模块
    echo "编译bzImage（内核映像） 编译驱动模块"
    make -j10 bzImage
    make -j10
    make -j10 modules

    #将编译好的驱动包拷贝到系统目录
    echo "将编译好的驱动包拷贝到系统目录"
    make modules_install
    
    # 对驱动包进行打包
    echo "对驱动包进行打包"
    mksquashfs /lib/modules/${kernel_version}-Unraid/ bzmodules -keep-as-directory -noappend
}

deal_result() {
    # 设置最后的生成文件的路径
    target_foler="${work_folder}/unraid_target"

    # 复制目标文件到最后的目录中
    echo "复制结果到${target_foler}中"
    mkdir -p target_foler
    cp ${linux_kernel_src}/arch/x86/boot/bzImage ${target_foler}
    cp ${linux_kernel_src}/bzmodules ${target_foler}
}

main() {

    # 1. 配置环境
    set_config_file

    # 2. 是否先执行清理工作和设置环境
    clean_compile
    config_compile_env

    # 3. 编译内核
    comppile_kernel

    # 4. 复制结果
    deal_result
}

# 主程序
main
