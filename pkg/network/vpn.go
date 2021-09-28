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
	"github.com/EdgeNet-project/edgenet/pkg/apis/networking/v1alpha"
	"github.com/EdgeNet-project/node/pkg/utils"
	"github.com/vishvananda/netlink"
	"golang.org/x/sys/unix"
	"golang.zx2c4.com/wireguard/wgctrl"
	"golang.zx2c4.com/wireguard/wgctrl/wgtypes"
	"log"
	"net"
	"time"
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
	link := getOrAddVPNLink(name)
	check(netlink.LinkSetUp(link))
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

	err = netlink.AddrReplace(link, addr4)
	if err != nil {
		log.Printf("Failed to set IPv4 for link %s: %s\n", name, err)
	}
	err = netlink.AddrReplace(link, addr6)
	if err != nil {
		log.Printf("Failed to set IPv6 for link %s: %s\n", name, err)
	}
}

func AddPeer(name string, peer v1alpha.VPNPeer) {
	client, err := wgctrl.New()
	check(err)

	publicKey, err := wgtypes.ParseKey(peer.Spec.PublicKey)
	check(err)

	allowedIPs := []net.IPNet{
		{
			IP:   net.ParseIP(peer.Spec.AddressV4),
			Mask: net.CIDRMask(32, 32),
		},
		{
			IP:   net.ParseIP(peer.Spec.AddressV6),
			Mask: net.CIDRMask(128, 128),
		},
	}

	var endpoint *net.UDPAddr
	if peer.Spec.EndpointAddress != nil && peer.Spec.EndpointPort != nil {
		endpoint = &net.UDPAddr{
			IP:   net.ParseIP(*peer.Spec.EndpointAddress),
			Port: *peer.Spec.EndpointPort,
		}
	}

	keepaliveInterval := 5 * time.Second

	peerConfig := wgtypes.PeerConfig{
		AllowedIPs:                  allowedIPs,
		Endpoint:                    endpoint,
		PublicKey:                   publicKey,
		PersistentKeepaliveInterval: &keepaliveInterval,
		Remove:                      false,
		ReplaceAllowedIPs:           true,
		UpdateOnly:                  false,
	}

	deviceConfig := wgtypes.Config{
		Peers:        []wgtypes.PeerConfig{peerConfig},
		ReplacePeers: false,
	}

	check(client.ConfigureDevice(name, deviceConfig))
}
