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
	"github.com/go-logr/logr"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"

	daemonsv1alpha1 "github.com/sarroutbi/tang-operator/api/v1alpha1"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/types"
	// "k8s.io/apimachinery/pkg/util/intstr"
	_ "k8s.io/client-go/plugin/pkg/client/auth" // Check if really necessary
	"reflect"
)

const DEFAULT_APP_IMAGE = "registry.redhat.io/rhel8/tang"
const DEFAULT_APP_VERSION = "latest"

// TangServerReconciler reconciles a TangServer object
type TangServerReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=daemons.redhat,resources=tangservers,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=daemons.redhat,resources=tangservers/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=daemons.redhat,resources=tangservers/finalizers,verbs=update

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// TODO(user): Modify the Reconcile function to compare the state specified by
// the TangServer object against the actual cluster state, and then
// perform operations to make the cluster state reflect the state specified by
// the user.
//
// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.8.3/pkg/reconcile
//+kubebuilder:rbac:groups=apps.redhat,resources=tangservers,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=apps.redhat,resources=tangservers/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=services,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=pods,verbs=get;list;watch
func (r *TangServerReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	l := log.FromContext(ctx)

	// your logic here
	tangservers := &daemonsv1alpha1.TangServer{}
	err := r.Get(ctx, req.NamespacedName, tangservers)
	if err != nil {
		if errors.IsNotFound(err) {
			l.Info("TangServer resource not found")
			return ctrl.Result{}, nil
		}
	}

	// Check if the CR is marked to be deleted
	isInstanceMarkedToBeDeleted := tangservers.GetDeletionTimestamp() != nil
	if isInstanceMarkedToBeDeleted {
		l.Info("Instance marked for deletion, running finalizers")
		// TODO: Implement finalizers
	}

	// Reconcile Deployment object
	result, err := r.reconcileDeployment(tangservers, l)
	if err != nil {
		return result, err
	}
	// Reconcile Service object
	result, err = r.reconcileService(tangservers, l)
	if err != nil {
		return result, err
	}
	return ctrl.Result{}, err
}

// checkDeploymentImage returns wether the deployment image is different or not
func checkDeploymentImage(current *appsv1.Deployment, desired *appsv1.Deployment) bool {
	for _, curr := range current.Spec.Template.Spec.Containers {
		for _, des := range desired.Spec.Template.Spec.Containers {
			// Only compare the images of containers with the same name
			if curr.Name == des.Name {
				if curr.Image != des.Image {
					return true
				}
			}
		}
	}
	return false
}

// isDeploymentReady returns a true bool if the deployment has all its pods ready
func isDeploymentReady(deployment *appsv1.Deployment) bool {
	configuredReplicas := deployment.Status.Replicas
	readyReplicas := deployment.Status.ReadyReplicas
	deploymentReady := false
	if configuredReplicas == readyReplicas {
		deploymentReady = true
	}
	return deploymentReady
}

// newDeploymentForCR returns a new deployment without replicas configured
func newDeploymentForCR(cr *daemonsv1alpha1.TangServer, log logr.Logger) *appsv1.Deployment {
	labels := map[string]string{
		"app": cr.Name,
	}
	replicas := cr.Spec.Replicas
	appImage := DEFAULT_APP_IMAGE
	appVersion := DEFAULT_APP_VERSION
	if cr.Spec.Image != "" {
		appImage = cr.Spec.Image
	}
	if cr.Spec.Version != "" {
		appVersion = cr.Spec.Version
	}
	// TODO:Check if application version exists and provide app name with
	// configuration value
	containerImage := appImage + ":" + appVersion
	log.Info("Container Image Description", "Image File", containerImage, "Version", appVersion)
	probe := &corev1.Probe{
		Handler: corev1.Handler{
			Exec: &corev1.ExecAction{
				Command: []string{
					"/usr/bin/tangd-health-check",
				},
			},
		},
		InitialDelaySeconds: 5,
		TimeoutSeconds:      2,
		PeriodSeconds:       15,
	}
	return &appsv1.Deployment{
		TypeMeta: metav1.TypeMeta{
			APIVersion: "apps/v1",
			Kind:       "Deployment",
		},
		ObjectMeta: metav1.ObjectMeta{
			Name:      "tsdp-" + cr.Name,
			Namespace: cr.Namespace,
			Labels:    labels,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: labels,
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: labels,
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Image: containerImage,
							Name:  "tangserver",
							Ports: []corev1.ContainerPort{
								{
									ContainerPort: 8080,
									Name:          "tangserver",
								},
							},
							LivenessProbe:  probe,
							ReadinessProbe: probe,
						},
					},
					// TODO: Check how to change Restart Policy
					RestartPolicy: corev1.RestartPolicyAlways,
				},
			},
		},
	}
}

func (r *TangServerReconciler) reconcileDeployment(cr *daemonsv1alpha1.TangServer, log logr.Logger) (ctrl.Result, error) {
	// TODO: Reconcile Deployment
	// Define a new Deployment object
	log.Info("reconcileDeployment")
	deployment := newDeploymentForCR(cr, log)

	// Set ReverseWordsApp instance as the owner and controller of the Deployment
	if err := ctrl.SetControllerReference(cr, deployment, r.Scheme); err != nil {
		return ctrl.Result{}, err
	}

	// Check if this Deployment already exists
	deploymentFound := &appsv1.Deployment{}
	err := r.Get(context.Background(), types.NamespacedName{Name: deployment.Name, Namespace: deployment.Namespace}, deploymentFound)
	if err != nil && errors.IsNotFound(err) {
		log.Info("Creating a new Deployment", "Deployment.Namespace", deployment.Namespace, "Deployment.Name", deployment.Name)
		err = r.Create(context.Background(), deployment)
		if err != nil {
			return ctrl.Result{}, err
		}
		// Requeue the object to update its status
		return ctrl.Result{Requeue: true}, nil
	} else if err != nil {
		return ctrl.Result{}, err
	} else {
		// Deployment already exists
		log.Info("Deployment already exists", "Deployment.Namespace", deploymentFound.Namespace, "Deployment.Name", deploymentFound.Name)
	}

	// Ensure deployment replicas match the desired state
	if !reflect.DeepEqual(deploymentFound.Spec.Replicas, deployment.Spec.Replicas) {
		log.Info("Current deployment do not match Tang Server configured Replicas")
		// Update the replicas
		err = r.Update(context.Background(), deployment)
		if err != nil {
			log.Error(err, "Failed to update Deployment.", "Deployment.Namespace", deploymentFound.Namespace, "Deployment.Name", deploymentFound.Name)
			return ctrl.Result{}, err
		}
	}
	// Ensure deployment container image match the desired state, returns true if deployment needs to be updated
	if checkDeploymentImage(deploymentFound, deployment) {
		log.Info("Current deployment image version do not match TangServers configured version")
		// Update the image
		err = r.Update(context.Background(), deployment)
		if err != nil {
			log.Error(err, "Failed to update Deployment.", "Deployment.Namespace", deploymentFound.Namespace, "Deployment.Name", deploymentFound.Name)
			return ctrl.Result{}, err
		}
	}

	// Check if the deployment is ready
	deploymentReady := isDeploymentReady(deploymentFound)
	if !deploymentReady {
		log.Info("Deployment not ready", "Deployment.Namespace", deploymentFound.Namespace, "Deployment.Name", deploymentFound.Name)
	}

	// Create list options for listing deployment pods
	podList := &corev1.PodList{}
	listOpts := []client.ListOption{
		client.InNamespace(deploymentFound.Namespace),
		client.MatchingLabels(deploymentFound.Labels),
	}
	// List the pods for this ReverseWordsApp deployment
	err = r.List(context.Background(), podList, listOpts...)
	if err != nil {
		log.Error(err, "Failed to list Pods.", "Deployment.Namespace", deploymentFound.Namespace, "Deployment.Name", deploymentFound.Name)
		return ctrl.Result{}, err
	}
	// TODO: Get running Pods
	// podNames := getRunningPodNames(podList.Items)
	// if deploymentReady {
	// 	// Update the status to ready
	// 	cr.Status.AppPods = podNames
	// 	cr.SetCondition(appsv1alpha1.ConditionTypeReverseWordsDeploymentNotReady, false)
	// 	cr.SetCondition(appsv1alpha1.ConditionTypeReady, true)
	// } else {
	// 	// Update the status to not ready
	// 	cr.Status.AppPods = podNames
	// 	cr.SetCondition(appsv1alpha1.ConditionTypeReverseWordsDeploymentNotReady, true)
	// 	cr.SetCondition(appsv1alpha1.ConditionTypeReady, false)
	// }
	// TODO: Reconcile the new status for the instance
	// cr, err = r.updateTangServerStatus(cr, log)
	// if err != nil {
	// 	log.Error(err, "Failed to update ReverseWordsApp Status.")
	// 	return ctrl.Result{}, err
	// }
	// Deployment reconcile finished
	return ctrl.Result{}, nil
}

func (r *TangServerReconciler) reconcileService(cr *daemonsv1alpha1.TangServer, log logr.Logger) (ctrl.Result, error) {
	// TODO: Reconcile Service
	return ctrl.Result{}, nil
}

// SetupWithManager sets up the controller with the Manager.
func (r *TangServerReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&daemonsv1alpha1.TangServer{}).
		Owns(&appsv1.Deployment{}).
		Owns(&corev1.Service{}).
		// TODO: try to enable next option:
		// WithOptions(ctrl.Options{MaxConcurrentReconciles: 2}).
		Complete(r)
}
