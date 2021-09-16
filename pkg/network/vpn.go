/*
Copyright 2021 Contributors to the EdgeNet project.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package network

import (
	"github.com/EdgeNet-project/node/pkg/utils"
	"github.com/vishvananda/netlink"
	"golang.org/x/sys/unix"
	"golang.zx2c4.com/wireguard/wgctrl"
	"golang.zx2c4.com/wireguard/wgctrl/wgtypes"
)

func getOrAddVPNLink(name string) netlink.Link {
	link, err := netlink.LinkByName(name)
	if err == nil {
		return link
	}
	_, ok := err.(netlink.LinkNotFoundError)
	if !ok {
		panic(err)
	}
	linkAttrs := netlink.NewLinkAttrs()
	linkAttrs.Name = name
	link = &netlink.Wireguard{LinkAttrs: linkAttrs}
	check(netlink.LinkAdd(link))
	return link
}

func InitializeVPN(name string, privateKey string, listenPort int) {
	getOrAddVPNLink(name)
	client, err := wgctrl.New()
	check(err)
	key, err := wgtypes.ParseKey(privateKey)
	check(err)
	config := wgtypes.Config{PrivateKey: &key, ListenPort: &listenPort}
	check(client.ConfigureDevice(name, config))
}

func AssignVPNIP(name string, ipv4 utils.IPWithMask, ipv6 utils.IPWithMask) {
	link := getOrAddVPNLink(name)

	addr4, err := netlink.ParseAddr(ipv4.String())
	check(err)
	addrs, err := netlink.AddrList(link, unix.AF_INET)
	check(err)
	for _, addr := range addrs {
		if !addr.Equal(*addr4) {
			check(netlink.AddrDel(link, &addr))
		}
	}

	addr6, err := netlink.ParseAddr(ipv6.String())
	check(err)
	addrs, err = netlink.AddrList(link, unix.AF_INET6)
	check(err)
	for _, addr := range addrs {
		if !addr.Equal(*addr6) {
			check(netlink.AddrDel(link, &addr))
		}
	}

	check(netlink.AddrReplace(link, addr4))
	check(netlink.AddrReplace(link, addr6))
}
