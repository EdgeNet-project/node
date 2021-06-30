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
	"github.com/coreos/go-iptables/iptables"
	"github.com/vishvananda/netlink"
	"net"
)

// AssignPublicIP assign the publicIP to the interface with the localIP.
func AssignPublicIP(localIP net.IP, publicIP net.IP) {
	link, err := findLink(localIP)
	check(err)
	addr, err := netlink.ParseAddr(publicIP.String() + "/32")
	check(err)
	err = netlink.AddrReplace(link, addr)
	check(err)
}

// Cloud providers assign a public IP to instances through NAT.
// The instance only sees an private _internal_ IP.
// This is problematic for Kubernetes, which expects to see the public IP on the interface.
// In this script, we assign the public IP to the instance interface.
func RewritePublicIP(localIP net.IP, publicIP net.IP) {
	table, err := iptables.New()
	check(err)

	err = table.AppendUnique(
		"nat",
		"PREROUTING",
		"--jump", "DNAT",
		"--source", localIP.String(),
		"--to", publicIP.String())
	check(err)

	err = table.AppendUnique(
		"nat",
		"POSTROUTING",
		"--jump", "SNAT",
		"--source", publicIP.String(),
		"--to", localIP.String())
	check(err)
}
