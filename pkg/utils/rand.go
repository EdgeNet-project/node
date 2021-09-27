package utils

import (
	"encoding/binary"
	"math/rand"
	"net"
	"time"
)

// firstLastIPv4 return the first and the last IP of an IPv4 network,
// excluding the network and the broadcast address.
func firstLastIPv4(network net.IPNet) (uint32, uint32) {
	ones, bits := network.Mask.Size()
	if bits > 32 || ones > 30 {
		panic("IPv4 network <= /30 expected")
	}
	// https://stackoverflow.com/a/60542265
	mask := binary.BigEndian.Uint32(network.Mask)
	first := binary.BigEndian.Uint32(network.IP)
	last := (first & mask) | (mask ^ 0xffffffff)
	return first + 1, last - 1
}

// TODO: Cleanup, this is horrible... :-)
func RandIPv4(network net.IPNet, excluded []net.IP) net.IP {
	excludedMap := make(map[uint32]bool)
	for _, ip := range excluded {
		excludedMap[binary.BigEndian.Uint32(ip.To4())] = true
	}
	rand.Seed(time.Now().UnixNano())
	first, last := firstLastIPv4(network)
	for i := 0; i < 1000; i++ {
		candidate := uint32(rand.Int63n(int64(last-first+1)) + int64(first))
		if _, found := excludedMap[candidate]; !found {
			ip := make(net.IP, 4)
			binary.BigEndian.PutUint32(ip, candidate)
			return ip
		}
	}
	return nil
}
