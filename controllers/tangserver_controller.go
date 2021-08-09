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
	"crypto/sha256"
	"fmt"
	"github.com/go-logr/logr"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"math/rand"
	"os"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"

	daemonsv1alpha1 "github.com/sarroutbi/tang-operator/api/v1alpha1"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"

	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/types"
	_ "k8s.io/client-go/plugin/pkg/client/auth" // Check if really necessary
	"reflect"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
)

// Finalizer for tang server
const DEFAULT_TANG_FINALIZER = "finalizer.daemons.tangserver.redhat.com"

// TangServerReconciler reconciles a TangServer object
type TangServerReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

// contains returns true if a string is found on a slice
func contains(hayjack []string, needle string) bool {
	for _, n := range hayjack {
		if n == needle {
			return true
		}
	}
	return false
}

// finalizeTangServerApp runs required tasks before deleting the objects owned by the CR
func (r *TangServerReconciler) finalizeTangServer(log logr.Logger, cr *daemonsv1alpha1.TangServer) error {
	// TODO(user): Add the cleanup steps that the operator
	// needs to do before the CR can be deleted. Examples
	// of finalizers include performing backups and deleting
	// resources that are not owned by this CR, like a PVC.
	log.Info("Successfully finalized TangServer")
	return nil
}

// isInstanceMarkedToBeDeleted checks if deletion has been initialized for tang server
func isInstanceMarkedToBeDeleted(tangserver *daemonsv1alpha1.TangServer) bool {
	return tangserver.GetDeletionTimestamp() != nil
}

//dumpToErrFile allows dumping string to error file
func dumpToErrFile(msg string) {
	f, err := os.OpenFile("/tmp/tangserver-error", os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
	if err != nil {
		panic(err)
	}
	defer f.Close()
	if _, err = f.WriteString(msg); err != nil {
		panic(err)
	}
}

// checkCRReadyForDeletion will check if CR can be deleted appropriately
func (r *TangServerReconciler) checkCRReadyForDeletion(ctx context.Context, tangserver *daemonsv1alpha1.TangServer) (ctrl.Result, error) {
	l := log.FromContext(ctx)
	if contains(tangserver.GetFinalizers(), DEFAULT_TANG_FINALIZER) {
		// Run the finalizer logic
		err := r.finalizeTangServer(l, tangserver)
		if err != nil {
			// Don't remove the finalizer if we failed to finalize the object
			return ctrl.Result{}, err
		}
		l.Info("TangServer finalizers completed")
		// Remove finalizer once the finalizer logic has run
		controllerutil.RemoveFinalizer(tangserver, DEFAULT_TANG_FINALIZER)
		err = r.Update(ctx, tangserver)
		if err != nil {
			// If the object update fails, requeue
			return ctrl.Result{}, err
		}
	}
	l.Info("TangServer can be deleted now")
	return ctrl.Result{}, nil
}

// getSHA256 returns a random SHA256 number
func getSHA256() string {
	data := make([]byte, 10)
	for i := range data {
		data[i] = byte(rand.Intn(256))
	}
	sha := fmt.Sprintf("%x", sha256.Sum256(data))
	return sha
}

// updateUID allows to set a UID for those cases where it is not set (i.e.:running on test infra)
func updateUID(cr *daemonsv1alpha1.TangServer, req ctrl.Request) {
	// Ugly hack to update UID for test to run appropriately
	if req.NamespacedName.Name == daemonsv1alpha1.DefaultTestName {
		cr.ObjectMeta.UID = types.UID(getSHA256())
	}
}

//+kubebuilder:rbac:groups=daemons.redhat.com,resources=tangservers,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=daemons.redhat.com,resources=tangservers/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=daemons.redhat.com,resources=tangservers/finalizers,verbs=update
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=services,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=pods,verbs=get;list;watch

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
func (r *TangServerReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	l := log.FromContext(ctx)

	// your logic here
	tangserver := &daemonsv1alpha1.TangServer{
		ObjectMeta: metav1.ObjectMeta{
			Namespace: req.NamespacedName.Namespace,
			Name:      req.NamespacedName.Name,
		},
	}
	updateUID(tangserver, req)

	err := r.Get(ctx, req.NamespacedName, tangserver)
	if err != nil {
		if errors.IsNotFound(err) {
			l.Info("TangServer resource not found")
			return ctrl.Result{}, nil
		}
	}

	// Check if the CR is marked to be deleted
	if isInstanceMarkedToBeDeleted(tangserver) {
		l.Info("Instance marked for deletion, running finalizers")
		return r.checkCRReadyForDeletion(ctx, tangserver)
	}

	// Reconcile Deployment object
	result, err := r.reconcileDeployment(tangserver, l)
	if err != nil {
		l.Error(err, "Error on deployment reconciliation", "Error:", err.Error())
		dumpToErrFile("Error on deployment reconciliation, Error:" + err.Error() + "\n")
		return result, err
	}
	// Reconcile Service object
	result, err = r.reconcileService(tangserver, l)
	if err != nil {
		l.Error(err, "Error on service reconciliation")
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

// reconcileDeployment creates deployment appropriate for this CR
func (r *TangServerReconciler) reconcileDeployment(cr *daemonsv1alpha1.TangServer, log logr.Logger) (ctrl.Result, error) {
	// TODO: Reconcile Deployment
	// Define a new Deployment object
	log.Info("reconcileDeployment")
	deployment := getDeployment(cr)

	cr.Status.TangServerError = daemonsv1alpha1.NoError

	// Set tangserver instance as the owner and controller of the Deployment
	if err := ctrl.SetControllerReference(cr, deployment, r.Scheme); err != nil {
		cr.Status.TangServerError = daemonsv1alpha1.CreateError
		return ctrl.Result{}, err
	}

	// Check if this Deployment already exists
	deploymentFound := &appsv1.Deployment{}
	err := r.Get(context.Background(), types.NamespacedName{Name: deployment.Name, Namespace: deployment.Namespace}, deploymentFound)
	if err != nil && errors.IsNotFound(err) {
		log.Info("Creating a new Deployment", "Deployment.Namespace", deployment.Namespace, "Deployment.Name", deployment.Name)
		err = r.Create(context.Background(), deployment)
		if err != nil {
			cr.Status.TangServerError = daemonsv1alpha1.CreateError
			return ctrl.Result{}, err
		}
		// Requeue the object to update its status
		return ctrl.Result{Requeue: true}, nil
	} else if err != nil {
		cr.Status.TangServerError = daemonsv1alpha1.CreateError
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
	// List the pods for this deployment
	err = r.List(context.Background(), podList, listOpts...)
	if err != nil {
		log.Error(err, "Failed to list Pods.", "Deployment.Namespace", deploymentFound.Namespace, "Deployment.Name", deploymentFound.Name)
		return ctrl.Result{}, err
	}
	// Deployment reconcile finished
	return ctrl.Result{}, nil
}

func (r *TangServerReconciler) reconcileService(cr *daemonsv1alpha1.TangServer, log logr.Logger) (ctrl.Result, error) {
	service := getService(cr)

	// Set TangServer instance as the owner and controller of the Service
	if err := controllerutil.SetControllerReference(cr, service, r.Scheme); err != nil {
		return ctrl.Result{}, err
	}

	// Check if this Service already exists
	serviceFound := &corev1.Service{}
	err := r.Get(context.Background(), types.NamespacedName{Name: service.Name, Namespace: service.Namespace}, serviceFound)
	if err != nil && errors.IsNotFound(err) {
		log.Info("Creating a new Service", "Service.Namespace", service.Namespace, "Service.Name", service.Name)
		err = r.Create(context.Background(), service)
		if err != nil {
			return ctrl.Result{}, err
		}
		// Service created successfully - don't requeue
		return ctrl.Result{}, nil
	} else if err != nil {
		return ctrl.Result{}, err
	} else {
		// Service already exists
		log.Info("Service already exists", "Service.Namespace", serviceFound.Namespace, "Service.Name", serviceFound.Name)
	}
	// Service reconcile finished
	return ctrl.Result{}, nil
}

// SetupWithManager sets up the controller with the Manager.
func (r *TangServerReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&daemonsv1alpha1.TangServer{}).
		Owns(&appsv1.Deployment{}).
		Owns(&corev1.Service{}).
		Complete(r)
}
