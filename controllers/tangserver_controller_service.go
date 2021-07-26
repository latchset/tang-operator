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
	daemonsv1alpha1 "github.com/sarroutbi/tang-operator/api/v1alpha1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// constants to use
const (
	DEFAULT_SERVICE_PORT   = 8080
	DEFAULT_SERVICE_TYPE   = "Service"
	DEFAULT_API_VERSION    = "v1"
	DEFAULT_SERVICE_PREFIX = "service-"
	DEFAULT_SERVICE_PROTO  = "http"
)

// getService function returns correctly created service
func getService(tangserver *daemonsv1alpha1.TangServer) *corev1.Service {
	labels := map[string]string{
		"app": tangserver.Name,
	}
	servicePort := uint32(tangserver.Spec.ServiceListenPort)
	if 0 == servicePort {
		servicePort = DEFAULT_SERVICE_PORT
	}
	return &corev1.Service{
		TypeMeta: metav1.TypeMeta{
			APIVersion: DEFAULT_API_VERSION,
			Kind:       DEFAULT_SERVICE_TYPE,
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      DEFAULT_SERVICE_PREFIX + tangserver.Name,
			Namespace: tangserver.Namespace,
			Labels:    labels,
		},
		Spec: corev1.ServiceSpec{
			Type:     corev1.ServiceTypeLoadBalancer,
			Selector: labels,
			Ports: []corev1.ServicePort{
				{
					Name: DEFAULT_SERVICE_PROTO,
					Port: int32(servicePort),
				},
			},
		},
	}
}
