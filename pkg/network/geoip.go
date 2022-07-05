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
	Status      string  `json:"success"`
	Country     string  `json:"country"`
	CountryCode string  `json:"countryCode"`
	Region      string  `json:"region"`
	RegionName  string  `json:"regionName"`
	City        string  `json:"city"`
	Zip         string  `json:"zip"`
	Lat         float64 `json:"lat"`
	Lon         float64 `json:"lon"`
	Timezone    string  `json:"timezone"`
	ISP         string  `json:"isp"`
	Org         string  `json:"org"`
	As          string  `json:"as"`
	Query       string  `json:"query"`
}

// GeoIP returns the geographical location of the requester IP address
// using an external service.
func GeoIP() GeoIPResponse {
	// NOTE: this might return an IPv6 address if the host has IPv6 connectivity.
	resp, err := http.Get("http://ip-api.com/json/")
	check(err)
	defer resp.Body.Close()
	var geoIP GeoIPResponse
	err = json.NewDecoder(resp.Body).Decode(&geoIP)
	check(err)
	if geoIP.CountryCode == "" {
		geoIP.CountryCode = "na"
	}
	if geoIP.Region == "" {
		geoIP.Region = geoIP.CountryCode
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
