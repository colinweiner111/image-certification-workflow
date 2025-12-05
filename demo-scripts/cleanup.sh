#!/bin/bash
# Cleanup all demo resources
az group delete --name rg-aib-images --yes --no-wait
az group delete --name rg-acg --yes --no-wait
az group delete --name rg-demo --yes --no-wait
