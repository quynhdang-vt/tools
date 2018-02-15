package main

import (
	"flag"
	"fmt"
	"net"
)

func getMacAddr() ([]string, error) {
	ifas, err := net.Interfaces()
	if err != nil {
		return nil, err
	}
	var as []string
	fmt.Println("Getting MAC addresses:")
	for _, ifa := range ifas {
		fmt.Printf("%s\t", ifa.Name)
		a := ifa.HardwareAddr.String()
		addrs, _ := ifa.Addrs()
		if a != "" {
			as = append(as, a)
			fmt.Printf("%s, ", a)
		}
		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			// process IP address
			fmt.Printf("IP: %s, ", ip.String())
		}
		fmt.Println()
	}

	return as, nil
}

func main() {
	get_mac := flag.Bool("getmac", false, "Getting mac addresses")

	flag.Parse()
	if *get_mac {
		getMacAddr()
	}
}
