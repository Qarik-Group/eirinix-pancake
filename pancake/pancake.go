package hello

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	eirinix "github.com/SUSE/eirinix"
	"github.com/cloudfoundry-community/go-cfenv"
	"github.com/mitchellh/mapstructure"
	"github.com/starkandwayne/cf-pancake/flatten"
	"go.uber.org/zap"
	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

// Extension changes pod definitions
type Extension struct{ Logger *zap.SugaredLogger }

// New returns the persi extension
func New() eirinix.Extension {
	return &Extension{}
}

// Handle manages volume claims for ExtendedStatefulSet pods
func (ext *Extension) Handle(ctx context.Context, eiriniManager eirinix.Manager, pod *corev1.Pod, req admission.Request) admission.Response {

	if pod == nil {
		return admission.Errored(http.StatusBadRequest, errors.New("No pod could be decoded from the request"))
	}

	log := eiriniManager.GetLogger().Named("cf-pancake")
	ext.Logger = log

	podCopy := pod.DeepCopy()
	vcapServicesEnvVar := ""
	for _, envvar := range podCopy.Spec.Containers[0].Env {
		if envvar.Name == "VCAP_SERVICES" {
			vcapServicesEnvVar = envvar.Value
			break
		}
	}
	if vcapServicesEnvVar == "" {
		log.Infof("Pod does not contain $VCAP_SERVICES: %s (%s)", podCopy.Name, podCopy.Namespace)
		return eiriniManager.PatchFromPod(req, podCopy)
	}

	var rawServices map[string]interface{}
	if err := json.Unmarshal([]byte(vcapServicesEnvVar), &rawServices); err != nil {
		log.Error(err)
		return eiriniManager.PatchFromPod(req, podCopy)
	}

	vcapServices := make(cfenv.Services)
	for k, v := range rawServices {
		var serviceInstances []cfenv.Service
		if err := mapstructure.WeakDecode(v, &serviceInstances); err != nil {
			log.Error(err)
			return eiriniManager.PatchFromPod(req, podCopy)
		}
		vcapServices[k] = serviceInstances
	}

	flattenedEnvVars := flatten.VCAPServices(&vcapServices)

	log.Infof("Found $VCAP_SERVICES in %s (%s): %#v", podCopy.Name, podCopy.Namespace, flattenedEnvVars)
	return eiriniManager.PatchFromPod(req, podCopy)
}
