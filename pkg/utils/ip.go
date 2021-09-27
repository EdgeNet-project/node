package utils

import (
	"fmt"
	"net"
)

// IPWithMask stores an IP address and its associated network mask.
// It _semantically_ differs from IPNet which stores a network address.
type IPWithMask struct {
	IP   net.IP
	Mask net.IPMask
}

func (IP IPWithMask) String() string {
	ones, _ := IP.Mask.Size()
	return fmt.Sprintf("%s/%d", IP.IP.String(), ones)
}

func (IP *IPWithMask) FromString(s string) error {
	ip, ipnet, err := net.ParseCIDR(s)
	if err == nil {
		IP.IP = ip
		IP.Mask = ipnet.Mask
	}
	return err
}

func (IP IPWithMask) MarshalYAML() (interface{}, error) {
	return IP.String(), nil
}

func (IP *IPWithMask) UnmarshalYAML(unmarshal func(interface{}) error) error {
	s := ""
	err := unmarshal(&s)
	if err != nil {
		return err
	}
	return IP.FromString(s)
}
