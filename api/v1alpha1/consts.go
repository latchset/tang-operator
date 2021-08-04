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

type TangServerStatusError string

const (
	NoError              TangServerStatusError = "No Error"
	CreateError          TangServerStatusError = "Error on pod creation"
	DefaultTestName      string                = "tangserver-test"
	DefaultTestNameNoUID string                = "tangserver-test-nouid"
	// TODO: test why it can not be tested in non default namespace
	DefaultTestNamespace string = "default"
)
