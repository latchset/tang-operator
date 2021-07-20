/*

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
// +kubebuilder:docs-gen:collapse=Apache License

package controllers

import (
	"context"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	daemonsv1alpha1 "github.com/sarroutbi/tang-operator/api/v1alpha1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// +kubebuilder:docs-gen:collapse=Imports

var _ = Describe("TangServer controller", func() {

	// Define utility constants for object names and testing timeouts/durations and intervals.
	const (
		TangserverName = "test-tangserver"
		// TODO: test why it can not be tested in non default namespace
		TangserverNamespace = "default"
	)

	Context("When Creating Simple TangServer", func() {
		It("Should be created with no error", func() {
			By("By creating a new TangServer with default specs")
			ctx := context.Background()
			tangServer := &daemonsv1alpha1.TangServer{
				ObjectMeta: metav1.ObjectMeta{
					Name:      TangserverName,
					Namespace: TangserverNamespace,
				},
			}
			Expect(k8sClient.Create(ctx, tangServer)).Should(Succeed())

			By("By checking complete empty specs are valid")
			emptyTangServer := &daemonsv1alpha1.TangServer{}
			Expect(emptyTangServer.Spec.KeyPath).Should(Equal(""))
			Expect(emptyTangServer.Spec.KeyAmount).Should(Equal(uint32(0)))
			Expect(emptyTangServer.Spec.Replicas).Should(Equal(uint32(0)))
			Expect(emptyTangServer.Spec.Image).Should(Equal(""))
			Expect(emptyTangServer.Spec.Version).Should(Equal(""))
		})
		It("Should not be created", func() {
			By("By creating a TangServer that already exist")
			ctx := context.Background()
			tangServer := &daemonsv1alpha1.TangServer{
				ObjectMeta: metav1.ObjectMeta{
					Name:      TangserverName,
					Namespace: TangserverNamespace,
				},
				Spec: daemonsv1alpha1.TangServerSpec{
					KeyPath: "/",
				},
			}
			Expect(k8sClient.Create(ctx, tangServer)).Should(Not(Succeed()))
		})
	})
})
