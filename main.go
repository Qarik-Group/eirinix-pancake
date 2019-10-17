package main

import (
	"fmt"
	"os"

	eirinix "github.com/SUSE/eirinix"
	pancake "github.com/starkandwayne/eirinix-pancake/pancake"
)

func main() {
	fmt.Println("Running starkandwayne/eirinix-pancake...")
	options := eirinix.ManagerOptions{
		Namespace:           os.Getenv("POD_NAMESPACE"),
		Host:                "0.0.0.0",
		Port:                4545,
		ServiceName:         os.Getenv("WEBHOOK_SERVICE_NAME"),
		WebhookNamespace:    os.Getenv("WEBHOOK_NAMESPACE"),
		OperatorFingerprint: "eirini-x-starkandwayne-pancake",
	}
	fmt.Printf("--> %#v\n", options)
	x := eirinix.NewManager(options)
	x.AddExtension(&pancake.Extension{})
	x.Start()
}
