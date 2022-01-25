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

package platforms

import (
	gcpmetadata "cloud.google.com/go/compute/metadata"
	"fmt"
	"github.com/EdgeNet-project/node/pkg/utils"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/ec2metadata"
	awssession "github.com/aws/aws-sdk-go/aws/session"
	"github.com/yumaojun03/dmidecode"
	"log"
	"net/http"
	"time"
)

const (
	Azure   = "azure"
	EC2     = "ec2"
	Generic = "generic"
	GENI    = "geni"
	GCP     = "gcp"
	NUC     = "intel-nuc"
	SCW     = "scaleway"
)

// Detect returns the host platform.
// If no platform is detected, it returns PlatformGeneric.
func Detect() string {
	client := http.Client{Timeout: 2 * time.Second}

	// Azure
	log.Printf("try-detect=%s", Azure)
	url := fmt.Sprintf("http://169.254.169.254/metadata/instance/?api-version=2020-09-01&format=text")
	req, err := http.NewRequest("GET", url, nil)
	check(err)
	req.Header.Set("Metadata", "true")
	res, err := client.Do(req)
	if err == nil && res.StatusCode != 404 {
		return Azure
	}

	// OpenStack
	log.Printf("try-detect=OpenStack")
	res, err = client.Get("http://169.254.169.254/openstack")
	if err == nil && res.StatusCode != 404 {
		return Generic
	}

	// EC2
	log.Printf("try-detect=%s", EC2)
	awsconfig := aws.NewConfig().WithHTTPClient(&client).WithMaxRetries(0)
	awssess, err := awssession.NewSession(awsconfig)
	if err == nil {
		ec2meta := ec2metadata.New(awssess)
		if ec2meta.Available() {
			return EC2
		}
	}

	// GCP
	log.Printf("try-detect=%s", GCP)
	name, err := gcpmetadata.InstanceName()
	if err == nil && name != "" {
		return GCP
	}

	// GENI
	if utils.Exists("/usr/local/etc/emulab") {
		return GENI
	}

	// NUC
	log.Printf("try-detect=%s", NUC)
	dmi, err := dmidecode.New()
	if err == nil {
		sys, err := dmi.System()
		if err == nil {
			for _, el := range sys {
				if el.Family == "Intel NUC" {
					return NUC
				}
			}

		}
	}

	// SCW
	// We dot not use the Scaleway client here, since it has a very high timeout by default.
	log.Printf("try-detect=%s", SCW)
	res, err = client.Get("http://169.254.42.42/conf?format=json")
	if err == nil && res.StatusCode != 404 {
		return SCW
	}

	// Fallback
	return Generic
}
