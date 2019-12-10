# tun2socks-manager
Manage automatically SOCKS5 tunnel created with [tun2socks](https://github.com/ambrop72/badvpn/wiki/Tun2socks) from package [badvpn](https://github.com/ambrop72/badvpn).

## Install

Install dependencies

    sudo apt install dnsmasq-base

We need badvpn-tun2socks

    sudo apt install cmake
    git clone https://github.com/ambrop72/badvpn.git
    cd badvpn
    mkdir badvpn-build
    cd badvpn-build
    cmake /path/to/badvpn -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1
    make
    sudo cp tun2socks/badvpn-tun2socks /usr/local/bin

Install

    sudo make install

## Configure

See files `/etc/tun2socks-manager.conf` and sample file in `/etc/tun2socks-manager.d`.

## Troubleshooting

### Error org.freedesktop.DBus.Error.ServiceUnknown with dnsmasq

    Error org.freedesktop.DBus.Error.ServiceUnknown: The name org.freedesktop.NetworkManager.dnsmasq
    was not provided by any .service files

## Debugging
Messages are sent to /var/log/messages


    grep tun2socks-manager /var/log/messages


When troubleshooting, it helps to follow these messages in a separate window. For instance:

    tail -f /var/log/messages

First, the tun interface is created with:

    /usr/local/bin/tun2socks-manager start

Then the routing rule are created with (replace with correct network interface as necessary):

    /usr/local/bin/tun2socks-manager update eth0 up
