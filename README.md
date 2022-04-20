# tun2socks-manager

Manage automatically SOCKS5 tunnel created with
[tun2socks](https://github.com/ambrop72/badvpn/wiki/Tun2socks) from package
[badvpn](https://github.com/ambrop72/badvpn).

## Install client

Install `dnsmasq-base`:

``` bash
sudo apt install dnsmasq-base
sudo vi /etc/NetworkManager/NetworkManager.conf
# Edit as follows:
#      [main]
#      plugins=ifupdown,keyfile
#     +dns=dnsmasq
sudo vi /etc/dhcp/dhclient.conf
# Edit as follows:
#      #supersede domain-name "fugue.com home.vix.com";
#     -#prepend domain-name-servers 127.0.0.1;
#     +prepend domain-name-servers 127.0.0.1;
```

Build `badvpn-tun2socks` from source:

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

Install `tun2socks-manager`:

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

This is likely because `dnsmasq` is not running. Check that NetworkManager started it in background.
Otherwise follows the install instructions above.

``` bash
ps faux | grep dnsmasq
# nobody    128496  0.0  0.0  12976  4548 ?        S    10:06   0:00 /usr/sbin/dnsmasq --no-resolv
# --keep-in-foreground --no-hosts --bind-interfaces --pid-file=/run/NetworkManager/dnsmasq.pid
# --listen-address=127.0.0.1 --cache-size=400 --clear-on-reload --conf-file=/dev/null --proxy-dnssec
# --enable-dbus=org.freedesktop.NetworkManager.dnsmasq --conf-dir=/etc/NetworkManager/dnsmasq.d
```

Also check that the parameter given to `--enable-dbus` matches the expected string.

### WiFi hot-spot no longer working ###

The script heavily interferes with the routing table, and may interfere with the routing of IP packets
from the WiFi interface. In particular, if the computer is also used as hotspot, the routing may be
broken.

    $ ip route
    default via 10.137.3.254 dev enp0s31f6 proto dhcp metric 100
    10.0.10.0/24 dev tun0 proto kernel scope link src 10.0.10.1
    10.42.0.0/24 dev wlp1s0 proto kernel scope link src 10.42.0.1 metric 600
    10.137.2.0/23 dev enp0s31f6 proto kernel scope link src 10.137.2.174 metric 100

We see we have a dedicated route for the hotspot on itf wlsp1s0. However when looking in the tun
table, we don't find such routing, but instead the routing is caught in a general routing rule.

    $ ip route show table tun
    default via 10.0.10.2 dev tun0
    10.0.0.0/8 via 10.137.3.254 dev enp0s31f6
    10.0.10.0/24 dev tun0 proto kernel scope link src 10.0.10.1
    10.137.2.0/23 dev enp0s31f6 proto kernel scope link src 10.137.2.174
    ...

To fix this, we must duplicate the hotspot routing rule in the tun table:

    sudo ip route add 10.42.0.0/24 dev wlp1s0 proto kernel scope link src 10.42.0.1 metric 600 table tun

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
