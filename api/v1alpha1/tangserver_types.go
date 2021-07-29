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
	// +operator-sdk:csv:customresourcedefinitions:type=spec,displayName="Key Path"
	// +optional
	KeyPath string `json:"keypath,omitempty"`

	// Replicas is the Tang Server amount to bringup
	Replicas uint32 `json:"replicas"`

	// Image is the base container image of the TangServer to use
	// +operator-sdk:csv:customresourcedefinitions:type=spec,displayName="Image of Container to deploy"
	// +optional
	Image string `json:"image,omitempty"`

	// Version is the version of the TangServer container to use
	// (empty => latest)
	// +operator-sdk:csv:customresourcedefinitions:type=spec,displayName="Image Version of Container to deploy"
	// +optional
	Version string `json:"version,omitempty"`

	// HealthScript is the script to run for healthiness/readiness
	// +operator-sdk:csv:customresourcedefinitions:type=spec,displayName="Health Script to execute"
	// +optional
	HealthScript string `json:"healthscript,omitempty"`

	// PodListenPort is the port where pods will listen for traffic
	// +operator-sdk:csv:customresourcedefinitions:type=spec,displayName="Port where Pod will listen "
	// +optional
	PodListenPort uint32 `json:"podlistenport,omitempty"`

	// Secret is the secret name to use to download image appropriately
	// +operator-sdk:csv:customresourcedefinitions:type=spec,displayName="Secret name to use for container download"
	// +optional
	Secret string `json:"secret,omitempty"`

	// ServiceListenPort is the port where service will listen for traffic
	// +operator-sdk:csv:customresourcedefinitions:type=spec,displayName="Port where service will listen"
	// +optional
	ServiceListenPort uint32 `json:"servicelistenport,omitempty"`
}

// TangServerStatus defines the observed state of TangServer
type TangServerStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file
	// +operator-sdk:csv:customresourcedefinitions:type=status,xDescriptors="urn:alm:descriptor:text",displayName="Tang Server Error"
	TangServerError TangServerStatusError `json:"tangServerError,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
// +kubebuilder:printcolumn:name="KeyPath",type="string",JSONPath=".spec.keypath",description="Directory to use for key generation"
// +kubebuilder:printcolumn:name="Replicas",type="integer",JSONPath=".spec.replicas",description="Replicas to launch for a particular deployment"
// +kubebuilder:printcolumn:name="Image",type="string",JSONPath=".spec.replicas",description="Container Image to use"
// +kubebuilder:printcolumn:name="Version",type="string",JSONPath=".spec.version",description="Version of the Container Image to use"
// +kubebuilder:printcolumn:name="HealthScript",type="string",JSONPath=".spec.healthscript",description="Health Script to execute"
// +kubebuilder:printcolumn:name="PodListenPort",type="integer",JSONPath=".spec.podlistenport",description="Port where each Pod will listen"
// +kubebuilder:printcolumn:name="Secret",type="string",JSONPath=".spec.secret",description="Secret name to use in case it is necessary"
// +kubebuilder:printcolumn:name="ServiceListenPort",type="integer",JSONPath=".spec.podlistenport",description="Port where each Service will listen"
// TangServer is the Schema for the tangservers API
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
