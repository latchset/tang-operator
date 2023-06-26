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
	"context"
	"strings"

	daemonsv1alpha1 "github.com/latchset/tang-operator/api/v1alpha1"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/controller-runtime/pkg/log"
)

var _ = Describe("TangServer controller service", func() {

	// Define utility constants for object names
	const (
		TangServerName = "test-tangserver-service"
		// TODO: test why it can not be tested in non default namespace
		TangServerNamespace             = "default"
		TangServerResourceVersion       = "1"
		TangServerTestServiceListenPort = 8090
		TangServerTestIp                = "1.2.3.4"
		TangServerTestHostname          = "mylocalhost"
	)

	Context("When Creating TangServer", func() {
		It("Should be created with default listen port", func() {
			By("By creating a new TangServer with empty listen port")
			ctx := context.Background()
			tangServer := &daemonsv1alpha1.TangServer{
				ObjectMeta: metav1.ObjectMeta{
					Name:      TangServerName,
					Namespace: TangServerNamespace,
				},
				Spec: daemonsv1alpha1.TangServerSpec{},
			}
			Expect(k8sClient.Create(ctx, tangServer)).Should(Succeed())
			SetLogInstance(log.FromContext(ctx))
			service := getService(tangServer)
			Expect(service, Not(nil))
			Expect(service.TypeMeta.Kind, DEFAULT_SERVICE_TYPE)
			Expect(service.ObjectMeta.Name, getDefaultName(tangServer))
			Expect(service.Spec.Ports[0].Port, DEFAULT_SERVICE_PORT)
			err := k8sClient.Delete(ctx, tangServer)
			Expect(err, nil)
		})
		It("Should be created with specific service listen port", func() {
			By("By creating a new TangServer with non empty listen port")
			ctx := context.Background()
			tangServer := &daemonsv1alpha1.TangServer{
				ObjectMeta: metav1.ObjectMeta{
					Name:      TangServerName,
					Namespace: TangServerNamespace,
				},
				Spec: daemonsv1alpha1.TangServerSpec{
					ServiceListenPort: TangServerTestServiceListenPort,
				},
			}
			Expect(k8sClient.Create(ctx, tangServer)).Should(Succeed())
			SetLogInstance(log.FromContext(ctx))
			service := getService(tangServer)
			Expect(service, Not(nil))
			Expect(service.TypeMeta.Kind, DEFAULT_SERVICE_TYPE)
			Expect(service.ObjectMeta.Name, getDefaultName(tangServer))
			Expect(service.Spec.Ports[0].Port, TangServerTestServiceListenPort)
			err := k8sClient.Delete(ctx, tangServer)
			Expect(err, nil)
		})
		It("Should return a correct service url and related", func() {
			By("By creating a new TangServer")
			ctx := context.Background()
			tangServer := &daemonsv1alpha1.TangServer{
				ObjectMeta: metav1.ObjectMeta{
					Name:      TangServerName,
					Namespace: TangServerNamespace,
				},
				Spec: daemonsv1alpha1.TangServerSpec{
					ServiceListenPort: TangServerTestServiceListenPort,
				},
			}
			Expect(k8sClient.Create(ctx, tangServer)).Should(Succeed())
			serviceUrl := getServiceUrl(tangServer)
			Expect(len(serviceUrl) > 0)
			serviceIpUrl := getServiceIpUrl(tangServer, TangServerTestIp)
			Expect(len(serviceIpUrl) > 0)
			Expect(strings.Contains(serviceIpUrl, TangServerTestIp))
			loadBalancer := corev1.LoadBalancerIngress{
				Hostname: TangServerTestHostname,
			}
			serviceIpExternalServiceUrl := getExternalServiceUrl(tangServer, loadBalancer)
			Expect(strings.Contains(serviceIpExternalServiceUrl, TangServerTestHostname))
			loadBalancer = corev1.LoadBalancerIngress{
				IP: TangServerTestIp,
			}
			serviceIpExternalServiceUrl = getExternalServiceUrl(tangServer, loadBalancer)
			Expect(strings.Contains(serviceIpExternalServiceUrl, TangServerTestIp))
			err := k8sClient.Delete(ctx, tangServer)
			Expect(err, nil)
		})
	})
})
