# tun2socks-manager

Manage automatically SOCKS5 tunnel created with
[tun2socks](https://github.com/ambrop72/badvpn/wiki/Tun2socks) from package
[badvpn](https://github.com/ambrop72/badvpn).

## Install client

Install dependencies:

``` bash
sudo apt install dnsmasq-base
```

We need badvpn-tun2socks:

``` bash
sudo apt install cmake
git clone https://github.com/ambrop72/badvpn.git
cd badvpn
mkdir badvpn-build
cd badvpn-build
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1
make
sudo cp tun2socks/badvpn-tun2socks /usr/local/bin
```

Install tun2socks-manager:

``` bash
cd tun2socks-manager
sudo make install
```

## Install server

By default tun2socks is configured to use UDP forwarding (parameter `TUN2SOCKS_UDPGW_REMOTE`) for better
performance. This requires running `badvpn-udpgw` on the server side (as standard user, no root access
mandatory).  For instance:

``` bash
git clone https://github.com/ambrop72/badvpn.git
cd badvpn
mkdir badvpn-build
cd badvpn-build
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make
sudo cp badvpn-udpgw /usr/local/bin      # if no root: install in ~/bin
```

Then we need to run it automatically. Using systemd, we first create a service file
`/etc/systemd/system/udpgw.service` containing:

    [Unit]
    Description=UDP forwarding for badvpn-tun2socks
    After=nss-lookup.target

    [Service]
    ExecStart=/usr/local/bin/badvpn-udpgw --loglevel none --listen-addr 127.0.0.1:7300
    User=udpgw

    [Install]
    WantedBy=multi-user.target

Then we create the user, and enable / start the service:

```bash
sudo useradd -m udpgw
sudo systemctl enable udpgw
sudo systemctl start udpgw
```

An non-root alternative is to edit the crontab (`crontab -e`) and add a user `@reboot` event:

    @reboot           sleep 15 && ~/bin/badvpn-udpgw --loglevel none --listen-addr 127.0.0.1:7300

## Configure

See file `/etc/tun2socks-manager.conf` and per-connection sample file in `/etc/tun2socks-manager.d`.

## Troubleshooting

### Error org.freedesktop.DBus.Error.ServiceUnknown with dnsmasq

    Error org.freedesktop.DBus.Error.ServiceUnknown: The name org.freedesktop.NetworkManager.dnsmasq
    was not provided by any .service files

## Debugging

Messages are sent to `/var/log/messages`:

``` bash
grep tun2socks-manager /var/log/messages
```

When troubleshooting, it helps to follow these messages in a separate window. For instance:

``` bash
tail -f /var/log/messages
```

`tun2socks-manager` is installed as a Network Manager (NM) dispatcher script. When NM starts, 
it launches the tun2socks-manager with:

``` bash
/usr/local/bin/tun2socks-manager start
```

Then, NM sends `up` or `down` event to the script, which updates the routing table based on configuration
files in `/etc/tun2socks-manager.d/` . This can be triggered manually with:

``` bash
/usr/local/bin/tun2socks-manager update eth0 up       # Simulate up event on itf eth0
```

[//]: # ( vim: set tw=105 sw=4 fo=tcq2 spell: )
