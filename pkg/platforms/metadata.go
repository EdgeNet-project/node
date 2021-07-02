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
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/ec2metadata"
	awssession "github.com/aws/aws-sdk-go/aws/session"
	"github.com/scaleway/scaleway-sdk-go/api/instance/v1"
	"io/ioutil"
	"net/http"
	"time"
)

func check(err error) {
	if err != nil {
		panic(err)
	}
}

func AzureGetMetadata(s string) string {
	// Azure Go SDK does not support VM Instance Metadata,
	// we do the requests manually instead.
	url := fmt.Sprintf("http://169.254.169.254/metadata/instance/%s?api-version=2020-09-01&format=text", s)
	client := http.Client{Timeout: 2 * time.Second}
	req, err := http.NewRequest("GET", url, nil)
	check(err)
	req.Header.Set("Metadata", "true")
	res, err := client.Do(req)
	defer res.Body.Close()
	check(err)
	buf, err := ioutil.ReadAll(res.Body)
	check(err)
	return string(buf)
}

func EC2GetMetadata(s string) string {
	client := http.Client{Timeout: 2 * time.Second}
	config := aws.NewConfig().WithHTTPClient(&client).WithMaxRetries(2)
	sess, err := awssession.NewSession(config)
	check(err)
	ec2meta := ec2metadata.New(sess)
	res, err := ec2meta.GetMetadata(s)
	check(err)
	return res
}

func GCPGetMetadata(s string) string {
	res, err := gcpmetadata.Get(s)
	check(err)
	return res
}

func SCWGetMetadata() instance.Metadata {
	api := instance.NewMetadataAPI()
	res, err := api.GetMetadata()
	check(err)
	return *res
}
