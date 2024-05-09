package main

import (
	"encoding/hex"
	"fmt"

	"github.com/herumi/bls-eth-go-binary/bls"
)

func main() {
	bls.Init(bls.BLS12_381)
	bls.SetETHmode(bls.EthModeDraft07)

	signatureHex := "95f06dab8f67a4bb2dc54c43a717da4588839f103d2a40e6bc13d69fd07d05eaea552b61095bddbb026b5f8e9e0f441508594f5d8e9c2355e6800ced624bac2f89dd6ffa12766966b29e02ad0b1bc4de538f50a805133724706c3a547701845b"
	publicKeyHex := "966c488d807b3208bb1b10a1af422bac8d363c8015cda4e24d214549ced019cd3dd575545dd887461cae3f70d95cb061"
	messageHex := "a5acaa2107efba9860f6cc3a93f8309404862abaeb0d2ac3539fdef24e2dd615"

	signatureBytes, _ := hex.DecodeString(signatureHex)
	publicKeyBytes, _ := hex.DecodeString(publicKeyHex)
	messageBytes, _ := hex.DecodeString(messageHex)

	var pubKey bls.PublicKey
	var sig bls.Sign

	pubKey.Deserialize(publicKeyBytes)
	sig.Deserialize(signatureBytes)

	if sig.VerifyHash(&pubKey, messageBytes) {
		fmt.Println("Signature verification successful!")
	} else {
		fmt.Println("Signature verification failed!")
	}
}
