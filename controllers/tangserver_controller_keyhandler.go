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
	"github.com/go-logr/logr"
	daemonsv1alpha1 "github.com/sarroutbi/tang-operator/api/v1alpha1"
	"strings"
)

type SHAType uint8
type FileModType uint8

const (
	UNKNOWN_SHA SHAType = iota
	SHA256
	SHA1
)

const (
	UNKNOWN_MOD FileModType = iota
	CREATION
	MODIFICATION
)

const DEFAULT_DEPLOYMENT_KEY_PATH = "/var/db/tang"

var FORBIDDEN_PATH_MAP = map[string]string{
	".":          "FORBIDDEN",
	"..":         "FORBIDDEN",
	"lost+found": "FORBIDDEN",
}

type KeyObtainInfo struct {
	PodName    string
	Namespace  string
	DbPath     string
	TangServer *daemonsv1alpha1.TangServer
}

type KeyRotateInfo struct {
	KeyInfo     *KeyObtainInfo
	KeyFileName string
}

func getDefaultKeyPath(cr *daemonsv1alpha1.TangServer) string {
	if cr.Spec.KeyPath != "" {
		return cr.Spec.KeyPath
	}
	return DEFAULT_DEPLOYMENT_KEY_PATH
}

// readActiveKeys function return active key list
func readActiveKeys(keyInfo KeyObtainInfo, log logr.Logger) ([]daemonsv1alpha1.TangServerActiveKeys, error) {
	command := "ls " + keyInfo.DbPath
	stdo, stde, err := podCommandExec(command, "", keyInfo.PodName, keyInfo.Namespace, nil)
	if err != nil {
		log.Error(err, "Unable to execute command in Pod", "command", command, "stderror", stde, "podname", keyInfo.PodName, "namespace", keyInfo.Namespace)
	} else {
		log.Info("Executed active keys retrieval command correctly", "Active keys:", stdo)
		keys := strings.Split(stdo, "\n")
		activeKeys := make([]daemonsv1alpha1.TangServerActiveKeys, 0)
		for _, k := range keys {
			if len(k) > 0 {
				if _, forbidden := FORBIDDEN_PATH_MAP[k]; forbidden {
					continue
				}
				k = strings.TrimLeft(strings.TrimRight(k, "\n"), "\n")
				k = strings.TrimLeft(strings.TrimRight(k, "\r"), "\r")
				fpath := keyInfo.DbPath + "/" + k
				sha1 := getSHA(SHA1, keyInfo, fpath, log)
				sha256 := getSHA(SHA256, keyInfo, fpath, log)
				creationTime := getLastTime(CREATION, keyInfo, fpath, log)
				activeKeys = append(activeKeys, daemonsv1alpha1.TangServerActiveKeys{
					Sha1:      sha1,
					Sha256:    sha256,
					Generated: creationTime,
					FileName:  k,
				})
			}
		}
		return activeKeys, nil
	}
	return nil, err
}

// readHiddenKeys function return hidden key list
func readHiddenKeys(keyInfo KeyObtainInfo, log logr.Logger) ([]daemonsv1alpha1.TangServerHiddenKeys, error) {
	command := "ls -a " + keyInfo.DbPath + "/"
	stdo, stde, err := podCommandExec(command, "", keyInfo.PodName, keyInfo.Namespace, nil)
	if err != nil {
		log.Error(err, "Unable to execute command in Pod", "command", command, "stdo", stdo, "stderror", stde, "podname", keyInfo.PodName, "namespace", keyInfo.Namespace)
	} else {
		log.Info("Executed hidden keys retrieval command correctly", "Hidden keys:", stdo)
		keys := strings.Split(stdo, "\n")
		hiddenKeys := make([]daemonsv1alpha1.TangServerHiddenKeys, 0)
		for _, k := range keys {
			if len(k) > 0 {
				if _, forbidden := FORBIDDEN_PATH_MAP[k]; forbidden {
					continue
				}
				if k[0] == '.' {
					k = strings.TrimLeft(strings.TrimRight(k, "\n"), "\n")
					k = strings.TrimLeft(strings.TrimRight(k, "\r"), "\r")
					fpath := keyInfo.DbPath + "/" + k
					sha1 := getSHA(SHA1, keyInfo, fpath, log)
					sha256 := getSHA(SHA256, keyInfo, fpath, log)
					hiddenKeys = append(hiddenKeys, daemonsv1alpha1.TangServerHiddenKeys{
						Sha1:      sha1,
						Sha256:    sha256,
						Generated: getCreationTimeFromKeys(keyInfo, sha1, log),
						Hidden:    getLastTime(MODIFICATION, keyInfo, fpath, log),
						FileName:  k,
					})

				}
			}
		}
		return hiddenKeys, nil
	}
	return nil, err
}

// getCreationTimeFromKeys function returns creation time for an active or hidden key with its sha1
func getCreationTimeFromKeys(keyInfo KeyObtainInfo, sha1 string, log logr.Logger) string {
	for _, k := range keyInfo.TangServer.Status.ActiveKeys {
		if k.Sha1 == sha1 {
			return k.Generated
		}
	}
	// Check if its already stored
	return getCreationTimeFromHiddenKey(keyInfo, sha1, log)
}

// getCreationTimeFromHiddenKey function returns creation time for an active key with its sha1
func getCreationTimeFromHiddenKey(keyInfo KeyObtainInfo, sha1 string, log logr.Logger) string {
	for _, k := range keyInfo.TangServer.Status.HiddenKeys {
		if k.Sha1 == sha1 {
			return k.Generated
		}
	}
	return "UNKNOWN_CREATION_TIME"
}

// createNewPairOfKeys function creates new pair of keys (via /usr/libexec/tangd-keygen)
func createNewPairOfKeys(k KeyObtainInfo, log logr.Logger) error {
	command := "/usr/libexec/tangd-keygen " + k.DbPath + "/"
	stdo, stde, err := podCommandExec(command, "", k.PodName, k.Namespace, nil)
	if err != nil {
		log.Error(err, "Unable to execute command in Pod", "command", command, "stdo", stdo, "stderror", stde, "podname", k.PodName, "namespace", k.Namespace)
	}
	return err
}

// rotateKey function rotate key file, moving it to hidden file
func rotateKey(k KeyRotateInfo, log logr.Logger) error {
	command := "mv " + k.KeyInfo.DbPath + "/" + k.KeyFileName + " " + k.KeyInfo.DbPath + "/." + k.KeyFileName
	stdo, stde, err := podCommandExec(command, "", k.KeyInfo.PodName, k.KeyInfo.Namespace, nil)
	if err != nil {
		log.Error(err, "Unable to execute command in Pod", "command", command, "stdo", stdo, "stderror", stde, "podname", k.KeyInfo.PodName, "namespace", k.KeyInfo.Namespace)
	}
	return err
}

// getSHA function returns SHA1 or SHA256 of the file provided in the parameters
func getSHA(shaType SHAType, keyInfo KeyObtainInfo, filePath string, log logr.Logger) string {
	alg := "Unknown"
	switch shaType {
	case SHA1:
		alg = "S1"
	case SHA256:
		alg = "S256"
	}
	command := "jose jwk thp -a" + alg + " -i " + filePath
	stdo, stde, err := podCommandExec(command, "", keyInfo.PodName, keyInfo.Namespace, nil)
	if err != nil {
		log.Error(err, "Unable to execute command in Pod", "command", command, "stdo", stdo, "stderror", stde, "podname", keyInfo.PodName, "namespace", keyInfo.Namespace)
		return ""
	}
	return stdo
}

// getLastTime indicates last creation/modficiation time of the file
func getLastTime(fmod FileModType, keyInfo KeyObtainInfo, filePath string, log logr.Logger) string {
	command := "stat -c "
	ftype := ""
	switch fmod {
	case CREATION:
		ftype += "'%y'"
	case MODIFICATION:
		ftype += "'%z'"
	}
	command += ftype + " " + filePath
	stdo, stde, err := podCommandExec(command, "", keyInfo.PodName, keyInfo.Namespace, nil)
	if err != nil {
		log.Error(err, "Unable to execute command in Pod", "command", command, "stdo", stdo, "stderror", stde, "podname", keyInfo.PodName, "namespace", keyInfo.Namespace)
		return ""
	}
	return strings.TrimLeft(strings.TrimRight(stdo, "\n"), "\n")
}

// deleteHiddenKeys function return active key list
func deleteHiddenKeys(keyInfo KeyObtainInfo, log logr.Logger) {
	if len(keyInfo.TangServer.Status.ActiveKeys) > 0 {
		command := "rm -frv"
		for _, kf := range keyInfo.TangServer.Status.HiddenKeys {
			command += " " + keyInfo.DbPath + "/" + kf.FileName
		}
		stdo, stde, err := podCommandExec(command, "", keyInfo.PodName, keyInfo.Namespace, nil)
		log.Info("Executing command in Pod", "command", command, "podname", keyInfo.PodName)
		if err != nil {
			log.Error(err, "Unable to execute command in Pod", "command", command, "stdo", stdo, "stderror", stde, "podname", keyInfo.PodName, "namespace", keyInfo.Namespace)
		} else {
			log.Info("Command correctly executed", "output", stdo, "error", stde)
		}
	}
}
