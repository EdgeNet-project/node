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
	"errors"
	"fmt"
	"github.com/txn2/txeh"
	"github.com/vishvananda/netlink"
	"golang.org/x/sys/unix"
	"io/ioutil"
	"net"
	"os"
	"os/exec"
	"strings"
)

func check(err error) {
	if err != nil {
		panic(err)
	}
}

// findLink returns the link which has the specified IP address.
func findLink(ip net.IP) (netlink.Link, error) {
	family := unix.AF_INET
	if ip.To4() == nil {
		family = unix.AF_INET6
	}
	links, err := netlink.LinkList()
	if err != nil {
		return nil, err
	}
	for _, link := range links {
		addrs, err := netlink.AddrList(link, family)
		if err != nil {
			return nil, err
		}
		for _, addr := range addrs {
			if addr.IP.Equal(ip) {
				return link, nil
			}
		}
	}
	return nil, fmt.Errorf("link not found for IPv%d address %s", family, ip)
}

// SetHostname sets the node hostname and update the hosts file.
func SetHostname(hostname string) {
	// Update /etc/hostname
	cmd := exec.Command("hostnamectl", "set-hostname", hostname)
	check(cmd.Run())
	// Update /etc/hosts
	hosts, err := txeh.NewHostsDefault()
	check(err)
	// 1. Remove old entries
	var hostsToRemove []string
	for _, line := range *hosts.GetHostFileLines() {
		for _, hostname := range line.Hostnames {
			if strings.HasSuffix(hostname, ".edge-net.io") {
				hostsToRemove = append(hostsToRemove, hostname)
			}
		}
	}
	hosts.RemoveHosts(hostsToRemove)
	// 2. Add updated entry
	hosts.AddHosts("127.0.0.1", []string{hostname})
	check(hosts.Save())
}

// SetKubeletNodeIP sets the node IP in the kubelet configuration.
func SetKubeletNodeIP(kubeletEnvFile string, ip net.IP) {
	if _, err := os.Stat(kubeletEnvFile); errors.Is(err, os.ErrNotExist) {
		return
	}
	// TODO: Do not override existing content?
	s := fmt.Sprintf("KUBELET_EXTRA_ARGS=\"--node-ip=%s\"\n", ip.String())
	check(ioutil.WriteFile(kubeletEnvFile, []byte(s), 0644))
}
