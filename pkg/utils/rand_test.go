package utils

import (
	"net"
	"testing"
)

func Test_firstLastIPv4(t *testing.T) {
	type args struct {
		network net.IPNet
	}
	_, net1, _ := net.ParseCIDR("0.0.0.0/0")
	_, net2, _ := net.ParseCIDR("192.168.142.0/24")
	tests := []struct {
		name  string
		args  args
		want  uint32
		want1 uint32
	}{
		{"0.0.0.0/0", args{*net1}, 1, 4294967294},
		{"192.168.142.0/24", args{*net2}, 3232271873, 3232272126},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, got1 := firstLastIPv4(tt.args.network)
			if got != tt.want {
				t.Errorf("firstLastIPv4() got = %v, want %v", got, tt.want)
			}
			if got1 != tt.want1 {
				t.Errorf("firstLastIPv4() got1 = %v, want %v", got1, tt.want1)
			}
		})
	}
}

func Test_RandIPv4(t *testing.T) {
	type args struct {
		network  net.IPNet
		excluded []net.IP
	}
	_, net1, _ := net.ParseCIDR("192.168.142.0/30")
	tests := []struct {
		name string
		args args
		want net.IP
	}{
		{"192.168.142.0/30",
			args{*net1, []net.IP{net.ParseIP("192.168.142.2")}},
			net.ParseIP("192.168.142.1"),
		},
		{"192.168.142.0/30",
			args{*net1, []net.IP{net.ParseIP("192.168.142.1")}},
			net.ParseIP("192.168.142.2"),
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := RandIPv4(tt.args.network, tt.args.excluded); !got.Equal(tt.want) {
				t.Errorf("randIPv4() = %v, want %v", got, tt.want)
			}
		})
	}
}
