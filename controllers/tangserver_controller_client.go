/*
Copyright 2021.

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

package controllers

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	core_v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/remotecommand"
)

// GetClusterClientConfig first tries to get a config object which uses the service account kubernetes gives to pods,
// if it is called from a process running in a kubernetes environment.
// Otherwise, it tries to build config from a default kubeconfig filepath if it fails, it fallback to the default config.
// Once it get the config, it returns the same.
func GetClusterClientConfig() (*rest.Config, error) {
	config, err := rest.InClusterConfig()
	if err != nil {
		err1 := err
		kubeconfig := filepath.Join(os.Getenv("HOME"), ".kube", "config")
		config, err = clientcmd.BuildConfigFromFlags("", kubeconfig)
		if err != nil {
			err = fmt.Errorf("InClusterConfig as well as BuildConfigFromFlags Failed. Error in InClusterConfig: %+v\nError in BuildConfigFromFlags: %+v", err1, err)
			return nil, err
		}
	}
	return config, nil
}

// GetClientsetFromClusterConfig takes REST config and Create a clientset based on that and return that clientset
func GetClientsetFromClusterConfig(config *rest.Config) (*kubernetes.Clientset, error) {
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		err = fmt.Errorf("failed creating clientset. Error: %+v", err)
		return nil, err
	}

	return clientset, nil
}

// GetClusterClientset first tries to get a config object which uses the service account kubernetes gives to pods,
// if it is called from a process running in a kubernetes environment.
// Otherwise, it tries to build config from a default kubeconfig filepath if it fails, it fallback to the default config.
// Once it get the config, it creates a new Clientset for the given config and returns the clientset.
func GetClusterClientset() (*kubernetes.Clientset, error) {
	config, err := GetClusterClientConfig()
	if err != nil {
		return nil, err
	}

	return GetClientsetFromClusterConfig(config)
}

// GetRESTClient first tries to get a config object which uses the service account kubernetes gives to pods,
// if it is called from a process running in a kubernetes environment.
// Otherwise, it tries to build config from a default kubeconfig filepath if it fails, it fallback to the default config.
// Once it get the config, it
func GetRESTClient() (*rest.RESTClient, error) {
	config, err := GetClusterClientConfig()
	if err != nil {
		return &rest.RESTClient{}, err
	}

	return rest.RESTClientFor(config)
}

// podCommandExec uninterractively exec to the pod with the command specified.
// :param string command: list of the str which specify the command.
// :param string pod_name: Pod name
// :param string namespace: namespace of the Pod.
// :param io.Reader stdin: Standard Input if necessary, otherwise `nil`
// :return: string: Output of the command. (STDOUT)
//          string: Errors. (STDERR)
//           error: If any error has occurred otherwise `nil`
func podCommandExec(command, containerName, podName, namespace string, stdin io.Reader) (string, string, error) {
	config, err := GetClusterClientConfig()
	if err != nil {
		return "", "", err
	}
	if config == nil {
		err = fmt.Errorf("nil config")
		return "", "", err
	}

	clientset, err := GetClientsetFromClusterConfig(config)
	if err != nil {
		return "", "", err
	}
	if clientset == nil {
		err = fmt.Errorf("nil clientset")
		return "", "", err
	}

	req := clientset.CoreV1().RESTClient().Post().
		Resource("pods").
		Name(podName).
		Namespace(namespace).
		SubResource("exec")
	scheme := runtime.NewScheme()
	if err := core_v1.AddToScheme(scheme); err != nil {
		return "", "", fmt.Errorf("error adding to scheme: %v", err)
	}

	parameterCodec := runtime.NewParameterCodec(scheme)
	req.VersionedParams(&core_v1.PodExecOptions{
		Command:   strings.Fields(command),
		Container: containerName,
		Stdin:     stdin != nil,
		Stdout:    true,
		Stderr:    true,
		TTY:       false,
	}, parameterCodec)

	exec, spdyerr := remotecommand.NewSPDYExecutor(config, "POST", req.URL())
	if spdyerr != nil {
		return "", "", fmt.Errorf("error while creating Executor: %v, Command: %s", err, strings.Fields(command))
	}

	var stdout, stderr bytes.Buffer
	err = exec.Stream(remotecommand.StreamOptions{
		Stdin:  stdin,
		Stdout: &stdout,
		Stderr: &stderr,
		Tty:    false,
	})
	if err != nil {
		return "", "", fmt.Errorf("error in Stream: %v, Command: %s", err, strings.Fields(command))
	}

	return stdout.String(), stderr.String(), nil
}
