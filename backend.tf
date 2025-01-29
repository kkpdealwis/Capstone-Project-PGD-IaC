terraform { 
  backend "remote" {
    organization = "kkpdealwis93"
    workspaces {
      name = "edureka-pdp-workspace"
    }
  }
}