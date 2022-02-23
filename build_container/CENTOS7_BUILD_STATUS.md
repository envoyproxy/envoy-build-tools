You are strongly encouraged to test the produced Envoy binary on CentOS 7 yourselves to ensure that it satisfies your required functionality and operates as expected.

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