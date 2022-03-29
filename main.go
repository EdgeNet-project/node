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

package main

import (
	"fmt"
	"github.com/EdgeNet-project/node/pkg/cluster"
	"github.com/EdgeNet-project/node/pkg/network"
	"github.com/EdgeNet-project/node/pkg/platforms"
	"github.com/EdgeNet-project/node/pkg/utils"
	"github.com/thanhpk/randstr"
	"golang.zx2c4.com/wireguard/wgctrl/wgtypes"
	"gopkg.in/yaml.v3"
	"log"
	"math/rand"
	"net"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const defaultVPNNetworkV4 = "10.183.0.0/20"
const defaultVPNNetworkV6 = "fdb4:ae86:ec99:4004::/64"
const edgenetConfigFile = "/opt/edgenet/config.yaml"
const kubeletEnvFileDebian = "/etc/default/kubelet"
const kubeletEnvFileRedHat = "/etc/sysconfig/kubelet"
const vpnLinkName = "edgenetmesh0"

func check(err error) {
	if err != nil {
		log.Panic(err)
	}
}

type edgenetConfig struct {
	// HostnameRoot is the deterministic component of the hostname (e.g. `aws-eu-west-1a`).
	HostnameRoot string `yaml:"hostnameRoot"`
	// HostnameSuffix is the random component of the hostname (e.g. `3fe8`).
	HostnameSuffix string `yaml:"hostnameSuffix"`
	// KubeconfigURL is the URL of the cluster public kubeconfig file.
	KubeconfigURL string `yaml:"kubeconfigURL"`
	// Platform is the host platform (e.g. `ec2`)
	Platform string `yaml:"platform"`
	// LocalIPv4 is the IPv4 address associated to the main network interface.
	// In presence of NAT, this will be a private IP.
	LocalIPv4 net.IP `yaml:"localIPv4"`
	// PublicIPv4 is the public IPv4 address of the host.
	// This address must be reachable from the Internet.
	PublicIPv4 net.IP `yaml:"publicIPv4"`
	// VPNIPv4 is the private IPv4 address of the VPN mesh interface.
	// This address must be unique among the node in the cluster.
	VPNIPv4 *utils.IPWithMask `yaml:"vpnIPv4"`
	// VPNIPv4 is the private IPv6 address of the VPN mesh interface.
	// This address must be unique among the node in the cluster.
	VPNIPv6 *utils.IPWithMask `yaml:"vpnIPv6"`
	// VPNPrivateKey is the WireGuard private key of the VPN mesh interface.
	VPNPrivateKey string `yaml:"vpnPrivateKey"`
	// VPNListenPort is the WireGuard port of the VPN mesh interface.
	VPNListenPort int `yaml:"vpnListenPort"`
}

// load the EdgeNet configuration from the specified file.
func (c *edgenetConfig) load(file string) {
	buf, err := os.ReadFile(file)
	if os.IsNotExist(err) {
		return
	}
	check(err)
	check(yaml.Unmarshal(buf, c))
}

// save the EdgeNet configuration to the specified filed.
func (c edgenetConfig) save(file string) {
	buf, err := yaml.Marshal(&c)
	check(err)
	check(os.WriteFile(file, buf, 0644))
}

// getHostnameRoot returns the deterministic component of the hostname.
func getHostnameRoot(platform string) string {
	switch platform {
	case platforms.Azure:
		region := platforms.AzureGetMetadata("compute/location")
		return fmt.Sprintf("az-%s", region)
	case platforms.EC2:
		region := platforms.EC2GetMetadata("placement/availability-zone")
		return fmt.Sprintf("aws-%s", region)
	case platforms.GENI:
		// TODO: From slice name?
		geoIP := network.GeoIP()
		return strings.ToLower(fmt.Sprintf("geni-%s-%s", geoIP.CountryCode, geoIP.RegionCode))
	case platforms.GCP:
		region := platforms.GCPGetMetadata("instance/zone")
		region = strings.Split(region, "/")[3]
		return fmt.Sprintf("gcp-%s", region)
	case platforms.NUC:
		geoIP := network.GeoIP()
		return strings.ToLower(fmt.Sprintf("nuc-%s-%s", geoIP.CountryCode, geoIP.RegionCode))
	case platforms.SCW:
		meta := platforms.SCWGetMetadata()
		return fmt.Sprintf("scw-%s", meta.Location.ZoneID)
	default:
		geoIP := network.GeoIP()
		return strings.ToLower(fmt.Sprintf("%s-%s", geoIP.CountryCode, geoIP.RegionCode))
	}
}

// getIPv4 returns the local and public IPv4 addresses associated to the host.
func getIPv4(platform string) (net.IP, net.IP) {
	switch platform {
	case platforms.Azure:
		localIP := net.ParseIP(platforms.AzureGetMetadata("network/interface/0/ipv4/ipAddress/0/privateIpAddress"))
		publicIP := network.PublicIPv4()
		return localIP, publicIP
	case platforms.EC2:
		localIP := net.ParseIP(platforms.EC2GetMetadata("local-ipv4"))
		publicIP := network.PublicIPv4()
		return localIP, publicIP
	case platforms.GCP:
		localIP := net.ParseIP(platforms.GCPGetMetadata("instance/network-interfaces/0/ip"))
		publicIP := network.PublicIPv4()
		return localIP, publicIP
	case platforms.SCW:
		meta := platforms.SCWGetMetadata()
		localIP := net.ParseIP(meta.PrivateIP)
		publicIP := network.PublicIPv4()
		return localIP, publicIP
	default:
		localIP := network.LocalIPv4()
		publicIP := network.PublicIPv4()
		return localIP, publicIP
	}
}

func main() {
	log.Println("step=ensure-dir")
	check(os.MkdirAll(filepath.Dir(edgenetConfigFile), 0755))

	log.Println("step=load-config")
	config := edgenetConfig{}
	config.load(edgenetConfigFile)
	log.Printf("config=%+v\n", config)

	if config.Platform == "" {
		log.Println("step=detect-platform")
		config.Platform = platforms.Detect()
	}

	if config.HostnameRoot == "" {
		log.Println("step=get-hostname-root")
		config.HostnameRoot = getHostnameRoot(config.Platform)
	}

	if config.HostnameSuffix == "" {
		log.Println("step=get-hostname-suffix")
		config.HostnameSuffix = randstr.Hex(2)
	}

	if config.LocalIPv4 == nil || config.PublicIPv4 == nil {
		log.Println("step=get-ip")
		config.LocalIPv4, config.PublicIPv4 = getIPv4(config.Platform)
	}

	// https://github.com/EdgeNet-project/edgenet/issues/156
	if config.VPNIPv4 == nil || config.VPNIPv6 == nil {
		log.Println("step=get-vpn-ip")
		_, vpnNetworkV4, err := net.ParseCIDR(defaultVPNNetworkV4)
		check(err)
		_, vpnNetworkV6, err := net.ParseCIDR(defaultVPNNetworkV6)
		check(err)
		config.VPNIPv4, config.VPNIPv6 = cluster.FindVPNIPs(config.KubeconfigURL, *vpnNetworkV4, *vpnNetworkV6)
	}

	if config.VPNPrivateKey == "" {
		log.Println("step=get-vpn-private-key")
		key, err := wgtypes.GeneratePrivateKey()
		check(err)
		config.VPNPrivateKey = key.String()
	}

	if config.VPNListenPort == 0 {
		log.Println("step=get-vpn-listen-port")
		rand.Seed(time.Now().UnixNano())
		config.VPNListenPort = rand.Intn(32768) + 32768
	}

	log.Println("step=save-config")
	log.Printf("config=%+v\n", config)
	config.save(edgenetConfigFile)

	log.Println("step=set-hostname")
	hostname := fmt.Sprintf("%s-%s.edge-net.io", config.HostnameRoot, config.HostnameSuffix)
	network.SetHostname(hostname)

	// https://github.com/EdgeNet-project/edgenet/issues/156
	if config.VPNIPv4 != nil && config.VPNIPv6 != nil {
		log.Println("step=configure-vpn")
		network.InitializeVPN(vpnLinkName, config.VPNPrivateKey, config.VPNListenPort)
		network.AssignVPNIP(vpnLinkName, *config.VPNIPv4, *config.VPNIPv6)
		privateKey, err := wgtypes.ParseKey(config.VPNPrivateKey)
		check(err)
		cluster.CreateVPNPeer(config.KubeconfigURL, hostname, config.PublicIPv4, config.VPNIPv4.IP, config.VPNIPv6.IP, config.VPNListenPort, privateKey.PublicKey().String())
		// Pre-establish the tunnels before the VPNPeer controller gets started.
		peers := cluster.ListVPNPeer(config.KubeconfigURL)
		for _, peer := range peers {
			network.AddPeer(vpnLinkName, peer)
		}
	}

	var nodeIP net.IP
	if config.LocalIPv4.Equal(config.PublicIPv4) {
		nodeIP = config.PublicIPv4
	} else {
		nodeIP = config.VPNIPv4.IP
	}

	log.Println("step=set-node-ip")
	network.SetKubeletNodeIP(kubeletEnvFileDebian, nodeIP)
	network.SetKubeletNodeIP(kubeletEnvFileRedHat, nodeIP)

	log.Println("step=join-cluster")
	cluster.Join(config.KubeconfigURL, hostname, nodeIP)
}
