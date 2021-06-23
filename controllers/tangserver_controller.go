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
	"k8s.io/apimachinery/pkg/api/errors"
)

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
//+kubebuilder:rbac:groups=daemons.redhat,resources=tangservers,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=daemons.redhat,resources=tangservers/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=daemons.redhat,resources=tangservers/finalizers,verbs=update
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=pods,verbs=get;list;
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

func (r *TangServerReconciler) reconcileDeployment(cr *daemonsv1alpha1.TangServer, log logr.Logger) (ctrl.Result, error) {
	// TODO: Reconcile Deployment
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
