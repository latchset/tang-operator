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
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	daemonsv1alpha1 "github.com/sarroutbi/tang-operator/api/v1alpha1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

var _ = Describe("TangServer controller deployment", func() {

	// Define utility constants for object names
	const (
		TangserverName = "test-tangserver-deployment"
		// TODO: test why it can not be tested in non default namespace
		TangserverNamespace         = "default"
		TangserverResourceVersion   = "1"
		TangServerTestReplicaAmount = 4
	)

	Context("When Creating TangServer", func() {
		It("Should be created with default replica amount", func() {
			By("By creating a new TangServer with empty replica amount")
			ctx := context.Background()
			tangServer := &daemonsv1alpha1.TangServer{
				ObjectMeta: metav1.ObjectMeta{
					Name:      TangserverName,
					Namespace: TangserverNamespace,
				},
				Spec: daemonsv1alpha1.TangServerSpec{},
			}
			Expect(k8sClient.Create(ctx, tangServer)).Should(Succeed())
			deployment := getDeployment(tangServer)
			Expect(deployment, Not(nil))
			Expect(deployment.TypeMeta.Kind, DEFAULT_DEPLOYMENT_TYPE)
			Expect(deployment.ObjectMeta.Name, getDefaultName(tangServer))
			Expect(deployment.Spec.Replicas, DEFAULT_REPLICA_AMOUNT)
			Expect(deployment.Spec.Template, Not(nil))
			k8sClient.Delete(ctx, tangServer)
		})
		It("Should be created with specific replica amount", func() {
			By("By creating a new TangServer with non empty replicas")
			ctx := context.Background()
			tangServer := &daemonsv1alpha1.TangServer{
				ObjectMeta: metav1.ObjectMeta{
					Name:      TangserverName,
					Namespace: TangserverNamespace,
				},
				Spec: daemonsv1alpha1.TangServerSpec{
					Replicas: TangServerTestReplicaAmount,
				},
			}
			Expect(k8sClient.Create(ctx, tangServer)).Should(Succeed())
			deployment := getDeployment(tangServer)
			Expect(deployment, Not(nil))
			Expect(deployment.TypeMeta.Kind, DEFAULT_DEPLOYMENT_TYPE)
			Expect(deployment.ObjectMeta.Name, getDefaultName(tangServer))
			Expect(deployment.Spec.Replicas, TangServerTestReplicaAmount)
			Expect(deployment.Spec.Template, Not(nil))
			k8sClient.Delete(ctx, tangServer)
		})
	})
})
