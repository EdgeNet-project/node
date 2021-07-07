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
	"github.com/EdgeNet-project/edgenet/pkg/generated/clientset/versioned"
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

// Join the node to the cluster specified by configURL.
// It ignores AlreadyExists errors when creating the NodeContribution object.
func Join(configURL string, externalIP net.IP, hostname string) {
	config, err := configFromUrl(configURL)
	check(err)
	clientset, err := versioned.NewForConfig(config)
	check(err)
	nodeContributionClient := clientset.CoreV1alpha().NodeContributions()
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
	_, err = nodeContributionClient.Create(context.TODO(), nodeContribution.DeepCopy(), metav1.CreateOptions{})
	if errors.IsAlreadyExists(err) {
		log.Print("node-contribution-status=already-exists")
	} else if err != nil {
		panic(err)
	} else {
		log.Print("node-contribution-status=created")
	}
}
