You are strongly encouraged to test the produced Envoy binary on CentOS 7 yourselves to ensure that it satisfies your required functionality and operates as expected.

## Version 1.25.x
If you need to run this version of Envoy on CentOS 7, your best bet is to use an Envoy binary built on Oracle Linux 8 and an updated version of glibc. CentOS 7 only comes with glibc 2.17, but the Envoy binary built on Oracle Linux 8 depends on a newer version of glibc, so you have to install a newer version on your system. Be careful not to override the existing version of glibc. Here are the rough instructions for accomplishing this:
1. Use the Oracle Linux 8 image in this repo to build envoy.
2. Copy the resulting Envoy binary to a CentOS 7 host.
3. Install glibc 2.28 on the CentOS 7 host. This is the only version of glibc that has been tested with Envoy 1.25.x on CentOS 7.
    1. One option is to compile it from source.
    ```
    wget https://ftp.gnu.org/gnu/glibc/glibc-2.28.tar.gz
    tar zxvf glibc-2.28.tar.gz
    cd glibc-2.28
    mkdir build
    cd build
    ../configure --prefix=/opt/glibc-2.28
    make -j4
    sudo make install
    ```
    2. Another option is to download a pre-built RPM and extract it to a specific directory.
    ```
    mkdir /opt/glibc-2.28
    cd /opt/glibc-2.28
    wget https://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/glibc-2.28-155.el8.x86_64.rpm
    rpm2cpio glibc-2.28-155.el8.x86_64.rpm | cpio -idmv
    rm glibc-2.28-155.el8.x86_64.rpm
    ```
4. Use [patchelf](https://github.com/NixOS/patchelf) to patch the Oracle Linux 8 Envoy binary to use the updated version of glibc ld-linux for its interpreter and set the rpath to include the libs from glibc. This allows you to start the binary using a newer glibc version that includes the features required by the Oracle Linux 8 binary. Without this, it will run the system ld-linux which is from glibc 2.17 on CentOS 7.
```
patchelf --set-interpreter '/opt/glibc-2.28/lib64/ld-linux-x86-64.so.2' --set-rpath '/opt/glibc-2.28/lib64/' ${path_to_envoy_binary}
```
5. You should now be able to run the Envoy binary on your CentOS 7 host.

## Version 1.21.x
Envoy version 1.21 onwards cannot currently be compiled on CentOS 7.

This is due the changes that were made to `tcp_stats.cc` during the 1.21 release and these being incompatible with the linux/tcp.h headers that are included in CentOS 7.

- `glibc-headers-2.17-317.el7.x86_64.rpm`
- `kernel-headers-3.10.0-1160.el7.x86_64.rpm`

```console
source/extensions/transport_sockets/tcp_stats/tcp_stats.cc:119:18: error: no member named 'tcpi_data_segs_out' in 'tcp_info'; did you mean 'tcpi_segs_out'?
  if ((tcp_info->tcpi_data_segs_out > last_cx_tx_data_segments_) &&
                 ^~~~~~~~~~~~~~~~~~
                 tcpi_segs_out
/usr/include/linux/tcp.h:204:8: note: 'tcpi_segs_out' declared here
        __u32   tcpi_segs_out;       /* RFC4898 tcpEStatsPerfSegsOut */
                ^
source/extensions/transport_sockets/tcp_stats/tcp_stats.cc:126:51: error: no member named 'tcpi_data_segs_out' in 'tcp_info'; did you mean 'tcpi_segs_out'?
    const uint32_t data_segs_out_diff = tcp_info->tcpi_data_segs_out - last_cx_tx_data_segments_;
                                                  ^~~~~~~~~~~~~~~~~~
                                                  tcpi_segs_out
/usr/include/linux/tcp.h:204:8: note: 'tcpi_segs_out' declared here
        __u32   tcpi_segs_out;       /* RFC4898 tcpEStatsPerfSegsOut */
                ^
source/extensions/transport_sockets/tcp_stats/tcp_stats.cc:139:28: error: no member named 'tcpi_data_segs_out' in 'tcp_info'; did you mean 'tcpi_segs_out'?
                 tcp_info->tcpi_data_segs_out);
                           ^~~~~~~~~~~~~~~~~~
                           tcpi_segs_out
/usr/include/linux/tcp.h:204:8: note: 'tcpi_segs_out' declared here
        __u32   tcpi_segs_out;       /* RFC4898 tcpEStatsPerfSegsOut */
                ^
source/extensions/transport_sockets/tcp_stats/tcp_stats.cc:141:28: error: no member named 'tcpi_data_segs_in' in 'tcp_info'; did you mean 'tcpi_segs_in'?
                 tcp_info->tcpi_data_segs_in);
                           ^~~~~~~~~~~~~~~~~
                           tcpi_segs_in
/usr/include/linux/tcp.h:205:8: note: 'tcpi_segs_in' declared here
        __u32   tcpi_segs_in;        /* RFC4898 tcpEStatsPerfSegsIn */
                ^
source/extensions/transport_sockets/tcp_stats/tcp_stats.cc:146:26: error: no member named 'tcpi_notsent_bytes' in 'tcp_info'
               tcp_info->tcpi_notsent_bytes);
               ~~~~~~~~  ^
```

Further investigation is needed to resolve this problem. Contributions are welcome! For more detail see [here](https://github.com/envoyproxy/envoy-build-tools/pull/154#issuecomment-1033902348). 

## Version 1.20.x
Envoy version 1.20 can be compiled on CentOS 7 using `clang and libc++`, but not `clang and libstdc++`, which throws an ambiguous function error. For more detail on this issue and a proposed fix see [here](https://github.com/envoyproxy/envoy/issues/19978).

## Version 1.19.x
Envoy version 1.19 can be built using either `clang and libc++` or `clang and libstdc++` on CentOS 7.
