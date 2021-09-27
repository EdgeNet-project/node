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

package cluster

import (
	"context"
	"github.com/EdgeNet-project/edgenet/pkg/apis/core/v1alpha"
	v1alpha2 "github.com/EdgeNet-project/edgenet/pkg/apis/networking/v1alpha"
	"github.com/EdgeNet-project/edgenet/pkg/generated/clientset/versioned"
	"github.com/EdgeNet-project/node/pkg/utils"
	"io/ioutil"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"log"
	"net"
	"net/http"
	"strings"
)

func check(err error) {
	if err != nil {
		panic(err)
	}
}

func configFromUrl(url string) (*rest.Config, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	buf, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	return clientcmd.RESTConfigFromKubeConfig(buf)
}

func FindVPNIPs(configURL string, netv4 net.IPNet, netv6 net.IPNet) (*utils.IPWithMask, *utils.IPWithMask) {
	peers := ListVPNPeer(configURL)
	usedIPs := make([]net.IP, 0)
	for _, peer := range peers {
		usedIPs = append(usedIPs, net.ParseIP(peer.Spec.AddressV4))
	}
	ipv4 := utils.RandIPv4(netv4, usedIPs)
	ipv6 := make(net.IP, 16)
	copy(ipv6[:12], netv6.IP[:12])
	copy(ipv6[12:16], ipv4)
	return &utils.IPWithMask{IP: ipv4, Mask: netv4.Mask}, &utils.IPWithMask{IP: ipv6, Mask: netv6.Mask}
}

func CreateVPNPeer(configURL string, hostname string, externalIP net.IP, ipv4 net.IP, ipv6 net.IP, listenPort int, publicKey string) {
	config, err := configFromUrl(configURL)
	check(err)
	clientset, err := versioned.NewForConfig(config)
	check(err)
	client := clientset.NetworkingV1alpha().VPNPeers()
	_externalIP := externalIP.String()
	peer := &v1alpha2.VPNPeer{
		ObjectMeta: metav1.ObjectMeta{
			Name: hostname,
		},
		Spec: v1alpha2.VPNPeerSpec{
			AddressV4:       ipv4.String(),
			AddressV6:       ipv6.String(),
			EndpointAddress: &_externalIP,
			EndpointPort:    &listenPort,
			PublicKey:       publicKey,
		},
	}
	_, err = client.Create(context.TODO(), peer.DeepCopy(), metav1.CreateOptions{})
	if errors.IsAlreadyExists(err) {
		log.Print("vpn-peer-status=already-exists")
	} else if err != nil {
		panic(err)
	} else {
		log.Print("vpn-peer-status=created")
	}
}

func ListVPNPeer(configURL string) []v1alpha2.VPNPeer {
	config, err := configFromUrl(configURL)
	check(err)
	clientset, err := versioned.NewForConfig(config)
	check(err)
	client := clientset.NetworkingV1alpha().VPNPeers()
	peers, err := client.List(context.TODO(), metav1.ListOptions{})
	check(err)
	return peers.Items
}

// Join the node to the cluster specified by configURL.
// It ignores AlreadyExists errors when creating the NodeContribution object.
func Join(configURL string, hostname string, externalIP net.IP) {
	config, err := configFromUrl(configURL)
	check(err)
	clientset, err := versioned.NewForConfig(config)
	check(err)
	client := clientset.CoreV1alpha().NodeContributions()
	nodeContribution := &v1alpha.NodeContribution{
		ObjectMeta: metav1.ObjectMeta{
			Name: strings.ReplaceAll(hostname, ".edge-net.io", ""),
		},
		Spec: v1alpha.NodeContributionSpec{
			Enabled: true,
			Host:    externalIP.String(),
			Port:    22,
			Tenant:  nil,
			User:    "edgenet",
		},
	}
	_, err = client.Create(context.TODO(), nodeContribution.DeepCopy(), metav1.CreateOptions{})
	if errors.IsAlreadyExists(err) {
		log.Print("node-contribution-status=already-exists")
	} else if err != nil {
		panic(err)
	} else {
		log.Print("node-contribution-status=created")
	}
}
