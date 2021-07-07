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
	"encoding/json"
	"io/ioutil"
	"log"
	"net"
	"net/http"
)

type GeoIPResponse struct {
	City        string  `json:"string"`
	CountryCode string  `json:"country_code"`
	CountryName string  `json:"country_name"`
	IP          net.IP  `json:"ip"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	RegionCode  string  `json:"region_code"`
	RegionName  string  `json:"region_name"`
	Timezone    string  `json:"time_zone"`
}

// GeoIP returns the geographical location of the requester IP address
// using an external service.
func GeoIP() GeoIPResponse {
	// NOTE: this might return an IPv6 address if the host has IPv6 connectivity.
	resp, err := http.Get("https://freegeoip.app/json/")
	check(err)
	defer resp.Body.Close()
	var geoIP GeoIPResponse
	err = json.NewDecoder(resp.Body).Decode(&geoIP)
	check(err)
	if geoIP.RegionCode == "" {
		geoIP.RegionCode = geoIP.CountryCode
	}
	return geoIP
}

// PublicIPv4 returns the public IPv4 address of the requester.
func PublicIPv4() net.IP {
	// This service is IPv4-only.
	resp, err := http.Get("https://api.ipify.org")
	if err != nil {
		// Fallback service
		resp, err = http.Get("https://ip4.seeip.org")
		check(err)
	}
	defer resp.Body.Close()
	buf, err := ioutil.ReadAll(resp.Body)
	check(err)
	return net.ParseIP(string(buf))
}

// LocalIPv4 returns the IPv4 address configured for the main network interface.
func LocalIPv4() net.IP {
	//https://stackoverflow.com/a/37382208
	conn, err := net.Dial("udp", "8.8.8.8:53")
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()
	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP
}
