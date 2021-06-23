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

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// EDIT THIS FILE!  THIS IS SCAFFOLDING FOR YOU TO OWN!
// NOTE: json tags are required.  Any new fields you add must have json tags for the fields to be serialized.

// TangServerSpec defines the desired state of TangServer
type TangServerSpec struct {
	// INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
	// Important: Run "make" to regenerate code after modifying this file

	// KeyPath is field of TangServer. It allows to specify the path where keys will be generated
	KeyPath string `json:"keypath,omitempty"`

	// KeyAmount is the amount of keys required to be deployed
	KeyAmount uint32 `json:"keyamount,omitempty"`

	// Size is the Tang Server amount to bringup
	Replicas int32 `json:"replicas"`

	// Version is the version of the TangServer to use (empty => latest)
	Version string `json:"version"`
}

// TangServerStatus defines the observed state of TangServer
type TangServerStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status

// TangServer is the Schema for the tangservers API
//+kubebuilder:subresource:status
type TangServer struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   TangServerSpec   `json:"spec,omitempty"`
	Status TangServerStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// TangServerList contains a list of TangServer
type TangServerList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []TangServer `json:"items"`
}

func init() {
	SchemeBuilder.Register(&TangServer{}, &TangServerList{})
}
